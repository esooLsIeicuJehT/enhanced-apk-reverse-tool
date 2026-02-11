# Web Interface User Guide

## Overview

The Enhanced APK Reverse Engineering Tool Web Interface provides a modern, intuitive platform for analyzing Android APKs with real-time feedback and comprehensive reporting.

## Accessing the Web Interface

### Local Deployment
- **URL:** http://localhost:3000
- **Requires:** Docker Compose or manual deployment

### Docker Deployment
```bash
docker-compose up -d
# Access at http://localhost:3000
```

### Production Deployment
Configure your reverse proxy (Nginx, Apache) to point to the web interface service.

---

## Dashboard Overview

The main dashboard provides an at-a-glance view of:

1. **Quick Stats** - Total analyses, completed, running, failed
2. **System Status** - CPU, memory, disk usage
3. **Recent Analyses** - Latest 10 analyses with status
4. **Storage Widget** - Available space and usage
5. **Trend Widget** - Weekly analysis patterns
6. **Quick Actions** - Upload, browse, analyze

---

## Uploading an APK

### Method 1: Drag and Drop
1. Click "Upload APK" or drag APK file to upload area
2. Select analysis options
3. Click "Start Analysis"

### Method 2: File Browser
1. Click "Browse Files" in quick actions
2. Navigate to your APK file
3. Select and upload

### Analysis Options

| Option | Description | Impact |
|--------|-------------|--------|
| Deep Analysis | Complete code and resource analysis | Slower |
| OWASP Scan | Security vulnerability scan | Medium |
| Malware Detection | ML-based malware check | Medium |
| Permission Analysis | Permission review | Fast |
| Certificate Check | Certificate validation | Fast |
| Code Smells | Code quality issues | Medium |

---

## Analysis Results

### Overview Tab

Shows:
- **Security Score** (0-100)
- **Total Vulnerabilities**
- **Critical/High/Medium/Low/Info breakdown**
- Basic APK information

### OWASP Analysis Tab

Displays OWASP Mobile Top 10 results:
- Radar chart visualization
- Detailed vulnerability list
- Severity ratings
- Evidence and recommendations
- Risk assessment

### Malware Detection Tab

Shows:
- **Classification**: SAFE, SUSPICIOUS, LIKELY_MALWARE, MALWARE
- **Confidence Score**: 0-100%
- **Risk Factors**: Detailed breakdown
- **Feature Importance**: ML model insights
- Recommendations

### Permissions Tab

Visualizes:
- Permission distribution by category
- Permission details
- Usage status
- Risk level assessment

### Code Analysis Tab

Provides:
- Total classes and methods
- Obfuscation detection
- Programming language
- Code smells list
- Quality metrics

### Certificates Tab

Shows:
- Issuer information
- Subject details
- Validity period
- Signature algorithm
- Serial number

---

## Interactive Charts

### Security Score Chart
- Doughnut visualization
- Color-coded (green = secure, red = vulnerable)
- Click for details

### Vulnerability Breakdown
- Bar chart by severity
- Shows distribution
- Hover for counts

### OWASP Radar Chart
- 10-axis radar
- Risk assessment per category
- Interactive legend

### Permission Distribution
- Doughnut chart
- By permission type
- Usage statistics

---

## Real-Time Updates

### WebSocket Connection
The web interface uses WebSockets for real-time updates:
- Analysis progress
- Status changes
- Completion notifications
- Error alerts

### Progress Indicators
- Linear progress bars
- Percentage complete
- Estimated time remaining
- Current step

---

## Managing Analyses

### View History
```bash
Dashboard → Recent Analyses
```
Shows:
- Package name
- File name
- Date/time
- Status
- Security score

### Download Results
1. Open analysis result
2. Click "Download Report"
3. Choose format (PDF, JSON, XML)

### Delete Analysis
1. Find analysis in history
2. Click delete icon
3. Confirm deletion

### Share Results
1. Open analysis result
2. Click "Share"
3. Generate shareable link
4. Copy and share

---

## Settings

### API Configuration
- API Endpoint
- WebSocket URL
- Timeout settings

### Notifications
- Enable/disable alerts
- Email notifications
- Browser notifications

### Storage Management
- Clear cache
- View storage usage
- Delete old analyses

### Advanced
- Debug mode
- Developer options
- API keys

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + U` | Upload APK |
| `Ctrl/Cmd + H` | Home/Dashboard |
| `Ctrl/Cmd + A` | Analyses |
| `Ctrl/Cmd + S` | Settings |
| `Esc` | Close modal |
| `F5` | Refresh |

---

## Mobile Experience

The web interface is fully mobile-responsive:

### Features
- Touch-optimized controls
- Swipe gestures
- Mobile navigation
- Offline support (PWA)
- Install as app

### Installing as PWA
1. Open in mobile browser
2. Tap "Add to Home Screen"
3. Install as native app

---

## Troubleshooting

### Upload Fails
1. Check file size (< 1GB)
2. Verify file is valid APK
3. Check network connection
4. Refresh page

### Analysis Stuck
1. Check system status widget
2. Verify API is running
3. Check WebSocket connection
4. Try re-upload

### Charts Not Displaying
1. Check browser console for errors
2. Verify Chart.js loaded
3. Try different browser
4. Clear browser cache

### WebSocket Disconnected
1. Refresh page
2. Check API endpoint
3. Verify firewall settings
4. Check server status

---

## Best Practices

1. **Start with Basic Analysis** - Quick overview first
2. **Use Deep Analysis** - For thorough security review
3. **Review OWASP** - Check mobile security
4. **Check Malware** - Verify app safety
5. **Export Reports** - Save findings
6. **Monitor Storage** - Manage disk space
7. **Use HTTPS** - For production

---

## API Integration

### Upload via API
```bash
curl -X POST http://localhost:8080/api/upload \
  -F "file=@app.apk" \
  -F "options=deep,owasp,malware"
```

### Get Results
```bash
curl http://localhost:8080/api/analysis/{id}
```

### WebSocket Connection
```javascript
const socket = io('http://localhost:8080');
socket.on('analysis-progress', (data) => {
  console.log(data.progress);
});
```

---

## Performance Tips

1. **Enable Caching** - Reduce server load
2. **Use CDN** - For static assets
3. **Monitor Resources** - Check system status
4. **Optimize Images** - Reduce load times
5. **Minify Assets** - Faster downloads
6. **Use HTTPS** - Secure connections
7. **Load Balancing** - Scale horizontally

---

## Security

### Authentication
- API key required (production)
- Session management
- Secure cookies

### Data Protection
- HTTPS encryption
- File validation
- Sanitized uploads
- Secure storage

### Access Control
- Role-based access
- IP restrictions
- Rate limiting
- Audit logs

---

## Getting Help

- [Documentation](README.md)
- [API Reference](API-REFERENCE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [GitHub Issues](https://github.com/esooLsIeicuJehT/enhanced-apk-reverse-tool/issues)

---

## Tips & Tricks

1. **Batch Analysis** - Upload multiple APKs
2. **Compare Results** - Use side-by-side view
3. **Export All** - Bulk download reports
4. **Schedule Analysis** - Use API for automation
5. **Integrate CI/CD** - Automated security checks
6. **Monitor Trends** - Track security over time
7. **Set Alerts** - Get notified of findings

---

## Next Steps

- [API Documentation](API-REFERENCE.md)
- [Android App Guide](ANDROID_APP_GUIDE.md)
- [Docker Deployment](DEPLOYMENT.md)
- [Installation Guide](INSTALLATION.md)