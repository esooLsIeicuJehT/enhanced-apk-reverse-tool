#!/usr/bin/env python3
"""Production API for the Enhanced APK Reverse Engineering Tool.

The API keeps durable user/analysis metadata in SQLite and runs the existing
shell analyzer in a bounded background worker.  It intentionally uses a single
application worker plus threads so Socket.IO and the local analysis queue share
one process.  Scale-out should replace the local queue with a durable broker.
"""

from __future__ import annotations

import json
import logging
import os
import queue
import re
import secrets
import shutil
import sqlite3
import subprocess
import threading
import uuid
import zipfile
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Dict, Optional

import jwt
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_socketio import SocketIO, emit, join_room, leave_room
from werkzeug.security import check_password_hash, generate_password_hash
from werkzeug.utils import secure_filename


BASE_DIR = Path(__file__).resolve().parents[1]
DATA_DIR = Path(os.environ.get("DATA_DIR", BASE_DIR / "data")).resolve()
UPLOAD_DIR = DATA_DIR / "uploads"
RESULTS_DIR = DATA_DIR / "results"
WORK_DIR = DATA_DIR / "work"
DATABASE_PATH = Path(os.environ.get("DATABASE_PATH", DATA_DIR / "apktool.db")).resolve()
TOOL_SCRIPT = Path(os.environ.get("APK_TOOL_SCRIPT", BASE_DIR / "apk-reverse-tool.sh")).resolve()

for directory in (DATA_DIR, UPLOAD_DIR, RESULTS_DIR, WORK_DIR):
    directory.mkdir(parents=True, exist_ok=True)


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.environ.get(name, str(default)))
    except ValueError as exc:
        raise RuntimeError(f"{name} must be an integer") from exc


def _runtime_secret(name: str) -> str:
    value = os.environ.get(name)
    if value:
        return value
    if os.environ.get("APP_ENV", "development").lower() == "production":
        raise RuntimeError(f"{name} must be set when APP_ENV=production")
    return secrets.token_urlsafe(48)


class Config:
    SECRET_KEY = _runtime_secret("SECRET_KEY")
    JWT_SECRET_KEY = _runtime_secret("JWT_SECRET_KEY")
    JWT_EXPIRATION_HOURS = _env_int("JWT_EXPIRATION_HOURS", 24)
    MAX_CONTENT_LENGTH = _env_int("MAX_UPLOAD_SIZE", 512 * 1024 * 1024)
    ANALYSIS_TIMEOUT = _env_int("MAX_ANALYSIS_TIME", 3600)
    MAX_QUEUE_SIZE = _env_int("MAX_QUEUE_SIZE", 16)
    MAX_ZIP_ENTRIES = _env_int("MAX_ZIP_ENTRIES", 200_000)
    MAX_UNCOMPRESSED_BYTES = _env_int("MAX_UNCOMPRESSED_BYTES", 2 * 1024 * 1024 * 1024)
    DELETE_UPLOADS_AFTER_ANALYSIS = os.environ.get("DELETE_UPLOADS_AFTER_ANALYSIS", "true").lower() in {
        "1",
        "true",
        "yes",
    }
    CORS_ALLOWED_ORIGINS = [
        origin.strip()
        for origin in os.environ.get("CORS_ALLOWED_ORIGINS", "http://localhost:3000").split(",")
        if origin.strip()
    ]


logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("apktool.api")

app = Flask(__name__)
app.config.from_object(Config)
CORS(app, origins=Config.CORS_ALLOWED_ORIGINS)
socketio = SocketIO(
    app,
    cors_allowed_origins=Config.CORS_ALLOWED_ORIGINS,
    async_mode="threading",
    logger=False,
    engineio_logger=False,
)

analysis_queue: queue.Queue[str] = queue.Queue(maxsize=Config.MAX_QUEUE_SIZE)
_worker_lock = threading.Lock()
_worker_thread: Optional[threading.Thread] = None

USERNAME_RE = re.compile(r"^[A-Za-z0-9_.-]{3,64}$")
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")
ALLOWED_OPTION_KEYS = {
    "deep_analysis",
    "vulnerability_scan",
    "certificate_analysis",
    "permission_analysis",
    "code_analysis",
    "owasp_scan",
    "malware_detection",
}


@dataclass(frozen=True)
class User:
    id: str
    username: str
    email: str
    password_hash: str
    created_at: str
    last_login: Optional[str] = None


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def db_connect() -> sqlite3.Connection:
    connection = sqlite3.connect(DATABASE_PATH, timeout=30)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def init_db() -> None:
    DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with db_connect() as db:
        db.execute("PRAGMA journal_mode = WAL")
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                username TEXT NOT NULL UNIQUE COLLATE NOCASE,
                email TEXT NOT NULL UNIQUE COLLATE NOCASE,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL,
                last_login TEXT
            )
            """
        )
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS analyses (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                filename TEXT NOT NULL,
                file_path TEXT NOT NULL,
                options_json TEXT NOT NULL DEFAULT '{}',
                status TEXT NOT NULL,
                progress INTEGER NOT NULL DEFAULT 0,
                current_step TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL,
                started_at TEXT,
                completed_at TEXT,
                result_path TEXT,
                error TEXT,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )
            """
        )
        db.execute("CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON analyses(user_id, created_at DESC)")
        db.commit()


init_db()


def allowed_file(filename: str) -> bool:
    return bool(filename and "." in filename and filename.rsplit(".", 1)[1].lower() == "apk")


def validate_apk_archive(path: Path) -> tuple[bool, str]:
    if not zipfile.is_zipfile(path):
        return False, "Uploaded file is not a valid APK/ZIP archive"

    try:
        with zipfile.ZipFile(path) as archive:
            infos = archive.infolist()
            if len(infos) > Config.MAX_ZIP_ENTRIES:
                return False, "APK contains too many archive entries"

            total_uncompressed = 0
            has_manifest = False
            for info in infos:
                member = PurePosixPath(info.filename)
                if member.is_absolute() or ".." in member.parts:
                    return False, "APK contains an unsafe archive path"
                if info.flag_bits & 0x1:
                    return False, "Encrypted APK archives are not supported"
                total_uncompressed += info.file_size
                if total_uncompressed > Config.MAX_UNCOMPRESSED_BYTES:
                    return False, "APK expands beyond the configured analysis limit"
                if info.filename == "AndroidManifest.xml":
                    has_manifest = True

            if not has_manifest:
                return False, "APK is missing AndroidManifest.xml"
    except (OSError, zipfile.BadZipFile) as exc:
        logger.warning("APK validation failed: %s", exc)
        return False, "APK archive could not be read"

    return True, ""


def generate_jwt_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "user_id": user_id,
        "iat": now,
        "exp": now + timedelta(hours=Config.JWT_EXPIRATION_HOURS),
    }
    return jwt.encode(payload, Config.JWT_SECRET_KEY, algorithm="HS256")


def verify_jwt_token(token: str) -> Optional[str]:
    if not token:
        return None
    try:
        payload = jwt.decode(token, Config.JWT_SECRET_KEY, algorithms=["HS256"])
        return payload.get("user_id") or payload.get("sub")
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None


def _user_from_row(row: Optional[sqlite3.Row]) -> Optional[User]:
    if row is None:
        return None
    return User(
        id=row["id"],
        username=row["username"],
        email=row["email"],
        password_hash=row["password_hash"],
        created_at=row["created_at"],
        last_login=row["last_login"],
    )


def get_user_by_token(token: str) -> Optional[User]:
    user_id = verify_jwt_token(token)
    if not user_id:
        return None
    with db_connect() as db:
        return _user_from_row(db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone())


def _bearer_token() -> str:
    authorization = request.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return ""
    return authorization[7:].strip()


def _analysis_for_user(analysis_id: str, user_id: str) -> Optional[sqlite3.Row]:
    with db_connect() as db:
        return db.execute(
            "SELECT * FROM analyses WHERE id = ? AND user_id = ?",
            (analysis_id, user_id),
        ).fetchone()


def _set_analysis_state(
    analysis_id: str,
    *,
    status: Optional[str] = None,
    progress: Optional[int] = None,
    current_step: Optional[str] = None,
    started_at: Optional[str] = None,
    completed_at: Optional[str] = None,
    result_path: Optional[str] = None,
    error: Optional[str] = None,
) -> None:
    fields: list[str] = []
    values: list[Any] = []
    for column, value in (
        ("status", status),
        ("progress", progress),
        ("current_step", current_step),
        ("started_at", started_at),
        ("completed_at", completed_at),
        ("result_path", result_path),
        ("error", error),
    ):
        if value is not None:
            fields.append(f"{column} = ?")
            values.append(value)
    if not fields:
        return
    values.append(analysis_id)
    with db_connect() as db:
        db.execute(f"UPDATE analyses SET {', '.join(fields)} WHERE id = ?", values)
        db.commit()


def _emit_update(analysis_id: str, event: str, payload: Dict[str, Any]) -> None:
    socketio.emit(event, {"analysis_id": analysis_id, **payload}, room=analysis_id)


def _bool_option(options: Dict[str, Any], key: str, default: bool) -> bool:
    value = options.get(key, default)
    if isinstance(value, bool):
        return value
    raise ValueError(f"Option '{key}' must be a boolean")


def _prepare_analysis_environment(analysis_id: str, options: Dict[str, Any]) -> tuple[Dict[str, str], Path]:
    unknown = set(options) - ALLOWED_OPTION_KEYS
    if unknown:
        raise ValueError(f"Unsupported analysis options: {', '.join(sorted(unknown))}")

    home = WORK_DIR / analysis_id / "home"
    config_dir = home / ".apk-reverse-tool" / "configs"
    config_dir.mkdir(parents=True, exist_ok=True)

    config = f"""# Generated per-analysis configuration.\n
APKTOOL_VER=\"latest\"\n
FRIDA_VER=\"latest\"\n
BUILDTOOLS_VER=\"33.0.1\"\n
ENABLE_DEEP_ANALYSIS={'true' if _bool_option(options, 'deep_analysis', False) else 'false'}\n
ENABLE_VULNERABILITY_SCAN={'true' if _bool_option(options, 'vulnerability_scan', True) else 'false'}\n
ENABLE_CERTIFICATE_ANALYSIS={'true' if _bool_option(options, 'certificate_analysis', True) else 'false'}\n
ENABLE_PERMISSION_ANALYSIS={'true' if _bool_option(options, 'permission_analysis', True) else 'false'}\n
DEFAULT_OUTPUT_FORMAT=\"json\"\n
ENABLE_VERBOSITY=false\n
CREATE_BACKUPS=false\n
CHECK_DEVICE_COMPATIBILITY=false\n
AUTO_DETECT_ARCH=true\n
ENABLE_OBFUSCATION_DETECTION=true\n
ENABLE_ANTI_TAMPERING_CHECK=true\n
ENABLE_CODE_ANALYSIS={'true' if _bool_option(options, 'code_analysis', True) else 'false'}\n
LOAD_PLUGINS=false\n
PLUGIN_DIR=\"$HOME/.apk-reverse-tool/plugins\"\n
"""
    (config_dir / "default.conf").write_text(config, encoding="utf-8")

    environment = os.environ.copy()
    environment["HOME"] = str(home)
    environment["ENABLE_OWASP_SCAN"] = "true" if _bool_option(options, "owasp_scan", True) else "false"
    environment["ENABLE_MALWARE_DETECTION"] = (
        "true" if _bool_option(options, "malware_detection", True) else "false"
    )
    return environment, home


def run_apk_analysis(analysis_id: str) -> Dict[str, Any]:
    with db_connect() as db:
        row = db.execute("SELECT * FROM analyses WHERE id = ?", (analysis_id,)).fetchone()
    if row is None:
        raise RuntimeError("Analysis record disappeared")

    apk_path = Path(row["file_path"])
    if not apk_path.is_file():
        raise FileNotFoundError("Uploaded APK is no longer available")
    if not TOOL_SCRIPT.is_file():
        raise FileNotFoundError(f"Analyzer script not found: {TOOL_SCRIPT}")

    options = json.loads(row["options_json"] or "{}")
    environment, analysis_home = _prepare_analysis_environment(analysis_id, options)
    report_dir = Path(f"{str(apk_path)[:-4]}_analysis")
    report_path = report_dir / "analysis_report.json"

    try:
        completed = subprocess.run(
            ["bash", str(TOOL_SCRIPT), "analyze", str(apk_path)],
            cwd=BASE_DIR,
            env=environment,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=Config.ANALYSIS_TIMEOUT,
            check=False,
        )

        output_tail = (completed.stdout or "")[-6000:]
        if completed.returncode != 0:
            raise RuntimeError(f"Analyzer exited with code {completed.returncode}: {output_tail}")
        if not report_path.is_file():
            raise RuntimeError("Analyzer completed without producing analysis_report.json")

        result = json.loads(report_path.read_text(encoding="utf-8"))
        destination = RESULTS_DIR / f"{analysis_id}.json"
        destination.write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
        _set_analysis_state(analysis_id, result_path=str(destination))
        return result
    finally:
        shutil.rmtree(report_dir, ignore_errors=True)
        shutil.rmtree(analysis_home.parent, ignore_errors=True)
        if Config.DELETE_UPLOADS_AFTER_ANALYSIS:
            apk_path.unlink(missing_ok=True)


def analysis_worker() -> None:
    logger.info("Analysis worker started")
    while True:
        analysis_id = analysis_queue.get()
        try:
            started_at = utc_now()
            _set_analysis_state(
                analysis_id,
                status="running",
                progress=10,
                current_step="Running analyzer",
                started_at=started_at,
                error="",
            )
            _emit_update(
                analysis_id,
                "analysis_update",
                {"status": "running", "progress": 10, "current_step": "Running analyzer"},
            )

            result = run_apk_analysis(analysis_id)
            completed_at = utc_now()
            _set_analysis_state(
                analysis_id,
                status="completed",
                progress=100,
                current_step="Completed",
                completed_at=completed_at,
                error="",
            )
            _emit_update(analysis_id, "analysis_complete", {"status": "completed", "progress": 100, "result": result})
            logger.info("Analysis %s completed", analysis_id)
        except subprocess.TimeoutExpired:
            message = f"Analysis exceeded the {Config.ANALYSIS_TIMEOUT}s timeout"
            _set_analysis_state(
                analysis_id,
                status="failed",
                progress=100,
                current_step="Failed",
                completed_at=utc_now(),
                error=message,
            )
            _emit_update(analysis_id, "analysis_error", {"status": "failed", "error": message})
            logger.warning("Analysis %s timed out", analysis_id)
        except Exception as exc:  # keep worker alive after one failed APK
            message = str(exc)[:6000]
            _set_analysis_state(
                analysis_id,
                status="failed",
                progress=100,
                current_step="Failed",
                completed_at=utc_now(),
                error=message,
            )
            _emit_update(analysis_id, "analysis_error", {"status": "failed", "error": message})
            logger.exception("Analysis %s failed", analysis_id)
        finally:
            analysis_queue.task_done()


def start_analysis_worker() -> threading.Thread:
    global _worker_thread
    with _worker_lock:
        if _worker_thread and _worker_thread.is_alive():
            return _worker_thread
        _worker_thread = threading.Thread(target=analysis_worker, name="apk-analysis-worker", daemon=True)
        _worker_thread.start()

        # Recover work that was queued/running when a single-process instance restarted.
        with db_connect() as db:
            pending = db.execute(
                "SELECT id, file_path FROM analyses WHERE status IN ('queued', 'running') ORDER BY created_at ASC"
            ).fetchall()
            for row in pending:
                if not Path(row["file_path"]).is_file():
                    db.execute(
                        "UPDATE analyses SET status='failed', progress=100, completed_at=?, error=? WHERE id=?",
                        (utc_now(), "Uploaded APK is unavailable after restart", row["id"]),
                    )
                    continue
                db.execute(
                    "UPDATE analyses SET status='queued', progress=0, current_step='Queued after restart' WHERE id=?",
                    (row["id"],),
                )
                try:
                    analysis_queue.put_nowait(row["id"])
                except queue.Full:
                    break
            db.commit()
        return _worker_thread


@app.errorhandler(413)
def request_too_large(_error):
    return jsonify({"error": "Upload exceeds MAX_UPLOAD_SIZE"}), 413


@app.route("/api/auth/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    username = str(data.get("username", "")).strip()
    email = str(data.get("email", "")).strip().lower()
    password = str(data.get("password", ""))

    if not USERNAME_RE.fullmatch(username):
        return jsonify({"error": "Username must be 3-64 characters using letters, numbers, ., _, or -"}), 400
    if not EMAIL_RE.fullmatch(email):
        return jsonify({"error": "A valid email address is required"}), 400
    if len(password) < 10:
        return jsonify({"error": "Password must be at least 10 characters"}), 400

    user_id = str(uuid.uuid4())
    created_at = utc_now()
    try:
        with db_connect() as db:
            db.execute(
                "INSERT INTO users(id, username, email, password_hash, created_at) VALUES (?, ?, ?, ?, ?)",
                (user_id, username, email, generate_password_hash(password), created_at),
            )
            db.commit()
    except sqlite3.IntegrityError:
        return jsonify({"error": "Username or email already exists"}), 409

    return (
        jsonify(
            {
                "token": generate_jwt_token(user_id),
                "user": {"id": user_id, "username": username, "email": email},
            }
        ),
        201,
    )


@app.route("/api/auth/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = str(data.get("username", "")).strip()
    password = str(data.get("password", ""))
    if not username or not password:
        return jsonify({"error": "Missing username or password"}), 400

    with db_connect() as db:
        row = db.execute("SELECT * FROM users WHERE username = ? COLLATE NOCASE", (username,)).fetchone()
        user = _user_from_row(row)
        if not user or not check_password_hash(user.password_hash, password):
            return jsonify({"error": "Invalid credentials"}), 401
        db.execute("UPDATE users SET last_login = ? WHERE id = ?", (utc_now(), user.id))
        db.commit()

    return jsonify(
        {
            "token": generate_jwt_token(user.id),
            "user": {"id": user.id, "username": user.username, "email": user.email},
        }
    )


@app.route("/api/analysis/upload", methods=["POST"])
def upload_file():
    user = get_user_by_token(_bearer_token())
    if not user:
        return jsonify({"error": "Authentication required"}), 401

    upload = request.files.get("file")
    if upload is None or not upload.filename:
        return jsonify({"error": "No APK file provided"}), 400
    if not allowed_file(upload.filename):
        return jsonify({"error": "Only .apk files are accepted"}), 400

    raw_options = request.form.get("options", "{}")
    try:
        options = json.loads(raw_options)
    except json.JSONDecodeError:
        return jsonify({"error": "options must be valid JSON"}), 400
    if not isinstance(options, dict):
        return jsonify({"error": "options must be a JSON object"}), 400
    unknown = set(options) - ALLOWED_OPTION_KEYS
    if unknown:
        return jsonify({"error": f"Unsupported options: {', '.join(sorted(unknown))}"}), 400
    try:
        for key in options:
            _bool_option(options, key, True)
    except ValueError as exc:
        return jsonify({"error": str(exc)}), 400

    analysis_id = str(uuid.uuid4())
    safe_stem = secure_filename(Path(upload.filename).stem)[:120] or "upload"
    final_path = UPLOAD_DIR / f"{analysis_id}_{safe_stem}.apk"
    temporary_path = UPLOAD_DIR / f".{analysis_id}.upload"

    try:
        upload.save(temporary_path)
        valid, reason = validate_apk_archive(temporary_path)
        if not valid:
            return jsonify({"error": reason}), 400
        os.replace(temporary_path, final_path)

        created_at = utc_now()
        with db_connect() as db:
            db.execute(
                """
                INSERT INTO analyses(
                    id, user_id, filename, file_path, options_json, status,
                    progress, current_step, created_at
                ) VALUES (?, ?, ?, ?, ?, 'queued', 0, 'Queued', ?)
                """,
                (
                    analysis_id,
                    user.id,
                    secure_filename(upload.filename),
                    str(final_path),
                    json.dumps(options, sort_keys=True),
                    created_at,
                ),
            )
            db.commit()

        try:
            analysis_queue.put_nowait(analysis_id)
        except queue.Full:
            with db_connect() as db:
                db.execute("DELETE FROM analyses WHERE id = ?", (analysis_id,))
                db.commit()
            final_path.unlink(missing_ok=True)
            return jsonify({"error": "Analysis queue is full; retry later"}), 503

        return jsonify({"analysis_id": analysis_id, "status": "queued", "message": "APK accepted for analysis"}), 202
    finally:
        temporary_path.unlink(missing_ok=True)


@app.route("/api/analysis/<analysis_id>/status", methods=["GET"])
def get_analysis_status(analysis_id: str):
    user = get_user_by_token(_bearer_token())
    if not user:
        return jsonify({"error": "Authentication required"}), 401

    row = _analysis_for_user(analysis_id, user.id)
    if row is None:
        return jsonify({"error": "Analysis not found"}), 404

    return jsonify(
        {
            "id": row["id"],
            "filename": row["filename"],
            "status": row["status"],
            "progress": row["progress"],
            "current_step": row["current_step"],
            "created_at": row["created_at"],
            "started_at": row["started_at"],
            "completed_at": row["completed_at"],
            "error": row["error"],
        }
    )


@app.route("/api/analysis/<analysis_id>/results", methods=["GET"])
def get_analysis_results(analysis_id: str):
    user = get_user_by_token(_bearer_token())
    if not user:
        return jsonify({"error": "Authentication required"}), 401

    row = _analysis_for_user(analysis_id, user.id)
    if row is None:
        return jsonify({"error": "Analysis not found"}), 404
    if row["status"] != "completed":
        return jsonify({"error": "Analysis has not completed", "status": row["status"]}), 409

    result_path = Path(row["result_path"] or "")
    if not result_path.is_file():
        return jsonify({"error": "Stored result is unavailable"}), 500
    try:
        return jsonify(json.loads(result_path.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError):
        logger.exception("Failed to read result for %s", analysis_id)
        return jsonify({"error": "Stored result is unreadable"}), 500


@app.route("/api/analysis/history", methods=["GET"])
def get_analysis_history():
    user = get_user_by_token(_bearer_token())
    if not user:
        return jsonify({"error": "Authentication required"}), 401

    with db_connect() as db:
        rows = db.execute(
            """
            SELECT id, filename, status, progress, current_step, created_at, started_at, completed_at, error
            FROM analyses WHERE user_id = ? ORDER BY created_at DESC LIMIT 100
            """,
            (user.id,),
        ).fetchall()
    return jsonify({"history": [dict(row) for row in rows]})


@socketio.on("connect")
def handle_connect():
    logger.debug("Socket.IO client connected")


@socketio.on("disconnect")
def handle_disconnect():
    logger.debug("Socket.IO client disconnected")


@socketio.on("join_analysis")
def handle_join_analysis(data):
    data = data or {}
    analysis_id = str(data.get("analysis_id", ""))
    user = get_user_by_token(str(data.get("token", "")))
    if not user or not analysis_id or _analysis_for_user(analysis_id, user.id) is None:
        emit("analysis_error", {"analysis_id": analysis_id, "error": "Unauthorized analysis subscription"})
        return
    join_room(analysis_id)
    emit("joined", {"analysis_id": analysis_id})


@socketio.on("leave_analysis")
def handle_leave_analysis(data):
    analysis_id = str((data or {}).get("analysis_id", ""))
    if analysis_id:
        leave_room(analysis_id)
        emit("left", {"analysis_id": analysis_id})


@app.route("/api/health", methods=["GET"])
@app.route("/health", methods=["GET"])
def health_check():
    database_ok = True
    try:
        with db_connect() as db:
            db.execute("SELECT 1").fetchone()
    except sqlite3.Error:
        database_ok = False
        logger.exception("Database health check failed")

    worker_ok = bool(_worker_thread and _worker_thread.is_alive())
    analyzer_ok = TOOL_SCRIPT.is_file()
    healthy = database_ok and analyzer_ok
    payload = {
        "status": "healthy" if healthy else "unhealthy",
        "database": "ok" if database_ok else "error",
        "analyzer_script": "ok" if analyzer_ok else "missing",
        "worker": "running" if worker_ok else "not_started",
        "queued_analyses": analysis_queue.qsize(),
        "timestamp": utc_now(),
    }
    return jsonify(payload), 200 if healthy else 503


@app.route("/", methods=["GET"])
def root():
    return jsonify(
        {
            "service": "Enhanced APK Reverse Engineering Tool API",
            "health": "/api/health",
            "version": "2.1.0",
        }
    )


if __name__ == "__main__":
    start_analysis_worker()
    socketio.run(
        app,
        host=os.environ.get("API_HOST", "0.0.0.0"),
        port=_env_int("API_PORT", 8080),
        debug=False,
    )
