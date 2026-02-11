#!/bin/bash

set -e

# Configuration
VERSION="2.0.0-1"
PACKAGE_NAME="apk-reverse-tool"
BUILD_DIR="build/debian"
OUTPUT_DIR="dist"

echo "Building .deb package for APK Reverse Engineering Tool..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$OUTPUT_DIR"

# Create build directory structure
mkdir -p "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/opt/apk-reverse-tool"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME"
mkdir -p "$BUILD_DIR/etc/apk-reverse-tool"

# Copy control files
cp debian/DEBIAN/control "$BUILD_DIR/DEBIAN/"
cp debian/DEBIAN/postinst "$BUILD_DIR/DEBIAN/"
cp debian/DEBIAN/prerm "$BUILD_DIR/DEBIAN/"
cp debian/DEBIAN/postrm "$BUILD_DIR/DEBIAN/"

# Set permissions for control scripts
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# Copy tool files
cp -r ../apk-reverse-tool.sh "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../api-server "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../apk-tool-features "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../install-dependencies.sh "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../README.md "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../requirements.txt "$BUILD_DIR/opt/apk-reverse-tool/"
cp -r ../CHANGELOG.md "$BUILD_DIR/opt/apk-reverse-tool/"

# Make main script executable
chmod +x "$BUILD_DIR/opt/apk-reverse-tool/apk-reverse-tool.sh"

# Create symlink for CLI access
ln -sf /opt/apk-reverse-tool/apk-reverse-tool.sh "$BUILD_DIR/usr/local/bin/apk-reverse-tool"

# Copy documentation
cp ../README.md "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/README"
cp ../CHANGELOG.md "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/CHANGELOG"
gzip -9 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/README"
gzip -9 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/CHANGELOG"

# Create changelog
cat > "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog.Debian.gz" << EOF
$PACKAGE_NAME ($VERSION) unstable; urgency=medium

  * Initial release
  * Complete APK reverse engineering tool with OWASP analysis
  * ML-based malware detection
  * REST API and WebSocket support
  * Cross-platform support

 -- APK Tool Team <dev@apktool.com>  $(date -R)
EOF

# Create copyright file
cat > "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Enhanced APK Reverse Engineering Tool
Upstream-Contact: dev@apktool.com
Source: https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool

Files: *
Copyright: 2024 APK Tool Team
License: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Calculate installed size
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)
sed -i "s/^Installed-Size:.*/Installed-Size: $INSTALLED_SIZE/" "$BUILD_DIR/DEBIAN/control"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build the package
fakeroot dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_amd64.deb"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "✓ Package built successfully: $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_amd64.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}_amd64.deb"
echo "  sudo apt-get install -f"
echo ""