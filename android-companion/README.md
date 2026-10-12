# Android Companion Prototype

> **Status: experimental and not part of the production release.**

This directory contains an earlier Android client prototype for the Enhanced APK Reverse Tool. It is retained as future-work source material, but it is **not built, tested, packaged, or supported by the current production CI/CD path**.

Do not distribute an APK built from this directory as a supported product without first completing a dedicated hardening pass.

## Why it is excluded from the release

The current production contract is the browser/API/CLI stack documented in the repository root. This Android prototype predates that contract and may contain stale API models, endpoints, Gradle assumptions, UI flows, or dependency versions.

In particular, the repository does not currently guarantee that this directory:

- builds with a current Android Gradle Plugin and SDK,
- matches the current authenticated API schema,
- handles current analysis result fields,
- implements current Socket.IO authentication,
- has release signing, shrinking, dependency scanning, or Android CI,
- meets current Android target-SDK and store policy requirements.

## Re-enabling it later

Before promoting the companion app back into the supported product, treat it as its own release project:

1. add a complete Gradle wrapper and root project configuration;
2. update target/min SDK and dependencies;
3. regenerate API models from the current server contract;
4. implement authenticated upload, history, status polling/socket authorization, and result rendering against the current API;
5. add unit/instrumentation tests and a CI build matrix;
6. add release signing and reproducible release artifacts;
7. perform Android security and privacy review;
8. document installation and support only after those gates pass.

For the supported release today, use the web console, REST API, or `apk-reverse-tool.sh` described in the root [README](../README.md).
