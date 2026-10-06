#!/usr/bin/env bash
# Enhanced APK Reverse Engineering Tool
# Evidence-based APK metadata, structure, permission, OWASP-aligned, and risk-indicator analysis.

set -uo pipefail

VERSION="2.1.0"
TOOL_NAME="apk-reverse-tool"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    local level="${1:-INFO}"
    shift || true
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    case "$level" in
        ERROR) printf '%b[ERROR]%b [%s] %s\n' "$RED" "$NC" "$timestamp" "$message" ;;
        WARN) printf '%b[WARN]%b  [%s] %s\n' "$YELLOW" "$NC" "$timestamp" "$message" ;;
        DEBUG) printf '%b[DEBUG]%b [%s] %s\n' "$BLUE" "$NC" "$timestamp" "$message" ;;
        SUCCESS) printf '%b[SUCCESS]%b [%s] %s\n' "$GREEN" "$NC" "$timestamp" "$message" ;;
        *) printf '%b[INFO]%b  [%s] %s\n' "$GREEN" "$NC" "$timestamp" "$message" ;;
    esac

    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message" >> "$LOG_FILE"
    fi
}

if [[ -f "$SCRIPT_DIR/integrate.sh" ]]; then
    # shellcheck source=integrate.sh
    source "$SCRIPT_DIR/integrate.sh"
else
    log ERROR "Missing integration module: $SCRIPT_DIR/integrate.sh"
    exit 1
fi

: "${ENABLE_DEEP_ANALYSIS:=false}"
: "${ENABLE_VULNERABILITY_SCAN:=true}"
: "${ENABLE_CERTIFICATE_ANALYSIS:=true}"
: "${ENABLE_PERMISSION_ANALYSIS:=true}"
: "${ENABLE_CODE_ANALYSIS:=true}"
: "${ENABLE_OWASP_SCAN:=true}"
: "${ENABLE_RISK_SCAN:=true}"
: "${CREATE_BACKUPS:=false}"

print_banner() {
    printf '%b' "$CYAN"
    cat <<EOF
╔══════════════════════════════════════════════════════════════╗
║              $TOOL_NAME v$VERSION              ║
║        Evidence-based Android APK static analysis            ║
╚══════════════════════════════════════════════════════════════╝
EOF
    printf '%b' "$NC"
}

load_config() {
    local config_file="$APK_TOOL_HOME/configs/default.conf"
    if [[ -f "$config_file" ]]; then
        # shellcheck disable=SC1090
        source "$config_file"
        log INFO "Configuration loaded from $config_file"
        return
    fi

    cat > "$config_file" <<'EOF'
ENABLE_DEEP_ANALYSIS=false
ENABLE_VULNERABILITY_SCAN=true
ENABLE_CERTIFICATE_ANALYSIS=true
ENABLE_PERMISSION_ANALYSIS=true
ENABLE_CODE_ANALYSIS=true
ENABLE_OWASP_SCAN=true
ENABLE_RISK_SCAN=true
CREATE_BACKUPS=false
EOF
    log INFO "Default configuration created at $config_file"
}

require_commands() {
    local missing=()
    local command_name
    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            missing+=("$command_name")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        log ERROR "Missing required commands: ${missing[*]}"
        return 1
    fi
}

init_environment() {
    local command_name="${1:-analyze}"
    APK_TOOL_HOME="${HOME}/.$TOOL_NAME"
    mkdir -p "$APK_TOOL_HOME/logs" "$APK_TOOL_HOME/configs" "$APK_TOOL_HOME/backups"
    LOG_FILE="$APK_TOOL_HOME/logs/$(date +%Y%m%d_%H%M%S)_$$.log"
    load_config

    case "$command_name" in
        analyze)
            require_commands aapt apktool jq python3 unzip || return 1
            ;;
        pull)
            require_commands adb || return 1
            ;;
    esac
}

merge_json_section() {
    local report_file="$1"
    local section="$2"
    local section_file="$3"
    local temp_file
    temp_file="$(mktemp)"

    if ! jq -e . "$section_file" >/dev/null 2>&1; then
        rm -f "$temp_file"
        log ERROR "Generated $section data is not valid JSON"
        return 1
    fi

    if jq --arg section "$section" --slurpfile data "$section_file" '.[$section] = $data[0]' \
        "$report_file" > "$temp_file"; then
        mv "$temp_file" "$report_file"
        return 0
    fi

    rm -f "$temp_file"
    return 1
}

init_analysis_report() {
    local report_file="$1"
    local apk_file="$2"
    jq -n \
        --arg name "$TOOL_NAME" \
        --arg version "$VERSION" \
        --arg date "$(date -Iseconds)" \
        --arg apk "$apk_file" \
        '{
          schema_version: 2,
          tool_info: {name: $name, version: $version, analysis_date: $date, apk_file: $apk},
          basic_info: null,
          certificate_analysis: null,
          permission_analysis: null,
          security_analysis: null,
          vulnerability_scan: null,
          code_analysis: null
        }' > "$report_file"
}

extract_basic_info() {
    local apk_file="$1"
    local report_file="$2"
    local section_file
    section_file="$(mktemp)"

    if ! python3 - "$apk_file" > "$section_file" <<'PY'
import json, re, subprocess, sys
apk = sys.argv[1]
result = subprocess.run(["aapt", "dump", "badging", apk], capture_output=True, text=True)
if result.returncode != 0:
    raise SystemExit(result.returncode or 1)
out = result.stdout

def one(pattern):
    match = re.search(pattern, out)
    return match.group(1) if match else None

print(json.dumps({
    "package_name": one(r"package:\s+name='([^']+)'"),
    "version_name": one(r"versionName='([^']*)'"),
    "version_code": one(r"versionCode='([^']*)'"),
    "min_sdk": one(r"sdkVersion:'([^']+)'"),
    "target_sdk": one(r"targetSdkVersion:'([^']+)'"),
    "launchable_activity": one(r"launchable-activity:\s+name='([^']+)'"),
}))
PY
    then
        rm -f "$section_file"
        log ERROR "aapt could not read APK metadata"
        return 1
    fi

    merge_json_section "$report_file" basic_info "$section_file"
    rm -f "$section_file"
}

analyze_permissions() {
    local apk_file="$1"
    local report_file="$2"
    local section_file
    section_file="$(mktemp)"

    if ! python3 - "$apk_file" > "$section_file" <<'PY'
import json, re, subprocess, sys
apk = sys.argv[1]
result = subprocess.run(["aapt", "dump", "permissions", apk], capture_output=True, text=True)
if result.returncode != 0:
    raise SystemExit(result.returncode or 1)
permissions = sorted(set(re.findall(r"uses-permission:\s+name=['\"]([^'\"]+)['\"]", result.stdout)))
dangerous_set = {
    "android.permission.READ_CONTACTS", "android.permission.WRITE_CONTACTS",
    "android.permission.READ_CALENDAR", "android.permission.WRITE_CALENDAR",
    "android.permission.CAMERA", "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION", "android.permission.RECORD_AUDIO",
    "android.permission.READ_PHONE_STATE", "android.permission.CALL_PHONE",
    "android.permission.READ_SMS", "android.permission.SEND_SMS", "android.permission.RECEIVE_SMS",
}
dangerous = [p for p in permissions if p in dangerous_set]
print(json.dumps({
    "total": len(permissions),
    "dangerous_count": len(dangerous),
    "dangerous": dangerous,
    "all": permissions,
    "note": "Permission sensitivity is contextual; this list is not a vulnerability verdict."
}))
PY
    then
        rm -f "$section_file"
        log ERROR "aapt could not read APK permissions"
        return 1
    fi

    merge_json_section "$report_file" permission_analysis "$section_file"
    rm -f "$section_file"
}

analyze_certificates() {
    local apk_file="$1"
    local report_file="$2"
    local section_file
    section_file="$(mktemp)"

    python3 - "$apk_file" > "$section_file" <<'PY'
import json, shutil, subprocess, sys, tempfile, zipfile
from pathlib import Path

apk = Path(sys.argv[1])
result = {"status": "not_checked", "verification": None, "certificates": [], "notes": []}

apksigner = shutil.which("apksigner")
if apksigner:
    proc = subprocess.run([apksigner, "verify", "--verbose", "--print-certs", str(apk)], capture_output=True, text=True)
    result["verification"] = "verified" if proc.returncode == 0 else "failed"
    result["status"] = "checked_with_apksigner"
    interesting = []
    for line in (proc.stdout + "\n" + proc.stderr).splitlines():
        stripped = line.strip()
        if stripped.startswith("Signer #") or stripped.startswith("Verified using") or stripped.startswith("Number of signers"):
            interesting.append(stripped)
    result["certificates"] = interesting[:50]
else:
    try:
        with zipfile.ZipFile(apk) as archive:
            signature_files = [n for n in archive.namelist() if n.upper().startswith("META-INF/") and n.upper().endswith((".RSA", ".DSA", ".EC"))]
            if signature_files and shutil.which("keytool"):
                with tempfile.TemporaryDirectory(prefix="apk-cert-") as tmp:
                    target = Path(tmp) / "signer.bin"
                    target.write_bytes(archive.read(signature_files[0]))
                    proc = subprocess.run(["keytool", "-printcert", "-file", str(target)], capture_output=True, text=True)
                    result["status"] = "checked_v1_certificate"
                    result["verification"] = "certificate_read" if proc.returncode == 0 else "certificate_unreadable"
                    result["certificates"] = [line.strip() for line in proc.stdout.splitlines() if line.strip()][:50]
            else:
                result["notes"].append("No v1 certificate block was available; install apksigner to verify APK Signature Scheme v2/v3/v4 signatures.")
    except (OSError, zipfile.BadZipFile) as exc:
        result["notes"].append(f"Certificate inspection failed: {exc}")

print(json.dumps(result))
PY

    merge_json_section "$report_file" certificate_analysis "$section_file"
    rm -f "$section_file"
}

analyze_code_structure() {
    local apk_file="$1"
    local report_file="$2"
    local section_file
    section_file="$(mktemp)"

    if ! python3 - "$apk_file" > "$section_file" <<'PY'
import json, re, sys, zipfile
from pathlib import Path
apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    infos = archive.infolist()
    dex = [i for i in infos if re.search(r"(?:^|/)classes\d*\.dex$", i.filename.lower())]
    native = [i for i in infos if i.filename.lower().endswith(".so") and "/lib/" in f"/{i.filename.lower()}"]
    assets = [i for i in infos if i.filename.startswith("assets/") and not i.is_dir()]
    resources = [i for i in infos if i.filename.startswith("res/") and not i.is_dir()]
    print(json.dumps({
        "archive_entries": len(infos),
        "dex_files": len(dex),
        "dex_bytes": sum(i.file_size for i in dex),
        "native_libraries": len(native),
        "native_library_abis": sorted({i.filename.split('/')[1] for i in native if len(i.filename.split('/')) > 2}),
        "asset_files": len(assets),
        "resource_files": len(resources),
        "note": "These are measured package-structure metrics; no class/method counts are inferred without a DEX parser."
    }))
PY
    then
        rm -f "$section_file"
        log ERROR "Unable to inspect APK archive structure"
        return 1
    fi

    merge_json_section "$report_file" code_analysis "$section_file"
    rm -f "$section_file"
}

set_vulnerability_summary() {
    local report_file="$1"
    local temp_file
    temp_file="$(mktemp)"

    if jq '
      if .owasp_results then
        .vulnerability_scan = {
          engine: .owasp_results.engine,
          status: .owasp_results.scan_status,
          finding_count: (.owasp_results.summary.total_findings // 0),
          review_priority_score: (.owasp_results.summary.review_priority_score // 0),
          note: "See owasp_results.findings for evidence and confidence."
        }
      else
        .vulnerability_scan = {
          status: "not_run",
          finding_count: 0,
          note: "OWASP evidence scan was disabled or failed."
        }
      end' "$report_file" > "$temp_file"; then
        mv "$temp_file" "$report_file"
    else
        rm -f "$temp_file"
        return 1
    fi
}

set_security_summary() {
    local report_file="$1"
    local temp_file
    temp_file="$(mktemp)"
    if jq '
      .security_analysis = {
        owasp_engine: (.owasp_results.engine // null),
        owasp_findings: (.owasp_results.summary.total_findings // null),
        static_risk_engine: (.risk_indicator_results.engine // null),
        static_review_priority: (.risk_indicator_results.review_priority_score // null),
        note: "See the evidence-bearing module results instead of inferred generic security claims."
      }' "$report_file" > "$temp_file"; then
        mv "$temp_file" "$report_file"
    else
        rm -f "$temp_file"
        return 1
    fi
}

analyze_apk() {
    local apk_file="${1:-}"
    if [[ -z "$apk_file" || ! -f "$apk_file" ]]; then
        log ERROR "APK file not found: ${apk_file:-<missing>}"
        return 1
    fi
    if ! unzip -tq "$apk_file" >/dev/null 2>&1; then
        log ERROR "Input is not a readable APK/ZIP archive: $apk_file"
        return 1
    fi

    local analysis_dir="${apk_file%.apk}_analysis"
    local report_file="$analysis_dir/analysis_report.json"
    mkdir -p "$analysis_dir"
    init_analysis_report "$report_file" "$apk_file" || return 1

    log INFO "Reading package metadata"
    extract_basic_info "$apk_file" "$report_file" || return 1

    if [[ "$ENABLE_CERTIFICATE_ANALYSIS" == "true" ]]; then
        log INFO "Inspecting APK signing metadata"
        analyze_certificates "$apk_file" "$report_file" || return 1
    fi

    if [[ "$ENABLE_PERMISSION_ANALYSIS" == "true" ]]; then
        log INFO "Reading manifest permissions"
        analyze_permissions "$apk_file" "$report_file" || return 1
    fi

    local module_failed=0
    if [[ "$ENABLE_OWASP_SCAN" == "true" ]]; then
        run_owasp_scan "$apk_file" "$report_file" || module_failed=1
    fi
    if [[ "$ENABLE_RISK_SCAN" == "true" ]]; then
        run_risk_scan "$apk_file" "$report_file" || module_failed=1
    fi

    if [[ "$ENABLE_VULNERABILITY_SCAN" == "true" ]]; then
        set_vulnerability_summary "$report_file" || module_failed=1
    fi
    if [[ "$ENABLE_DEEP_ANALYSIS" == "true" ]]; then
        set_security_summary "$report_file" || module_failed=1
    fi
    if [[ "$ENABLE_CODE_ANALYSIS" == "true" ]]; then
        log INFO "Measuring package code structure"
        analyze_code_structure "$apk_file" "$report_file" || module_failed=1
    fi

    if (( module_failed != 0 )); then
        log ERROR "One or more selected analysis modules failed. Partial report: $report_file"
        return 1
    fi

    log SUCCESS "Analysis completed: $report_file"
}

pull_apk() {
    local package="${1:-}"
    if [[ -z "$package" ]]; then
        log ERROR "Package name is required"
        return 1
    fi
    if ! adb get-state >/dev/null 2>&1; then
        log ERROR "No authorized ADB device is connected"
        return 1
    fi

    local paths
    paths="$(adb shell pm path "$package" 2>/dev/null | tr -d '\r' | sed -n 's/^package://p')"
    if [[ -z "$paths" ]]; then
        log ERROR "Package not found on connected device: $package"
        return 1
    fi

    local count
    count="$(printf '%s\n' "$paths" | sed '/^$/d' | wc -l | tr -d ' ')"
    if (( count > 1 )); then
        local output_dir="${package}_split_apks"
        mkdir -p "$output_dir"
        while IFS= read -r remote_path; do
            [[ -z "$remote_path" ]] && continue
            adb pull "$remote_path" "$output_dir/" || return 1
        done <<< "$paths"
        log SUCCESS "Pulled $count split APK files to $output_dir"
        log INFO "Split APKs are preserved separately; this command does not pretend to merge them into a universal APK."
        return 0
    fi

    local remote_path="$paths"
    local output_name="${package}.apk"
    adb pull "$remote_path" "$output_name" || return 1
    log SUCCESS "Pulled APK to $output_name"
}

show_help() {
    cat <<EOF
$TOOL_NAME v$VERSION

USAGE
  $0 analyze <apk_file>
  $0 pull <package_name>
  $0 help

COMMANDS
  analyze   Produce an evidence-based JSON report containing package metadata,
            signing metadata when verifiable, permissions, OWASP-aligned static
            findings, static risk indicators, and measured package structure.
  pull      Pull a single APK or all split APK files from an authorized ADB device.
  help      Show this help.

NOTES
  Static analysis does not prove that an APK is safe or malicious.
  Only inspect applications you are authorized to analyze.
EOF
}

main() {
    local command_name="${1:-help}"
    case "$command_name" in
        analyze)
            init_environment analyze || exit 1
            print_banner
            shift
            analyze_apk "$@"
            ;;
        pull)
            init_environment pull || exit 1
            print_banner
            shift
            pull_apk "$@"
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log ERROR "Unknown command: $command_name"
            show_help
            return 2
            ;;
    esac
}

main "$@"
