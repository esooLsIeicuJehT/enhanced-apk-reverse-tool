#!/usr/bin/env python3
"""Evidence-based static risk indicator scanner for Android APK files.

This module does not claim to determine whether an APK is malware. It reports
observable static indicators and a review-priority score so an analyst can
triage an APK without presenting heuristic output as a malware verdict.
"""

from __future__ import annotations

import argparse
import ipaddress
import json
import re
import subprocess
import zipfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable


DANGEROUS_PERMISSIONS = {
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.READ_CALENDAR",
    "android.permission.WRITE_CALENDAR",
    "android.permission.CAMERA",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.RECORD_AUDIO",
    "android.permission.READ_PHONE_STATE",
    "android.permission.CALL_PHONE",
    "android.permission.READ_SMS",
    "android.permission.SEND_SMS",
    "android.permission.RECEIVE_SMS",
}

PERMISSION_RE = re.compile(r"uses-permission:\s+name=['\"]([^'\"]+)['\"]")
HTTP_URL_RE = re.compile(r"http://([A-Za-z0-9.-]+)(?::\d{1,5})?(?:/[^\s\"'<>\\]*)?", re.IGNORECASE)
CREDENTIAL_PATTERNS = {
    "aws_access_key_id": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "google_api_key": re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
    "private_key": re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"),
    "jwt_literal": re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
}

MAX_SCAN_BYTES = 96 * 1024 * 1024
MAX_MEMBER_BYTES = 24 * 1024 * 1024
SCAN_SUFFIXES = {
    ".dex",
    ".xml",
    ".json",
    ".js",
    ".html",
    ".txt",
    ".properties",
    ".conf",
    ".ini",
    ".yaml",
    ".yml",
}


@dataclass(frozen=True)
class Indicator:
    id: str
    title: str
    weight: int
    evidence: list[str]
    rationale: str


class StaticRiskAnalyzer:
    def __init__(self, apk_path: str):
        self.apk_path = Path(apk_path)
        self.tool_errors: list[str] = []

    def analyze(self) -> dict[str, Any]:
        if not self.apk_path.is_file():
            raise FileNotFoundError(f"APK not found: {self.apk_path}")
        if not zipfile.is_zipfile(self.apk_path):
            raise ValueError("Input is not a valid APK/ZIP archive")

        permissions = self._permissions()
        manifest_flags = self._manifest_flags()
        archive_facts, text = self._archive_facts_and_text()
        indicators = self._indicators(permissions, manifest_flags, text)
        score = min(100, sum(item.weight for item in indicators))

        if score >= 50:
            review_level = "HIGH_REVIEW_PRIORITY"
        elif score >= 20:
            review_level = "REVIEW_RECOMMENDED"
        else:
            review_level = "LOW_STATIC_RISK_INDICATORS"

        facts = {
            **archive_facts,
            "permission_count": len(permissions),
            "dangerous_permission_count": len(DANGEROUS_PERMISSIONS.intersection(permissions)),
            "permissions": sorted(permissions),
            "manifest_flags": manifest_flags,
        }

        return {
            "engine": "static-risk-indicators-v1",
            "is_malware_verdict": False,
            "review_priority_score": score,
            "review_level": review_level,
            "facts": facts,
            "indicators": [asdict(item) for item in indicators],
            "tool_errors": self.tool_errors,
            "limitations": [
                "Static indicators cannot prove malicious intent or runtime behavior.",
                "Absence of an indicator does not prove an APK is safe.",
                "Packed, encrypted, dynamically downloaded, or native behavior may require manual/runtime analysis.",
            ],
        }

    def _run(self, args: list[str]) -> str:
        try:
            result = subprocess.run(
                args,
                capture_output=True,
                text=True,
                timeout=60,
                check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            self.tool_errors.append(f"{' '.join(args[:3])}: {exc}")
            return ""

        if result.returncode != 0:
            detail = (result.stderr or result.stdout or "command failed").strip().replace("\n", " ")[:500]
            self.tool_errors.append(f"{' '.join(args[:3])}: {detail}")
            return ""
        return result.stdout

    def _permissions(self) -> set[str]:
        output = self._run(["aapt", "dump", "permissions", str(self.apk_path)])
        return set(PERMISSION_RE.findall(output))

    def _manifest_flags(self) -> dict[str, bool | None]:
        output = self._run(["aapt", "dump", "xmltree", str(self.apk_path), "AndroidManifest.xml"])
        return {
            "debuggable": self._xmltree_bool(output, "debuggable"),
            "allow_backup": self._xmltree_bool(output, "allowBackup"),
            "uses_cleartext_traffic": self._xmltree_bool(output, "usesCleartextTraffic"),
        }

    @staticmethod
    def _xmltree_bool(output: str, attribute: str) -> bool | None:
        for line in output.splitlines():
            if f"android:{attribute}" not in line:
                continue
            lowered = line.lower()
            if 'raw: "true"' in lowered or lowered.rstrip().endswith("0xffffffff"):
                return True
            if 'raw: "false"' in lowered or lowered.rstrip().endswith("0x0"):
                return False
        return None

    def _archive_facts_and_text(self) -> tuple[dict[str, Any], str]:
        native_libraries = 0
        dex_files = 0
        dex_bytes = 0
        scanned_bytes = 0
        chunks: list[str] = []

        with zipfile.ZipFile(self.apk_path) as archive:
            infos = archive.infolist()
            for info in infos:
                lower = info.filename.lower()
                suffix = Path(lower).suffix
                if lower.endswith(".so") and "/lib" in f"/{lower}":
                    native_libraries += 1
                if re.search(r"(?:^|/)classes\d*\.dex$", lower):
                    dex_files += 1
                    dex_bytes += info.file_size

                should_scan = suffix in SCAN_SUFFIXES or lower.endswith(".dex")
                if not should_scan or info.file_size <= 0 or scanned_bytes >= MAX_SCAN_BYTES:
                    continue

                member_budget = min(info.file_size, MAX_MEMBER_BYTES, MAX_SCAN_BYTES - scanned_bytes)
                try:
                    with archive.open(info) as member:
                        data = member.read(member_budget)
                except (OSError, RuntimeError, zipfile.BadZipFile):
                    continue
                scanned_bytes += len(data)
                chunks.append(data.decode("latin-1", errors="ignore"))

        return (
            {
                "archive_entry_count": len(infos),
                "apk_size_bytes": self.apk_path.stat().st_size,
                "dex_file_count": dex_files,
                "dex_size_bytes": dex_bytes,
                "native_library_count": native_libraries,
                "content_scanned_bytes": scanned_bytes,
            },
            "\n".join(chunks),
        )

    def _indicators(
        self,
        permissions: set[str],
        manifest_flags: dict[str, bool | None],
        text: str,
    ) -> list[Indicator]:
        indicators: list[Indicator] = []

        if manifest_flags.get("debuggable") is True:
            indicators.append(Indicator(
                id="debuggable",
                title="Release manifest explicitly enables debugging",
                weight=15,
                evidence=["android:debuggable=true"],
                rationale="Debuggable production apps expose additional inspection and debugging surface.",
            ))

        if manifest_flags.get("uses_cleartext_traffic") is True:
            indicators.append(Indicator(
                id="manifest_cleartext",
                title="Manifest explicitly permits cleartext traffic",
                weight=15,
                evidence=["android:usesCleartextTraffic=true"],
                rationale="Cleartext traffic can expose data to interception when used for non-local endpoints.",
            ))

        public_http_hosts = sorted({host for host in HTTP_URL_RE.findall(text) if self._is_public_host(host)})
        if public_http_hosts:
            indicators.append(Indicator(
                id="public_http_literals",
                title="Public cleartext HTTP endpoint literals are embedded",
                weight=10,
                evidence=[f"http://{host}" for host in public_http_hosts[:10]],
                rationale="These literals are observable evidence of potential cleartext network use and merit endpoint review.",
            ))

        credential_types = [name for name, pattern in CREDENTIAL_PATTERNS.items() if pattern.search(text)]
        if credential_types:
            indicators.append(Indicator(
                id="credential_shaped_literals",
                title="Credential-shaped literal material is embedded",
                weight=20,
                evidence=sorted(credential_types),
                rationale="The scanner never outputs the secret value; each detected credential type should be validated and rotated if live.",
            ))

        dynamic_markers = [
            marker
            for marker in ("DexClassLoader", "InMemoryDexClassLoader", "dalvik/system/DexClassLoader")
            if marker in text
        ]
        if dynamic_markers:
            indicators.append(Indicator(
                id="dynamic_code_loading",
                title="Dynamic code-loading APIs are referenced",
                weight=10,
                evidence=sorted(set(dynamic_markers)),
                rationale="Dynamic loading is legitimate in some apps but reduces what static inspection can establish.",
            ))

        exec_markers = [
            marker
            for marker in ("Ljava/lang/Runtime;->exec", "java/lang/ProcessBuilder", "/system/bin/sh")
            if marker in text
        ]
        if exec_markers:
            indicators.append(Indicator(
                id="process_execution",
                title="Process or shell execution APIs are referenced",
                weight=10,
                evidence=sorted(set(exec_markers)),
                rationale="Process execution is a high-impact capability that should be reviewed in context.",
            ))

        if {
            "android.permission.REQUEST_INSTALL_PACKAGES",
            "android.permission.SYSTEM_ALERT_WINDOW",
        }.issubset(permissions):
            indicators.append(Indicator(
                id="install_overlay_combo",
                title="Package-install and overlay capabilities are both requested",
                weight=20,
                evidence=[
                    "android.permission.REQUEST_INSTALL_PACKAGES",
                    "android.permission.SYSTEM_ALERT_WINDOW",
                ],
                rationale="The combination is not inherently malicious but is sufficiently powerful to warrant manual review.",
            ))

        sms_permissions = sorted({
            "android.permission.READ_SMS",
            "android.permission.SEND_SMS",
            "android.permission.RECEIVE_SMS",
        }.intersection(permissions))
        if len(sms_permissions) >= 2:
            indicators.append(Indicator(
                id="sms_capabilities",
                title="Multiple SMS capabilities are requested",
                weight=10,
                evidence=sms_permissions,
                rationale="SMS access is sensitive and should match the app's documented purpose.",
            ))

        return indicators

    @staticmethod
    def _is_public_host(host: str) -> bool:
        host = host.rstrip(".").lower()
        if host in {"localhost", "10.0.2.2"} or host.endswith(".local"):
            return False
        try:
            address = ipaddress.ip_address(host)
            return not (
                address.is_private
                or address.is_loopback
                or address.is_link_local
                or address.is_reserved
                or address.is_multicast
            )
        except ValueError:
            return "." in host


def format_text(result: dict[str, Any]) -> str:
    lines = [
        "Static APK Risk Indicator Results",
        "=" * 40,
        f"Review priority score: {result['review_priority_score']}/100",
        f"Review level: {result['review_level']}",
        "Malware verdict: no",
        "",
        "Indicators:",
    ]
    indicators = result["indicators"]
    if not indicators:
        lines.append("  No configured static risk indicators were observed.")
    for item in indicators:
        lines.append(f"  [{item['weight']:02d}] {item['title']}")
        for evidence in item["evidence"]:
            lines.append(f"       evidence: {evidence}")
    if result["tool_errors"]:
        lines.append("\nTool errors:")
        lines.extend(f"  - {error}" for error in result["tool_errors"])
    lines.append("\nStatic analysis is not proof that an APK is safe or malicious.")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Evidence-based static APK risk indicator scanner")
    parser.add_argument("apk_path", help="Path to the APK file")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--format", "-f", choices=("json", "text"), default="json")
    args = parser.parse_args()

    try:
        result = StaticRiskAnalyzer(args.apk_path).analyze()
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        parser.error(str(exc))
        return 2

    output = json.dumps(result, indent=2, sort_keys=True) if args.format == "json" else format_text(result)
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
