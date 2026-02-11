#!/bin/bash
# Integration script for OWASP and ML features
# This file is sourced by the main tool to add the new analysis features

# Source OWASP scanner
if [[ -f "apk-tool-features/owasp/owasp_scanner.py" ]]; then
    source