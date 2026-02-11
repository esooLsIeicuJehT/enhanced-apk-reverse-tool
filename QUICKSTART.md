# Quick Start Guide - Enhanced APK Reverse Engineering Tool v2.0

## Installation

### Docker (Recommended)
```bash
docker-compose up -d
# Access at http://localhost:3000
```

### Linux
```bash
wget https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/apk-reverse-tool_2.0.0-1_amd64.deb
sudo dpkg -i apk-reverse-tool_2.0.0-1_amd64.deb
```

## Basic Usage

### Web Interface

1. Open http://localhost:3000
2. Click "Upload APK"
3. Select your .apk file
4. Choose analysis options (Deep, OWASP, Malware)
5. Click "Start Analysis"
6. Review results

### Command Line

```bash
# Analyze APK
apk-reverse-tool analyze app.apk

# Full analysis
apk-reverse-tool analyze app.apk --deep

# OWASP scan
apk-reverse-tool analyze app.apk --owasp

# Malware detection
apk-reverse-tool analyze app.apk --malware
```

## Common Tasks

### Security Check
```bash
apk-reverse-tool analyze app.apk --security
```

### Pull from Device
```bash
apk-reverse-tool pull com.example.app
```

### Export Report
```bash
apk-reverse-tool analyze app.apk --format json --output report.json
```

## Next Steps

- [Full Installation Guide](INSTALLATION.md)
- [Docker Deployment](DEPLOYMENT.md)
- [API Documentation](API-REFERENCE.md)
- [Troubleshooting](TROUBLESHOOTING.md)