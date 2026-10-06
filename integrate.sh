#!/usr/bin/env bash
# OWASP and ML feature integration for apk-reverse-tool.sh.

INTEGRATION_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_merge_json_section() {
    local report_file="$1"
    local section="$2"
    local payload_file="$3"

    if ! command -v jq >/dev/null 2>&1; then
        log "WARN" "jq is unavailable; skipping merge of ${section} results"
        return 0
    fi

    if ! jq -e . "$payload_file" >/dev/null 2>&1; then
        log "ERROR" "${section} output is not valid JSON: $payload_file"
        return 1
    fi

    local temp_file
    temp_file="$(mktemp)"
    if jq --arg section "$section" --slurpfile payload "$payload_file" \
        '.[$section] = $payload[0]' "$report_file" > "$temp_file"; then
        mv "$temp_file" "$report_file"
    else
        rm -f "$temp_file"
        return 1
    fi
}

run_owasp_scan() {
    local apk_file="$1"
    local report_file="$2"
    local scanner="$INTEGRATION_ROOT/apk-tool-features/owasp/owasp_scanner.py"
    local owasp_output="${apk_file%.apk}_owasp.json"

    log "INFO" "Running OWASP Mobile Top 10 vulnerability scan..."

    if [[ ! -f "$scanner" ]]; then
        log "ERROR" "OWASP scanner not found: $scanner"
        return 1
    fi

    if python3 "$scanner" --apk "$apk_file" --output "$owasp_output" --format json; then
        _merge_json_section "$report_file" "owasp_results" "$owasp_output" || true
        rm -f "$owasp_output"
        log "SUCCESS" "OWASP scan completed successfully"
        return 0
    fi

    rm -f "$owasp_output"
    log "ERROR" "OWASP scan failed"
    return 1
}

run_malware_detection() {
    local apk_file="$1"
    local report_file="$2"
    local detector="$INTEGRATION_ROOT/apk-tool-features/ml/malware_detector.py"
    local ml_output="${apk_file%.apk}_malware.json"

    log "INFO" "Running ML-based malware detection..."

    if [[ ! -f "$detector" ]]; then
        log "ERROR" "Malware detector not found: $detector"
        return 1
    fi

    if python3 "$detector" --apk "$apk_file" --output "$ml_output" --format json; then
        _merge_json_section "$report_file" "malware_results" "$ml_output" || true
        rm -f "$ml_output"
        log "SUCCESS" "Malware detection completed"
        return 0
    fi

    rm -f "$ml_output"
    log "ERROR" "Malware detection failed"
    return 1
}

ENABLE_OWASP_SCAN="${ENABLE_OWASP_SCAN:-true}"
ENABLE_MALWARE_DETECTION="${ENABLE_MALWARE_DETECTION:-true}"
