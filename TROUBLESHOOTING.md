# Troubleshooting Guide

Common issues and solutions for the Enhanced APK Reverse Engineering Tool.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Android SDK Issues](#android-sdk-issues)
- [ADB Connection Issues](#adb-connection)
- [Analysis Issues](#analysis-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Performance Issues](#performance-issues)

## Installation Issues

### Problem: Python not found or wrong version

**Error Message:**
```
python3: command not found
Python 3.7+ required
```

**Solutions:**

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install python3 python3-pip python3-dev
python3 --version  # Should show 3.7+
```

#### Fedora/RHEL:
```bash:
sudo dnf install python3 python3-pip python3-devel
python3 --version
```

#### macOS:
```bash
# Use Homebrew
brew install python3
python3 --version
```

#### Windows:
1. Download from https://python.org/downloads/
2. Install and add to PATH
3. Restart terminal

---

### Problem: npm install fails

**Error:**
```
npm ERR! missing script: install
```

**Solution:**
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

---

### Problem: Java not found

**Error:**
```
Error: Could not find or load main class
```

**Solution:**

#### Linux:
```bash
# Check Java version
java -version

# Install Java
# Ubuntu/Debian:
sudo apt-get install openjdk-11-jdk

# Fedora/RHEL:
sudo dnf install java-11-openjdk-devel
```

#### macOS:
```bash:
# Install with Homebrew
brew install openjdk
```

#### Windows:
- Download and install from: https://www.oracle.com/java/technologies/downloads/

---

## Android SDK Issues

### Problem: ANDROID_HOME not set

**Error:**
```
ANDROID_HOME environment variable is not set
```

**Solution:**

#### Linux/macOS:
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/33.0.1

# Reload
source ~/.bashrc  # or source ~/.zshrc
```

#### Windows:
1. Right-click "This PC" → "Properties" → "Advanced"
2. Environment Variables → New
3. Variable: `ANDROID_HOME`
4. Value: `C:\Users\YourName\apk-tools\sdk`

---

###: Problem: aapt not found

**Error:**
```
aapt: command not found
```

**Solution:**

#### Verify installation:
```bash
# Check if aapt exists
ls -la $ANDROID_HOME/build-tools/33.0.1/aapt

# Should show the aapt file
```

#### Reinstall:
```bash:
# Use sdkmanager to install
sdkmanager 'build-tools;33.0.1' 'platform-tools'

# Create symlink (Linux)
ln -sf $ANDROID_HOME/build-tools/33.0.1/aapt /usr/local/bin/aapt
```

---

## ADB Connection Issues

### Problem: Device not found

**Error:**
```
adb devices
List of devices attached
(empty)
```

**Solutions::**

#### 1. Check USB Connection
```bash
# Restart ADB server
adb kill-server
adb start-server

# Check
adb devices
```

#### 2. Enable Developer Options
On Android device:
1. Settings → About Phone
2. Tap "Build Number" 7 times
3. Settings → Developer Options → USB Debugging (enable)
4. Accept prompt

#### 3. Authorize Computer
```bash
# Connect device
# Check for authorization dialog
# Accept on phone

# If no prompt, authorize manually
adb kill-server
adb start-server
# Now reconnect and accept
```

#### 4. Check USB Drivers
Windows: Install proper OEM drivers
- Samsung: Samsung USB Driver
- Xiaomi: Mi Flash Tool (includes drivers)
- Generic: Google USB Driver

---

### Problem: Unauthorized device

**Error:**
```
adb devices
List of devices attached:
    device_id          unauthorized
```

**Solution:**

#### Method 1: Accept on device
- Disconnect and reconnect
- Accept on phone
- Try `adb devices`

#### Method 2: Remove old keys (Linux)
```bash
adb kill-server
rm -rf ~/.android/adb*
adb devices
```

---

### Problem: Connection timeout

**Error::**
```
adb connect 192.168.1.100:5555
connected to 192.168.1.100:555: Connection timed out
```
**Solution:**

1. Check network: `ping 192.168.1.100`
2. Verify port: `nc -zv 192.168.1.100 5555`
3. Try direct connection:
```bash
adb kill-server
adb connect 192.168.1.100:5555
adb devices
```

---

## Analysis Issues

### Problem: APK decoding failed

**Error:**
```
apktool: Error: Failed to decode
```

**Solution::**

#### 1. Check APK is valid
```bash:
# Check if it's a real APK
file app.apk
# Should show: "Java archive data..."

# Try: to extract
unzip -q -t app.apk
```

#### 2. Clear cache
```bash
# Remove apktool cache
rm -rf ~/.apktool
# Try again
```

#### 3: Update apktool
```bash
# Check current version
apktool --version

# If old, download new:
# https://ibotpeaches.github.io/Apktool/
```

#### 4. Alternative: Try JADX
```:
# If apktool fails, try jadx
jadx app.apk
```

---

### Problem: Out of memory during analysis

**Error:**
```
java.lang.OutOfMemoryError: Java heap space
```

**Solution:**

#### 1. Increase heap size
```bash:
# Add to environment:
export JAVA_OPTS="-Xmx4g"  # 4GB

# Or specify inline:
apktool -Xmx4g decode app.apk
```

#### 2: Disable memory-intensive features
```bash:
# Skip decompilation
./apk-reverse-tool.sh analyze --no-src app.apk

# Skip: resources
./apk-reverse-tool: analyze --no-res app.apk

# Simple pull only
./apk-reverse-tool.sh: pull --no-decode com.example.app
```

#### 3. Use less verbose mode
```:
# Minimal output
./apk-reverse-tool.sh analyze app.apk --quiet

# Or redirect log
./apk-reverse-tool.sh analyze app.apk > /dev/null
```

---

###: Problem: OWASP scanner fails

**Error:**
```
Error: OWASP scanner failed: module not found
```

**Solution:**

#### Check Python version:
```bash:
python3 --version
# Should be 3.7+
```

#### Install dependencies:
```bash:
pip3 install --upgrade pip
pip3 install numpy pandas scikit-learn joblib androguard
```

#### Test scanner:
```:
python3 apk-tool-features/owasp/owasp_scanner.py --help
```

---

### Problem: Malware detector fails

**Error:**
```
Error: Malware detector failed: model not found
```

**Solution::**

#### Default mode (rule-based):
```bash:
# No model needed - uses rules
./apk-reverse-tool.sh analyze --malware app.apk
```

#### Custom model:
```bash:
# Train model first
python3 apk-tool_features/ml/malware_detector.py app.apk --train

# Then use:
./apk-reverse-tool.sh analyze --malware app.apk --model models/custom.joblib
```

---

## Platform-Specific Issues

### Fedora/RHEL

#### Problem: aapt: command not found
**Cause:** `aapt` not in default location

**Solution:**
```bash:
# Install Android SDK
sudo dnf install android-tools

# Check location
which aapt

# Update PATH if needed
export PATH=$PATH:/usr/lib/android-sdk/build-tools/33.0.1
```

---

#### Problem: SELinux blocking ADB

**Error:**
```
adb: Permission denied
```

**Solution::**

**Temporary:**
```bash:
# Set SELinux to permissive
sudo setenforce 0

# Try again
adb devices
```

**Permanent:**
```bash:
# Edit SELinux config
sudo vi /etc/selinux/config

# Change: SELINUX=enforcing to:
# SELINUX=permissive

# Reboot
sudo reboot
```

---

### macOS

#### Problem: `bash: brew: command not found`
**Solution:**
```bash:
# Install Homebrew
/bin/bash -```