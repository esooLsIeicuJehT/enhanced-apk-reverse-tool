import io
import json
import os
import queue
import sys
import tempfile
import zipfile
from pathlib import Path

import pytest

API_DIR = Path(__file__).resolve().parents[1]
TEST_DATA_DIR = Path(tempfile.mkdtemp(prefix="apk-tool-tests-"))

os.environ["APP_ENV"] = "test"
os.environ["DATA_DIR"] = str(TEST_DATA_DIR)
os.environ["DATABASE_PATH"] = str(TEST_DATA_DIR / "test.db")
os.environ["SECRET_KEY"] = "test-secret-key-not-for-production"
os.environ["JWT_SECRET_KEY"] = "test-jwt-secret-key-not-for-production"
os.environ["MAX_QUEUE_SIZE"] = "8"

sys.path.insert(0, str(API_DIR))
import server  # noqa: E402


@pytest.fixture(autouse=True)
def reset_state():
    with server.db_connect() as db:
        db.execute("DELETE FROM analyses")
        db.execute("DELETE FROM users")
        db.commit()

    while True:
        try:
            server.analysis_queue.get_nowait()
            server.analysis_queue.task_done()
        except queue.Empty:
            break

    yield


@pytest.fixture
def client():
    server.app.config.update(TESTING=True)
    return server.app.test_client()


def make_apk(*, traversal: bool = False, include_manifest: bool = True) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        if include_manifest:
            archive.writestr("AndroidManifest.xml", b"binary-manifest-placeholder")
        archive.writestr("classes.dex", b"dex\n035\x00")
        if traversal:
            archive.writestr("../escape.txt", b"nope")
    return buffer.getvalue()


def register_user(client, username: str = "tester") -> str:
    response = client.post(
        "/api/auth/register",
        json={
            "username": username,
            "email": f"{username}@example.com",
            "password": "correct-horse-battery-staple",
        },
    )
    assert response.status_code == 201, response.get_json()
    return response.get_json()["token"]


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def upload(client, token: str, apk: bytes, *, options: dict | None = None):
    return client.post(
        "/api/analysis/upload",
        headers=auth(token),
        data={
            "file": (io.BytesIO(apk), "sample.apk"),
            "options": json.dumps(options or {}),
        },
        content_type="multipart/form-data",
    )


def test_register_login_and_duplicate_identity(client):
    token = register_user(client)
    assert token

    login_response = client.post(
        "/api/auth/login",
        json={"username": "tester", "password": "correct-horse-battery-staple"},
    )
    assert login_response.status_code == 200
    assert login_response.get_json()["user"]["username"] == "tester"

    duplicate = client.post(
        "/api/auth/register",
        json={
            "username": "TESTER",
            "email": "different@example.com",
            "password": "correct-horse-battery-staple",
        },
    )
    assert duplicate.status_code == 409


def test_rejects_weak_registration_input(client):
    response = client.post(
        "/api/auth/register",
        json={"username": "x", "email": "not-an-email", "password": "short"},
    )
    assert response.status_code == 400


def test_upload_status_history_and_result_guard(client):
    token = register_user(client)
    response = upload(
        client,
        token,
        make_apk(),
        options={
            "owasp_scan": True,
            "malware_detection": False,
            "permission_analysis": True,
        },
    )
    assert response.status_code == 202, response.get_json()
    analysis_id = response.get_json()["analysis_id"]

    status_response = client.get(f"/api/analysis/{analysis_id}/status", headers=auth(token))
    assert status_response.status_code == 200
    status = status_response.get_json()
    assert status["status"] == "queued"
    assert status["filename"] == "sample.apk"

    history_response = client.get("/api/analysis/history", headers=auth(token))
    assert history_response.status_code == 200
    history = history_response.get_json()["history"]
    assert len(history) == 1
    assert history[0]["id"] == analysis_id

    results_response = client.get(f"/api/analysis/{analysis_id}/results", headers=auth(token))
    assert results_response.status_code == 409


def test_analysis_records_are_owner_scoped(client):
    owner_token = register_user(client, "owner")
    other_token = register_user(client, "other")
    response = upload(client, owner_token, make_apk())
    analysis_id = response.get_json()["analysis_id"]

    denied = client.get(f"/api/analysis/{analysis_id}/status", headers=auth(other_token))
    assert denied.status_code == 404


def test_upload_requires_authentication(client):
    response = client.post(
        "/api/analysis/upload",
        data={"file": (io.BytesIO(make_apk()), "sample.apk")},
        content_type="multipart/form-data",
    )
    assert response.status_code == 401


def test_rejects_non_apk_archives(client):
    token = register_user(client)
    response = upload(client, token, b"this is not a zip")
    assert response.status_code == 400
    assert "valid APK" in response.get_json()["error"]


def test_rejects_archive_path_traversal(client):
    token = register_user(client)
    response = upload(client, token, make_apk(traversal=True))
    assert response.status_code == 400
    assert "unsafe archive path" in response.get_json()["error"]


def test_rejects_missing_manifest(client):
    token = register_user(client)
    response = upload(client, token, make_apk(include_manifest=False))
    assert response.status_code == 400
    assert "AndroidManifest.xml" in response.get_json()["error"]


def test_rejects_unknown_or_non_boolean_options(client):
    token = register_user(client)

    unknown = upload(client, token, make_apk(), options={"pretend_scan": True})
    assert unknown.status_code == 400

    wrong_type = upload(client, token, make_apk(), options={"owasp_scan": "yes"})
    assert wrong_type.status_code == 400


def test_websocket_room_requires_analysis_ownership(client):
    token = register_user(client)
    response = upload(client, token, make_apk())
    analysis_id = response.get_json()["analysis_id"]

    socket_client = server.socketio.test_client(server.app)
    socket_client.emit("join_analysis", {"analysis_id": analysis_id, "token": token})
    names = [packet["name"] for packet in socket_client.get_received()]
    assert "joined" in names
    socket_client.disconnect()

    unauthenticated = server.socketio.test_client(server.app)
    unauthenticated.emit("join_analysis", {"analysis_id": analysis_id, "token": "invalid"})
    names = [packet["name"] for packet in unauthenticated.get_received()]
    assert "analysis_error" in names
    unauthenticated.disconnect()


def test_health_endpoint_checks_real_dependencies(client):
    response = client.get("/api/health")
    assert response.status_code == 200
    body = response.get_json()
    assert body["status"] == "healthy"
    assert body["database"] == "ok"
    assert body["analyzer_script"] == "ok"
