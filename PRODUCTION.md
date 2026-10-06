# Production Operations

This repository ships a two-service baseline:

- `apk-tool`: authenticated Flask API, SQLite metadata store, bounded local analysis queue, and the APK analysis toolchain.
- `web-interface`: unprivileged nginx container serving the React client and proxying `/api` and `/socket.io` to the API.

The backend intentionally runs **one Gunicorn process with multiple threads**. The analysis queue is in-process while user and analysis metadata are durable in SQLite. Do not increase the Gunicorn worker count without first moving the queue to a durable external broker.

## 1. Configure secrets

```bash
cp .env.example .env
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
```

Put the two different generated values into `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`.

Never commit `.env`. Production startup fails closed when either secret is missing.

## 2. Validate configuration

```bash
docker compose config --quiet
```

## 3. Build and start

```bash
docker compose up -d --build
```

Verify both services:

```bash
curl --fail http://127.0.0.1:8080/api/health
curl --fail http://127.0.0.1:3000/health
```

The API is bound to loopback by default. The web service is the intended browser entrypoint at port `3000`.

## 4. Put TLS in front of the web service

For an internet-facing deployment, terminate HTTPS at a trusted reverse proxy or load balancer and forward traffic to the web service. Do not expose the API's port `8080` directly unless there is a specific operational reason.

Set `CORS_ALLOWED_ORIGINS` to the exact browser origins that need direct API access. Avoid `*` in production.

## 5. Persistent data

The `apk-data` volume contains:

- SQLite user and analysis metadata
- completed JSON reports
- temporary uploads while an analysis is queued or running

Uploaded APKs are deleted after processing by default. Completed reports and metadata remain.

Before an upgrade, take a consistent copy of `/data`. A simple maintenance-window backup is:

```bash
docker compose stop apk-tool
rm -rf ./backup-data
docker compose cp apk-tool:/data ./backup-data
docker compose start apk-tool
```

Protect backups because the database contains account identifiers and password hashes.

## 6. Upgrade

```bash
git pull --ff-only
docker compose build --pull
docker compose up -d
curl --fail http://127.0.0.1:8080/api/health
curl --fail http://127.0.0.1:3000/health
```

If health checks fail, inspect logs before changing state:

```bash
docker compose ps
docker compose logs --tail=200 apk-tool
docker compose logs --tail=200 web-interface
```

## 7. Capacity model

`MAX_QUEUE_SIZE` limits waiting analyses. `MAX_ANALYSIS_TIME` bounds each tool execution. `MAX_UPLOAD_SIZE` bounds the request body, and the API additionally limits APK entry count and total uncompressed archive size.

For horizontal scaling, move these responsibilities out of the single API container first:

1. analysis jobs to a durable broker/worker system,
2. SQLite to a multi-instance database,
3. reports/uploads to shared object storage,
4. WebSocket fan-out to a shared message layer.

Until then, deploy one API container per persistent data volume.

## 8. Security expectations

- Analyze APKs only when you are authorized to inspect them.
- Keep the services current and rebuild images regularly.
- Keep the API private behind the bundled web proxy whenever possible.
- Use unique production secrets and rotate them deliberately. Rotating `JWT_SECRET_KEY` invalidates existing sessions.
- Treat uploaded APKs as hostile input. The container runs as a non-root user with Linux capabilities dropped, and the API rejects malformed, encrypted, path-traversal, oversized, and over-expanded archives before analysis.
- Do not mount the Docker socket or sensitive host directories into the analysis container.

## 9. Release gate

A release should not be tagged unless CI passes all three jobs:

- backend Python compilation, shell syntax, and API tests,
- frontend production build,
- Docker Compose validation, image build, boot, and health checks.
