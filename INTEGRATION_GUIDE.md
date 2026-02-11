# Integration Guide: OWASP Scanner and ML Malware Detector

This guide explains how to integrate the OWASP Mobile Top 10 Scanner and ML-based Malware Detector into the main APK Reverse Engineering Tool.

## 📋 Prerequisites

1. **Python 3.7+** required
2. **Required Python packages:**
   ```bash
   pip3 install numpy pandas scikit-learn joblib androguard
   ```

## 🔧 Integration Steps

### Step 1: Add Flags to Main Script

Add these flags to the main script's flag parsing section:

```bash
# OWASP Scanner
ENABLE_OWASP_SCAN="false"
if [[ "$ENABLE_OWASP_SCAN" == "true" ]]; then
    FLAG_OWASP="true"
fi

# ML Malware Detection
ENABLE_MALWARE_DETECTION="false"
if [[ "$ENABLE_MALWARE_DETECTION" == "true" ]]; then
    FLAG_MALWARE_DETECTION="true"
fi
```

### Step 2: Add Flag Parsing

Add to the flag parsing section:

```bash
--owasp)
    ENABLE_OWASP_SCAN="true"
    FLAG_OWASP="true"
    ;;
--malware)
    ENABLE_MALWARE_DETECTION="true"
    FLAG_MALWARE_DETECTION="true"
    ;;
```

### Step 3: Add Functions to Main Script

Add these functions to the main script:

```bash
# Run OWASP vulnerability scanning
run_owasp_scan() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Running OWASP Mobile Top 10 vulnerability scan..."
    
    # Check if scanner exists
    if [[ ! -f "apk-tool-features/owasp/owasp_scanner.py" ]]; then
        log "WARN" "OWASP scanner not found at apk-tool-features/owasp/owasp_scanner.py"
        log "INFO" "Run 'python3 apk-tool-features/owasp/owasp_scanner.py' to check dependencies"
        return 1
    fi
    
    # Run scanner
    local owasp_results=$(python3 apk-tool-features/owasp/owasp_scanner.py "$apk_file" --format json)
    
    # Check if scan succeeded
    if [[ $? -ne 0 ]]; then
        log "ERROR" "OWASP scan failed"
        return 1
    fi
    
    # Parse JSON and update report
    local temp_file=$(mktemp)
    jq --argjson owasp "$owasp_results" '.owasp_scan = $owasp' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "SUCCESS" "OWASP scan completed"
}

# Run ML-based malware detection
run_malware_detection() {
    local apk_file="$1"
    local report_file="$2"
    
    log "INFO" "Running ML-based malware detection..."
    
    # Check if detector exists
    if [[ ! -f "apk-tool-features/ml/malware_detector.py" ]]; then
        log "WARN" "Malware detector not found at apk-tool-features/ml/malware_detector.py"
        log "INFO" "Run 'python3 apk-tool-features/ml/malware_detector.py' to check dependencies"
        return 1
    fi
    
    # Run detector
    local malware_results=$(python3 apk-tool-features/ml/malware_detector.py "$apk_file" --format json)
    
    # Check if detection succeeded
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Malware detection failed"
        return 1
    fi
    
    # Parse JSON and update report
    local temp_file=$(mktemp)
    jq --argjson malware "$malware_results" '.malware_detection = $malware' "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    log "SUCCESS" "Malware detection completed"
}
```

### Step 4: Integrate into analyze_apk()

In the `analyze_apk()` function, add these calls:

```bash
analyze_apk() {
    local apk_file="$1"
    local analysis_options="$2"
    
    # ... existing analysis code ...
    
    # NEW: OWASP vulnerability scanning
    if [[ "$ENABLE_OWASP_SCAN" == "true" ]]; then
        run_owasp_scan "$apk_file" "$report_file"
    fi
    
    # NEW: ML-based malware detection
    if [[ "$ENABLE_MALWARE_DETECTION" == "true" ]]; then
        run_malware_detection "$apk_file" "$report_file"
    fi
    
    # ... remaining code ...
}
```

## 📝 Usage Examples

### Basic Analysis with OWASP Scan

```bash
./apk-reverse-tool.sh analyze --owasp app.apk
```

### Comprehensive Analysis (OWASP + Malware)

```bash
./apk-reverse-tool.sh analyze --owasp --malware --deep-analysis app.apk
```

### Pull and Analyze with Full Scanning

```bash
./apk-reverse-tool.sh pull com.example.app --device-compat
./apk-reverse-tool.sh analyze --owasp --malware --deep-analysis com.example.apk
```

## 📊 Report Structure

The integrated analysis report includes:

```json
{
  "tool_info": {
    "name": "apk-reverse-tool",
    "version": "2.0"
  },
  "basic_info": {
    "package_name": "com.example.app",
    "version": "1.0"
  },
  "owasp_scan": {
    "apk_path": "/path/to/app.apk",
    "timestamp": "2024-02-11T00:00:00",
    "scan_status": "completed",
    "vulnerabilities": [...],
    "summary": {
      "total_vulnerabilities": 5,
      "risk_score": 42,
      "by_severity": {...}
    }
  },
  "malware_detection": {
    "score": 15.5,
    "confidence": 0.85,
    "classification": "SAFE",
    "features": {...},
    "risk_factors": [...]
  },
  "security_analysis": {...}
}
```

## 🔍 Troubleshooting

### Issue: "Python not found"
**Solution:** Install Python 3.7+
```bash
# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# Fedora/RHEL
sudo dnf install python3 python3-pip
```

### Issue: "Module not found"
**Solution:** Install required packages
```bash
pip3 install numpy pandas scikit-learn joblib androguard
```

### Issue: "OWASP scanner failed"
**Solution:** Check dependencies and APK access
```bash
# Verify scanner can run
python3 apk-tool-features/owasp/owasp_scanner.py --help

# Verify APK exists and is readable
ls -la app.apk
```

### Issue: "Malware detector failed"
**Solution:** Check model loading and features
```bash
# Verify detector can run
python3 apk-tool-features/ml/malware_detector.py --help

# If using custom model, verify it exists
ls -la models/malware_model.joblib
```

## ⚙️ Advanced Configuration

### Custom Model Path

If you have a trained model, modify the detector:

```bash
# Use custom model
python3 apk-tool-features/ml/malware_detector.py app.apk --model models/custom.joblib
```

### OWASP Thresholds

Modify the `OWASPScanner` class to adjust thresholds:

```python
# In owasp_scanner.py
# Modify class variables
self.THRESHOLDS = {
    "critical": 90,
    "high": 70,
    "medium": 50,
    "low": 30
}
```

## 📈 Performance Considerations

- **OWASP Scan:** 5-30 seconds depending on APK size
- **Malware Detection:** 2-10 seconds
- **Memory Usage:** 100-500MB
- **Disk Usage:** Minimal (temp files only)

## 🔗 Next Steps

1. **Train Custom Models:** Use the `malware_detector.py` with your dataset
2. **Custom OWASP Rules:** Add custom patterns to `OWASPScanner`
3. **Integration Testing:** Test with your APKs
4. **Performance Tuning:** Optimize for your use case

## 📚 Additional Resources

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Androguard Documentation](https://androguard.readthedocs.io/)
- [Scikit-learn Guide](https://scikit-learn.org/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add integration tests
4. Submit pull request

## 📄 License

This integration follows the same license as the parent project.