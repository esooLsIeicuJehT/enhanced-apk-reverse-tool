#!/bin/bash
#
# Frida Without Root - Complete Demo Script
# Demonstrates how to use Frida on non-rooted Android devices
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Frida Without Root - Complete Demo & Tutorial        ║"
    echo "║         Dynamic Analysis on Any Android Device              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if main tool exists
    if [[ ! -f "../apk-reverse-tool.sh" ]]; then
        echo -e "${RED}✗ Main tool not found!${NC}"
        echo "Please ensure apk-reverse-tool.sh is in the parent directory."
        exit 1
    fi
    
    # Check if Frida tools are installed
    if ! command -v frida &> /dev/null; then
        echo -e "${YELLOW}⚠ Frida tools not found${NC}"
        echo "Installing Frida tools..."
        pip3 install frida-tools
        print_success "Frida tools installed"
    else
        print_success "Frida tools found: $(frida --version)"
    fi
    
    # Check ADB
    if ! command -v adb &> /dev/null; then
        echo -e "${YELLOW}⚠ ADB not found${NC}"
        echo "Please install Android SDK platform-tools"
        exit 1
    else
        print_success "ADB found"
    fi
    
    # Check device connection
    local devices=$(adb devices | grep -c "device$")
    if [[ $devices -eq 0 ]]; then
        echo -e "${RED}✗ No Android device connected${NC}"
        echo "Please connect an Android device and enable USB debugging"
        exit 1
    else
        print_success "$devices Android device(s) connected"
    fi
}

# Show device information
show_device_info() {
    print_step "Device Information"
    
    echo "Connected devices:"
    adb devices
    
    echo -e "\nDevice details:"
    local device_id=$(adb devices | grep "device$" | head -1 | cut -f1)
    
    echo "Device ID: $device_id"
    echo "Model: $(adb -s "$device_id" shell getprop ro.product.model)"
    echo "Manufacturer: $(adb -s "$device_id" shell getprop ro.product.manufacturer)"
    echo "Android Version: $(adb -s "$device_id" shell getprop ro.build.version.release)"
    echo "API Level: $(adb -s "$device_id" shell getprop ro.build.version.sdk)"
    echo "Architecture: $(adb -s "$device_id" shell getprop ro.product.cpu.abi)"
}

# Demonstrate architecture detection
demo_architecture_detection() {
    print_step "Architecture Detection"
    
    local device_id=$(adb devices | grep "device$" | head -1 | cut -f1)
    local arch=$(adb -s "$device_id" shell getprop ro.product.cpu.abi)
    
    echo "Detected architecture: $arch"
    
    case "$arch" in
        "armeabi-v7a")
            print_info "Use: --arch arm"
            ;;
        "arm64-v8a")
            print_info "Use: --arch arm64"
            ;;
        "x86")
            print_info "Use: --arch x86"
            ;;
        "x86_64")
            print_info "Use: --arch x86_64"
            ;;
        *)
            echo -e "${YELLOW}⚠ Unknown architecture: $arch${NC}"
            ;;
    esac
}

# Create sample Frida scripts
create_sample_scripts() {
    print_step "Creating Sample Frida Scripts"
    
    # SSL Bypass Script
    cat > ssl-bypass.js << 'EOF'
// SSL Certificate Bypass Script
Java.perform(function() {
    console.log("[+] SSL Bypass Script Loaded");
    
    // Hook SSL certificate validation
    var X509TrustManager = Java.use("javax.net.ssl.X509TrustManager");
    X509TrustManager.checkServerTrusted.implementation = function(chain, authType) {
        console.log("[+] SSL certificate validation bypassed");
        return;
    };
    
    // Hook hostname verification
    var HostnameVerifier = Java.use("javax.net.ssl.HostnameVerifier");
    HostnameVerifier.verify.implementation = function(hostname, session) {
        console.log("[+] Hostname verification bypassed for: " + hostname);
        return true;
    };
    
    console.log("[+] SSL bypass hooks installed");
});
EOF
    
    # Network Monitor Script
    cat > network-monitor.js << 'EOF'
// Network Traffic Monitor
Java.perform(function() {
    console.log("[+] Network Monitor Started");
    
    // Hook URL connections
    var URL = Java.use("java.net.URL");
    URL.$init.overload('java.lang.String').implementation = function(url) {
        console.log("[NETWORK] URL requested: " + url);
        return this.$init(url);
    };
    
    // Hook HTTP requests
    var HttpURLConnection = Java.use("java.net.HttpURLConnection");
    HttpURLConnection.getResponseCode.implementation = function() {
        var code = this.getResponseCode();
        var url = this.getURL();
        console.log("[NETWORK] " + url + " -> Response Code: " + code);
        return code;
    };
    
    console.log("[+] Network monitoring hooks installed");
});
EOF
    
    # API Hook Script
    cat > api-hooks.js << 'EOF'
// API Function Hooking
Java.perform(function() {
    console.log("[+] API Hooking Script Loaded");
    
    // Hook cryptographic operations
    var MessageDigest = Java.use("java.security.MessageDigest");
    MessageDigest.digest.overload('[B').implementation = function(input) {
        console.log("[CRYPTO] MessageDigest.digest() called");
        if (input.length < 64) {
            console.log("[CRYPTO] Input: " + Array.from(input).map(b => b.toString(16).padStart(2, '0')).join(''));
        }
        return this.digest(input);
    };
    
    // Hook string operations for key detection
    var String = Java.use("java.lang.String");
    String.$init.overload('[B').implementation = function(bytes) {
        var result = this.$init(bytes);
        var text = this.toString();
        
        if (text.includes("key") || text.includes("secret") || text.includes("token")) {
            console.log("[STRING] Potential key/secret: " + text.substring(0, 100));
        }
        
        return result;
    };
    
    console.log("[+] API hooks installed");
});
EOF
    
    # Runtime Analysis Script
    cat > runtime-analysis.js << 'EOF'
// Runtime Application Analysis
Java.perform(function() {
    console.log("[+] Runtime Analysis Script Loaded");
    
    // Hook application lifecycle
    var Application = Java.use("android.app.Application");
    Application.onCreate.implementation = function() {
        console.log("[LIFECYCLE] Application onCreate() called");
        this.onCreate();
        
        // Start analysis after app initialization
        setTimeout(function() {
            performApplicationAnalysis();
        }, 2000);
    };
    
    function performApplicationAnalysis() {
        console.log("[+] Starting application analysis...");
        
        // Enumerate loaded classes
        Java.enumerateLoadedClasses({
            onMatch: function(className) {
                if (className.includes("crypto") || 
                    className.includes("ssl") || 
                    className.includes("security") ||
                    className.includes("network")) {
                    console.log("[CLASS] Security/Network class: " + className);
                }
            },
            onComplete: function() {
                console.log("[+] Class enumeration completed");
            }
        });
    }
    
    console.log("[+] Runtime analysis hooks installed");
});
EOF
    
    print_success "Sample Frida scripts created:"
    ls -la *.js
}

# Create custom Frida configuration
create_custom_config() {
    print_step "Creating Custom Frida Configuration"
    
    # Interactive configuration
    cat > interactive-config.json << 'EOF'
{
  "interaction": {
    "type": "listen",
    "address": "127.0.0.1",
    "port": 27042,
    "on_load": "wait"
  }
}
EOF
    
    # Autonomous configuration
    cat > autonomous-config.json << 'EOF'
{
  "interaction": {
    "type": "script",
    "path": "/data/local/tmp/runtime-analysis.js",
    "on_change": "reload"
  }
}
EOF
    
    # Network capture configuration
    cat > network-config.json << 'EOF'
{
  "interaction": {
    "type": "script",
    "path": "/data/local/tmp/network-monitor.js",
    "on_change": "reload"
  },
  "code_signing": {
    "certificate": "none"
  },
  "telemetry": {
    "enabled": false
  }
}
EOF
    
    print_success "Custom configurations created:"
    ls -la *config.json
}

# Demo the complete Frida workflow
demo_frida_workflow() {
    print_step "Complete Frida Workflow Demonstration"
    
    print_info "This demo shows the complete process of using Frida without root"
    print_info "You'll need to provide an APK file to analyze"
    
    echo -e "\n${BLUE}Step 1: Pull APK from device (or provide existing APK)${NC}"
    echo -n "Enter package name (or path to APK file): "
    read -r target
    
    if [[ -f "$target" ]]; then
        local apk_file="$target"
        print_success "Using APK file: $apk_file"
    else
        print_info "Pulling APK from device: $target"
        ../apk-reverse-tool.sh pull "$target"
        local apk_file="${target##*/}.apk"
        
        if [[ ! -f "$apk_file" ]]; then
            echo -e "${RED}✗ Failed to pull APK${NC}"
            exit 1
        fi
        print_success "APK pulled: $apk_file"
    fi
    
    # Step 2: Detect architecture
    echo -e "\n${BLUE}Step 2: Detect device architecture${NC}"
    local device_id=$(adb devices | grep "device$" | head -1 | cut -f1)
    local arch=$(adb -s "$device_id" shell getprop ro.product.cpu.abi)
    
    case "$arch" in
        "armeabi-v7a") arch="arm" ;;
        "arm64-v8a") arch="arm64" ;;
        "x86") arch="x86" ;;
        "x86_64") arch="x86_64" ;;
        *) 
            echo -e "${YELLOW}⚠ Unknown architecture, using arm${NC}"
            arch="arm"
            ;;
    esac
    
    print_success "Device architecture: $arch"
    
    # Step 3: Patch APK with Frida
    echo -e "\n${BLUE}Step 3: Patch APK with Frida gadget${NC}"
    print_info "Patching $apk_file for $arch architecture..."
    
    ../apk-reverse-tool.sh patch "$apk_file" --arch "$arch" --gadget-conf interactive-config.json
    
    local patched_file="${apk_file%.apk}.gadget.apk"
    if [[ ! -f "$patched_file" ]]; then
        echo -e "${RED}✗ Failed to patch APK${NC}"
        exit 1
    fi
    
    print_success "APK patched: $patched_file"
    
    # Step 4: Install patched APK
    echo -e "\n${BLUE}Step 4: Install patched APK${NC}"
    print_info "Installing $patched_file on device..."
    
    adb install "$patched_file"
    print_success "APK installed successfully"
    
    # Step 5: Start Frida analysis
    echo -e "\n${BLUE}Step 5: Start Frida Analysis${NC}"
    print_info "Choose analysis type:"
    echo "1. SSL Bypass"
    echo "2. Network Monitoring"
    echo "3. API Hooking"
    echo "4. Runtime Analysis"
    echo -n "Select (1-4): "
    read -r choice
    
    local script_file=""
    case "$choice" in
        1) script_file="ssl-bypass.js" ;;
        2) script_file="network-monitor.js" ;;
        3) script_file="api-hooks.js" ;;
        4) script_file="runtime-analysis.js" ;;
        *) 
            echo -e "${YELLOW}⚠ Invalid choice, using SSL bypass${NC}"
            script_file="ssl-bypass.js"
            ;;
    esac
    
    print_success "Starting Frida with $script_file"
    
    # Extract package name from APK
    local package_name=$(aapt dump badging "$apk_file" | grep "package: name=" | cut -d"'" -f2)
    
    echo -e "\n${GREEN}Frida is ready! Use the following commands:${NC}"
    echo -e "${BLUE}# Start the app and attach Frida:${NC}"
    echo "frida -U $package_name -l $script_file"
    echo -e "\n${BLUE}# Or spawn fresh instance:${NC}"
    echo "frida -U -f $package_name -l $script_file"
    echo -e "\n${BLUE}# Push autonomous script to device:${NC}"
    echo "adb push $script_file /data/local/tmp/"
    echo "adb shell am start -n $package_name/.MainActivity"
    
    print_success "Frida setup completed!"
}

# Show troubleshooting tips
show_troubleshooting() {
    print_step "Troubleshooting & Tips"
    
    echo -e "${YELLOW}Common Issues and Solutions:${NC}"
    echo ""
    echo "1. App crashes after patching:"
    echo "   - Try different architecture (arm vs arm64)"
    echo "   - Use --no-src --no-res flags"
    echo "   - Check if app uses native libraries"
    echo ""
    echo "2. Frida connection fails:"
    echo "   - Ensure app is running"
    echo "   - Check device connection: adb devices"
    echo "   - Try different connection methods"
    echo ""
    echo "3. Gadget not loading:"
    echo "   - Check device logs: adb logcat | grep frida"
    echo "   - Verify architecture match"
    echo "   - Try debug mode: --debug-mode"
    echo ""
    echo "4. SSL bypass not working:"
    echo "   - App may use certificate pinning"
    echo "   - Try hooking different SSL classes"
    echo "   - Check for custom security implementations"
    
    echo -e "\n${GREEN}Pro Tips:${NC}"
    echo "• Use --verbose for detailed logging"
    echo "• Create backup before patching: --backup"
    echo "• Use custom configs for advanced scenarios"
    echo "• Check logs in ~/.apk-reverse-tool/logs/"
}

# Main demo function
main() {
    print_banner
    
    echo -e "${GREEN}Welcome to the Frida Without Root Demo!${NC}"
    echo "This demonstration shows how to use Frida on any Android device"
    echo "without requiring root access or system modifications."
    echo ""
    
    # Check if user wants interactive demo
    echo -n "Run interactive demo? (y/n): "
    read -r interactive
    
    if [[ "$interactive" == "y" || "$interactive" == "Y" ]]; then
        check_prerequisites
        show_device_info
        demo_architecture_detection
        create_sample_scripts
        create_custom_config
        demo_frida_workflow
        show_troubleshooting
    else
        print_info "Skipping interactive setup"
        print_info "Check the created scripts and configurations:"
        ls -la *.js *.json
    fi
    
    echo -e "\n${GREEN}Demo completed!${NC}"
    echo "You now have everything needed for Frida without root:"
    echo "• Sample scripts for common analysis scenarios"
    echo "• Custom configurations for different use cases"
    echo "• Complete workflow demonstration"
    echo ""
    echo "For more information, check:"
    echo "• docs/FRIDA-NO-ROOT-GUIDE.md"
    echo "• ../apk-reverse-tool.sh --help"
    echo "• examples/sample-analysis.sh"
}

# Run demo
main "$@"