# Enhanced APK Reverse Engineering Tool - Docker Image
# Multi-stage build for optimal size and security

# Base image with essential dependencies
FROM ubuntu:20.04 as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV ANDROID_HOME=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/33.0.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core utilities
    wget \
    curl \
    unzip \
    zip \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    build-essential \
    git \
    jq \
    tree \
    file \
    hexdump \
    strings \
    lsof \
    # Android tools
    python3-dev \
    libssl-dev \
    libffi-dev \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Stage for Android SDK
FROM base as android-sdk

# Download and install Android SDK
RUN mkdir -p $ANDROID_HOME && \
    cd $ANDROID_HOME && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip && \
    unzip -q commandlinetools-linux-9123335_latest.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ && \
    rm -f commandlinetools-linux-9123335_latest.zip && \
    yes | cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME 'platform-tools' 'build-tools;33.0.1' 'platforms;android-33'

# Stage for analysis tools
FROM android-sdk as tools

# Install apktool
RUN cd /usr/local/bin && \
    wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1.jar && \
    wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1 && \
    chmod +x apktool_2.8.1 && \
    echo '#!/bin/bash\njava -jar /usr/local/bin/apktool_2.8.1.jar "$@"' > apktool && \
    chmod +x apktool

# Install jadx
RUN cd /opt && \
    wget -q https://github.com/skylot/jadx/releases/download/v1.4.7/jadx-1.4.7.zip && \
    unzip -q jadx-1.4.7.zip && \
    rm -f jadx-1.4.7.zip && \
    ln -sf /opt/jadx-1.4.7/bin/jadx /usr/local/bin/jadx && \
    ln -sf /opt/jadx-1.4.7/bin/jadx-gui /usr/local/bin/jadx-gui

# Install Frida tools and gadgets
RUN pip3 install frida-tools && \
    mkdir -p /opt/frida-gadgets && \
    cd /opt/frida-gadgets && \
    wget -q https://github.com/frida/frida/releases/download/v16.0.11/frida-gadget-16.0.11-android-arm.so.xz && \
    wget -q https://github.com/frida/frida/releases/download/v16.0.11/frida-gadget-16.0.11-android-arm64.so.xz && \
    wget -q https://github.com/frida/frida/releases/download/v16.0.11/frida-gadget-16.0.11-android-x86.so.xz && \
    wget -q https://github.com/frida/frida/releases/download/v16.0.11/frida-gadget-16.0.11-android-x86_64.so.xz

# Create utility scripts
RUN mkdir -p /opt/apk-tools/utils && \
    cat > /opt/apk-tools/utils/cert-analyzer.sh << 'EOF' && \
#!/bin/bash
APK_FILE="$1"
if [[ -z "$APK_FILE" ]]; then
    echo "Usage: $0 <apk_file>"
    exit 1
fi
if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi
echo "Analyzing certificate for: $APK_FILE"
echo "=================================="
TEMP_DIR=$(mktemp -d)
unzip -q "$APK_FILE" -d "$TEMP_DIR"
if [[ -f "$TEMP_DIR/META-INF/CERT.RSA" ]]; then
    echo "Certificate Information:"
    keytool -printcert -file "$TEMP_DIR/META-INF/CERT.RSA"
else
    echo "No certificate found in APK"
fi
rm -rf "$TEMP_DIR"
EOF && \
    chmod +x /opt/apk-tools/utils/cert-analyzer.sh

# Create symbolic links for system tools
RUN ln -sf $ANDROID_HOME/platform-tools/adb /usr/local/bin/adb && \
    ln -sf $ANDROID_HOME/build-tools/33.0.1/aapt /usr/local/bin/aapt && \
    ln -sf $ANDROID_HOME/build-tools/33.0.1/apksigner /usr/local/bin/apksigner && \
    ln -sf $ANDROID_HOME/build-tools/33.0.1/zipalign /usr/local/bin/zipalign

# Create application user for security
RUN useradd -m -u 1000 -s /bin/bash apkuser && \
    mkdir -p /home/apkuser/.apk-reverse-tool && \
    chown -R apkuser:apkuser /home/apkuser

# Final stage - minimal runtime image
FROM tools as runtime

# Set working directory
WORKDIR /app

# Copy application files
COPY . /app/
RUN chmod +x /app/apk-reverse-tool.sh && \
    chmod +x /app/install-dependencies.sh && \
    chmod +x /app/demo.sh && \
    chmod +x /app/examples/sample-analysis.sh

# Create directories for application
RUN mkdir -p /app/logs /app/reports /app/backups /app/plugins /app/configs && \
    chown -R apkuser:apkuser /app

# Switch to non-root user
USER apkuser

# Set environment variables for application
ENV APK_REVERSE_TOOL_HOME=/home/apkuser/.apk-reverse-tool
ENV LOG_DIR=/app/logs
ENV REPORT_DIR=/app/reports

# Expose ports for API server
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/apk-reverse-tool.sh --version || exit 1

# Default command - interactive demo
CMD ["/app/demo.sh"]

# Labels for metadata
LABEL maintainer="Enhanced APK Tool Team" \
      version="2.0.0" \
      description="Enhanced Android APK Reverse Engineering Tool" \
      org.opencontainers.image.source="https://github.com/example/apk-reverse-tool" \
      org.opencontainers.image.documentation="https://docs.example.com" \
      org.opencontainers.image.licenses="GPL-3.0"