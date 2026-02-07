#!/bin/bash
#
# Cross-Platform Dependency Installation Script for APK Reverse Engineering Tool
# Supports: Linux (Debian/Ubuntu/Fedora/RHEL), macOS, Windows (WSL)
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

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Detect Operating System
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/debian_version ]]; then
            echo "debian"
        elif [[ -f /etc/redhat-release ]]; then
            echo "redhat"
        elif [[ -f /etc/fedora-release ]]; then
            echo "fedora"
        elif [[ -f /etc/arch-release ]]; then
            echo "arch"
        else
            echo "linux-generic"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Check if running as root or with sudo
check_privileges() {
    if [[ "$EUID" -ne 0 ]]; then
        if command -v sudo &> /dev/null; then
            log "INFO" "This script requires root privileges. Using sudo..."
            SUDO="sudo"
        else
            error "This script must be run as root or with sudo privileges."
            exit 1
        fi
    else
        SUDO=""
    fi
}

# Install dependencies based on OS
install_dependencies() {
    local os=$(detect_os)
    
    log "INFO" "Detected OS: $os"
    log "INFO" "Installing dependencies for APK Reverse Engineering Tool..."
    
    case "$os" in
        debian)
            install_debian
            ;;
        redhat|fedora)
            install_redhat
            ;;
        arch)
            install_arch
            ;;
        macos)
            install_macos
            ;;
        windows)
            install_windows_wsl
            ;;
        *)
            error "Unsupported operating system: $os"
            log "INFO" "Manual installation required. Please refer to the documentation."
            exit 1
            ;;
    esac
}

# Debian/Ubuntu installation
install_debian() {
    log "INFO" "Updating package manager (apt-get)..."
    $SUDO apt-get update -y
    
    log "INFO" "Installing basic dependencies..."
    $SUDO apt-get install -y \
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
    
    install_common_tools
}

# RedHat/Fedora installation
install_redhat() {
    log "INFO" "Updating package manager (dnf)..."
    $SUDO dnf upgrade -y
    
    log "INFO" "Installing basic dependencies..."
    $SUDO dnf install -y \
        wget \
        curl \
        unzip \
        zip \
        python3 \
        python3-pip \
        java-11-openjdk-devel \
        gcc \
        gcc-c++ \
        make \
        git \
        jq \
        tree \
        file \
        util-linux \
        which \
        findutils
    
    install_common_tools
}

# Arch Linux installation
install_arch() {
    log "INFO" "Updating package manager (pacman)..."
    $SUDO pacman -Syu --noconfirm
    
    log "INFO" "Installing basic dependencies..."
    $SUDO pacman -S --noconfirm \
        wget \
        curl \
        unzip \
        zip \
        python \
        python-pip \
        jdk11-openjdk \
        gcc \
        make \
        git \
        jq \
        tree \
        file \
        lsof
    
    install_common_tools
}

# macOS installation
install_macos() {
    log "INFO" "Checking for Homebrew..."
    if ! command -v brew &> /dev/null; then
        log "INFO" "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    log "INFO" "Installing basic dependencies via Homebrew..."
    brew install \
        wget \
        curl \
        unzip \
        python3 \
        openjdk@11 \
        git \
        jq \
        tree \
        file
    
    install_common_tools
}

# Windows WSL installation
install_windows_wsl() {
    warn "Detected Windows environment. Please ensure you're running in WSL (Windows Subsystem for Linux)."
    
    log "INFO" "Checking WSL distribution..."
    if [[ -f /etc/debian_version ]]; then
        install_debian
    elif [[ -f /etc/redhat-release || -f /etc/fedora-release ]]; then
        install_redhat
    else
        error "Unsupported WSL distribution. Please use Ubuntu or Fedora WSL."
        exit 1
    fi
}

# Common tools installation (OS-independent)
install_common_tools() {
    # Install Python dependencies
    log "INFO" "Installing Python dependencies..."
    $SUDO pip3 install --upgrade pip
    $SUDO pip3 install \
        requests \
        beautifulsoup4 \
        lxml \
        androguard \
        apkutils \
        pyaxmlparser
    
    # Install Android SDK components
    install_android_sdk
    
    # Install apktool
    install_apktool
    
    # Install jadx
    install_jadx
    
    # Install Frida tools
    install_frida
    
    # Install additional tools
    install_additional_tools
    
    # Create utility scripts
    create_utility_scripts
}

# Install Android SDK
install_android_sdk() {
    log "INFO" "Setting up Android SDK..."
    
    # Create Android directory
    $SUDO mkdir -p /opt/android-sdk
    cd /opt/android-sdk
    
    # Download command line tools
    log "INFO" "Downloading Android command line tools..."
    if [[ ! -d cmdline-tools/latest ]]; then
        wget -q https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip
        unzip -q commandlinetools-linux-9123335_latest.zip
        $SUDO mkdir -p cmdline-tools/latest
        $SUDO mv cmdline-tools/* cmdline-tools/latest/
        $SUDO rm -f commandlinetools-linux-9123335_latest.zip
    fi
    
    # Set environment variables
    export ANDROID_HOME=/opt/android-sdk
    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/33.0.1
    
    # Add to profile for persistence
    $SUDO bash -c 'echo "export ANDROID_HOME=/opt/android-sdk" >> /etc/profile'
    $SUDO bash -c 'echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/33.0.1" >> /etc/profile'
    
    # Install Android SDK components
    log "INFO" "Installing Android SDK components..."
    yes | cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME 'platform-tools' 'build-tools;33.0.1' 'platforms;android-33' 2>/dev/null || warn "Some Android SDK components may already be installed"
}

# Install apktool
install_apktool() {
    log "INFO" "Installing apktool..."
    
    if ! command -v apktool &> /dev/null; then
        cd /usr/local/bin
        $SUDO wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1.jar -O apktool.jar
        $SUDO wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1
        
        # Create wrapper script for apktool
        $SUDO bash -c 'cat > /usr/local/bin/apktool << '\''EOF'\''
#!/bin/bash
java -jar /usr/local/bin/apktool.jar "$@"
EOF'
        
        $SUDO chmod +x /usr/local/bin/apktool
        $SUDO chmod +x /usr/local/bin/apktool.jar
    else
        log "INFO" "apktool already installed"
    fi
}

# Install jadx
install_jadx() {
    log "INFO" "Installing jadx for Java decompilation..."
    
    if ! command -v jadx &> /dev/null; then
        cd /opt
        if [[ ! -d jadx-1.4.7 ]]; then
            wget -q https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip
            unzip -q jadx-1.4.7.zip
            rm -f jadx-1.4.7.zip
        fi
        
        # Create symbolic link
        $SUDO ln -sf /opt/jadx-1.4.7/bin/jadx /usr/local/bin/jadx
        $SUDO ln -sf /opt/jadx-1.4.7/bin/jadx-gui /usr/local/bin/jadx-gui
    else
        log "INFO" "jadx already installed"
    fi
}

# Install Frida tools
install_frida() {
    log "INFO" "Installing Frida..."
    pip3 install frida-tools || $SUDO pip3 install frida-tools
    
    # Download Frida gadget
    $SUDO mkdir -p /opt/frida-gadgets
    cd /opt/frida-gadgets
    
    # Get latest Frida release
    FRIDA_VERSION=$(curl -s https://api.github.com/repos/frida/frida/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
    
    if [[ -n "$FRIDA_VERSION" ]]; then
        log "INFO" "Downloading Frida gadgets (version: $FRIDA_VERSION)..."
        
        # Download gadgets for all architectures
        for arch in android-arm android-arm64 android-x86 android-x86_64; do
            if [[ ! -f "frida-gadget-$arch.so" ]]; then
                log "INFO" "Downloading Frida gadget for $arch..."
                wget -q "https://github.com/frida/frida/releases/download/$FRIDA_VERSION/frida-gadget-$FRIDA_VERSION-$arch.so.xz" || warn "Failed to download gadget for $arch"
            fi
        done
    else
        warn "Could not determine latest Frida version"
    fi
}

# Install additional tools
install_additional_tools() {
    log "INFO" "Installing additional analysis tools..."
    
    # Install aapt (if not already available)
    if ! command -v aapt &> /dev/null; then
        if [[ -f /etc/debian_version ]]; then
            $SUDO apt-get install -y aapt
        elif [[ -f /etc/redhat-release || -f /etc/fedora-release ]]; then
            $SUDO dnf install -y aapt
        fi
    fi
    
    # Install apksigner (symlink)
    if ! command -v apksigner &> /dev/null; then
        $SUDO ln -sf /opt/android-sdk/build-tools/33.0.1/apksigner /usr/local/bin/apksigner 2>/dev/null || true
    fi
    
    # Install zipalign (symlink)
    if ! command -v zipalign &> /dev/null; then
        $SUDO ln -sf /opt/android-sdk/build-tools/33.0.1/zipalign /usr/local/bin/zipalign 2>/dev/null || true
    fi
}

# Create utility scripts
create_utility_scripts() {
    log "INFO" "Creating utility scripts..."
    
    # Create utility scripts directory
    $SUDO mkdir -p /opt/apk-tools/utils
    
    # Create certificate analysis script
    $SUDO bash -c 'cat > /opt/apk-tools/utils/cert-analyzer.sh << '\''EOF'\''
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
EOF'
    $SUDO chmod +x /opt/apk-tools/utils/cert-analyzer.sh
    
    # Create permission analysis script
    $SUDO bash -c 'cat > /opt/apk-tools/utils/perm-analyzer.sh << '\''EOF'\''
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
if command -v aapt &> /dev/null; then
    PERMISSIONS=$(aapt dump permissions "$APK_FILE" 2>/dev/null | grep "uses-permission:" | cut -d= -f2 | tr -d "'" | sort)
    
    echo "Total permissions: $(echo "$PERMISSIONS" | wc -l)"
    echo ""
    
    echo "Dangerous permissions:"
    echo "$PERMISSIONS" | grep -E "(READ_CONTACTS|WRITE_CONTACTS|READ_CALENDAR|WRITE_CALENDAR|CAMERA|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|RECORD_AUDIO|READ_PHONE_STATE|CALL_PHONE|READ_SMS|SEND_SMS|RECEIVE_SMS|ACCESS_WIFI_STATE)" || echo "None"
    
    echo ""
    echo "All permissions:"
    echo "$PERMISSIONS"
else
    echo "Error: aapt not found. Cannot analyze permissions."
fi
EOF'
    $SUDO chmod +x /opt/apk-tools/utils/perm-analyzer.sh
    
    # Create device info script
    $SUDO bash -c 'cat > /opt/apk-tools/utils/device-info.sh << '\''EOF'\''
#!/bin/bash
# Device Information Utility

echo "Connected Android Devices:"
echo "=========================="

adb devices 2>/dev/null | grep -v "List of devices" | while read -r line; do
    if [[ -n "$line" ]]; then
        DEVICE_ID=$(echo "$line" | cut -f1)
        STATUS=$(echo "$line" | cut -f2)
        
        echo "Device ID: $DEVICE_ID"
        echo "Status: $STATUS"
        
        if [[ "$STATUS" == "device" ]]; then
            echo "Model: $(adb -s "$DEVICE_ID" shell getprop ro.product.model 2>/dev/null)"
            echo "Manufacturer: $(adb -s "$DEVICE_ID" shell getprop ro.product.manufacturer 2>/dev/null)"
            echo "Android Version: $(adb -s "$DEVICE_ID" shell getprop ro.build.version.release 2>/dev/null)"
            echo "API Level: $(adb -s "$DEVICE_ID" shell getprop ro.build.version.sdk 2>/dev/null)"
            echo "Architecture: $(adb -s "$DEVICE_ID" shell getprop ro.product.cpu.abi 2>/dev/null)"
        fi
        echo "----------------------------------"
    fi
done
EOF'
    $SUDO chmod +x /opt/apk-tools/utils/device-info.sh
    
    # Create full analysis script
    $SUDO bash -c 'cat > /opt/apk-tools/utils/full-analysis.sh << '\''EOF'\''
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
if command -v aapt &> /dev/null; then
    echo "1. Extracting basic information..."
    aapt dump badging "$APK_FILE" > "$OUTPUT_DIR/basic_info.txt" 2>/dev/null || echo "Failed to extract basic info"
fi

# Certificate analysis
echo "2. Analyzing certificate..."
/opt/apk-tools/utils/cert-analyzer.sh "$APK_FILE" > "$OUTPUT_DIR/certificate_analysis.txt" 2>/dev/null || echo "Certificate analysis failed"

# Permission analysis
echo "3. Analyzing permissions..."
/opt/apk-tools/utils/perm-analyzer.sh "$APK_FILE" > "$OUTPUT_DIR/permission_analysis.txt" 2>/dev/null || echo "Permission analysis failed"

# Decompile with jadx (if available)
if command -v jadx &> /dev/null; then
    echo "4. Decompiling with jadx..."
    jadx -d "$OUTPUT_DIR/decompiled" "$APK_FILE" 2>/dev/null || echo "Jadx decompilation failed"
fi

# File listing
echo "5. Creating file listing..."
unzip -l "$APK_FILE" > "$OUTPUT_DIR/file_listing.txt" 2>/dev/null || echo "Failed to create file listing"

# Extract APK contents
echo "6. Extracting APK contents..."
mkdir -p "$OUTPUT_DIR/extracted"
unzip -q "$APK_FILE" -d "$OUTPUT_DIR/extracted" 2>/dev/null || echo "Failed to extract APK"

echo "Analysis completed! Results saved in: $OUTPUT_DIR"
echo ""
echo "Generated files:"
ls -la "$OUTPUT_DIR"
EOF'
    $SUDO chmod +x /opt/apk-tools/utils/full-analysis.sh
    
    # Create aliases for easy access
    local bashrc="/etc/bash.bashrc"
    if [[ ! -f "$bashrc" ]]; then
        bashrc="/etc/profile"
    fi
    
    # Check if aliases already exist
    if ! grep -q "apk-analyze" "$bashrc" 2>/dev/null; then
        $SUDO bash -c "echo 'alias apk-analyze=&quot;/opt/apk-tools/utils/cert-analyzer.sh&quot;' >> $bashrc"
        $SUDO bash -c "echo 'alias perm-analyze=&quot;/opt/apk-tools/utils/perm-analyzer.sh&quot;' >> $bashrc"
        $SUDO bash -c "echo 'alias device-info=&quot;/opt/apk-tools/utils/device-info.sh&quot;' >> $bashrc"
        $SUDO bash -c "echo 'alias full-analysis=&quot;/opt/apk-tools/utils/full-analysis.sh&quot;' >> $bashrc"
    fi
}

# Print installation summary
print_summary() {
    echo ""
    echo "=========================================="
    log "SUCCESS" "Dependency installation completed!"
    echo "=========================================="
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
    echo ""
    warn "Please restart your terminal or run 'source /etc/bash.bashrc' to use the new aliases"
    echo ""
    log "INFO" "All dependencies installed successfully!"
    echo "=========================================="
}

# Main execution
main() {
    check_privileges
    install_dependencies
    print_summary
}

# Run main function
main "$@"