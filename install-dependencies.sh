#!/bin/bash
#
# Dependency Installation Script for APK Reverse Engineering Tool
# This script installs all required dependencies for the enhanced tool
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level=$1
    shift
    echo -e "${GREEN}[$level]${NC} $*"
}

log "INFO" "Installing dependencies for APK Reverse Engineering Tool..."

# Update package manager
log "INFO" "Updating package manager..."
apt-get update -y

# Install basic dependencies
log "INFO" "Installing basic dependencies..."
apt-get install -y \
    wget \
    curl \
    unzip \
    zip \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    build-essential \
    git \
    jq \
    tree \
    file \
    hexdump \
    strings \
    lsof

# Install Python dependencies
log "INFO" "Installing Python dependencies..."
pip3 install \
    requests \
    beautifulsoup4 \
    lxml \
    androguard \
    apkutils \
    pyaxmlparser

# Install Android SDK components
log "INFO" "Setting up Android SDK..."

# Create Android directory
mkdir -p /opt/android-sdk
cd /opt/android-sdk

# Download command line tools
log "INFO" "Downloading Android command line tools..."
wget -q https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip

# Extract command line tools
unzip -q commandlinetools-linux-9123335_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/
rm -f commandlinetools-linux-9123335_latest.zip

# Set environment variables
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/33.0.1

# Add to /etc/profile for persistence
echo 'export ANDROID_HOME=/opt/android-sdk' >> /etc/profile
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/33.0.1' >> /etc/profile

# Install Android SDK components
log "INFO" "Installing Android SDK components..."
yes | cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME 'platform-tools' 'build-tools;33.0.1' 'platforms;android-33'

# Install apktool
log "INFO" "Installing apktool..."
cd /usr/local/bin
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1.jar -O apktool.jar
wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1

# Create wrapper script for apktool
cat > /usr/local/bin/apktool << 'EOF'
#!/bin/bash
java -jar /usr/local/bin/apktool.jar "$@"
EOF

chmod +x /usr/local/bin/apktool
chmod +x /usr/local/bin/apktool.jar

# Install jadx for decompilation
log "INFO" "Installing jadx for Java decompilation..."
cd /opt
wget -q https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip
unzip -q jadx-1.4.7.zip
rm -f jadx-1.4.7.zip

# Create symbolic link
ln -sf /opt/jadx-1.4.7/bin/jadx /usr/local/bin/jadx
ln -sf /opt/jadx-1.4.7/bin/jadx-gui /usr/local/bin/jadx-gui

# Install Frida tools
log "INFO" "Installing Frida..."
pip3 install frida-tools

# Download Frida gadget
mkdir -p /opt/frida-gadgets
cd /opt/frida-gadgets

# Get latest Frida release
FRIDA_VERSION=$(curl -s https://api.github.com/repos/frida/frida/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)

# Download gadgets for all architectures
for arch in android-arm android-arm64 android-x86 android-x86_64; do
    log "INFO" "Downloading Frida gadget for $arch..."
    wget -q "https://github.com/frida/frida/releases/download/$FRIDA_VERSION/frida-gadget-$FRIDA_VERSION-$arch.so.xz"
done

# Install additional analysis tools
log "INFO" "Installing additional analysis tools..."

# Install aapt (if not already available)
if ! command -v aapt &> /dev/null; then
    apt-get install -y aapt
fi

# Install keytool for certificate analysis
if ! command -v keytool &> /dev/null; then
    apt-get install -y openjdk-11-jdk-headless
fi

# Install apksigner
if ! command -v apksigner &> /dev/null; then
    ln -sf /opt/android-sdk/build-tools/33.0.1/apksigner /usr/local/bin/apksigner
fi

# Install zipalign
if ! command -v zipalign &> /dev/null; then
    ln -sf /opt/android-sdk/build-tools/33.0.1/zipalign /usr/local/bin/zipalign
fi

# Create utility scripts directory
mkdir -p /opt/apk-tools/utils

# Create certificate analysis script
cat > /opt/apk-tools/utils/cert-analyzer.sh << 'EOF'
#!/bin/bash
# Certificate Analysis Utility

APK_FILE="$1"

if [[ -z "$APK_FILE" ]]; then
    echo "Usage: $0 <apk_file>"
    exit 1
fi

if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "Analyzing certificate for: $APK_FILE"
echo "=================================="

# Extract APK
TEMP_DIR=$(mktemp -d)
unzip -q "$APK_FILE" -d "$TEMP_DIR"

if [[ -f "$TEMP_DIR/META-INF/CERT.RSA" ]]; then
    echo "Certificate Information:"
    keytool -printcert -file "$TEMP_DIR/META-INF/CERT.RSA"
else
    echo "No certificate found in APK"
fi

# Clean up
rm -rf "$TEMP_DIR"
EOF

chmod +x /opt/apk-tools/utils/cert-analyzer.sh

# Create permission analysis script
cat > /opt/apk-tools/utils/perm-analyzer.sh << 'EOF'
#!/bin/bash
# Permission Analysis Utility

APK_FILE="$1"

if [[ -z "$APK_FILE" ]]; then
    echo "Usage: $0 <apk_file>"
    exit 1
fi

if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "Analyzing permissions for: $APK_FILE"
echo "=================================="

# Extract permissions
PERMISSIONS=$(aapt dump permissions "$APK_FILE" | grep "uses-permission:" | cut -d= -f2 | tr -d "'" | sort)

echo "Total permissions: $(echo "$PERMISSIONS" | wc -l)"
echo ""

echo "Dangerous permissions:"
echo "$PERMISSIONS" | grep -E "(READ_CONTACTS|WRITE_CONTACTS|READ_CALENDAR|WRITE_CALENDAR|CAMERA|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|RECORD_AUDIO|READ_PHONE_STATE|CALL_PHONE|READ_SMS|SEND_SMS|RECEIVE_SMS|ACCESS_WIFI_STATE)" || echo "None"

echo ""
echo "All permissions:"
echo "$PERMISSIONS"
EOF

chmod +x /opt/apk-tools/utils/perm-analyzer.sh

# Create device info script
cat > /opt/apk-tools/utils/device-info.sh << 'EOF'
#!/bin/bash
# Device Information Utility

echo "Connected Android Devices:"
echo "=========================="

adb devices | grep -v "List of devices" | while read -r line; do
    if [[ -n "$line" ]]; then
        DEVICE_ID=$(echo "$line" | cut -f1)
        STATUS=$(echo "$line" | cut -f2)
        
        echo "Device ID: $DEVICE_ID"
        echo "Status: $STATUS"
        
        if [[ "$STATUS" == "device" ]]; then
            echo "Model: $(adb -s "$DEVICE_ID" shell getprop ro.product.model)"
            echo "Manufacturer: $(adb -s "$DEVICE_ID" shell getprop ro.product.manufacturer)"
            echo "Android Version: $(adb -s "$DEVICE_ID" shell getprop ro.build.version.release)"
            echo "API Level: $(adb -s "$DEVICE_ID" shell getprop ro.build.version.sdk)"
            echo "Architecture: $(adb -s "$DEVICE_ID" shell getprop ro.product.cpu.abi)"
        fi
        echo "----------------------------------"
    fi
done
EOF

chmod +x /opt/apk-tools/utils/device-info.sh

# Create aliases for easy access
echo 'alias apk-analyze="/opt/apk-tools/utils/cert-analyzer.sh"' >> /etc/bash.bashrc
echo 'alias perm-analyze="/opt/apk-tools/utils/perm-analyzer.sh"' >> /etc/bash.bashrc
echo 'alias device-info="/opt/apk-tools/utils/device-info.sh"' >> /etc/bash.bashrc

# Create comprehensive analysis script
cat > /opt/apk-tools/utils/full-analysis.sh << 'EOF'
#!/bin/bash
# Comprehensive APK Analysis Script

APK_FILE="$1"
OUTPUT_DIR="${2:-$(basename "$APK_FILE" .apk)_analysis}"

if [[ -z "$APK_FILE" ]]; then
    echo "Usage: $0 <apk_file> [output_directory]"
    exit 1
fi

if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "Starting comprehensive analysis of: $APK_FILE"
echo "Output directory: $OUTPUT_DIR"
echo "=================================="

mkdir -p "$OUTPUT_DIR"

# Basic info
echo "1. Extracting basic information..."
aapt dump badging "$APK_FILE" > "$OUTPUT_DIR/basic_info.txt"

# Certificate analysis
echo "2. Analyzing certificate..."
/opt/apk-tools/utils/cert-analyzer.sh "$APK_FILE" > "$OUTPUT_DIR/certificate_analysis.txt"

# Permission analysis
echo "3. Analyzing permissions..."
/opt/apk-tools/utils/perm-analyzer.sh "$APK_FILE" > "$OUTPUT_DIR/permission_analysis.txt"

# Decompile with jadx (if available)
if command -v jadx &> /dev/null; then
    echo "4. Decompiling with jadx..."
    jadx -d "$OUTPUT_DIR/decompiled" "$APK_FILE" 2>/dev/null || echo "Jadx decompilation failed"
fi

# Analyze with androguard (if available)
if command -v androguard &> /dev/null; then
    echo "5. Analyzing with androguard..."
    androguard analyze "$APK_FILE" > "$OUTPUT_DIR/androguard_analysis.txt" 2>/dev/null || echo "Androguard analysis failed"
fi

# File listing
echo "6. Creating file listing..."
unzip -l "$APK_FILE" > "$OUTPUT_DIR/file_listing.txt"

# Extract APK contents
echo "7. Extracting APK contents..."
mkdir -p "$OUTPUT_DIR/extracted"
unzip -q "$APK_FILE" -d "$OUTPUT_DIR/extracted"

echo "Analysis completed! Results saved in: $OUTPUT_DIR"
echo ""
echo "Generated files:"
ls -la "$OUTPUT_DIR"
EOF

chmod +x /opt/apk-tools/utils/full-analysis.sh

echo 'alias full-analysis="/opt/apk-tools/utils/full-analysis.sh"' >> /etc/bash.bashrc

# Source the new aliases
source /etc/bash.bashrc

# Final verification
log "SUCCESS" "Dependency installation completed!"

echo ""
echo "Installed Tools Summary:"
echo "======================="
echo "- Java Development Kit (OpenJDK 11)"
echo "- Android SDK (Platform Tools, Build Tools 33.0.1)"
echo "- apktool v2.8.1"
echo "- jadx v1.4.7 (Java decompiler)"
echo "- Frida tools and gadgets"
echo "- Androguard (Python APK analysis)"
echo "- jq (JSON processor)"
echo "- Additional utility scripts"

echo ""
echo "New Commands Available:"
echo "======================="
echo "apk-analyze <apk_file>           - Analyze APK certificate"
echo "perm-analyze <apk_file>          - Analyze APK permissions"
echo "device-info                      - Show connected device information"
echo "full-analysis <apk_file> [dir]   - Comprehensive APK analysis"
echo ""

echo "Environment variables set:"
echo "- ANDROID_HOME=/opt/android-sdk"
echo "- PATH updated to include Android tools"

log "INFO" "All dependencies installed successfully!"