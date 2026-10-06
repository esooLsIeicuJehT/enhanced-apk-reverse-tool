#!/usr/bin/env bash
# Evidence-based OWASP and static-risk feature integration for apk-reverse-tool.sh.

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

    log "INFO" "Running evidence-based OWASP static checks..."

    if [[ ! -f "$scanner" ]]; then
        log "ERROR" "OWASP scanner not found: $scanner"
        return 1
    fi

    if python3 "$scanner" "$apk_file" --output "$owasp_output" --format json; then
        _merge_json_section "$report_file" "owasp_results" "$owasp_output" || true
        rm -f "$owasp_output"
        log "SUCCESS" "OWASP static checks completed successfully"
        return 0
    fi

    rm -f "$owasp_output"
    log "ERROR" "OWASP static checks failed"
    return 1
}

run_risk_scan() {
    local apk_file="$1"
    local report_file="$2"
    local detector="$INTEGRATION_ROOT/apk-tool-features/risk/risk_detector.py"
    local risk_output="${apk_file%.apk}_risk.json"

    log "INFO" "Running static APK risk indicator scan..."

    if [[ ! -f "$detector" ]]; then
        log "ERROR" "Risk indicator scanner not found: $detector"
        return 1
    fi

    if python3 "$detector" "$apk_file" --output "$risk_output" --format json; then
        _merge_json_section "$report_file" "risk_indicator_results" "$risk_output" || true
        rm -f "$risk_output"
        log "SUCCESS" "Static risk indicator scan completed"
        return 0
    fi

    rm -f "$risk_output"
    log "ERROR" "Static risk indicator scan failed"
    return 1
}

# Backward-compatible function name for scripts that sourced older releases.
run_malware_detection() {
    log "WARN" "run_malware_detection is deprecated; running static risk indicators instead"
    run_risk_scan "$@"
}

ENABLE_OWASP_SCAN="${ENABLE_OWASP_SCAN:-true}"
ENABLE_RISK_SCAN="${ENABLE_RISK_SCAN:-${ENABLE_MALWARE_DETECTION:-true}}"
