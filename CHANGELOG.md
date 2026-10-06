# Changelog

Notable production changes to the Enhanced APK Reverse Tool are recorded here.

## [2.1.0] - 2026-10-06

### Production baseline
- Replaced the broken in-memory/multiprocessing API job model with a bounded in-process worker and durable SQLite user/analysis metadata.
- Added restart recovery for queued/running analyses when the uploaded APK is still available.
- Added production secret requirements, persistent authentication, owner-scoped analysis history/results, and authenticated Socket.IO room joins.
- Added APK archive validation before queueing, including path-traversal, encryption, entry-count, expanded-size, and manifest checks.
- Rebuilt the browser client around the actual API contract with registration/login, upload, module selection, status polling, history, and JSON results.
- Replaced the container stack with a two-service non-root baseline: API/analysis service plus an unprivileged nginx web service.
- Added deployment health checks, browser security headers, restrictive CORS defaults, dropped Linux capabilities, and `no-new-privileges`.
- Added a production operations runbook and environment template.

### Analysis integrity
- Replaced the untrained placeholder "ML malware detector" with an evidence-based static risk-indicator engine.
- The risk engine now explicitly reports that it is not a malware verdict and returns observable evidence plus a review-priority score.
- Replaced false-positive-prone OWASP regex rules with evidence-based manifest/resource/code checks and confidence/evidence fields.
- Fixed OWASP/risk scanner integration so the shell invokes the scanners with their real CLI contracts.
- Replaced placeholder code-analysis claims with measured APK package-structure metrics.
- Improved signing analysis and added modern APK signature verification support in the production container.
- Reduced the CLI to supported commands only: `analyze`, `pull`, and `help`.
- Split APK pulls are preserved as separate artifacts rather than being described as automatically merged.

### Tests and CI
- Replaced mock-only API tests with Flask/SQLite integration tests covering authentication, multipart uploads, owner isolation, archive safety, result guards, WebSocket authorization, and health checks.
- Added scanner regression tests to prevent broad TLS/SQL/root-detection strings from becoming unsupported vulnerability/malware claims.
- Added CI for Python compilation, shell syntax, backend/scanner tests, frontend production builds, Docker Compose validation, image builds, service boot, and health checks.

### Repository hygiene
- Removed committed runtime logs, generated release archives, workspace-output dumps, agent-session residue, conversation dumps, stale duplicate guides, broken deployment scripts, broken integration stubs, and unverified package recipes.
- Quarantined the unfinished Android companion app as an experimental prototype rather than presenting it as a supported release component.
- Replaced legacy documentation claims with the actual 2.1 production contract.

### Compatibility note
The API request option key `malware_detection` remains temporarily accepted for compatibility. It activates the static risk-indicator engine and does not invoke a trained malware classifier.

## Legacy repository history

Earlier repository revisions used the 2.0 label for a broad set of proposed and partially implemented capabilities. Those historical claims are not treated as the current production contract. The supported 2.1 surface is defined by the root `README.md`, `PRODUCTION.md`, CI workflow, and executable code.
