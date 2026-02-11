#!/bin/bash
# Integration script for OWASP and ML features
# This file is sourced by the main tool to add the new analysis features

# Run OWASP vulnerability scan
run_owasp_scan() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Running OWASP Mobile Top 10 vulnerability scan..."
    
    if [[ ! -f "apk-tool-features/owasp/owasp_scanner.py" ]]; then
        log "ERROR" "OWASP scanner not found at apk-tool-features/owasp/owasp_scanner.py"
        return 1
    fi
    
    # Run OWASP scanner
    local owasp_output="${apk_file%.apk}_owasp.json"
    
    if python3 "apk-tool-features/owasp/owasp_scanner.py" --apk "$apk_file" --output "$owasp_output" --format json; then
        log "SUCCESS" "OWASP scan completed successfully"
        
        # Update main report
        if command -v jq &> /dev/null; then
            local temp_file=$(mktemp)
            jq --argjson owasp "$(cat "$owasp_output")" '.owasp_results = $owasp' "$report_file" > "$temp_file"
            mv "$temp_file" "$report_file"
        fi
    else
        log "ERROR" "OWASP scan failed"
    fi
    
    rm -f "$owasp_output"
}

# Run malware detection
run_malware_detection() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Running ML-based malware detection..."
    
    if [[ ! -f "apk-tool-features/ml/malware_detector.py" ]]; then
        log "ERROR" "Malware detector not found at apk-tool-tool-features/ml/malware_detector.py"
        return 1
    fi
    
    # Run malware detector
    local ml_output="${apk_file%.apk}_malware.json"
    
    if python3 "apk-tool-features/ml/malware_detector.py" --apk "$apk_file" --output "$ml_output" --format json; then
        log "SUCCESS" "Malware detection completed"
        
        # Update main report
        if command -v jq &> /dev/null; then
            local temp_file=$(mktemp)
            jq --argjson malware "$(cat "$ml_output")' '.malware_results = $malware' "$report_file" > "$temp_file"
            mv "$temp_file" "$report_file"
        fi
    else
        log "ERROR" "Malware detection failed"
    fi
    
    rm -f "$ml_output"
}

# Enable OWASP and ML features by default
ENABLE_OWASP_SCAN="true"
ENABLE_MALWARE_DETECTION="true"

log "INFO" "OWASP scanner and ML malware detector integrated"