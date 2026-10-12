#!/usr/bin/env python3
"""OWASP-aligned, evidence-based static review for Android APK files.

The scanner intentionally distinguishes observable static findings from proven
runtime vulnerabilities. It avoids broad regex rules that turn normal API use
into security findings without supporting evidence.
"""

from __future__ import annotations

import argparse
import ipaddress
import json
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

ANDROID_NS = "http://schemas.android.com/apk/res/android"
A = f"{{{ANDROID_NS}}}"

HTTP_URL_RE = re.compile(r"http://([A-Za-z0-9.-]+)(?::\d{1,5})?(?:/[^\s\"'<>\\]*)?", re.IGNORECASE)
CREDENTIAL_PATTERNS = {
    "AWS access-key shaped literal": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "Google API-key shaped literal": re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"),
    "Private-key block": re.compile(r"-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"),
}
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
TEXT_SUFFIXES = {".smali", ".xml", ".json", ".js", ".html", ".txt", ".properties", ".conf"}
MAX_TEXT_SCAN_BYTES = 128 * 1024 * 1024


@dataclass(frozen=True)
class Finding:
    owasp_id: str
    title: str
    severity: str
    confidence: str
    location: str
    evidence: list[str]
    rationale: str
    recommendations: list[str]


class OWASPScanner:
    def __init__(self, apk_path: str):
        self.apk_path = Path(apk_path)
        self.findings: list[Finding] = []
        self.permissions: set[str] = set()
        self.package_name: str | None = None
        self.target_sdk: str | None = None
        self.tool_warnings: list[str] = []
        self._seen: set[tuple[str, str, tuple[str, ...]]] = set()

    def scan(self) -> dict[str, Any]:
        if not self.apk_path.is_file():
            raise FileNotFoundError(f"APK not found: {self.apk_path}")

        with tempfile.TemporaryDirectory(prefix="apk-owasp-") as tmp:
            decoded = Path(tmp) / "decoded"
            self._decode(decoded)
            manifest_path = decoded / "AndroidManifest.xml"
            if not manifest_path.is_file():
                raise RuntimeError("apktool completed without AndroidManifest.xml")

            tree = ET.parse(manifest_path)
            manifest = tree.getroot()
            self.package_name = manifest.get("package")
            self.permissions = {
                element.get(f"{A}name", "")
                for element in manifest.findall("uses-permission")
                if element.get(f"{A}name")
            }
            uses_sdk = manifest.find("uses-sdk")
            if uses_sdk is not None:
                self.target_sdk = uses_sdk.get(f"{A}targetSdkVersion")

            application = manifest.find("application")
            if application is not None:
                self._scan_application_manifest(application, decoded)
                self._scan_exported_components(application)

            self._scan_decoded_content(decoded)

        return self._result()

    def _decode(self, decoded: Path) -> None:
        try:
            result = subprocess.run(
                ["apktool", "d", "-f", str(self.apk_path), "-o", str(decoded)],
                capture_output=True,
                text=True,
                timeout=300,
                check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise RuntimeError(f"Unable to execute apktool: {exc}") from exc

        if result.returncode != 0:
            detail = (result.stderr or result.stdout or "apktool failed").strip()[-4000:]
            raise RuntimeError(f"APK decoding failed: {detail}")

    def _scan_application_manifest(self, application: ET.Element, decoded: Path) -> None:
        if self._is_true(application.get(f"{A}debuggable")):
            self._add(Finding(
                owasp_id="M8",
                title="Application explicitly enables debugging",
                severity="high",
                confidence="high",
                location="AndroidManifest.xml",
                evidence=["android:debuggable=true"],
                rationale="A debuggable release increases the attack and inspection surface on production devices.",
                recommendations=["Ship production builds with android:debuggable disabled."],
            ))

        if self._is_true(application.get(f"{A}usesCleartextTraffic")):
            self._add(Finding(
                owasp_id="M5",
                title="Application explicitly permits cleartext traffic",
                severity="medium",
                confidence="high",
                location="AndroidManifest.xml",
                evidence=["android:usesCleartextTraffic=true"],
                rationale="The manifest explicitly opts into cleartext network traffic.",
                recommendations=["Disable cleartext traffic unless a documented exception requires it."],
            ))

        if self._is_true(application.get(f"{A}allowBackup")):
            self._add(Finding(
                owasp_id="M9",
                title="Application explicitly permits OS backup",
                severity="low",
                confidence="high",
                location="AndroidManifest.xml",
                evidence=["android:allowBackup=true"],
                rationale="Backup can expand the paths by which application data leaves the app sandbox.",
                recommendations=["Review whether backed-up data can contain secrets; disable backup when it is not required."],
            ))

        network_config = application.get(f"{A}networkSecurityConfig")
        if network_config and network_config.startswith("@xml/"):
            resource_name = network_config.split("/", 1)[1]
            config_path = decoded / "res" / "xml" / f"{resource_name}.xml"
            if config_path.is_file():
                self._scan_network_security_config(config_path, decoded)

    def _scan_network_security_config(self, config_path: Path, decoded: Path) -> None:
        try:
            root = ET.parse(config_path).getroot()
        except ET.ParseError as exc:
            self.tool_warnings.append(f"Unable to parse {self._relative(config_path, decoded)}: {exc}")
            return

        cleartext_nodes: list[str] = []
        for element in root.iter():
            if self._is_true(element.get("cleartextTrafficPermitted")):
                cleartext_nodes.append(element.tag)
        if cleartext_nodes:
            self._add(Finding(
                owasp_id="M5",
                title="Network security configuration permits cleartext traffic",
                severity="medium",
                confidence="high",
                location=self._relative(config_path, decoded),
                evidence=[f"cleartextTrafficPermitted=true on <{tag}>" for tag in sorted(set(cleartext_nodes))],
                rationale="The referenced network security configuration explicitly allows cleartext traffic.",
                recommendations=["Restrict cleartext exceptions to the smallest necessary domain scope or remove them."],
            ))

    def _scan_exported_components(self, application: ET.Element) -> None:
        inherited_permission = application.get(f"{A}permission")
        component_tags = ("activity", "activity-alias", "service", "receiver", "provider")

        for tag in component_tags:
            for component in application.findall(tag):
                if not self._is_true(component.get(f"{A}exported")):
                    continue

                component_permission = component.get(f"{A}permission") or inherited_permission
                if tag == "provider":
                    component_permission = (
                        component_permission
                        or component.get(f"{A}readPermission")
                        or component.get(f"{A}writePermission")
                    )
                if component_permission:
                    continue

                name = component.get(f"{A}name", "<unnamed>")
                self._add(Finding(
                    owasp_id="M3",
                    title=f"Exported {tag} has no manifest permission gate",
                    severity="medium",
                    confidence="high",
                    location="AndroidManifest.xml",
                    evidence=[f"{tag}: {name}", "android:exported=true", "no component/application permission"],
                    rationale=(
                        "The component is explicitly reachable by other applications and the manifest does not require a permission. "
                        "This may be intentional, but it is a concrete external entry point that requires authorization review."
                    ),
                    recommendations=[
                        "Confirm the component is intentionally public.",
                        "If it is not public, set android:exported=false.",
                        "If it is public but privileged, enforce an appropriate permission and in-code authorization checks.",
                    ],
                ))

    def _scan_decoded_content(self, decoded: Path) -> None:
        scanned = 0
        http_hosts: dict[str, set[str]] = {}
        insecure_storage_locations: set[str] = set()
        credential_locations: dict[str, set[str]] = {name: set() for name in CREDENTIAL_PATTERNS}

        for path in decoded.rglob("*"):
            if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
                continue
            try:
                remaining = MAX_TEXT_SCAN_BYTES - scanned
                if remaining <= 0:
                    self.tool_warnings.append("Decoded text scan reached its configured byte limit")
                    break
                data = path.read_bytes()[:remaining]
                scanned += len(data)
                content = data.decode("utf-8", errors="ignore")
            except OSError:
                continue

            relative = self._relative(path, decoded)
            for host in HTTP_URL_RE.findall(content):
                if self._is_public_host(host):
                    http_hosts.setdefault(host.lower(), set()).add(relative)

            if "MODE_WORLD_READABLE" in content or "MODE_WORLD_WRITEABLE" in content:
                insecure_storage_locations.add(relative)

            for label, pattern in CREDENTIAL_PATTERNS.items():
                if pattern.search(content):
                    credential_locations[label].add(relative)

        if http_hosts:
            evidence = []
            for host in sorted(http_hosts)[:12]:
                locations = sorted(http_hosts[host])
                evidence.append(f"http://{host} in {locations[0]}")
            self._add(Finding(
                owasp_id="M5",
                title="Public cleartext HTTP endpoint literals are embedded",
                severity="medium",
                confidence="high",
                location="decoded application content",
                evidence=evidence,
                rationale="Public HTTP literals are direct static evidence of endpoints that may be contacted without transport encryption.",
                recommendations=["Migrate public endpoints to HTTPS or verify the literal cannot be used for production traffic."],
            ))

        if insecure_storage_locations:
            self._add(Finding(
                owasp_id="M9",
                title="World-readable or world-writeable storage mode is referenced",
                severity="high",
                confidence="high",
                location="decoded application content",
                evidence=sorted(insecure_storage_locations)[:12],
                rationale="These legacy storage modes can expose app data outside the intended sandbox boundary.",
                recommendations=["Replace world-readable/writeable storage with app-private or explicitly permissioned storage."],
            ))

        credential_evidence = []
        for label, locations in credential_locations.items():
            for location in sorted(locations)[:4]:
                credential_evidence.append(f"{label} in {location}")
        if credential_evidence:
            self._add(Finding(
                owasp_id="M1",
                title="Credential-shaped literal material is embedded",
                severity="high",
                confidence="medium",
                location="decoded application content",
                evidence=credential_evidence[:12],
                rationale=(
                    "The scanner matched a strongly credential-shaped literal. It deliberately does not print the value. "
                    "The value may still be a test or revoked credential, so manual validation is required."
                ),
                recommendations=["Validate whether each matched credential is live; remove it from the client and rotate it if necessary."],
            ))

    def _add(self, finding: Finding) -> None:
        key = (finding.title, finding.location, tuple(finding.evidence))
        if key not in self._seen:
            self.findings.append(finding)
            self._seen.add(key)

    def _result(self) -> dict[str, Any]:
        severity_counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "info": 0}
        owasp_counts: dict[str, int] = {}
        weights = {"critical": 20, "high": 15, "medium": 8, "low": 3, "info": 0}
        score = 0
        for finding in self.findings:
            severity = finding.severity.lower()
            severity_counts[severity] = severity_counts.get(severity, 0) + 1
            owasp_counts[finding.owasp_id] = owasp_counts.get(finding.owasp_id, 0) + 1
            score += weights.get(severity, 0)

        return {
            "schema_version": 2,
            "engine": "owasp-evidence-static-v2",
            "apk_path": str(self.apk_path),
            "package_name": self.package_name,
            "target_sdk": self.target_sdk,
            "scan_status": "completed",
            "findings": [asdict(finding) for finding in self.findings],
            "permission_summary": {
                "total": len(self.permissions),
                "dangerous": sorted(DANGEROUS_PERMISSIONS.intersection(self.permissions)),
            },
            "summary": {
                "total_findings": len(self.findings),
                "by_severity": severity_counts,
                "by_owasp": owasp_counts,
                "review_priority_score": min(100, score),
            },
            "tool_warnings": self.tool_warnings,
            "limitations": [
                "Static findings are evidence for review, not proof of exploitability.",
                "Runtime-only behavior, dynamically fetched code, and some native behavior require additional analysis.",
                "An exported component can be intentionally public; the finding indicates an unauthenticated manifest entry point, not automatic exploitation.",
            ],
        }

    @staticmethod
    def _is_true(value: str | None) -> bool:
        return str(value).strip().lower() == "true"

    @staticmethod
    def _relative(path: Path, root: Path) -> str:
        try:
            return str(path.relative_to(root))
        except ValueError:
            return str(path)

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


def format_text_results(results: dict[str, Any]) -> str:
    summary = results["summary"]
    lines = [
        "OWASP-Aligned Static Review",
        "=" * 40,
        f"Package: {results.get('package_name') or 'unknown'}",
        f"Findings: {summary['total_findings']}",
        f"Review priority score: {summary['review_priority_score']}/100",
    ]
    for finding in results["findings"]:
        lines.append(f"\n[{finding['severity'].upper()}] {finding['owasp_id']} {finding['title']}")
        lines.extend(f"  evidence: {item}" for item in finding["evidence"])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="OWASP-aligned evidence-based APK static review")
    parser.add_argument("apk_path", help="Path to the APK file")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--format", "-f", choices=("json", "text"), default="json")
    args = parser.parse_args()

    try:
        results = OWASPScanner(args.apk_path).scan()
    except (OSError, RuntimeError, ET.ParseError) as exc:
        parser.error(str(exc))
        return 2

    output = json.dumps(results, indent=2, sort_keys=True) if args.format == "json" else format_text_results(results)
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
