# Enhanced APK Reverse Tool

Production-oriented static analysis for Android APK files, with a CLI, authenticated API, browser console, durable analysis history, Docker deployment, and evidence-based security reporting.

The project deliberately avoids presenting heuristics as certainty. Static findings are accompanied by evidence and limitations, and the risk-indicator engine explicitly does **not** claim to decide whether an APK is malware.

## What is production-supported

### CLI

```bash
./apk-reverse-tool.sh analyze app.apk
./apk-reverse-tool.sh pull com.example.app
./apk-reverse-tool.sh help
```

`analyze` produces a JSON report containing:

- package/version/SDK metadata from `aapt`
- manifest permission inventory and sensitive-permission count
- APK signing metadata when it can be verified with the installed signing tools
- OWASP Mobile-aligned static findings backed by concrete manifest/code/resource evidence
- static risk indicators for high-impact capabilities and credential-shaped literals
- measured package structure such as DEX count/size, native libraries, assets, and resources

`pull` uses an authorized ADB device. Split APKs are preserved as separate files instead of pretending to create a universal APK.

### Web/API stack

The Docker deployment contains two services:

- **apk-tool**: Flask API, SQLite metadata/history, bounded analysis queue, static-analysis toolchain
- **web-interface**: unprivileged nginx + React console, with `/api` and `/socket.io` proxied to the backend

The browser console supports:

- account registration and sign-in
- validated APK uploads
- per-analysis module selection
- queued/running/completed/failed status
- durable analysis history
- JSON result viewing

## What this project does not claim

The production entrypoint does **not** currently advertise or expose APK patching, rebuilding, package renaming, Frida gadget injection, plugin loading, PWA push notifications, or a trained machine-learning malware classifier.

Those capabilities should only be added back when they have implementation, tests, packaging, and release support equal to the production paths above.

## Static-analysis semantics

### OWASP evidence scan

The OWASP-aligned scanner reports concrete static observations such as:

- `android:debuggable=true`
- explicit cleartext-traffic permission in the manifest/network security configuration
- exported components that have no manifest permission gate
- public `http://` endpoint literals
- world-readable/world-writeable storage API references
- strongly credential-shaped literals, without printing the matched secret

It intentionally does **not** infer SQL injection from the presence of SQL strings, infer missing TLS pinning from normal TLS API usage, or label root-detection code as a vulnerability.

### Static risk indicators

The risk engine reports a **review-priority score**, not a malware probability. Example indicators include:

- explicit debug mode
- public cleartext HTTP literals
- credential-shaped embedded material
- dynamic code-loading APIs
- process/shell execution APIs
- combined package-install and overlay permissions
- multiple SMS capabilities

Every report states that static analysis cannot prove an APK safe or malicious.

## Quick start with Docker

### 1. Configure secrets

```bash
cp .env.example .env
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
```

Put the two different generated values into `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`.

### 2. Validate and start

```bash
docker compose config --quiet
docker compose up -d --build
```

### 3. Check health

```bash
curl --fail http://127.0.0.1:8080/api/health
curl --fail http://127.0.0.1:3000/health
```

Open the web console on port `3000`.

For internet-facing deployments, terminate HTTPS at a trusted reverse proxy/load balancer and keep the API port private. See [PRODUCTION.md](PRODUCTION.md).

## CLI installation

For the supported analysis path you need:

- Bash
- Python 3.10+
- Java 17+
- `jq`
- `unzip`
- `aapt`
- `apktool`
- `adb` only for the `pull` command
- `apksigner` is recommended for modern APK signing verification

The Docker image contains the dependencies required by the web/API analysis path, except that certificate reporting gracefully degrades when `apksigner` is unavailable.

Then:

```bash
chmod +x apk-reverse-tool.sh integrate.sh
./apk-reverse-tool.sh analyze app.apk
```

The report is written beside the APK:

```text
app_analysis/analysis_report.json
```

## Report shape

A completed report has top-level sections similar to:

```json
{
  "schema_version": 2,
  "tool_info": {},
  "basic_info": {},
  "certificate_analysis": {},
  "permission_analysis": {},
  "owasp_results": {
    "engine": "owasp-evidence-static-v2",
    "findings": [],
    "summary": {}
  },
  "risk_indicator_results": {
    "engine": "static-risk-indicators-v1",
    "is_malware_verdict": false,
    "review_priority_score": 0,
    "indicators": []
  },
  "vulnerability_scan": {},
  "security_analysis": {},
  "code_analysis": {}
}
```

The API currently retains the request option name `malware_detection` as a compatibility key. It activates the static risk-indicator engine above, not a trained malware classifier.

## API behavior

Core routes:

```text
POST /api/auth/register
POST /api/auth/login
POST /api/analysis/upload
GET  /api/analysis/<id>/status
GET  /api/analysis/<id>/results
GET  /api/analysis/history
GET  /api/health
```

Uploads require a bearer token. Before an APK reaches the queue the server verifies that it is a ZIP/APK archive and rejects unsafe path traversal, encrypted archives, excessive entry counts, excessive expanded size, and missing `AndroidManifest.xml`.

Analysis metadata is stored in SQLite. Completed JSON reports are stored on the persistent data volume. Uploaded APKs are deleted after analysis by default.

## Capacity model

The current production baseline intentionally uses one Gunicorn process with threads because the job queue is in-process. SQLite and report files are durable, and queued/running work is re-queued after a single-process restart when the uploaded APK still exists.

Do **not** increase the Gunicorn worker count for horizontal scaling. First move:

1. analysis jobs to a durable broker/worker system,
2. SQLite to a multi-instance database,
3. reports/uploads to shared object storage,
4. Socket.IO fan-out to a shared message layer.

See [PRODUCTION.md](PRODUCTION.md) for the operational model.

## Security posture

The production containers:

- run as non-root users
- drop Linux capabilities
- use `no-new-privileges`
- require explicit production secrets
- keep the API bound to loopback by default
- use an unprivileged nginx frontend
- set browser security headers and a restrictive CSP
- avoid mounting the Docker socket or host directories

Treat all APKs as hostile input and analyze only applications you are authorized to inspect.

## Development and CI

CI is a release gate and runs:

- Python bytecode compilation
- shell syntax checks
- real Flask/SQLite API tests
- archive-validation and ownership-isolation tests
- evidence-scanner regression tests
- React production build
- Docker Compose validation
- backend/frontend image builds
- container boot and health checks

Local Python tests:

```bash
pip install -r requirements.txt
pytest -q api-server/tests apk-tool-features/tests
```

Frontend build:

```bash
cd web-interface
npm install --no-audit --no-fund
npm run build
```

## Project layout

```text
.
├── apk-reverse-tool.sh
├── integrate.sh
├── apk-tool-features/
│   ├── owasp/owasp_scanner.py
│   ├── risk/risk_detector.py
│   └── tests/
├── api-server/
│   ├── server.py
│   ├── wsgi.py
│   └── tests/
├── web-interface/
│   ├── src/
│   ├── Dockerfile
│   └── nginx.conf
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── PRODUCTION.md
```

## License

See [LICENSE](LICENSE) for the repository license and any obligations that apply to distribution or commercial use.
