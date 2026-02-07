#!/bin/bash
#
# Sample Analysis Scripts for Enhanced APK Reverse Engineering Tool
# This file demonstrates various usage patterns and workflows
#

set -e

# Source the main tool
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_TOOL="$SCRIPT_DIR/../apk-reverse-tool.sh"

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

# Example 1: Basic APK Analysis
example_basic_analysis() {
    log "INFO" "=== Example 1: Basic APK Analysis ==="
    
    local apk_file="$1"
    
    if [[ -z "$apk_file" ]]; then
        log "WARN" "Usage: $0 basic <apk_file>"
        return 1
    fi
    
    if [[ ! -f "$apk_file" ]]; then
        log "ERROR" "APK file not found: $apk_file"
        return 1
    fi
    
    log "INFO" "Analyzing APK: $apk_file"
    
    # Basic analysis
    "$MAIN_TOOL" analyze "$apk_file"
    
    log "SUCCESS" "Basic analysis completed"
}

# Example 2: Security Audit Workflow
example_security_audit() {
    log "INFO" "=== Example 2: Security Audit Workflow ==="
    
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        log "WARN" "Usage: $0 security <package_name>"
        return 1
    fi
    
    log "INFO" "Starting security audit for: $package_name"
    
    # Step 1: Pull APK with device compatibility check
    log "INFO" "Step 1: Pulling APK from device..."
    "$MAIN_TOOL" pull "$package_name" --device-compat --backup
    
    local apk_file="${package_name##*/}.apk"
    
    if [[ ! -f "$apk_file" ]]; then
        log "ERROR" "Failed to pull APK"
        return 1
    fi
    
    # Step 2: Comprehensive security analysis
    log "INFO" "Step 2: Performing security analysis..."
    "$MAIN_TOOL" analyze "$apk_file" --deep-analysis --format json
    
    # Step 3: Check for common vulnerabilities
    log "INFO" "Step 3: Scanning for vulnerabilities..."
    "$MAIN_TOOL" analyze "$apk_file" --vulnerability-scan
    
    # Step 4: Generate security report
    local report_dir="${apk_file%.apk}_security_audit"
    "$MAIN_TOOL" analyze "$apk_file" --output "$report_dir" --format json
    
    log "SUCCESS" "Security audit completed. Reports saved in $report_dir"
}

# Example 3: Frida Dynamic Analysis Setup
example_frida_setup() {
    log "INFO" "=== Example 3: Frida Dynamic Analysis Setup ==="
    
    local apk_file="$1"
    local arch="$2"
    
    if [[ -z "$apk_file" || -z "$arch" ]]; then
        log "WARN" "Usage: $0 frida <apk_file> <arch>"
        return 1
    fi
    
    log "INFO" "Setting up Frida dynamic analysis for: $apk_file ($arch)"
    
    # Create Frida configuration
    cat > frida-config.json << 'EOF'
{
  "interaction": {
    "type": "listen",
    "address": "0.0.0.0",
    "port": 27042,
    "on_load": "wait"
  }
}
EOF
    
    # Patch APK with Frida gadget
    "$MAIN_TOOL" patch "$apk_file" --arch "$arch" --gadget-conf frida-config.json
    
    # Install patched APK
    local patched_file="${apk_file%.apk}.gadget.apk"
    
    if [[ -f "$patched_file" ]]; then
        log "INFO" "Installing patched APK..."
        adb install "$patched_file"
        
        log "INFO" "Starting Frida server connection..."
        log "INFO" "Run: frida -U -f ${package_name} -l script.js"
        
        # Create sample Frida script
        cat > sample-frida-script.js << 'EOF'
// Sample Frida script for basic hooking
Java.perform(function() {
    console.log("[*] Frida script loaded");
    
    // Hook SSL certificate validation
    var X509TrustManager = Java.use("javax.net.ssl.X509TrustManager");
    X509TrustManager.checkServerTrusted.implementation = function(chain, authType) {
        console.log("[+] SSL certificate validation bypassed");
        return;
    };
    
    // Hook common cryptographic functions
    var MessageDigest = Java.use("java.security.MessageDigest");
    MessageDigest.digest.overload('[B').implementation = function(input) {
        console.log("[+] MessageDigest.digest() called with: " + Array.from(input));
        return this.digest(input);
    };
    
    console.log("[*] Hooks installed successfully");
});
EOF
        
        log "SUCCESS" "Frida setup completed. Sample script created: sample-frida-script.js"
    else
        log "ERROR" "Failed to create patched APK"
        return 1
    fi
}

# Example 4: Batch Analysis of Multiple APKs
example_batch_analysis() {
    log "INFO" "=== Example 4: Batch Analysis ==="
    
    local apk_dir="$1"
    local output_dir="$2"
    
    if [[ -z "$apk_dir" ]]; then
        log "WARN" "Usage: $0 batch <apk_directory> [output_directory]"
        return 1
    fi
    
    if [[ -z "$output_dir" ]]; then
        output_dir="batch_analysis_results"
    fi
    
    if [[ ! -d "$apk_dir" ]]; then
        log "ERROR" "APK directory not found: $apk_dir"
        return 1
    fi
    
    log "INFO" "Starting batch analysis of APKs in: $apk_dir"
    
    mkdir -p "$output_dir"
    
    # Create summary report
    local summary_file="$output_dir/batch_summary.json"
    echo '{"analysis_results": []}' > "$summary_file"
    
    local processed=0
    local total=$(find "$apk_dir" -name "*.apk" | wc -l)
    
    while IFS= read -r -d '' apk_file; do
        ((processed++))
        
        log "INFO" "Processing $processed/$total: $(basename "$apk_file")"
        
        # Create individual analysis directory
        local apk_name=$(basename "$apk_file" .apk)
        local analysis_dir="$output_dir/$apk_name"
        
        # Analyze APK
        "$MAIN_TOOL" analyze "$apk_file" --output "$analysis_dir" --format json
        
        # Extract key findings for summary
        if [[ -f "$analysis_dir/analysis_report.json" ]]; then
            local package_name=$(jq -r '.basic_info.package_name // "unknown"' "$analysis_dir/analysis_report.json")
            local risk_level=$(jq -r '.security_analysis.risk_level // "unknown"' "$analysis_dir/analysis_report.json")
            local vuln_count=$(jq -r '.vulnerability_scan.vulnerabilities_found // 0' "$analysis_dir/analysis_report.json")
            
            # Update summary
            local temp_file=$(mktemp)
            jq --arg apk "$apk_name" \
               --arg pkg "$package_name" \
               --arg risk "$risk_level" \
               --arg vulns "$vuln_count" \
               '.analysis_results += [{
                   "apk_name": $apk,
                   "package_name": $pkg,
                   "risk_level": $risk,
                   "vulnerabilities_found": ($vulns | tonumber)
               }]' "$summary_file" > "$temp_file" && mv "$temp_file" "$summary_file"
        fi
    done < <(find "$apk_dir" -name "*.apk" -print0)
    
    log "SUCCESS" "Batch analysis completed. Results in $output_dir"
    log "INFO" "Summary report: $summary_file"
}

# Example 5: Custom Analysis Pipeline
example_custom_pipeline() {
    log "INFO" "=== Example 5: Custom Analysis Pipeline ==="
    
    local apk_file="$1"
    local pipeline_config="$2"
    
    if [[ -z "$apk_file" ]]; then
        log "WARN" "Usage: $0 pipeline <apk_file> [config_file]"
        return 1
    fi
    
    log "INFO" "Running custom analysis pipeline for: $apk_file"
    
    # Default pipeline configuration
    if [[ -z "$pipeline_config" ]]; then
        pipeline_config="default"
    fi
    
    case "$pipeline_config" in
        "quick")
            log "INFO" "Running quick analysis pipeline..."
            "$MAIN_TOOL" analyze "$apk_file" --cert-analysis --perm-analysis
            ;;
        "comprehensive")
            log "INFO" "Running comprehensive analysis pipeline..."
            "$MAIN_TOOL" analyze "$apk_file" --deep-analysis --vulnerability-scan --code-analysis
            ;;
        "security")
            log "INFO" "Running security-focused pipeline..."
            "$MAIN_TOOL" analyze "$apk_file" --cert-analysis --perm-analysis --vulnerability-scan
            # Additional security checks
            perform_additional_security_checks "$apk_file"
            ;;
        "malware")
            log "INFO" "Running malware analysis pipeline..."
            "$MAIN_TOOL" analyze "$apk_file" --deep-analysis --vulnerability-scan --code-analysis
            perform_malware_analysis "$apk_file"
            ;;
        *)
            log "ERROR" "Unknown pipeline: $pipeline_config"
            return 1
            ;;
    esac
    
    log "SUCCESS" "Pipeline analysis completed"
}

# Additional security checks
perform_additional_security_checks() {
    local apk_file="$1"
    
    log "INFO" "Performing additional security checks..."
    
    # Check for common malware indicators
    local temp_dir=$(mktemp -d)
    unzip -q "$apk_file" -d "$temp_dir"
    
    # Check for suspicious file names
    if find "$temp_dir" -name "*malware*" -o -name "*hack*" -o -name "*crack*" | grep -q .; then
        log "WARN" "Suspicious file names found"
    fi
    
    # Check for encrypted/obfuscated content
    local obfuscated_files=$(find "$temp_dir" -name "*.dex" -exec file {} \; | grep -c "data")
    if [[ $obfuscated_files -gt 0 ]]; then
        log "WARN" "Potential obfuscated content detected"
    fi
    
    rm -rf "$temp_dir"
}

# Malware analysis specific checks
perform_malware_analysis() {
    local apk_file="$1"
    
    log "INFO" "Performing malware-specific analysis..."
    
    # Check for suspicious permissions
    local suspicious_perms=$(aapt dump permissions "$apk_file" | grep -c "SYSTEM_ALERT_WINDOW\|DEVICE_ADMIN\|REBOOT")
    if [[ $suspicious_perms -gt 0 ]]; then
        log "WARN" "Suspicious permissions detected: $suspicious_perms"
    fi
    
    # Check for suspicious activities
    local temp_dir=$(mktemp -d)
    unzip -q "$apk_file" -d "$temp_dir"
    
    # Look for suspicious activity names in manifest
    if grep -r -i "malware\|hack\|crack\|backdoor" "$temp_dir" 2>/dev/null; then
        log "WARN" "Suspicious activity names found"
    fi
    
    rm -rf "$temp_dir"
}

# Example 6: Device Compatibility Testing
example_device_compatibility() {
    log "INFO" "=== Example 6: Device Compatibility Testing ==="
    
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        log "WARN" "Usage: $0 compat <package_name>"
        return 1
    fi
    
    log "INFO" "Testing device compatibility for: $package_name"
    
    # Check connected devices
    local devices=$(adb devices | grep -v "List of devices" | grep -v "^$" | cut -f1)
    
    if [[ -z "$devices" ]]; then
        log "ERROR" "No devices connected"
        return 1
    fi
    
    while IFS= read -r device_id; do
        if [[ -n "$device_id" ]]; then
            log "INFO" "Testing device: $device_id"
            
            # Get device info
            local android_version=$(adb -s "$device_id" shell getprop ro.build.version.release)
            local api_level=$(adb -s "$device_id" shell getprop ro.build.version.sdk)
            local arch=$(adb -s "$device_id" shell getprop ro.product.cpu.abi)
            
            log "INFO" "Device: $device_id"
            log "INFO" "Android: $android_version (API $api_level)"
            log "INFO" "Architecture: $arch"
            
            # Check compatibility
            if [[ "$api_level" -lt 21 ]]; then
                log "WARN" "Device may not be compatible (API < 21)"
            else
                log "INFO" "Device appears compatible"
            fi
            
            # Test package existence
            if adb -s "$device_id" shell pm path "$package_name" >/dev/null 2>&1; then
                log "INFO" "Package found on device"
                
                # Pull and analyze
                "$MAIN_TOOL" pull "$package_name" --device-compat
            else
                log "WARN" "Package not found on device"
            fi
            
            echo "---"
        fi
    done <<< "$devices"
}

# Example 7: Interactive Demo
example_interactive_demo() {
    log "INFO" "=== Example 7: Interactive Demo ==="
    
    echo -e "${BLUE}This demo will guide you through the tool's capabilities.${NC}"
    echo ""
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        echo -e "${YELLOW}No Android device connected. Connect a device to proceed with full demo.${NC}"
        echo ""
    fi
    
    echo "Available examples:"
    echo "1. Basic APK analysis"
    echo "2. Security audit workflow"
    echo "3. Frida dynamic analysis setup"
    echo "4. Batch analysis"
    echo "5. Custom analysis pipeline"
    echo "6. Device compatibility testing"
    echo ""
    
    echo -n "Select an example (1-6) or press Enter to skip: "
    read -r choice
    
    case "$choice" in
        "1")
            echo -n "Enter APK file path: "
            read -r apk_file
            example_basic_analysis "$apk_file"
            ;;
        "2")
            echo -n "Enter package name: "
            read -r package_name
            example_security_audit "$package_name"
            ;;
        "3")
            echo -n "Enter APK file path: "
            read -r apk_file
            echo -n "Enter architecture (arm/arm64/x86/x86_64): "
            read -r arch
            example_frida_setup "$apk_file" "$arch"
            ;;
        "4")
            echo -n "Enter APK directory path: "
            read -r apk_dir
            example_batch_analysis "$apk_dir"
            ;;
        "5")
            echo -n "Enter APK file path: "
            read -r apk_file
            echo "Available pipelines: quick, comprehensive, security, malware"
            echo -n "Enter pipeline type: "
            read -r pipeline
            example_custom_pipeline "$apk_file" "$pipeline"
            ;;
        "6")
            echo -n "Enter package name: "
            read -r package_name
            example_device_compatibility "$package_name"
            ;;
        *)
            log "INFO" "Demo skipped"
            ;;
    esac
}

# Main function to run examples
main() {
    local example_type="$1"
    shift
    
    case "$example_type" in
        "basic")
            example_basic_analysis "$@"
            ;;
        "security")
            example_security_audit "$@"
            ;;
        "frida")
            example_frida_setup "$@"
            ;;
        "batch")
            example_batch_analysis "$@"
            ;;
        "pipeline")
            example_custom_pipeline "$@"
            ;;
        "compat")
            example_device_compatibility "$@"
            ;;
        "demo")
            example_interactive_demo
            ;;
        *)
            echo "Usage: $0 <example_type> [args...]"
            echo ""
            echo "Available examples:"
            echo "  basic <apk_file>                    - Basic APK analysis"
            echo "  security <package_name>             - Security audit workflow"
            echo "  frida <apk_file> <arch>             - Frida dynamic analysis setup"
            echo "  batch <apk_dir> [output_dir]        - Batch analysis"
            echo "  pipeline <apk_file> [pipeline]      - Custom analysis pipeline"
            echo "  compat <package_name>               - Device compatibility testing"
            echo "  demo                                - Interactive demo"
            echo ""
            echo "Pipelines: quick, comprehensive, security, malware"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"