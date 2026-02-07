# Enhanced APK Reverse Engineering Tool v2.0

A comprehensive, enhanced version of the popular `apk.sh` tool with advanced reverse engineering capabilities, security analysis, and device compatibility features.

## 🚀 Features

### Core Functionality (Enhanced from original apk.sh)
- **APK Pulling** - Pull APKs from Android devices with split APK support
- **Decoding** - Decode APKs using apktool with enhanced options
- **Building** - Rebuild APKs with validation and error checking
- **Patching** - Inject Frida gadgets and other runtime analysis tools
- **Package Renaming** - Rename APK packages with dependency resolution

### 🆕 New Advanced Features
- **🔍 Comprehensive Security Analysis**
  - Certificate analysis and validation
  - Permission categorization (dangerous, normal, signature)
  - Security vulnerability scanning
  - Debug mode detection
  - Hardcoded secret detection

- **📱 Device Compatibility**
  - Automatic device compatibility checking
  - Architecture detection and validation
  - Android version compatibility analysis
  - Multi-device support

- **🛡️ Enhanced Security Features**
  - Anti-tampering detection
  - Code obfuscation analysis
  - Network security configuration analysis
  - Backup and restore functionality

- **📊 Advanced Analysis**
  - Interactive mode with guided workflow
  - JSON-based reporting with detailed metrics
  - Automated vulnerability scanning
  - Code structure analysis

- **🔧 Developer Tools**
  - Plugin system for extensibility
  - Enhanced logging and debugging
  - Multiple output formats (JSON, XML, text)
  - Configuration management

### 📱 Android & Web Integration
- **📱 Android Companion App** - Native Android app for remote control of analysis tool
- **🌐 Mobile Web Interface** - Progressive Web App accessible from any Android browser
- **🔌 Cross-Platform API** - Unified REST API supporting both mobile and web clients
- **⚡ Real-time Analysis** - Live progress tracking via WebSocket connections
- **📱 Mobile Upload** - Upload APKs directly from Android devices
- **📊 Mobile Reports** - View analysis results optimized for mobile screens
- **🔔 Push Notifications** - Get analysis completion alerts on your device

## 📋 Requirements

### Supported Platforms
- ✅ **Linux**: Debian/Ubuntu (APT), Fedora/RHEL (DNF), Arch Linux (Pacman)
- ✅ **macOS**: macOS 10.14+ with Homebrew
- ✅ **Windows**: Windows 10/11 (native PowerShell or WSL)
- ✅ **Windows WSL**: Windows Subsystem for Linux (Ubuntu, Fedora, etc.)

### System Requirements
- Java 11 or higher
- Python 3.7+
- 2GB+ RAM
- 1GB+ disk space
- Internet connection for downloading dependencies

### Automatic Installation

#### Linux (Debian/Ubuntu)
```bash
sudo ./install-dependencies.sh
```

#### Linux (Fedora/RHEL)
```bash
sudo ./install-dependencies.sh
# The script automatically detects your distribution and uses DNF
```

#### Linux (Arch Linux)
```bash
sudo ./install-dependencies.sh
# The script automatically detects your distribution and uses Pacman
```

#### macOS
```bash
# Ensure you have Homebrew installed
sudo ./install-dependencies.sh
# The script automatically detects macOS and uses Homebrew
```

#### Windows (Native PowerShell)
```powershell
# Run PowerShell as Administrator
.\install-dependencies-windows.ps1
```

#### Windows (WSL)
```bash
# In WSL terminal (Ubuntu, Fedora, etc.)
sudo ./install-dependencies.sh
# The script automatically detects WSL environment
```

### Manual Dependencies
If you prefer manual installation, ensure you have:

#### Core Tools
- `wget`, `curl`, `unzip`, `zip`
- `openjdk-11-jdk` (Debian/Ubuntu) or `java-11-openjdk-devel` (Fedora/RHEL)
- `python3`, `pip3`
- `jq` (for JSON processing)

#### Android Tools
- `adb` (Android Debug Bridge)
- `apktool` v2.8.1+
- `aapt` (Android Asset Packaging Tool)
- `apksigner`, `zipalign`

#### Analysis Tools
- `jadx` (Java decompiler)
- `androguard` (Python APK analysis)
- `frida-tools` (Runtime analysis)

## 🚀 Quick Start

### 1. Installation

#### Linux/macOS/WSL
```bash
# Clone or download the tool
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Make executable
chmod +x apk-reverse-tool.sh

# Install dependencies (detects your OS automatically)
sudo ./install-dependencies.sh
```

#### Windows (Native PowerShell)
```powershell
# Clone or download the tool
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Run PowerShell installer as Administrator
.\install-dependencies-windows.ps1
```

### 2. Basic Usage

#### Interactive Mode (Recommended for beginners)
```bash
./apk-reverse-tool.sh interactive
```

#### Pull APK from Device
```bash
# Basic pull
./apk-reverse-tool.sh pull com.example.app

# With device compatibility check
./apk-reverse-tool.sh pull com.example.app --device-compat
```

#### Comprehensive Analysis
```bash
# Full analysis
./apk-reverse-tool.sh analyze app.apk

# Deep security analysis
./apk-reverse-tool.sh analyze app.apk --deep-analysis

# Export to specific format
./apk-reverse-tool.sh analyze app.apk --format json --output analysis_report
```

## 📖 Detailed Usage

### Command Structure
```bash
./apk-reverse-tool.sh [COMMAND] [OPTIONS] [ARGUMENTS]
```

### Available Commands

#### 🔍 `analyze` - Comprehensive APK Analysis
```bash
# Basic analysis
./apk-reverse-tool.sh analyze <apk_file>

# Deep security analysis
./apk-reverse-tool.sh analyze <apk_file> --deep-analysis

# Custom output format
./apk-reverse-tool.sh analyze <apk_file> --format json --output <directory>

# Enable specific analysis modules
./apk-reverse-tool.sh analyze <apk_file> --cert-analysis --perm-analysis
```

**Analysis Features:**
- Basic APK information extraction
- Certificate analysis with validation
- Permission categorization and security assessment
- Security vulnerability scanning
- Code structure analysis
- Anti-tampering detection
- Obfuscation detection

#### 📱 `pull` - Enhanced APK Pulling
```bash
# Pull with device compatibility check
./apk-reverse-tool.sh pull <package_name> --device-compat

# Create backup before pulling
./apk-reverse-tool.sh pull <package_name> --backup

# Pull with automatic analysis
./apk-reverse-tool.sh pull <package_name> --analyze-after
```

#### 🔧 `patch` - Advanced APK Patching
```bash
# Patch with Frida gadget
./apk-reverse-tool.sh patch <apk_file> --arch arm --gadget-conf config.json

# Patch with security enhancements
./apk-reverse-tool.sh patch <apk_file> --security-patches

# Patch for debugging
./apk-reverse-tool.sh patch <apk_file> --debug-mode --allow-backup
```

#### 🏗️ `build` - Enhanced APK Building
```bash
# Build with validation
./apk-reverse-tool.sh build <apk_directory> --validate

# Build with custom keystore
./apk-reverse-tool.sh build <apk_directory> --keystore custom.keystore

# Build with network permissive config
./apk-reverse-tool.sh build <apk_directory> --net-permissive
```

#### 🔄 `rename` - Smart Package Renaming
```bash
# Rename with dependency resolution
./apk-reverse-tool.sh rename <apk_file> <new_package_name>

# Rename with manifest updates
./apk-reverse-tool.sh rename <apk_file> <new_package_name> --update-manifest
```

### Options and Flags

#### General Options
- `-v, --verbose` - Enable verbose output
- `-i, --interactive` - Enable interactive mode
- `-o, --output <dir>` - Specify output directory
- `-f, --format <format>` - Output format (json, xml, text)
- `--backup` - Create backup before operations
- `--config <file>` - Use custom configuration file

#### Analysis Options
- `--deep-analysis` - Enable comprehensive security analysis
- `--cert-analysis` - Analyze certificates only
- `--perm-analysis` - Analyze permissions only
- `--vulnerability-scan` - Scan for known vulnerabilities
- `--code-analysis` - Perform code structure analysis

#### Device Options
- `--device-compat` - Check device compatibility
- `--device-id <id>` - Specify target device
- `--auto-detect-arch` - Automatically detect architecture

#### Security Options
- `--security-patches` - Apply security patches
- `--debug-mode` - Enable debug mode
- `--net-permissive` - Add permissive network config

## 📊 Output and Reports

### Analysis Reports
The tool generates comprehensive JSON reports with the following sections:

```json
{
    "tool_info": {
        "name": "apk-reverse-tool",
        "version": "2.0",
        "analysis_date": "2024-01-01T12:00:00Z",
        "apk_file": "example.apk"
    },
    "basic_info": {
        "package_name": "com.example.app",
        "version_name": "1.0.0",
        "version_code": "1",
        "min_sdk": "21",
        "target_sdk": "33"
    },
    "certificate_analysis": {
        "issuer": "CN=Example CA",
        "subject": "CN=Example App",
        "valid_from": "2024-01-01",
        "valid_until": "2025-01-01",
        "algorithm": "SHA256withRSA"
    },
    "permission_analysis": {
        "total": 15,
        "dangerous": ["android.permission.CAMERA", "android.permission.ACCESS_FINE_LOCATION"],
        "normal": ["android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE"],
        "signature": [],
        "dangerous_count": 2
    },
    "security_analysis": {
        "issues_found": 2,
        "issues": ["Application is debuggable", "Application allows backup"],
        "risk_level": "MEDIUM"
    },
    "vulnerability_scan": {
        "vulnerabilities_found": 1,
        "vulnerabilities": ["Potential hardcoded secrets detected"],
        "scan_date": "2024-01-01T12:00:00Z"
    }
}
```

## 🛠️ Utility Scripts

The installation includes several utility scripts for common tasks:

### Certificate Analysis
```bash
# Analyze APK certificate
apk-analyze <apk_file>
```

### Permission Analysis
```bash
# Analyze APK permissions
perm-analyze <apk_file>
```

### Device Information
```bash
# Show connected device information
device-info
```

### Full Analysis
```bash
# Comprehensive APK analysis
full-analysis <apk_file> [output_directory]
```

## 🔧 Configuration

### Default Configuration
Configuration is stored in `~/.apk-reverse-tool/configs/default.conf`:

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

### Custom Configuration
Create a custom configuration file:

```bash
./apk-reverse-tool.sh --config my-config.conf analyze app.apk
```

## 🔌 Plugin System

The tool supports plugins for extensibility. Plugins are stored in `~/.apk-reverse-tool/plugins/`.

### Creating a Plugin
```bash
# Example plugin structure
mkdir -p ~/.apk-reverse-tool/plugins/my-plugin
cat > ~/.apk-reverse-tool/plugins/my-plugin/plugin.sh << 'EOF'
#!/bin/bash
# Custom analysis plugin

plugin_analyze() {
    local apk_file="$1"
    echo "Custom analysis for $apk_file"
    # Add your custom analysis logic here
}
EOF

chmod +x ~/.apk-reverse-tool/plugins/my-plugin/plugin.sh
```

### Using Plugins
```bash
# Load specific plugin
./apk-reverse-tool.sh analyze app.apk --plugin my-plugin
```

## 📱 Device Compatibility

### Supported Android Versions
- Android 5.0 (API 21) and higher
- Full support for Android 7.0+ (API 24+)

### Supported Architectures
- ARM (armeabi-v7a)
- ARM64 (arm64-v8a)
- x86
- x86_64

### Device Requirements
- USB debugging enabled
- ADB authorization granted
- Sufficient storage space

## 🔍 Advanced Usage Examples

### Security Audit Workflow
```bash
# 1. Pull app from device
./apk-reverse-tool.sh pull com.target.app --device-compat --backup

# 2. Perform comprehensive analysis
./apk-reverse-tool.sh analyze target-app.apk --deep-analysis --format json

# 3. Patch for analysis
./apk-reverse-tool.sh patch target-app.apk --arch arm64 --security-patches

# 4. Deploy and monitor
adb install target-app.gadget.apk
frida -U -f com.target.app -l analysis-script.js
```

### Batch Analysis
```bash
# Analyze multiple APKs
for apk in *.apk; do
    ./apk-reverse-tool.sh analyze "$apk" --output "reports/${apk%.apk}_report"
done
```

### Custom Analysis Pipeline
```bash
#!/bin/bash
# Custom analysis pipeline

APK_DIR="apks"
REPORT_DIR="reports"

mkdir -p "$REPORT_DIR"

for apk in "$APK_DIR"/*.apk; do
    echo "Processing $apk..."
    
    # Extract basic info
    ./apk-reverse-tool.sh analyze "$apk" --cert-analysis --perm-analysis
    
    # Check for vulnerabilities
    ./apk-reverse-tool.sh analyze "$apk" --vulnerability-scan
    
    # Generate summary report
    echo "Analysis completed for $(basename "$apk")"
done
```

## 🐛 Troubleshooting

### Common Issues

#### ADB Connection Issues
```bash
# Check device connection
adb devices

# Restart ADB server
sudo adb kill-server
sudo adb start-server

# Check device authorization
adb devices
```

#### Permission Issues
```bash
# Fix ADB permissions
sudo usermod -aG plugdev $USER
sudo chmod -R 755 /opt/android-sdk
```

#### Java Issues
```bash
# Check Java version
java -version

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

#### Tool Path Issues
```bash
# Add tools to PATH
export PATH=$PATH:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/33.0.1
```

### Debug Mode
Enable verbose logging for troubleshooting:

```bash
./apk-reverse-tool.sh --verbose analyze app.apk
```

Check log files in `~/.apk-reverse-tool/logs/` for detailed error information.

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Update documentation
5. Submit a pull request

### Development Setup
```bash
# Clone repository
git clone <repository-url>
cd apk-reverse-tool

# Install development dependencies
pip install -r requirements-dev.txt

# Run tests
./run-tests.sh
```

## 📄 License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Original `apk.sh` by [ax](https://github.com/ax/apk.sh)
- [apktool](https://github.com/iBotPeaches/Apktool) for APK decoding
- [Frida](https://github.com/frida/frida) for dynamic instrumentation
- [jadx](https://github.com/skylot/jadx) for Java decompilation
- [Androguard](https://github.com/androguard/androguard) for Python analysis

## 📞 Support

- 📧 Email: support@example.com
- 💬 Discord: [Join our community](https://discord.gg/example)
- 📖 Documentation: [Full documentation](https://docs.example.com)
- 🐛 Issues: [GitHub Issues](https://github.com/example/apk-reverse-tool/issues)

---

**Enhanced APK Reverse Engineering Tool v2.0** - Making Android reverse engineering more powerful, secure, and accessible.