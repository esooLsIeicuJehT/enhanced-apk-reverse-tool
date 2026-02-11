# Installation Guide - Enhanced APK Reverse Engineering Tool v2.0

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Platform-Specific Installation](#platform-specific-installation)
4. [Docker Deployment](#docker-deployment)
5. [Building from Source](#building-from-source)
6. [Post-Installation Configuration](#post-installation-configuration)
7: [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements
- **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux), macOS 10.15+, or Windows 10+
- **RAM**: 4GB (8GB recommended)
- **Disk Space**: 2GB free space (10GB recommended)
- **Python**: Python 3.7 or higher
- **Java**: OpenJDK 11 or higher (required for Android tools)

### Optional Dependencies
- **adb**: Android Debug Bridge (for device interaction)
- **jadx**: Java APK decompiler (recommended for code analysis)
- **apktool**: APK tool for decompilation and rebuilding (recommended)
- **frida-tools**: Frida instrumentation framework (for dynamic analysis)

---

## Installation Methods

### 1. Automated Installation Script (Recommended)
The easiest way to install the tool is using the provided installation script:

```bash
# Download the tool
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Run the installation script
chmod +x install-dependencies.sh
./install-dependencies.sh
```

**Supported Platforms:** Linux, macOS, Windows (via WSL)

### 2. Package Manager Installation

#### Linux
**Debian/Ubuntu (.deb)**
```bash
wget https://github.com/esooLsIeicuJehT/enhanced-reverse-tool/releases/download/v2.0.0/apk-reverse-tool_2.0.0-1_amd64.deb
sudo dpkg -i apk-reverse-tool_2.0.0-1_amd64.deb
sudo apt-get install -f
```

**Fedora/RHEL (.rpm)**
```bash
wget https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/apk-reverse-tool-2.0.0-1.noarch.rpm
sudo dnf install apk-reverse-tool-2.0.0-1.noarch.rpm
```

**Arch Linux (AUR)**
```bash
git clone https://aur.archlinux.org/apk-reverse-tool.git
cd apk-reverse-tool
makepkg -si
```

**Snap**
```bash
sudo snap install apk-reverse-tool
```

#### macOS
```bash
brew tap apktool/tap
brew install apk-reverse-tool
```

#### Windows
Use the provided PowerShell script:
```powershell
# Open PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-WebRequest -Uri "https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

### 3. Docker Deployment (Recommended for Servers)

#### Quick Start
```bash
# Clone repository
git clone https://github.com/esooLsIecuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Deploy full stack (API + Web Interface + Database + Redis)
docker-compose up -d

# Access web interface
# http://localhost:3000
```

#### Individual Services
```bash
# Deploy only the main tool
docker build -t apk-reverse-tool -f Dockerfile.main-tool .
docker run -d -p 8080:8080 -v ./uploads:/workspace/uploads apk-reverse-tool

# Deploy only the web interface
cd web-interface
docker build -t apk-web-interface .
docker run -d -p 3000:80 apk-web-interface
```

---

## Platform-Specific Installation

### Debian/Ubuntu

#### Manual Installation
```bash
# Update package list
sudo apt update

# Install required dependencies
sudo apt install -y python3 python3-pip openjdk-11-jre git wget curl unzip adb

# Install Python dependencies
pip3 install --upgrade pip
pip3 install flask flask-cors flask-socketio websocket-client requests pyyaml

# Install optional tools
sudo apt install -y jadx apktool frida-tools

# Clone the tool
git clone https://github.com/esooLsLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Install dependencies
chmod +x install-dependencies.sh
./install-dependencies.sh

# Make executable
sudo chmod +x apk-reverse-tool.sh
sudo ln -s $(pwd)/apk-reverse-tool.sh /usr/local/bin/apk-reverse-tool
```

#### Using .deb Package
```bash
# Download package
wget https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/apk-reverse-tool_2.0.0-1_amd64.deb

# Install
sudo dpkg -i apk-reverse-tool_2.0.0-1_amd64.deb
sudo apt-get -f

# Start service
sudo systemctl start apk-reverse-tool
sudo systemctl enable apk-reverse-tool
```

### Fedora/RHEL

#### Manual Installation
```bash
# Install required dependencies
sudo dnf install -y python3 python3-pip known-adb openjdk-11-jre git wget curl unzip

# Clone and install
git clone https://.github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool
./install-dependencies.sh

# Install to /opt
sudo cp -r . /opt/apk-reverse-tool/
sudo chmod +x /opt/apk-reverse-tool/apk-reverse-tool.sh
sudo ln -s /opt/apk-reverse-tool/apk-reverse-tool.sh /usr/local/bin/apk-reverse-tool
```

### Arch Linux

#### From AUR
```bash
git clone https://aur.archlinux.org/apk-reverse-tool.git
cd apk-reverse-tool
makepkg -si
```

#### Manual Installation
```bash
# Install dependencies
sudo pacman -S --noconfirm python3 python-pip jdk11-openjdk android-tools git

# Clone and install
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool
./install-dependencies.sh

# Install to /usr
sudo cp -r . /usr/share/apk-reverse-tool/
sudo chmod +x /usr/share/apk-reverse-tool/apk-reverse-tool.sh
sudo ln -s /usr/share/apk-reverse-tool/apk-reverse-tool.sh /usr/bin/apk-reverse-tool
```

### macOS

#### Using Homebrew
```bash
# Tap homebrew
brew tap apktool/tap
brew install apk-reverse-tool
```

#### Manual Installation
```bash
# Install dependencies
brew install python3 python3-pip git

# Clone and install
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool
./install-dependencies.sh

# Add to PATH
echo 'export PATH="'"$(pwd)"'":$PATH' >> ~/.zshrc
```

### Windows

#### Using WSL
```bash
# Install Ubuntu in WSL
# Follow Debian/Ubuntu instructions above
```

#### Using PowerShell
```powershell
# Download and run installer
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-WebRequest -Uri "https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

---

## Docker Deployment

### Full Stack Deployment (Recommended)
```bash
# Clone repository
git clone https://github.com/esooLsIecuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Deploy with monitoring
docker-compose up -d

# Services deployed:
# - APK Tool API (http://localhost:8080)
# - Web Interface (http://localhost:3000)
# - Redis Cache (port 6379)
# - PostgreSQL (port 5432)
# - Nginx Proxy (http://localhost)
# - Prometheus Monitoring (http://localhost:9090)
# - Grafana (http://localhost:3001)
```

### Minimal Deployment
```bash
# Deploy only the API server
docker build -t apk-tool-api .
docker run -d \
    -p 8080:8080 \
    -v ./uploads:/workspace/uploads \
    -v ./analyses:/workspace/analyses \
    -e FLASK_ENV=production \
    apk-tool-api
```

### Kubernetes Deployment
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Deploy to production
kubectl scale deployment apk-tool --replicas=3
kubectl autoscale deployment apk-tool --cpu-percent=70 --min=2 --max=5
```

---

## Building from Source

### Development Build
```bash
# Clone repository
git clone https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool.git
cd enhanced-apk-reverse-tool

# Install dependencies
./install-dependencies.sh

# Run from source
./apk-reverse-tool.sh analyze app.apk
```

### Building Packages

#### .deb Package
```bash
cd packages
chmod +x build-deb.sh
./build-deb.sh
# Output: dist/apk-reverse-tool_2.0.0-1_amd64.deb
```

#### .rpm Package
```bash
cd packages
rpmbuild -bb --define "_topdir $(pwd)" apk-reverse-tool.spec
# Output: RPMS/noarch/apk-reverse-tool-2.0.0-1.noarch.rpm
```

#### Arch Package
```bash
cd packages
makepkg -si
```

#### Snap Package
```bash
cd packages
snapcraft
# Output: apk-reverse-tool_2.0.0_amd64.snap
```

---

## Post-Installation Configuration

### API Server Configuration

#### Create Configuration File
```json
{
    "host": "0.0.0.0",
    "port": 8080,
    "max_upload_size": 1073741824,
    "max_analysis_time": 3600,
    "log_level": "INFO",
    "database": {
        "url": "postgresql://apktool:apktool123@localhost:5432/apktool_db",
        "pool_size": 10,
        "max_overflow": 20
    },
    "redis": {
        "host": "localhost",
        "port": 6379,
        "db": 0
    }
}
```

#### Enable systemd Service
```bash
sudo systemctl enable apk-reverse-tool.service
sudo systemctl start apk-reverse-tool.service
sudo systemctl status apk-reverse-tool.service
```

### Web Interface Configuration

#### Environment Variables
```bash
# Set API URL
export REACT_APP_API_URL="http://localhost:8080"
export REACT_APP_WEBSOCKET_URL="ws://localhost:8080"
```

#### Build and Deploy
```bash
cd web-interface
npm install
npm run build

# Deploy to web server
sudo cp -r build/* /var/www/html/
```

### Android Companion App

#### Install APK
```bash
# Download APK
wget https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/releases/download/v2.0.0/app-release.apk

# Install to device
adb install app-release.apk
```

---

## Troubleshooting

### Installation Issues

#### Python 3 Not Found
```bash
# Ubuntu/Debian
sudo apt install -y python3 python3-pip

# Fedora/RHEL
sudo dnf install -y python3 python3-pip

# Arch
sudo pacman -S --noconfirm python3 python-pip
```

#### Permission Errors
```bash
# Use sudo
sudo ./install-dependencies.sh

# Or set ownership
sudo chown -R $USER:$USER /opt/apk-reverse-tool/
```

#### Missing Dependencies
```bash
# Run dependency installer
./install-dependencies.sh

# Or install manually
pip3 install flask flask-cors flask-socketio
```

### Runtime Issues

#### ADB Not Working
```bash
# Check device connection
adb devices

# Start ADB server
adb start-server

# Reconnect
adb kill-server
adb start-server
```

#### Java Not Found
```bash
# Install Java
sudo apt install -y openjdk-11-jre

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
```

#### Tool Not in PATH
```bash
# Add to PATH
export PATH="/opt/apk-reverse-tool:$PATH"

# Or create symlink
sudo ln -s /opt/apk-reverse-tool/apk-reverse-tool.sh /usr/local/bin/apk-reverse-tool
```

### Docker Issues

#### Container Not Starting
```bash
# Check logs
docker logs apk-reverse-tool

# Rebuild
docker-compose build --no-cache

# Or check port
sudo netstat -tulpn | grep 8080
```

#### Volume Issues
```bash
# Create volume directory
sudo mkdir -p /workspace/uploads
sudo chown -R 1000:1000 /workspace/
```

---

## Verification

### Test Installation
```bash
# Run help
apk-reverse-tool help

# Run demo
./demo.sh

# Run analysis
apk-reverse-tool analyze example.apk
```

### Verify Services
```bash
# Check API server
curl http://localhost:8080/health

# Check web interface
curl http://localhost:3000
```

---

## Next Steps

After installation, see:
- [Quick Start Guide](README.md) for basic usage
- [API Documentation](API-REFERENCE.md) for API usage
- [Integration Guide](INTEGRATION_GUIDE.md) for advanced features
- [Troubleshooting Guide](TROUBLESHOOTING.md) for solving issues

---

## Support

For installation support, please:
1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/esooLsLsIeicuJehT/enhanced-apk-reverse-tool/issues)
3. Open a new [GitHub Issue](https://github.com/esooLsLsIecuJehT/enhanced-reverse-tool/issues/new)