# API Reference - Enhanced APK Reverse Engineering Tool

## Overview

The Enhanced APK Reverse Engineering Tool provides both command-line interface and programmatic API for comprehensive Android APK analysis and reverse engineering.

## Command Line API

### Basic Syntax

```bash
./apk-reverse-tool.sh [COMMAND] [OPTIONS] [ARGUMENTS]
```

### Commands Reference

#### analyze

Comprehensive APK analysis with multiple modules.

**Syntax:**
```bash
./apk-reverse-tool.sh analyze <apk_file> [OPTIONS]
```

**Options:**
- `--deep-analysis` - Enable comprehensive security analysis
- `--cert-analysis` - Analyze certificates only
- `--perm-analysis` - Analyze permissions only
- `--vulnerability-scan` - Scan for known vulnerabilities
- `--code-analysis` - Perform code structure analysis
- `-o, --output <dir>` - Specify output directory
- `-f, --format <format>` - Output format (json, xml, text)
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Basic analysis
./apk-reverse-tool.sh analyze app.apk

# Deep security analysis
./apk-reverse-tool.sh analyze app.apk --deep-analysis

# Certificate analysis only
./apk-reverse-tool.sh analyze app.apk --cert-analysis

# Export to JSON format
./apk-reverse-tool.sh analyze app.apk --format json --output analysis_report
```

**Return Values:**
- `0` - Success
- `1` - Error (invalid APK, missing dependencies, etc.)

**Output Structure:**
```json
{
  "tool_info": { ... },
  "basic_info": { ... },
  "certificate_analysis": { ... },
  "permission_analysis": { ... },
  "security_analysis": { ... },
  "vulnerability_scan": { ... },
  "code_analysis": { ... }
}
```

#### pull

Enhanced APK pulling from Android devices.

**Syntax:**
```bash
./apk-reverse-tool.sh pull <package_name> [OPTIONS]
```

**Options:**
- `--device-compat` - Check device compatibility
- `--backup` - Create backup before pulling
- `--analyze-after` - Analyze APK after pulling
- `--device-id <id>` - Specify target device
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Basic pull
./apk-reverse-tool.sh pull com.example.app

# Pull with compatibility check
./apk-reverse-tool.sh pull com.example.app --device-compat

# Pull and analyze
./apk-reverse-tool.sh pull com.example.app --analyze-after
```

**Return Values:**
- `0` - Success
- `1` - Error (device not connected, package not found, etc.)

#### patch

Advanced APK patching with multiple framework options.

**Syntax:**
```bash
./apk-reverse-tool.sh patch <apk_file> --arch <arch> [OPTIONS]
```

**Required Options:**
- `-a, --arch <arch>` - Target architecture (arm, arm64, x86, x86_64)

**Options:**
- `-g, --gadget-conf <json_file>` - Frida gadget configuration
- `--security-patches` - Apply security patches
- `--debug-mode` - Enable debug mode
- `--net-permissive` - Add permissive network config
- `-o, --output <dir>` - Specify output directory
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Basic patching
./apk-reverse-tool.sh patch app.apk --arch arm

# Patch with custom Frida config
./apk-reverse-tool.sh patch app.apk --arch arm --gadget-conf config.json

# Patch with security enhancements
./apk-reverse-tool.sh patch app.apk --arch arm --security-patches
```

**Return Values:**
- `0` - Success
- `1` - Error (invalid architecture, patching failed, etc.)

#### build

Enhanced APK building with validation.

**Syntax:**
```bash
./apk-reverse-tool.sh build <apk_directory> [OPTIONS]
```

**Options:**
- `--validate` - Validate APK structure before building
- `--keystore <file>` - Use custom keystore
- `--net-permissive` - Add permissive network config
- `-o, --output <file>` - Specify output APK file
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Basic build
./apk-reverse-tool.sh build app_decoded

# Build with validation
./apk-reverse-tool.sh build app_decoded --validate

# Build with custom keystore
./apk-reverse-tool.sh build app_decoded --keystore custom.keystore
```

**Return Values:**
- `0` - Success
- `1` - Error (build failed, validation error, etc.)

#### rename

Smart package renaming with dependency resolution.

**Syntax:**
```bash
./apk-reverse-tool.sh rename <apk_file> <new_package_name> [OPTIONS]
```

**Options:**
- `--update-manifest` - Update AndroidManifest.xml
- `--update-resources` - Update resource references
- `--backup` - Create backup before renaming
- `-v, --verbose` - Enable verbose output

**Examples:**
```bash
# Basic renaming
./apk-reverse-tool.sh rename app.apk com.new.package

# Rename with manifest update
./apk-reverse-tool.sh rename app.apk com.new.package --update-manifest
```

**Return Values:**
- `0` - Success
- `1` - Error (invalid package name, renaming failed, etc.)

#### interactive

Interactive mode with guided workflow.

**Syntax:**
```bash
./apk-reverse-tool.sh interactive [OPTIONS]
```

**Options:**
- `--expert` - Enable expert mode
- `--theme <theme>` - Set color theme

**Examples:**
```bash
# Start interactive mode
./apk-reverse-tool.sh interactive

# Expert mode
./apk-reverse-tool.sh interactive --expert
```

### Global Options

These options can be used with any command:

- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help for command
- `--config <file>` - Use custom configuration file
- `--log-level <level>` - Set logging level (DEBUG, INFO, WARN, ERROR)
- `--no-color` - Disable colored output

## Programmatic API

### Python API

The tool can be imported and used programmatically in Python:

```python
from apk_reverse_tool import APKAnalyzer, AnalysisConfig

# Initialize analyzer
config = AnalysisConfig(
    deep_analysis=True,
    vulnerability_scan=True,
    output_format="json"
)
analyzer = APKAnalyzer(config)

# Analyze APK
result = analyzer.analyze("app.apk")

# Access results
print(f"Package: {result.basic_info.package_name}")
print(f"Risk Level: {result.security_analysis.risk_level}")
print(f"Vulnerabilities: {len(result.vulnerability_scan.vulnerabilities)}")
```

### Configuration Classes

#### AnalysisConfig

```python
class AnalysisConfig:
    def __init__(
        self,
        deep_analysis: bool = False,
        vulnerability_scan: bool = True,
        certificate_analysis: bool = True,
        permission_analysis: bool = True,
        code_analysis: bool = False,
        output_format: str = "json",
        output_directory: str = None,
        verbose: bool = False
    ):
        ...
```

#### SecurityConfig

```python
class SecurityConfig:
    def __init__(
        self,
        check_debug_mode: bool = True,
        check_allow_backup: bool = True,
        check_network_security: bool = True,
        check_hardcoded_secrets: bool = True,
        check_obfuscation: bool = True
    ):
        ...
```

### Result Objects

#### AnalysisResult

```python
class AnalysisResult:
    def __init__(self):
        self.tool_info: ToolInfo = None
        self.basic_info: BasicInfo = None
        self.certificate_analysis: CertificateAnalysis = None
        self.permission_analysis: PermissionAnalysis = None
        self.security_analysis: SecurityAnalysis = None
        self.vulnerability_scan: VulnerabilityScan = None
        self.code_analysis: CodeAnalysis = None
```

#### BasicInfo

```python
class BasicInfo:
    package_name: str
    version_name: str
    version_code: str
    min_sdk: str
    target_sdk: str
    permissions: List[str]
    activities: List[str]
    services: List[str]
    receivers: List[str]
```

#### SecurityAnalysis

```python
class SecurityAnalysis:
    issues_found: int
    issues: List[str]
    risk_level: str  # LOW, MEDIUM, HIGH, CRITICAL
    security_score: int  # 0-100
    recommendations: List[str]
```

### Plugin API

#### Creating Plugins

```python
from apk_reverse_tool.plugins import BasePlugin

class CustomAnalysisPlugin(BasePlugin):
    name = "custom-analysis"
    version = "1.0.0"
    
    def analyze(self, apk_file: str, config: AnalysisConfig) -> dict:
        # Custom analysis logic
        results = {
            "custom_metric": self.calculate_custom_metric(apk_file),
            "custom_findings": self.find_custom_issues(apk_file)
        }
        return results
    
    def calculate_custom_metric(self, apk_file: str) -> int:
        # Implementation
        pass
    
    def find_custom_issues(self, apk_file: str) -> List[str]:
        # Implementation
        pass
```

#### Registering Plugins

```python
from apk_reverse_tool import APKAnalyzer

analyzer = APKAnalyzer()
analyzer.register_plugin(CustomAnalysisPlugin())

# Use plugin
result = analyzer.analyze("app.apk", plugins=["custom-analysis"])
```

## REST API

The tool can expose a REST API for remote analysis:

### Starting the API Server

```bash
./apk-reverse-tool.sh serve --port 8080 --host 0.0.0.0
```

### API Endpoints

#### POST /analyze

Analyze an APK file.

**Request:**
```bash
curl -X POST \
  http://localhost:8080/analyze \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@app.apk' \
  -F 'deep_analysis=true' \
  -F 'format=json'
```

**Response:**
```json
{
  "status": "success",
  "task_id": "12345",
  "message": "Analysis started"
}
```

#### GET /analyze/{task_id}

Get analysis results.

**Request:**
```bash
curl http://localhost:8080/analyze/12345
```

**Response:**
```json
{
  "status": "completed",
  "result": {
    "tool_info": { ... },
    "basic_info": { ... },
    "security_analysis": { ... }
  }
}
```

#### GET /devices

List connected devices.

**Request:**
```bash
curl http://localhost:8080/devices
```

**Response:**
```json
{
  "devices": [
    {
      "id": "emulator-5554",
      "model": "Android SDK built for x86",
      "version": "11",
      "arch": "x86"
    }
  ]
}
```

#### POST /pull

Pull APK from device.

**Request:**
```bash
curl -X POST \
  http://localhost:8080/pull \
  -H 'Content-Type: application/json' \
  -d '{
    "package_name": "com.example.app",
    "device_id": "emulator-5554",
    "analyze_after": true
  }'
```

**Response:**
```json
{
  "status": "success",
  "apk_file": "com.example.app.apk",
  "analysis": { ... }
}
```

## Configuration API

### Configuration Files

#### Default Configuration

Location: `~/.apk-reverse-tool/configs/default.conf`

```bash
# Tool Versions
APKTOOL_VER="latest"
FRIDA_VER="latest"
BUILDTOOLS_VER="33.0.1"

# Security Settings
ENABLE_DEEP_ANALYSIS=false
ENABLE_VULNERABILITY_SCAN=true
ENABLE_CERTIFICATE_ANALYSIS=true
ENABLE_PERMISSION_ANALYSIS=true

# Output Settings
DEFAULT_OUTPUT_FORMAT="json"
ENABLE_VERBOSITY=false
CREATE_BACKUPS=true
```

#### Custom Configuration

```bash
# Create custom config
./apk-reverse-tool.sh --config custom.conf analyze app.apk
```

### Environment Variables

- `APK_REVERSE_TOOL_HOME` - Tool home directory
- `APK_REVERSE_TOOL_LOG_LEVEL` - Default log level
- `APK_REVERSE_TOOL_CONFIG` - Default config file
- `ANDROID_HOME` - Android SDK path
- `JAVA_HOME` - Java installation path

## Error Handling

### Error Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | File not found |
| 4 | Permission denied |
| 5 | Device not connected |
| 6 | Analysis failed |
| 7 | Build failed |
| 8 | Patch failed |

### Error Response Format

```json
{
  "error": {
    "code": 3,
    "message": "APK file not found",
    "details": "The specified APK file does not exist or is not readable"
  }
}
```

## Rate Limiting

When using the REST API, rate limiting applies:

- **Anonymous users**: 10 requests per minute
- **Authenticated users**: 100 requests per minute
- **Premium users**: 1000 requests per minute

Rate limit headers are included in responses:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## Integration Examples

### Docker Integration

```dockerfile
FROM ubuntu:20.04

# Install tool
COPY . /opt/apk-reverse-tool
RUN /opt/apk-reverse-tool/install-dependencies.sh

# Set up API server
EXPOSE 8080
CMD ["/opt/apk-reverse-tool/apk-reverse-tool.sh", "serve", "--port", "8080"]
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
name: APK Security Scan
on: [push]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Scan APK
      run: |
        ./apk-reverse-tool.sh analyze app.apk --deep-analysis --format json --output security-report
    
    - name: Upload Results
      uses: actions/upload-artifact@v2
      with:
        name: security-report
        path: security-report/
```

### Python Integration

```python
import subprocess
import json

def analyze_apk_security(apk_path):
    """Analyze APK security using the tool."""
    cmd = [
        "./apk-reverse-tool.sh",
        "analyze", apk_path,
        "--deep-analysis",
        "--format", "json",
        "--output", "temp_analysis"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        with open("temp_analysis/analysis_report.json", "r") as f:
            analysis = json.load(f)
        
        return analysis
    else:
        raise Exception(f"Analysis failed: {result.stderr}")

# Usage
try:
    security_report = analyze_apk_security("app.apk")
    print(f"Risk Level: {security_report['security_analysis']['risk_level']}")
    print(f"Vulnerabilities: {len(security_report['vulnerability_scan']['vulnerabilities'])}")
except Exception as e:
    print(f"Error: {e}")
```

## Performance Considerations

### Optimization Tips

1. **Use specific analysis modules** instead of full analysis when possible
2. **Enable caching** for repeated analyses of the same APK
3. **Use batch analysis** for multiple APKs
4. **Adjust parallel processing** based on available CPU cores
5. **Monitor memory usage** for large APKs

### Benchmarks

| APK Size | Analysis Time | Memory Usage |
|----------|---------------|--------------|
| 10MB | 5-10 seconds | 100-200MB |
| 50MB | 30-60 seconds | 300-500MB |
| 100MB | 2-5 minutes | 500MB-1GB |

### Resource Limits

- **Maximum APK size**: 500MB
- **Maximum analysis time**: 30 minutes
- **Memory limit**: 2GB per analysis
- **Concurrent analyses**: 5 (configurable)

---

This API reference provides comprehensive documentation for integrating and using the Enhanced APK Reverse Engineering Tool in various environments and workflows.