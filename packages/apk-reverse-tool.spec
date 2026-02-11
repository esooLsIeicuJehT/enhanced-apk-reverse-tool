Name:           apk-reverse-tool
Version:        2.0.0
Release:        1%{?dist}
Summary:        Enhanced APK Reverse Engineering Tool

License:        MIT
URL:            https://github.com esooLsIeicuJehT/enhanced-apk-reverse-tool
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
BuildRequires:  systemd-rpm-macros

Requires:       python3
Requires:       python3-pip
Requires:       openjdk-11-jre
Requires:       adb
Requires:       git
Requires:       wget
Requires:       curl
Requires:       unzip
Requires:       python3-flask
Requires:       python3-flask-cors
Requires:       python3-flask-socketio
Recommends:     jadx
Recommends:     apktool
Recommends:     frida-tools

%description
A comprehensive tool for reverse engineering Android APKs with features:
- Security analysis and vulnerability scanning
- OWASP Mobile Top 10 compliance checking
- Malware detection using machine learning
- Certificate and permission analysis
- Code analysis and decompilation
- Interactive command-line interface
- REST API for remote access
- Real-time WebSocket updates
- Plugin system for extensibility

This tool provides enterprise-grade APK analysis capabilities for security
researchers, penetration testers, and mobile application developers.

%prep
%setup -q

%build
# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install flask flask-cors flask-socketio websocket-client requests pyyaml

%install
# Create installation directories
mkdir -p %{buildroot}%{_datadir}/%{name}
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_localstatedir}/lib/%{name}
mkdir -p %{buildroot}%{_localstatedir}/log/%{name}
mkdir -p %{buildroot}%{_sysconfdir}/%{name}
mkdir -p %{buildroot}%{_docdir}/%{name}

# Copy tool files
cp -r * %{buildroot}%{_datadir}/%{name}/
chmod +x %{buildroot}%{_datadir}/%{name}/apk-reverse-tool.sh

# Create symlink for CLI access
ln -sf %{_datadir}/%{name}/apk-reverse-tool.sh %{buildroot}%{_bindir}/apk-reverse-tool

# Create virtual environment in installation directory
python3 -m venv %{buildroot}%{_datadir}/%{name}/venv

# Create systemd service file
install -D -m 0644 \
    %{SOURCE0} \
    %{buildroot}%{_unitdir}/apk-reverse-tool.service

# Create desktop file
install -D -m 0644 \
    %{SOURCE1} \
    %{buildroot}%{_datadir}/applications/%{name}.desktop

# Copy documentation
install -D -m 0644 \
    README.md \
    %{buildroot}%{_docdir}/%{name}/README.md
install -D -m 0644 \
    CHANGELOG.md \
    %{buildroot}%{_docdir}/%{name}/CHANGELOG.md

# Create configuration files
cat > %{buildroot}%{_sysconfdir}/%{name}/config.json << EOF
{
  "host": "0.0.0.0",
  "port": 8080,
  "max_upload_size": 1073741824,
  "max_analysis_time": 3600,
  "log_level": "INFO"
}
EOF

%post
# Download and install apktool
if [ ! -f "%{_bindir}/apktool.jar" ]; then
    wget -O %{_bindir}/apktool.jar \
        https://github.com/iBotPeaches/Apktool/releases/download/v2.8.1/apktool_2.8.1.jar
    chmod +x %{_bindir}/apktool.jar
fi

# Install Python dependencies
%{_datadir}/%{name}/venv/bin/pip install -r %{_datadir}/%{name}/requirements.txt

# Reload systemd
%systemd_post

# Enable and start service
%systemd_postun_with_restart apk-reverse-tool.service

%preun
%systemd_preun apk-reverse-tool.service

%postun
%systemd_postun

%files
%{_datadir}/%{name}
%{_bindir}/apk-reverse-tool
%{_docdir}/%{name}
%{_unitdir}/apk-reverse-tool.service
%{_datadir}/applications/%{name}.desktop
%{_sysconfdir}/%{name}
%license LICENSE
%doc README.md CHANGELOG.md

%config(noreplace) %{_sysconfdir}/%{name}/config.json

%changelog
* $(date +'%a %b %d %Y') APK Tool Team <dev@apktool.com> - 2.0.0-1
- Initial release
- Complete APK reverse engineering tool with OWASP analysis
- ML-based malware detection
- REST API and WebSocket support
- Cross-platform support