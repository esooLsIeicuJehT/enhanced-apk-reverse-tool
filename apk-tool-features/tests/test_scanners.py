import importlib.util
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def load_module(name: str, relative_path: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative_path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


risk = load_module("risk_detector_test_module", "apk-tool-features/risk/risk_detector.py")
owasp = load_module("owasp_scanner_test_module", "apk-tool-features/owasp/owasp_scanner.py")


def test_risk_scanner_does_not_call_low_signal_code_malware():
    analyzer = risk.StaticRiskAnalyzer("unused.apk")
    indicators = analyzer._indicators(
        permissions={"android.permission.INTERNET"},
        manifest_flags={"debuggable": False, "allow_backup": None, "uses_cleartext_traffic": False},
        text="SSLContext.getInstance SELECT * FROM users X509TrustManager",
    )
    assert indicators == []


def test_risk_scanner_reports_observable_high_impact_combination():
    analyzer = risk.StaticRiskAnalyzer("unused.apk")
    indicators = analyzer._indicators(
        permissions={
            "android.permission.REQUEST_INSTALL_PACKAGES",
            "android.permission.SYSTEM_ALERT_WINDOW",
        },
        manifest_flags={"debuggable": True, "allow_backup": None, "uses_cleartext_traffic": False},
        text="dalvik/system/DexClassLoader Ljava/lang/Runtime;->exec",
    )
    ids = {item.id for item in indicators}
    assert {"debuggable", "dynamic_code_loading", "process_execution", "install_overlay_combo"}.issubset(ids)


def test_private_or_local_http_hosts_are_not_flagged():
    analyzer = risk.StaticRiskAnalyzer("unused.apk")
    assert analyzer._is_public_host("localhost") is False
    assert analyzer._is_public_host("127.0.0.1") is False
    assert analyzer._is_public_host("192.168.1.10") is False
    assert analyzer._is_public_host("example.com") is True


def test_owasp_exported_component_requires_missing_permission_gate():
    scanner = owasp.OWASPScanner("unused.apk")
    xml = f"""
    <application xmlns:android="{owasp.ANDROID_NS}">
      <activity android:name=".PublicActivity" android:exported="true" />
      <service android:name=".ProtectedService" android:exported="true" android:permission="com.example.PRIV" />
      <receiver android:name=".InternalReceiver" android:exported="false" />
    </application>
    """
    scanner._scan_exported_components(ET.fromstring(xml))
    assert len(scanner.findings) == 1
    assert scanner.findings[0].title.startswith("Exported activity")
    assert ".PublicActivity" in scanner.findings[0].evidence[0]


def test_owasp_manifest_only_reports_explicit_security_flags(tmp_path):
    scanner = owasp.OWASPScanner("unused.apk")
    plain = ET.fromstring(f'<application xmlns:android="{owasp.ANDROID_NS}" />')
    scanner._scan_application_manifest(plain, tmp_path)
    assert scanner.findings == []

    explicit = ET.fromstring(
        f'<application xmlns:android="{owasp.ANDROID_NS}" '
        'android:debuggable="true" android:usesCleartextTraffic="true" android:allowBackup="true" />'
    )
    scanner._scan_application_manifest(explicit, tmp_path)
    titles = {finding.title for finding in scanner.findings}
    assert "Application explicitly enables debugging" in titles
    assert "Application explicitly permits cleartext traffic" in titles
    assert "Application explicitly permits OS backup" in titles


def test_credential_patterns_do_not_expose_matched_values():
    analyzer = risk.StaticRiskAnalyzer("unused.apk")
    secret = "AKIAABCDEFGHIJKLMNOP"
    indicators = analyzer._indicators(
        permissions=set(),
        manifest_flags={"debuggable": False, "allow_backup": None, "uses_cleartext_traffic": False},
        text=f"prefix {secret} suffix",
    )
    credential = next(item for item in indicators if item.id == "credential_shaped_literals")
    assert secret not in " ".join(credential.evidence)
    assert "aws_access_key_id" in credential.evidence
