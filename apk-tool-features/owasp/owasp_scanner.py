#!/usr/bin/env python3
"""
OWASP Mobile Top 10 Security Scanner
Scans APK files for OWASP Mobile Top 10 vulnerabilities
"""

import re
import json
import subprocess
from typing import List, Dict, Any, Optional
from pathlib import Path
from dataclasses import dataclass, asdict


@dataclass
class Vulnerability:
    owasp_id: str
    title: str
    description: str
    severity: str
    location: Optional[str] = None
    cwe: Optional[str] = None
    recommendations: List[str] = None

    def __post_init__(self):
        if self.recommendations is None:
            self.recommendations = []


class OWASPScanner:
    """OWASP Mobile Top 10 Security Scanner"""
    
    # OWASP Mobile Top 2024
    OWASP_TOP_10 = {
        "M1": "Improper Credential Usage",
        "M2": "Inadequate Supply Chain Security",
        "M3": "Insecure Authentication/Authorization",
        "M4": "Insufficient Input/Output Validation",
        "M5": "Insecure Communication",
        "M6": "Inadequate Privacy Controls",
        "M7": "Insufficient Binary Protections",
        "M8": "Security Misconfiguration",
        "M9": "Insecure Data Storage",
        "M10": "Insufficient Cryptography",
    }
    
    # Common vulnerability patterns
    PATTERNS = {
        "hardcoded_passwords": {
            "pattern": r'(password\s*=\s*["\']([^"\']{4,})["\']|pwd\s*=\s*["\']([^"\']{4,})["\'])',
            "cwe": "798",
            "severity": "high",
            "owasp": "M10"
        },
        "hardcoded_api_keys": {
            "pattern": r'(api[_-]?key\s*=\s*["\']([A-Za-z0-9_\-]{20,})["\']|key\s*=\s*["\']([A-Za-z0-9_\-]{20,})["\'])',
            "cwe": "798",
            "severity": "high",
            "owasp": "M10"
        },
        "insecure_http": {
            "pattern": r'http://(?!localhost|127\.0\.0\.1)',
            "cwe": "319",
            "severity": "medium",
            "owasp": "M5"
        },
        "debug_mode": {
            "pattern": r'(android:debuggable=["\']true["\']|setDebuggable\s*\(\s*true\s*\))',
            "cwe": "489",
            "severity": "high",
            "owasp": "M8"
        },
        "sql_injection": {
            "pattern": r"(SELECT.*FROM.*WHERE|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM)",
            "cwe": "89",
            "severity": "high",
            "owasp": "M4"
        },
        "weak_encryption": {
            "pattern": r'(DES|MD5|SHA1|RC4|RC2)',
            "cwe": "327",
            "severity": "medium",
            "owasp": "M10"
        },
        "exported_activities": {
            "pattern": r'android:exported=["\']true["\']',
            "cwe": "926",
            "severity": "medium",
            "owasp": "M8"
        },
        "insecure_storage": {
            "pattern": r'(MODE_WORLD_READABLE|MODE_WORLD_WRITEABLE|getExternalStoragePublicDirectory)',
            "cwe": "922",
            "severity": "high",
            "owasp": "M9"
        },
        "ssl_pinning": {
            "pattern": r'(SSLContext\.getInstance\(|X509TrustManager)',
            "cwe": "295",
            "severity": "medium",
            "owasp": "M5"
        },
        "root_detection": {
            "pattern": r'(su\s|/system/app/Superuser|/system/bin/su)',
            "cwe": "919",
            "severity": "low",
            "owasp": "M7"
        },
    }
    
    def __init__(self, apk_path: str):
        """
        Initialize the OWASP Scanner
        
        Args:
            apk_path: Path to the APK file
        """
        self.apk_path = Path(apk_path)
        self.vulnerabilities: List[Vulnerability] = []
        self.manifest_data: Dict[str, Any] = {}
        self.source_files: List[str] = []
        
    def scan(self) -> Dict[str, Any]:
        """
        Perform comprehensive OWASP Mobile Top 10 scan
        
        Returns:
            Dict containing scan results
        """
        results = {
            "apk_path": str(self.apk_path),
            "timestamp": None,
            "scan_status": "started",
            "vulnerabilities": [],
            "summary": {},
            "recommendations": []
        }
        
        try:
            # Decode APK
            self._decode_apk()
            
            # Parse manifest
            self._parse_manifest()
            
            # Scan for vulnerabilities
            self._scan_manifest_vulnerabilities()
            self._scan_source_code_vulnerabilities()
            self._scan_configuration_issues()
            self._analyze_permissions()
            self._check_binary_protections()
            
            # Generate summary
            results["vulnerabilities"] = [asdict(v) for v in self.vulnerabilities]
            results["summary"] = self._generate_summary()
            results["recommendations"] = self._generate_recommendations()
            results["scan_status"] = "completed"
            
        except Exception as e:
            results["scan_status"] = "failed"
            results["error"] = str(e)
        
        return results
    
    def _decode_apk(self):
        """Decode APK using apktool"""
        try:
            output_dir = self.apk_path.parent / f"{self.apk_path.stem}_decoded"
            cmd = ["apktool", "d", str(self.apk_path), "-o", str(output_dir), "-f"]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode != 0:
                raise Exception(f"Failed to decode APK: {result.stderr}")
            
            self.decoded_path = output_dir
            
        except Exception as e:
            raise Exception(f"APK decoding failed: {str(e)}")
    
    def _parse_manifest(self):
        """Parse AndroidManifest.xml"""
        manifest_path = self.decoded_path / "AndroidManifest.xml"
        
        if not manifest_path.exists():
            raise Exception("AndroidManifest.xml not found")
        
        # Parse using aapt
        try:
            cmd = ["aapt", "dump", "badging", str(self.apk_path)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                self._parse_aapt_output(result.stdout)
            
        except Exception as e:
            raise Exception(f"Failed to parse manifest: {str(e)}")
    
    def _parse_aapt_output(self, output: str):
        """Parse aapt dump badging output"""
        self.manifest_data["package_name"] = self._extract_value(output, "package:")
        self.manifest_data["version_code"] = self._extract_value(output, "versionCode")
        self.manifest["version_name"] = self._extract_value(output, "versionName")
        self.manifest_data["sdk_version"] = self._extract_value(output, "sdkVersion:")
        self.manifest_data["target_sdk"] = self._extract_value("targetorten", "targetSdkVersion:")
        self.manifest_data["permissions"] = self._extract_permissions(output)
    
    def _extract_value(self, output: str, key: str) -> str:
        """Extract value from aapt output"""
        pattern = rf'{key}([\'"])?([^\'"\s]+)\1'
        match = re.search(pattern, output)
        return match.group(2) if match else "N/A"
    
    def _extract_permissions(self, output: str) -> List[str]:
        """Extract permissions from aapt output"""
        pattern = r'uses-permission:\s+name=[\'"](.+?)[\'"]'
        return re.findall(pattern, output)
    
    def _scan_manifest_vulnerabilities(self):
        """Scan manifest for security issues"""
        # Check for debuggable applications
        if self._is_debuggable():
            self.vulnerabilities.append(Vulnerability(
                owasp_id="M8",
                title="Application is Debuggable",
                description="Application is configured for debug mode, which allows debugging and potentially exposes sensitive information.",
                severity="high",
                location="AndroidManifest.xml",
                cwe="489",
                recommendations=[
                    "Remove android:debuggable=&quot;true&quot; from the manifest",
                    "Ensure debug builds are not released to production",
                    "Use ProGuard/R8 to obfuscate code"
                ]
            ))
        
        # Check for exported activities
        exported_count = self._count_exported_components()
        if exported_count > 5:
            self.vulnerabilities.append(Vulnerability(
                owasp_id="M8",
                title="Excessive Exported Components",
                description=f"Application has {exported_count} exported components, which may increase attack surface.",
                severity="medium",
                location="AndroidManifest.xml",
                cwe="926",
                recommendations=[
                    "Review all exported components",
                    "Minimize exported components",
                    "Add proper permissions to exported components",
                    "Use intent filters carefully"
                ]
            ))
        
        # Check for allowBackup
        if self._is_backup_enabled():
            self.vulnerabilities.append(Vulnerability(
                owasp_id="M9",
                title="Backup Enabled",
                description="Application allows backup, which may expose sensitive data.",
                severity="medium",
                location="AndroidManifest.xml",
                cwe="922",
                recommendations=[
                    "Set android:allowBackup=&quot;false&quot; in the manifest",
                    "Implement proper data encryption",
                    "Use secure backup mechanisms"
                ]
            ))
    
    def _scan_source_code_vulnerabilities(self):
        """Scan source code for security patterns"""
        java_files = list(self.decoded_path.rglob("*.java"))
        smali_files = list(self.decoded_path.rglob("*.smali"))
        xml_files = list(self.decoded_path.rglob("*.xml"))
        
        all_files = java_files + smali_files + xml_files
        
        for file_path in all_files:
            try:
                content = file_path.read_text(encoding="utf-8", errors="ignore")
                self._scan_file_content(content, str(file_path))
            except Exception:
                continue
    
    def _scan_file_content(self, content: str, location: str):
        """Scan file content for vulnerability patterns"""
        for pattern_name, pattern_data in self.PATTERNS.items():
            pattern = pattern_data["pattern"]
            matches = re.finditer(pattern, content, re.IGNORECASE)
            
            for match in matches:
                # Create vulnerability for each match
                if self._should_create_vulnerability(pattern_name, location):
                    vulnerability = self._create_vulnerability(
                        pattern_name, pattern_data, location, match
                    )
                    self.vulnerabilities.append(vulnerability)
    
    def _should_create_vulnerability(self, pattern_name: str, location: str) -> bool:
        """Determine if vulnerability should be created"""
        # Deduplicate similar vulnerabilities
        for existing in self.vulnerabilities:
            if pattern_name in existing.title.lower() and \
               location in str(existing.location):
                return False
        return True
    
    def _create_vulnerability(
        self,
        pattern_name: str,
        pattern_data: Dict[str, Any],
        location: str,
        match: re.Match
    ) -> Vulnerability:
        """Create vulnerability from pattern match"""
        titles = {
            "hardcoded_passwords": "Hardcoded Password Found",
            "hardcoded_api_keys": "Hardcoded API Key Found",
            "insecure_http": "Insecure HTTP Usage",
            "debug_mode": "Debug Mode Enabled",
            "sql_injection": "Potential SQL Injection",
            "weak_encryption": "Weak Encryption Algorithm",
            "exported_activities": "Exported Activity",
            "insecure_storage": "Insecure Storage",
            "ssl_pinning": "SSL Pinning Not Implemented",
            "root_detection": "Root Detection Bypass"
        }
        
        descriptions = {
            "hardcoded_passwords": "Hardcoded password found in source code.",
            "hardcoded_api_keys": "Hardcoded API key found in source code.",
            "insecure": "Application uses insecure HTTP connections.",
            "debug_mode": "Debug mode is enabled in production code.",
            "sql_injection": "Potential SQL injection vulnerability found.",
            "weak_encryption": "Weak encryption algorithm detected.",
            "exported_activities": "Activity is exported without proper protection.",
            "insecure_storage": "Insecure data storage mechanism detected.",
            "ssl_pinning": "SSL pinning not implemented.",
            "root_detection": "Application may be vulnerable to root detection bypass."
        }
        
        return Vulnerability(
            owasp_id=pattern_data["owasp"],
            title=titles.get(pattern_name, f"Security Issue: {pattern_name}"),
            description=descriptions.get(pattern_name, f"Security pattern: {pattern_name}"),
            severity=pattern_data["severity"],
            location=location,
            cwe=pattern_data["cwe"],
            recommendations=self._get_recommendations(pattern_name)
        )
    
    def _get_recommendations(self, pattern_name: str) -> List[str]:
        """Get recommendations for specific pattern"""
        recommendations = {
            "hardcoded_passwords": [
                "Remove hardcoded credentials",
                "Use secure storage or keystore",
                "Implement proper secret management"
            ],
            "hardcoded_api_keys": [
                "Remove hardcoded API keys",
                "Use secure storage",
                "Rotate compromised keys",
                "Use environment variables"
            ],
            "insecure_http": [
                "Use HTTPS for all network connections",
                "Implement certificate pinning",
                "Use proper SSL/TLS configuration"
            ],
            "debug_mode": [
                "Remove debug flags",
                "Use different build configurations",
                "Enable ProGuard"
            ],
            "sql_injection": [
                "Use parameterized queries",
                "Implement proper input validation",
                "Use prepared statements"
            ],
            "weak_encryption": [
                "Use strong encryption (AES-256)",
                "Use secure random number generation",
                "Implement proper key management"
            ],
            "insecure_storage": [
                "Use secure storage (Keystore, EncryptedSharedPreferences)",
                "Encrypt sensitive data",
                "Use device-specific encryption"
            ]
        }
        return recommendations.get(pattern_name, [])
    
    def _is_debuggable(self) -> bool:
        """Check if application is debuggable"""
        try:
            cmd = ["aapt", "dump", "badging", str(self.apk_path)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            return "debuggable='true'" in result.stdout
        except Exception:
            return False
    
    def _count_exported_components(self) -> int:
        """Count exported components"""
        try:
            cmd = ["aapt", "dump", "badging", "str", "self.apk_path"]
            result = subprocess.run(cmd, capture_output=True, text="text")
            return result.stdout.count("exported='true'")
        except Exception:
            return 0
    
    def _is_backup_enabled(self) -> bool:
        """Check if backup is enabled"""
        try:
            cmd = ["aapt", "dump", "badging", str(self.apk_path)]
            result = subprocess.run(cmd, capture_output=True, text=True)
            return result.stdout.count("backup='true'") > 0
        except Exception:
            return False
    
    def _generate_summary(self) -> Dict[str, Any]:
        """Generate vulnerability summary"""
        severity_counts = {
            "critical": 0,
            "high": 0,
            "medium": 0,
            "low": 0,
            "info": 0
        }
        
        for vuln in self.vulnerabilities:
            severity_counts[vuln.severity.lower()] += 1
        
        return {
            "total_vulnerabilities": len(self.vulnerabilities),
            "by_severity": severity_counts,
            "by_owasp": self._group_by_owasp(),
            "risk_score": self._calculate_risk_score()
        }
    
    def _group_by_owasp(self) -> Dict[str, int]:
        """Group vulnerabilities by OWASP category"""
        owasp_counts = {}
        for vuln in self.vulnerabilities:
            owasp_id = vuln.owasp_id
            owasp_counts[owasp_id] = owasp_counts.get(owasp_id, 0) + 1
        return owasp_counts
    
    def _calculate_risk_score(self) -> float:
        """Calculate risk score (0-100)"""
        severity_weights = {
            "critical": 10,
            "high": 7,
            "medium": 4,
            "low": 1,
            "info": 0
        }
        
        total_score = sum(
            severity_weights[vuln.severity.lower()]
            for vuln in self.vulnerabilities
        )
        
        # Normalize to 0-100
        return min(100, total_score)
    
    def _generate_recommendations(self) -> List[str]:
        """Generate overall recommendations"""
        recommendations = []
        
        # Get unique recommendations
        seen = set()
        for vuln in self.vulnerabilities:
            for rec in vuln.recommendations:
                if rec not in seen:
                    recommendations.append(rec)
                    seen.add(rec)
        
        return recommendations


def main():
    """Main entry point"""
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description="OWASP Mobile Top 10 Security Scanner")
    parser.add_argument("apk_path", help="Path to the APK file")
    parser.add_argument("--output", "-o", help="Output file path", default=None)
    parser.add_argument("--format", "-f", choices=["json", "text"], default="json", help="Output format")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    # Create scanner
    scanner = OWASPScanner(args.apk_path)
    
    # Perform scan
    print(f"Scanning: {args.apk_path}")
    results = scanner.scan()
    
    # Output results
    if args.format == "json":
        output = json.dumps(results, indent=2)
    else:
        output = format_text_results(results)
    
    # Write to file or stdout
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"\nResults saved to: {args.output}")
    else:
        print(output)


def format_text_results(results: Dict[str, Any]) -> str:
    """Format results as text"""
    output = [
        "OWASP Mobile Top 10 Security Scan Results",
        "=" * 50,
        f"\nAPK: {results.get('apk_path', 'Unknown')}",
        f"Status: {results.get('scan_status', 'Unknown')}",
        f"Vulnerabilities Found: {results.get('summary', {}).get('total_vulnerabilities', 0)}",
        f"Risk Score: {results.get('summary', {}).get('risk_score', 0)}/100",
    ]
    
    vulnerabilities = results.get('vulnerabilities', [])
    if vulnerabilities:
        output.append("\n" + "=" * 50)
        output.append("\nVulnerabilities:")
        for vuln in vulnerabilities:
            output.append(f"\n[{vuln.get('severity', '').upper()}] {vuln.get('owasp_id')}: {vuln.get('title')}")
            output.append(f"  Description: {vuln.get('description')}")
            output.append(f"  CWE: {vuln.get('cwe', 'N/A')}")
            output.append(f"  Location: {vuln.get('location', 'N/A')}")
            
            recommendations = vuln.get('recommendations', [])
            if recommendations:
                output.append("  Recommendations:")
                for rec in recommendations:
                    output.append(f"    • {rec}")
    
    return "\n".join(output)


if __name__ == "__main__":
    main()