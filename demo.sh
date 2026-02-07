#!/bin/bash
#
# Demo Script for Enhanced APK Reverse Engineering Tool
# This script demonstrates the key features and capabilities
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Tool info
TOOL_NAME="apk-reverse-tool"
VERSION="2.0"

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     $TOOL_NAME v$VERSION - Enhanced Demo & Tour              ║"
    echo "║         Comprehensive Android APK Analysis Tool              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print section header
print_section() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

# Print feature highlight
print_feature() {
    echo -e "${GREEN}✓${NC} $1"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Print error
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if tool is available
check_tool() {
    if [[ ! -f "./apk-reverse-tool.sh" ]]; then
        print_error "Main tool script not found!"
        echo "Please ensure apk-reverse-tool.sh is in the current directory."
        exit 1
    fi
    
    if [[ ! -x "./apk-reverse-tool.sh" ]]; then
        print_error "Tool script is not executable!"
        echo "Run: chmod +x apk-reverse-tool.sh"
        exit 1
    fi
    
    print_feature "Tool script found and executable"
}

# Show basic help
show_basic_help() {
    print_section "Basic Usage & Commands"
    
    echo -e "${WHITE}Available Commands:${NC}"
    echo "  analyze     - Comprehensive APK analysis"
    echo "  pull        - Pull APK from Android device"
    echo "  patch       - Patch APK with analysis tools"
    echo "  build       - Rebuild APK from source"
    echo "  rename      - Rename APK package"
    echo "  interactive - Interactive guided mode"
    echo "  help        - Show detailed help"
    
    echo -e "\n${WHITE}Basic Examples:${NC}"
    echo "  ./apk-reverse-tool.sh analyze app.apk"
    echo "  ./apk-reverse-tool.sh pull com.example.app"
    echo "  ./apk-reverse-tool.sh interactive"
}

# Demonstrate help system
demo_help() {
    print_section "Help System"
    
    print_feature "Built-in help system with detailed command information"
    
    echo -e "${CYAN}Main help:${NC}"
    ./apk-reverse-tool.sh --help
    
    echo -e "\n${CYAN}Command-specific help:${NC}"
    echo "Each command supports --help flag for detailed information:"
    echo "  ./apk-reverse-tool.sh analyze --help"
    echo "  ./apk-reverse-tool.sh pull --help"
    echo "  ./apk-reverse-tool.sh patch --help"
}

# Demonstrate configuration
demo_configuration() {
    print_section "Configuration Management"
    
    print_feature "Flexible configuration system with defaults and customization"
    
    echo -e "${WHITE}Configuration Location:${NC}"
    echo "  Default: ~/.apk-reverse-tool/configs/default.conf"
    echo "  Custom:  --config <file>"
    
    echo -e "\n${WHITE}Key Configuration Options:${NC}"
    echo "  - Analysis depth settings"
    echo "  - Security scanning preferences"
    echo "  - Output format defaults"
    echo "  - Backup and logging options"
    echo "  - Tool version preferences"
    
    # Create demo config
    echo -e "\n${CYAN}Creating demo configuration...${NC}"
    mkdir -p ~/.apk-reverse-tool/configs
    
    cat > ~/.apk-reverse-tool/configs/demo.conf << 'EOF'
# Demo Configuration for APK Reverse Engineering Tool
ENABLE_DEEP_ANALYSIS=true
ENABLE_VULNERABILITY_SCAN=true
DEFAULT_OUTPUT_FORMAT="json"
CREATE_BACKUPS=true
ENABLE_VERBOSITY=true
EOF
    
    print_feature "Demo configuration created at ~/.apk-reverse-tool/configs/demo.conf"
}

# Demonstrate logging
demo_logging() {
    print_section "Enhanced Logging System"
    
    print_feature "Comprehensive logging with multiple levels and structured output"
    
    echo -e "${WHITE}Log Levels:${NC}"
    echo "  - ERROR: Critical errors that stop execution"
    echo "  - WARN : Warning messages for potential issues"
    echo "  - INFO : General information and progress updates"
    echo "  - DEBUG: Detailed debugging information"
    
    echo -e "\n${WHITE}Log Storage:${NC}"
    echo "  - Automatic log file creation"
    echo "  - Timestamped log entries"
    echo "  - Structured output for parsing"
    echo "  - Rotating log files"
    
    # Show log directory structure
    if [[ -d ~/.apk-reverse-tool/logs ]]; then
        echo -e "\n${CYAN}Existing log files:${NC}"
        ls -la ~/.apk-reverse-tool/logs/ 2>/dev/null || echo "No logs yet"
    fi
}

# Demonstrate device detection
demo_device_detection() {
    print_section "Device Detection & Compatibility"
    
    print_feature "Automatic device detection and compatibility checking"
    
    echo -e "${WHITE}Device Detection Features:${NC}"
    echo "  - Automatic device discovery"
    echo "  - Architecture detection"
    echo "  - Android version compatibility"
    echo "  - Multi-device support"
    echo "  - Device health checking"
    
    # Check for connected devices
    echo -e "\n${CYAN}Checking for connected devices...${NC}"
    if command -v adb &> /dev/null; then
        local devices=$(adb devices 2>/dev/null | grep -v "List of devices" | grep -v "^$" | wc -l)
        if [[ $devices -gt 0 ]]; then
            print_feature "Found $devices connected device(s)"
            adb devices
        else
            print_warning "No Android devices connected"
            echo "Connect a device and enable USB debugging to test device features"
        fi
    else
        print_warning "ADB not available - install Android SDK for device features"
    fi
}

# Demonstrate analysis capabilities
demo_analysis() {
    print_section "Comprehensive Analysis Capabilities"
    
    print_feature "Multi-layered APK analysis with security focus"
    
    echo -e "${WHITE}Analysis Modules:${NC}"
    echo "  • Basic Information Extraction"
    echo "    - Package name, version, SDK requirements"
    echo "    - Activities, services, receivers"
    echo "    - Application metadata"
    
    echo -e "\n  • Certificate Analysis"
    echo "    - Certificate chain validation"
    echo "    - Signature algorithm analysis"
    echo "    - Issuer and subject information"
    echo "    - Validity period checking"
    
    echo -e "\n  • Permission Analysis"
    echo "    - Permission categorization"
    echo "    - Dangerous permission detection"
    echo "    - Privacy impact assessment"
    echo "    - Security level evaluation"
    
    echo -e "\n  • Security Analysis"
    echo "    - Debug mode detection"
    echo "    - Backup configuration analysis"
    echo "    - Network security configuration"
    echo "    - Anti-tampering detection"
    
    echo -e "\n  • Vulnerability Scanning"
    echo "    - Known vulnerability database"
    echo "    - Hardcoded secret detection"
    echo "    - Outdated library detection"
    echo "    - Insecure configuration detection"
    
    echo -e "\n  • Code Analysis"
    echo "    - Obfuscation detection"
    echo "    - Code structure analysis"
    echo "    - Native library analysis"
    echo "    - Bytecode examination"
}

# Demonstrate output formats
demo_output_formats() {
    print_section "Flexible Output Formats"
    
    print_feature "Multiple output formats for different use cases"
    
    echo -e "${WHITE}Supported Formats:${NC}"
    echo "  • JSON - Structured data for programmatic use"
    echo "  • XML  - Markup format for integration"
    echo "  • Text - Human-readable reports"
    echo "  • HTML - Interactive web reports"
    
    echo -e "\n${WHITE}Output Features:${NC}"
    echo "  - Customizable output directory"
    echo "  - Structured report generation"
    echo "  - Metadata inclusion"
    echo "  - Timestamp tracking"
    echo "  - Exportable analysis data"
    
    # Create sample output structure demo
    echo -e "\n${CYAN}Sample output structure:${NC}"
    mkdir -p demo_output/analysis_report
    cat > demo_output/analysis_report/structure.txt << 'EOF'
analysis_report/
├── analysis_report.json    # Main analysis results
├── basic_info.txt         # Basic APK information
├── certificate_info.txt   # Certificate analysis
├── permission_analysis.txt # Permission breakdown
├── security_findings.txt  # Security issues
├── vulnerabilities.txt    # Vulnerability report
└── metadata.json         # Analysis metadata
EOF
    cat demo_output/analysis_report/structure.txt
}

# Demonstrate interactive mode
demo_interactive() {
    print_section "Interactive Mode"
    
    print_feature "User-friendly guided workflow for complex operations"
    
    echo -e "${WHITE}Interactive Features:${NC}"
    echo "  • Guided menu system"
    echo "  • Context-sensitive help"
    echo "  • Progress indicators"
    echo "  • Error recovery"
    echo "  • Expert mode toggle"
    
    echo -e "\n${WHITE}Interactive Workflow:${NC}"
    echo "  1. Select operation type"
    echo "  2. Provide required parameters"
    echo "  3. Configure analysis options"
    echo "  4. Execute with progress tracking"
    echo "  5. Review results and recommendations"
    
    echo -e "\n${CYAN}To start interactive mode:${NC}"
    echo "  ./apk-reverse-tool.sh interactive"
}

# Demonstrate security features
demo_security() {
    print_section "Security-Focused Features"
    
    print_feature "Comprehensive security analysis and vulnerability detection"
    
    echo -e "${WHITE}Security Analysis:${NC}"
    echo "  • Application hardening assessment"
    echo "  • Insecure configuration detection"
    echo "  • Privacy and permission evaluation"
    echo "  • Certificate validation"
    echo "  • Anti-tampering detection"
    
    echo -e "\n${WHITE}Vulnerability Detection:${NC}"
    echo "  • OWASP Mobile Top 10 coverage"
    echo "  • Known CVE detection"
    echo "  • Outdated dependency scanning"
    echo "  • Hardcoded credential detection"
    echo "  • Insecure network communication"
    
    echo -e "\n${WHITE}Risk Assessment:${NC}"
    echo "  • Risk level calculation"
    echo "  • Severity classification"
    echo "  • Remediation recommendations"
    echo "  • Compliance checking"
}

# Demonstrate extensibility
demo_extensibility() {
    print_section "Plugin System & Extensibility"
    
    print_feature "Modular architecture for custom analysis modules"
    
    echo -e "${WHITE}Plugin Features:${NC}"
    echo "  • Custom analysis modules"
    echo "  • Third-party tool integration"
    echo "  • Custom output formats"
    echo "  • Automated workflow plugins"
    echo "  • API integration plugins"
    
    echo -e "\n${WHITE}Plugin Development:${NC}"
    echo "  - Simple plugin interface"
    echo "  - Configuration-driven plugins"
    echo "  - Hook system for extensibility"
    echo "  - Plugin dependency management"
    
    echo -e "\n${CYAN}Plugin Directory:${NC}"
    echo "  ~/.apk-reverse-tool/plugins/"
    
    # Create demo plugin structure
    mkdir -p ~/.apk-reverse-tool/plugins/demo
    cat > ~/.apk-reverse-tool/plugins/demo/README.md << 'EOF'
# Demo Plugin

This is a sample plugin structure for the Enhanced APK Reverse Engineering Tool.

## Plugin Structure

- plugin.sh    - Main plugin script
- config.json  - Plugin configuration
- README.md    - Plugin documentation

## Usage

./apk-reverse-tool.sh analyze app.apk --plugin demo
EOF
    print_feature "Demo plugin structure created"
}

# Demonstrate batch processing
demo_batch() {
    print_section "Batch Processing & Automation"
    
    print_feature "Efficient processing of multiple APKs"
    
    echo -e "${WHITE}Batch Features:${NC}"
    echo "  • Multi-APK analysis"
    echo "  • Parallel processing"
    echo "  • Progress tracking"
    echo "  • Summary reporting"
    echo "  • Error handling"
    
    echo -e "\n${WHITE}Automation Capabilities:${NC}"
    echo "  - Scriptable interface"
    echo "  - CI/CD integration"
    echo "  - Scheduled analysis"
    echo "  - Report generation"
    echo "  - Notification systems"
    
    # Create demo batch script
    cat > demo_batch.sh << 'EOF'
#!/bin/bash
# Demo batch analysis script

APK_DIR="apks"
OUTPUT_DIR="batch_results"

echo "Starting batch analysis..."
mkdir -p "$OUTPUT_DIR"

for apk in "$APK_DIR"/*.apk; do
    echo "Processing $(basename "$apk")..."
    ./apk-reverse-tool.sh analyze "$apk" --output "$OUTPUT_DIR/$(basename "$apk" .apk)"
done

echo "Batch analysis completed!"
EOF
    chmod +x demo_batch.sh
    print_feature "Demo batch script created: demo_batch.sh"
}

# Show performance comparison
show_performance() {
    print_section "Performance & Efficiency"
    
    print_feature "Optimized for speed and resource efficiency"
    
    echo -e "${WHITE}Performance Features:${NC}"
    echo "  • Parallel processing capabilities"
    echo "  • Memory-efficient analysis"
    echo "  • Caching mechanisms"
    echo "  • Incremental analysis"
    echo "  • Resource monitoring"
    
    echo -e "\n${WHITE}Benchmark Examples (approximate):${NC}"
    echo "  • Small APK (10MB): 5-10 seconds"
    echo "  • Medium APK (50MB): 30-60 seconds"
    echo "  • Large APK (100MB+): 2-5 minutes"
    
    echo -e "\n${WHITE}Resource Usage:${NC}"
    echo "  • Memory: 100MB - 1GB depending on APK size"
    echo "  • CPU: Optimized for multi-core utilization"
    echo "  • Storage: Temporary files cleaned automatically"
    echo "  • Network: Minimal external dependencies"
}

# Show integration capabilities
show_integration() {
    print_section "Integration & Ecosystem"
    
    print_feature "Seamless integration with existing tools and workflows"
    
    echo -e "${WHITE}Tool Integrations:${NC}"
    echo "  • Frida dynamic analysis"
    echo "  • Jadx decompilation"
    echo "  • Androguard static analysis"
    echo "  • Android SDK tools"
    echo "  • Security scanning frameworks"
    
    echo -e "\n${WHITE}Platform Support:${NC}"
    echo "  • Linux (primary platform)"
    echo "  • Docker containerization"
    echo "  • CI/CD pipeline integration"
    echo "  • REST API for remote access"
    echo "  • Python API for programmatic use"
    
    echo -e "\n${WHITE}Workflow Integration:${NC}"
    echo "  - Security audit pipelines"
    echo "  - Development workflows"
    echo "  - Compliance checking"
    echo "  - Automated testing"
    echo "  - Research workflows"
}

# Show troubleshooting guide
show_troubleshooting() {
    print_section "Troubleshooting & Support"
    
    print_feature "Comprehensive troubleshooting resources"
    
    echo -e "${WHITE}Common Issues:${NC}"
    echo "  • Device connection problems"
    echo "  • Permission issues"
    echo "  • Dependency installation"
    echo "  • Memory limitations"
    echo "  • APK corruption"
    
    echo -e "\n${WHITE}Diagnostic Tools:${NC}"
    echo "  - Verbose logging mode"
    echo "  - System information utility"
    echo "  - Dependency checker"
    echo "  - Configuration validator"
    
    echo -e "\n${WHITE}Getting Help:${NC}"
    echo "  - Detailed error messages"
    echo "  - Log file analysis"
    echo "  - Documentation and examples"
    echo "  - Community support channels"
}

# Main demo function
main() {
    print_banner
    
    echo -e "${WHITE}Welcome to the Enhanced APK Reverse Engineering Tool Demo!${NC}"
    echo ""
    echo "This demo will showcase the key features and capabilities of our"
    echo "comprehensive Android APK analysis tool."
    echo ""
    
    # Check tool availability
    check_tool
    
    # Show basic usage
    show_basic_help
    
    # Feature demonstrations
    demo_help
    demo_configuration
    demo_logging
    demo_device_detection
    demo_analysis
    demo_output_formats
    demo_interactive
    demo_security
    demo_extensibility
    demo_batch
    
    # Performance and integration
    show_performance
    show_integration
    
    # Support and troubleshooting
    show_troubleshooting
    
    # Final summary
    print_section "Demo Summary"
    
    echo -e "${GREEN}✓${NC} Enhanced APK analysis capabilities demonstrated"
    echo -e "${GREEN}✓${NC} Comprehensive security features shown"
    echo -e "${GREEN}✓${NC} Flexible configuration system presented"
    echo -e "${GREEN}✓${NC} Interactive and batch processing modes covered"
    echo -e "${GREEN}✓${NC} Extensibility and integration options displayed"
    
    echo -e "\n${WHITE}Next Steps:${NC}"
    echo "1. Install dependencies: sudo ./install-dependencies.sh"
    echo "2. Connect Android device and enable USB debugging"
    echo "3. Try basic analysis: ./apk-reverse-tool.sh analyze app.apk"
    echo "4. Explore interactive mode: ./apk-reverse-tool.sh interactive"
    echo "5. Check examples: ./examples/sample-analysis.sh demo"
    
    echo -e "\n${CYAN}Thank you for trying the Enhanced APK Reverse Engineering Tool!${NC}"
    echo -e "${WHITE}Documentation: README.md${NC}"
    echo -e "${WHITE}API Reference: docs/API-REFERENCE.md${NC}"
    echo -e "${WHITE}Examples: examples/sample-analysis.sh${NC}"
    echo -e "${WHITE}Support: Check the documentation and log files${NC}"
}

# Run main demo
main "$@"