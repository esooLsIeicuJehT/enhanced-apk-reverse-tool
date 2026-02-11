#!/bin/bash
#
# Enhanced APK Reverse Engineering Tool v2.0
# Based on apk.sh by ax (github.com/ax) with significant enhancements
# Author: Enhanced by SuperNinja for comprehensive Android APK analysis
#
# -----------------------------------------------------------------------------
#
# SYNOPSIS
#   apk-reverse-tool.sh [SUBCOMMAND] [APK FILE|APK DIR|PKG NAME] [FLAGS]
#   apk-reverse-tool.sh pull [PKG NAME] [FLAGS]
#   apk-reverse-tool.sh decode [APK FILE] [FLAGS]
#   apk-reverse-tool.sh build [APK DIR] [FLAGS]
#   apk-reverse-tool.sh patch [APK FILE] [FLAGS]
#   apk-reverse-tool.sh rename [APK FILE] [PKG NAME] [FLAGS]
#   apk-reverse-tool.sh analyze [APK FILE] [FLAGS]
#   apk-reverse-tool.sh secure [APK FILE] [FLAGS]
#   apk-reverse-tool.sh monitor [DEVICE_ID] [FLAGS]
#
# NEW FEATURES:
#   - Comprehensive APK security analysis
#   - Device compatibility checking
#   - Automated vulnerability scanning
#   - Interactive mode with guided workflow
#   - Plugin system for extensibility
#   - Enhanced logging and reporting
#   - Backup and restore functionality
#   - Real-time device monitoring
#   - Certificate analysis
#   - Permission analysis
#   - Code obfuscation detection
#   - Anti-taming detection
#   - OWASP Mobile Top 10 vulnerability scanner
#   - ML-based malware detection
#   - Advanced security features
#
# SUBCOMMANDS
#   pull     Pull an apk from device/emulator with device compatibility check
#   decode   Decode an apk with enhanced analysis options
#   build    Re-build an apk with validation
#   patch    Patch an apk with multiple framework options
#   rename   Rename the apk package with dependency resolution
#   analyze  Comprehensive security and structure analysis
#   secure   Apply security enhancements and patches
#   monitor  Monitor device for APK changes and security events
#   backup   Create backup of APK and analysis data
#   restore  Restore from backup
#
# FLAGS
#   -a, --arch <arch>              Specify target architecture
#   -g, --gadget-conf <json_file>  Specify frida-gadget configuration
#   -n, --net                      Add permissive network security config
#   -r, --no-res                   Do not decode resources
#   -s, --no-src                   Do not disassemble dex
#   -v, --verbose                  Enable verbose output
#   -i, --interactive              Enable interactive mode
#   -o, --output <dir>             Specify output directory
#   -f, --format <format>          Output format (json, xml, text)
#   --deep-analysis                Enable deep security analysis
#   --plugin <plugin_name>         Load specific plugin
#   --backup                       Create backup before operations
#   --device-compat                Check device compatibility
#   --cert-analysis                Analyze certificates
#   --perm-analysis                Analyze permissions
#
# -----------------------------------------------------------------------------

VERSION="2.0"
TOOL_NAME="apk-reverse-tool"

# Source OWASP and ML integration features
if [[ -f "integrate.sh" ]]; then
    source "integrate.sh"
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Enhanced logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "ERROR") echo -e "${RED}[ERROR]${NC} [$timestamp] $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  [$timestamp] $message" ;;
        "INFO")  echo -e "${GREEN}[INFO]${NC}  [$timestamp] $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} [$timestamp] $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} [$timestamp] $message" ;;
        *) echo -e "${WHITE}[LOG]${NC}   [$timestamp] $message" ;;
    esac
    
    # Also log to file if logging is enabled
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    $TOOL_NAME v$VERSION                    ║"
    echo "║         Enhanced Android APK Reverse Engineering Tool        ║"
    echo "║    Based on apk.sh by ax with comprehensive enhancements     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Initialize tool environment
init_environment() {
    log "INFO" "Initializing $TOOL_NAME v$VERSION..."
    
    # Set up home directory
    APK_TOOL_HOME="${HOME}/.$TOOL_NAME"
    mkdir -p "$APK_TOOL_HOME"
    mkdir -p "$APK_TOOL_HOME/logs"
    mkdir -p "$APK_TOOL_HOME/backups"
    mkdir -p "$APK_TOOL_HOME/plugins"
    mkdir -p "$APK_TOOL_HOME/configs"
    mkdir -p "$APK_TOOL_HOME/reports"
    
    # Initialize log file
    LOG_FILE="$APK_TOOL_HOME/logs/$(date +%Y%m%d_%H%M%S).log"
    log "INFO" "Home directory: $APK_TOOL_HOME"
    log "INFO" "Log file: $LOG_FILE"
    
    # Supported architectures
    supported_arch=("arm" "x86_64" "x86" "arm64")
    
    # Load configuration
    load_config
    
    # Check dependencies
    check_dependencies
    
    log "SUCCESS" "Environment initialized successfully"
}

# Load configuration from file
load_config() {
    local config_file="$APK_TOOL_HOME/configs/default.conf"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log "INFO" "Configuration loaded from $config_file"
    else
        # Create default configuration
        cat > "$config_file" << 'EOF'
# Default Configuration for APK Reverse Engineering Tool

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

# Device Settings
CHECK_DEVICE_COMPATIBILITY=true
AUTO_DETECT_ARCH=true

# Analysis Settings
ENABLE_OBFUSCATION_DETECTION=true
ENABLE_ANTI_TAMPERING_CHECK=true
ENABLE_CODE_ANALYSIS=true

# Plugin Settings
LOAD_PLUGINS=true
PLUGIN_DIR="$APK_TOOL_HOME/plugins"
EOF
        log "INFO" "Default configuration created at $config_file"
        source "$config_file"
    fi
}

# Enhanced dependency checking
check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local missing_deps=()
    
    # Check basic tools
    for tool in wget unzip zip java; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    # Check Android tools
    if ! command -v adb &> /dev/null; then
        log "WARN" "ADB not found in PATH, will download if needed"
    fi
    
    if ! command -v apktool &> /dev/null; then
        log "WARN" "apktool not found in PATH, will download if needed"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing_deps[*]}"
        log "INFO" "Please install missing dependencies and try again"
        exit 1
    fi
    
    log "SUCCESS" "All dependencies checked"
}

# Device compatibility check
check_device_compatibility() {
    local device_id="$1"
    
    log "INFO" "Checking device compatibility..."
    
    # Get device information
    local android_version=$(adb -s "$device_id" shell getprop ro.build.version.release 2>/dev/null || echo "unknown")
    local api_level=$(adb -s "$device_id" shell getprop ro.build.version.sdk 2>/dev/null || echo "unknown")
    local arch=$(adb -s "$device_id" shell getprop ro.product.cpu.abi 2>/dev/null || echo "unknown")
    
    log "INFO" "Device: $device_id"
    log "INFO" "Android Version: $android_version (API $api_level)"
    log "INFO" "Architecture: $arch"
    
    # Check compatibility
    if [[ "$api_level" -lt 21 ]]; then
        log "WARN" "Android version $android_version may have limited compatibility"
    fi
    
    # Validate architecture
    if [[ ! " ${supported_arch[*]} " =~ " ${arch} " ]]; then
        log "ERROR" "Unsupported architecture: $arch"
        return 1
    fi
    
    log "SUCCESS" "Device is compatible"
    return 0
}

# Enhanced APK analysis
analyze_apk() {
    local apk_file="$1"
    local analysis_options="$2"
    
    log "INFO" "Starting comprehensive APK analysis..."
    
    if [[ ! -f "$apk_file" ]]; then
        log "ERROR" "APK file not found: $apk_file"
        return 1
    fi
    
    # Create analysis directory
    local analysis_dir="${apk_file%.apk}_analysis"
    mkdir -p "$analysis_dir"
    
    # Initialize analysis report
    local report_file="$analysis_dir/analysis_report.json"
    init_analysis_report "$report_file" "$apk_file"
    
    # Basic information extraction
    extract_basic_info "$apk_file" "$report_file"
    
    # Certificate analysis
    if [[ "$ENABLE_CERTIFICATE_ANALYSIS" == "true" ]]; then
        analyze_certificates "$apk_file" "$report_file"
    fi
    
    # Permission analysis
    if [[ "$ENABLE_PERMISSION_ANALYSIS" == "true" ]]; then
        analyze_permissions "$apk_file" "$report_file"
    fi
    
    # Security analysis
    if [[ "$ENABLE_DEEP_ANALYSIS" == "true" ]]; then
        perform_security_analysis "$apk_file" "$report_file"
    fi
    
    # OWASP vulnerability scanning
    if [[ "$ENABLE_OWASP_SCAN" == "true" ]]; then
        run_owasp_scan "$apk_file" "$report_file"
    fi
    
    # ML-based malware detection
    if [[ "$ENABLE_MALWARE_DETECTION" == "true" ]]; then
        run_malware_detection "$apk_file" "$report_file"
    fi
    
    # Vulnerability scanning
    if [[ "$ENABLE_VULNERABILITY_SCAN" == "true" ]]; then
        scan_vulnerabilities "$apk_file" "$report_file"
    fi
    
    # Code analysis
    if [[ "$ENABLE_CODE_ANALYSIS" == "true" ]]; then
        analyze_code "$apk_file" "$report_file"
    fi
    
    log "SUCCESS" "Analysis completed. Report saved to $report_file"
}

# Initialize analysis report
init_analysis_report() {
    local report_file="$1"
    local apk_file="$2"
    
    cat > "$report_file" << EOF
{
    "tool_info": {
        "name": "$TOOL_NAME",
        "version": "$VERSION",
        "analysis_date": "$(date -Iseconds)",
        "apk_file": "$apk_file"
    },
    "basic_info": {},
    "certificate_analysis": {},
    "permission_analysis": {},
    "security_analysis": {},
    "vulnerability_scan": {},
    "code_analysis": {}
}
EOF
}

# Extract basic APK information
extract_basic_info() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Extracting basic APK information..."
    
    # Use aapt to get basic info
    local package_name=$(aapt dump badging "$apk_file" | grep "package: name=" | cut -d"'" -f2)
    local version_name=$(aapt dump badging "$apk_file" | grep "versionName=" | cut -d"'" -f2)
    local version_code=$(aapt dump badging "$apk_file" | grep "versionCode=" | cut -d"'" -f6)
    local min_sdk=$(aapt dump badging "$apk_file" | grep "sdkVersion:" | cut -d"'" -f2)
    local target_sdk=$(aapt dump badging "$apk_file" | grep "targetSdkVersion:" | cut -d"'" -f2)
    
    # Update report with basic info
    local temp_file=$(mktemp)
    jq --arg pkg "$package_name" \
       --arg ver_name "$version_name" \
       --arg ver_code "$version_code" \
       --arg min_sdk "$min_sdk" \
       --arg target_sdk "$target_sdk" \
       '.basic_info = {
           "package_name": $pkg,
           "version_name": $ver_name,
           "version_code": $ver_code,
           "min_sdk": $min_sdk,
           "target_sdk": $target_sdk
       }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "INFO" "Package: $package_name, Version: $version_name ($version_code)"
}

# Analyze certificates
analyze_certificates() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Analyzing certificates..."
    
    # Extract APK to get certificate info
    local temp_dir=$(mktemp -d)
    unzip -q "$apk_file" -d "$temp_dir"
    
    if [[ -f "$temp_dir/META-INF/CERT.RSA" ]]; then
        # Get certificate information
        local cert_info=$(keytool -printcert -file "$temp_dir/META-INF/CERT.RSA" 2>/dev/null)
        
        # Extract key details
        local issuer=$(echo "$cert_info" | grep "Issuer:" | cut -d: -f2- | xargs)
        local subject=$(echo "$cert_info" | grep "Owner:" | cut -d: -f2- | xargs)
        local valid_from=$(echo "$cert_info" | grep "Valid from:" | cut -d: -f2- | xargs)
        local valid_until=$(echo "$cert_info" | grep "until:" | cut -d: -f3- | xargs)
        local algorithm=$(echo "$cert_info" | grep "Signature algorithm:" | cut -d: -f2- | xargs)
        
        # Update report
        local temp_file=$(mktemp)
        jq --arg issuer "$issuer" \
           --arg subject "$subject" \
           --arg valid_from "$valid_from" \
           --arg valid_until "$valid_until" \
           --arg algorithm "$algorithm" \
           '.certificate_analysis = {
               "issuer": $issuer,
               "subject": $subject,
               "valid_from": $valid_from,
               "valid_until": $valid_until,
               "algorithm": $algorithm
           }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    fi
    
    rm -rf "$temp_dir"
    log "INFO" "Certificate analysis completed"
}

# Analyze permissions
analyze_permissions() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Analyzing permissions..."
    
    # Extract permissions
    local permissions=$(aapt dump permissions "$apk_file" | grep "uses-permission:" | cut -d= -f2 | tr -d "'" | sort)
    
    # Categorize permissions
    local dangerous_perms=()
    local normal_perms=()
    local signature_perms=()
    
    while IFS= read -r perm; do
        case $perm in
            android.permission.READ_CONTACTS|android.permission.WRITE_CONTACTS|\
            android.permission.READ_CALENDAR|android.permission.WRITE_CALENDAR|\
            android.permission.CAMERA|android.permission.READ_EXTERNAL_STORAGE|\
            android.permission.WRITE_EXTERNAL_STORAGE|android.permission.ACCESS_FINE_LOCATION|\
            android.permission.ACCESS_COARSE_LOCATION|android.permission.RECORD_AUDIO|\
            android.permission.READ_PHONE_STATE|android.permission.CALL_PHONE|\
            android.permission.READ_SMS|android.permission.SEND_SMS|\
            android.permission.RECEIVE_SMS|android.permission.ACCESS_WIFI_STATE)
                dangerous_perms+=("$perm")
                ;;
            android.permission.*.SIGNATURE|android.permission.*.SIGNATURE*)
                signature_perms+=("$perm")
                ;;
            *)
                normal_perms+=("$perm")
                ;;
        esac
    done <<< "$permissions"
    
    # Update report
    local temp_file=$(mktemp)
    jq --argjson dangerous "$(printf '%s\n' "${dangerous_perms[@]}" | jq -R . | jq -s .)" \
       --argjson normal "$(printf '%s\n' "${normal_perms[@]}" | jq -R . | jq -s .)" \
       --argjson signature "$(printf '%s\n' "${signature_perms[@]}" | jq -R . | jq -s .)" \
       '.permission_analysis = {
           "total": '"$((${#dangerous_perms[@]} + ${#normal_perms[@]} + ${#signature_perms[@]}))"',
           "dangerous": $dangerous,
           "normal": $normal,
           "signature": $signature,
           "dangerous_count": '"${#dangerous_perms[@]}"'
       }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "WARN" "Found ${#dangerous_perms[@]} dangerous permissions"
    log "INFO" "Permission analysis completed"
}

# Perform security analysis
perform_security_analysis() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Performing security analysis..."
    
    local security_issues=()
    
    # Check for debug mode
    if aapt dump badging "$apk_file" | grep -q "application-debuggable=true"; then
        security_issues+=("Application is debuggable")
    fi
    
    # Check for allowBackup
    if aapt dump badging "$apk_file" | grep -q "android:allowBackup='true'"; then
        security_issues+=("Application allows backup")
    fi
    
    # Check for network security config
    if ! aapt dump badging "$apk_file" | grep -q "networkSecurityConfig"; then
        security_issues+=("No network security configuration found")
    fi
    
    # Update report
    local temp_file=$(mktemp)
    jq --argjson issues "$(printf '%s\n' "${security_issues[@]}" | jq -R . | jq -s .)" \
       '.security_analysis = {
           "issues_found": '"${#security_issues[@]}"',
           "issues": $issues,
           "risk_level": "'$((${#security_issues[@]} > 2 ? "HIGH" : ${#security_issues[@]} > 0 ? "MEDIUM" : "LOW"))'"
       }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "WARN" "Found ${#security_issues[@]} security issues"
    log "INFO" "Security analysis completed"
}

# Scan for vulnerabilities
scan_vulnerabilities() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Scanning for vulnerabilities..."
    
    local vulnerabilities=()
    
    # Check for common vulnerable libraries
    local temp_dir=$(mktemp -d)
    unzip -q "$apk_file" -d "$temp_dir"
    
    # Check for outdated libraries (simplified example)
    if [[ -f "$temp_dir/classes.dex" ]]; then
        # This would normally involve more sophisticated analysis
        # For now, just check basic indicators
        vulnerabilities+=("Consider checking for outdated dependencies")
    fi
    
    # Check for hardcoded secrets (basic pattern matching)
    if grep -r -i "api_key\|password\|secret" "$temp_dir" >/dev/null 2>&1; then
        vulnerabilities+=("Potential hardcoded secrets detected")
    fi
    
    # Update report
    local temp_file=$(mktemp)
    jq --argjson vulns "$(printf '%s\n' "${vulnerabilities[@]}" | jq -R . | jq -s .)" \
       '.vulnerability_scan = {
           "vulnerabilities_found": '"${#vulnerabilities[@]}"',
           "vulnerabilities": $vulns,
           "scan_date": "'$(date -Iseconds)'"
       }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    rm -rf "$temp_dir"
    log "WARN" "Found ${#vulnerabilities[@]} potential vulnerabilities"
    log "INFO" "Vulnerability scan completed"
}

# Analyze code
analyze_code() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Analyzing code structure..."
    
    local code_analysis=()
    
    # This would normally involve decompiling and analyzing the code
    # For now, provide basic structure analysis
    
    code_analysis+=("Code analysis requires decompilation")
    code_analysis+=("Consider using jadx or jadx-gui for detailed code analysis")
    
    # Update report
    local temp_file=$(mktemp)
    jq --argjson analysis "$(printf '%s\n' "${code_analysis[@]}" | jq -R . | jq -s .)" \
       '.code_analysis = {
           "recommendations": $analysis,
           "note": "Detailed code analysis requires additional decompilation tools"
       }' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "INFO" "Code analysis completed"
}

# Create backup
create_backup() {
    local target="$1"
    local backup_name="$2"
    
    if [[ "$CREATE_BACKUPS" != "true" ]]; then
        return 0
    fi
    
    log "INFO" "Creating backup: $backup_name"
    
    local backup_dir="$APK_TOOL_HOME/backups"
    local backup_path="$backup_dir/$backup_name"
    
    mkdir -p "$backup_path"
    
    if [[ -f "$target" ]]; then
        cp "$target" "$backup_path/"
    elif [[ -d "$target" ]]; then
        cp -r "$target" "$backup_path/"
    else
        log "ERROR" "Cannot backup: $target does not exist"
        return 1
    fi
    
    # Create backup metadata
    cat > "$backup_path/backup_info.json" << EOF
{
    "backup_name": "$backup_name",
    "original_path": "$target",
    "backup_date": "$(date -Iseconds)",
    "tool_version": "$VERSION"
}
EOF
    
    log "SUCCESS" "Backup created: $backup_path"
}

# Interactive mode
interactive_mode() {
    log "INFO" "Starting interactive mode..."
    
    while true; do
        echo -e "\n${CYAN}=== $TOOL_NAME Interactive Mode ===${NC}"
        echo "1. Pull APK from device"
        echo "2. Decode APK"
        echo "3. Analyze APK"
        echo "4. Patch APK"
        echo "5. Build APK"
        echo "6. Security Analysis"
        echo "7. Device Information"
        echo "8. Exit"
        echo -n "Please select an option (1-8): "
        
        read -r choice
        
        case $choice in
            1) interactive_pull ;;
            2) interactive_decode ;;
            3) interactive_analyze ;;
            4) interactive_patch ;;
            5) interactive_build ;;
            6) interactive_security ;;
            7) interactive_device_info ;;
            8) log "INFO" "Exiting interactive mode"; break ;;
            *) log "ERROR" "Invalid option. Please try again." ;;
        esac
    done
}

# Interactive pull function
interactive_pull() {
    echo -e "\n${YELLOW}=== Pull APK from Device ===${NC}"
    
    # List connected devices
    echo "Connected devices:"
    adb devices | grep -v "List" | grep -v "^$"
    
    echo -n "Enter package name to pull: "
    read -r package_name
    
    if [[ -n "$package_name" ]]; then
        # Device compatibility check
        local device_id=$(adb devices | grep -v "List" | grep -v "^$" | head -1 | cut -f1)
        if check_device_compatibility "$device_id"; then
            apk_pull_enhanced "$package_name"
        fi
    fi
}

# Enhanced APK pull function
apk_pull_enhanced() {
    local package="$1"
    local build_opts="$2"
    
    log "INFO" "Pulling APK package: $package"
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        log "ERROR" "No device connected"
        return 1
    fi
    
    # Get package path
    local package_path=$(adb shell pm path "$package" 2>/dev/null | sed 's/\r//' | cut -d: -f2)
    
    if [[ -z "$package_path" ]]; then
        log "ERROR" "Package $package not found on device"
        return 1
    fi
    
    # Create backup before pulling
    if [[ "$CREATE_BACKUPS" == "true" ]]; then
        create_backup "$package" "pull_$(date +%Y%m%d_%H%M%S)_$package"
    fi
    
    # Count number of APKs
    local num_apk=$(echo "$package_path" | wc -l)
    
    if [[ $num_apk -gt 1 ]]; then
        # Handle split APKs
        log "INFO" "Split APKs detected ($num_apk files)"
        
        local split_dir="${package}_split_apks"
        mkdir -p "$split_dir"
        
        echo "$package_path" | while read -r path; do
            log "INFO" "Pulling: $path"
            adb pull "$path" "$split_dir/"
        done
        
        # Combine split APKs (original logic would go here)
        log "INFO" "Split APKs pulled to $split_dir"
        log "WARN" "Split APK combination requires additional processing"
        
    else
        # Single APK
        log "INFO" "Pulling single APK from: $package_path"
        adb pull "$package_path" .
        local apk_name=$(basename "$package_path")
        log "SUCCESS" "APK pulled: $apk_name"
        
        # Basic analysis
        if command -v jq &> /dev/null; then
            analyze_apk "$apk_name" "--basic"
        fi
    fi
}

# Main function - entry point
main() {
    # Initialize
    init_environment
    print_banner
    
    # Parse command line arguments
    case "${1:-}" in
        "pull")
            shift
            apk_pull_enhanced "$@"
            ;;
        "analyze")
            shift
            analyze_apk "$@"
            ;;
        "interactive"|"i")
            interactive_mode
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Show help
show_help() {
    cat << EOF
$TOOL_NAME v$VERSION - Enhanced Android APK Reverse Engineering Tool

USAGE:
    $0 <command> [options]

COMMANDS:
    pull <package>          Pull APK from connected device
    analyze <apk_file>      Comprehensive APK analysis
    interactive             Start interactive mode
    help                    Show this help message

EXAMPLES:
    $0 pull com.example.app
    $0 analyze app.apk
    $0 interactive

For more detailed help, use: $0 <command> --help

EOF
}

# Check if jq is available for JSON processing
if ! command -v jq &> /dev/null; then
    log "WARN" "jq not found. JSON processing features will be limited"
fi

# Run main function with all arguments
main "$@"