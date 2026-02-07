# Android Companion App - APK Reverse Engineering Tool

## 📱 Overview

The Android Companion App is a native Android application that provides a mobile interface to control the Enhanced APK Reverse Engineering Tool running on a Linux system. It enables users to initiate, monitor, and review APK analysis directly from their Android device.

## 🎯 Key Features

### Remote Analysis Control
- **APK Upload**: Upload APK files from Android device to analysis server
- **Analysis Initiation**: Start comprehensive security analysis with custom parameters
- **Real-time Progress**: Live progress tracking and status updates
- **Batch Processing**: Analyze multiple APKs simultaneously

### Mobile Report Viewing
- **Interactive Dashboards**: Mobile-optimized analysis results
- **Security Scores**: Visual risk assessments and ratings
- **Vulnerability Details**: Detailed security findings with recommendations
- **Offline Access**: Download reports for offline viewing

### Device Management
- **Server Connection**: Connect to multiple analysis servers
- **Authentication**: Secure login with session management
- **Settings**: Customizable analysis preferences and notifications
- **History**: Complete analysis history and favorites

## 🏗️ Architecture

### Client-Server Model
```
Android App ←→ REST API ←→ Linux Analysis Tool
     ↓              ↓              ↓
  Mobile UI    Flask/FastAPI   Core Analysis Engine
```

### Communication Protocol
- **REST API**: Standard HTTP/HTTPS communication
- **WebSockets**: Real-time progress updates
- **Authentication**: JWT-based secure sessions
- **File Transfer**: Multipart form uploads

## 📋 Requirements

### Android Requirements
- **Minimum SDK**: Android 7.0 (API level 24)
- **Target SDK**: Android 13 (API level 33)
- **Architecture**: ARM64, ARM, x86, x86_64

### Server Requirements
- **Linux System**: Ubuntu 18.04+ or compatible
- **Analysis Tool**: Enhanced APK Reverse Engineering Tool v2.0+
- **Network**: WiFi or network connectivity to server
- **API Server**: Flask/FastAPI server running

## 🚀 Quick Start

### 1. Setup Analysis Server
```bash
# On your Linux system
cd enhanced-apk-reverse-tool-v2.0
./install-dependencies.sh

# Start the API server
./apk-reverse-tool.sh serve --port 8080 --host 0.0.0.0
```

### 2. Install Android App
```bash
# Build the Android app
cd android-companion
./gradlew assembleDebug

# Install on device
adb install app/build/outputs/apk/debug/app-debug.apk
```

### 3. Connect and Analyze
1. Open the Android app
2. Enter server IP address (e.g., 192.168.1.100:8080)
3. Login or create account
4. Upload APK file
5. Configure analysis options
6. Start analysis and monitor progress
7. Review results on mobile device

## 🛠️ Development Setup

### Prerequisites
- Android Studio 4.2+
- Java 11+
- Android SDK (API levels 24-33)
- Gradle 7.0+

### Build Instructions
```bash
# Clone the project
git clone <repository-url>
cd enhanced-apk-reverse-tool-v2.0/android-companion

# Open in Android Studio
# OR build from command line
./gradlew assembleDebug    # Debug build
./gradlew assembleRelease  # Release build
```

### Project Structure
```
android-companion/
├── app/
│   ├── src/main/
│   │   ├── java/com/apkreverse/
│   │   │   ├── MainActivity.java
│   │   │   ├── api/           # API communication
│   │   │   ├── ui/            # User interface
│   │   │   ├── models/        # Data models
│   │   │   └── utils/         # Utilities
│   │   ├── res/
│   │   │   ├── layout/        # XML layouts
│   │   │   ├── values/        # Strings, colors, etc.
│   │   │   └── drawable/      # Icons and images
│   │   └── AndroidManifest.xml
│   ├── build.gradle
│   └── proguard-rules.pro
├── build.gradle
├── settings.gradle
└── README.md
```

## 📱 UI Components

### Main Dashboard
- **Analysis Queue**: Current and pending analyses
- **Recent Results**: Latest completed analyses
- **Quick Actions**: Upload new APK, view history
- **Server Status**: Connection status and health

### Upload Screen
- **File Picker**: Select APK files from device storage
- **Analysis Options**: Security level, analysis modules
- **Batch Mode**: Select multiple files for batch analysis
- **Progress Bar**: Upload progress with pause/resume

### Analysis Screen
- **Live Progress**: Real-time analysis progress
- **Log Viewer**: Detailed analysis logs
- **Status Updates**: Step-by-step progress indicators
- **Cancel Option**: Stop running analysis

### Results Screen
- **Security Score**: Overall risk assessment
- **Vulnerability List**: Detailed security findings
- **Certificate Info**: APK certificate analysis
- **Permission Analysis**: Permission categorization
- **Export Options**: Save or share reports

## 🔧 Configuration

### Server Connection
```java
// Server configuration
ServerConfig config = new ServerConfig()
    .setHost("192.168.1.100")
    .setPort(8080)
    .setUseSsl(true)
    .setApiKey("your-api-key");
```

### Analysis Preferences
```java
// Analysis settings
AnalysisPreferences prefs = new AnalysisPreferences()
    .setDeepAnalysis(true)
    .setVulnerabilityScan(true)
    .setCertificateAnalysis(true)
    .setPermissionAnalysis(true);
```

## 🔐 Security Features

### Authentication
- **JWT Tokens**: Secure session management
- **Biometric Login**: Fingerprint/face recognition
- **Session Timeout**: Automatic logout after inactivity
- **Encryption**: All network traffic encrypted

### Data Protection
- **Local Encryption**: Sensitive data encrypted on device
- **Secure Storage**: Keystore for API keys and tokens
- **Certificate Pinning**: Prevent MITM attacks
- **App Obfuscation**: Code obfuscation for release builds

## 📊 API Integration

### Authentication Endpoint
```http
POST /api/auth/login
Content-Type: application/json

{
    "username": "user@example.com",
    "password": "securepassword"
}
```

### Upload Endpoint
```http
POST /api/analysis/upload
Content-Type: multipart/form-data
Authorization: Bearer <jwt-token>

file: <apk-file>
options: {
    "deep_analysis": true,
    "vulnerability_scan": true
}
```

### Status Endpoint
```http
GET /api/analysis/{analysis_id}/status
Authorization: Bearer <jwt-token>

{
    "id": "12345",
    "status": "running",
    "progress": 75,
    "current_step": "vulnerability_scanning",
    "estimated_completion": "2024-01-01T12:30:00Z"
}
```

## 🔄 Real-time Updates

### WebSocket Integration
```java
// WebSocket client for real-time updates
WebSocketClient client = new WebSocketClient();
client.connect("ws://192.168.1.100:8080/ws/analysis/12345");

// Handle progress updates
client.onMessage((message) -> {
    ProgressUpdate update = gson.fromJson(message, ProgressUpdate.class);
    updateProgressBar(update.getProgress());
});
```

### Push Notifications
```java
// Notification for analysis completion
NotificationCompat.Builder builder = new NotificationCompat.Builder(context, CHANNEL_ID)
    .setSmallIcon(R.drawable.ic_analysis_complete)
    .setContentTitle("Analysis Complete")
    .setContentText("APK security analysis finished successfully")
    .setAutoCancel(true)
    .setPriority(NotificationCompat.PRIORITY_DEFAULT);
```

## 📈 Performance Optimization

### Background Processing
- **WorkManager**: Background task management
- **Coroutines**: Asynchronous operations
- **Room Database**: Local data caching
- **Glide**: Efficient image loading

### Network Optimization
- **OkHttp**: Efficient HTTP client
- **GZIP Compression**: Reduced data transfer
- **Connection Pooling**: Reused network connections
- **Retry Logic**: Automatic retry on failures

## 🧪 Testing

### Unit Tests
```bash
# Run unit tests
./gradlew test
```

### Instrumentation Tests
```bash
# Run UI tests
./gradlew connectedAndroidTest
```

### Integration Tests
- API communication tests
- File upload/download tests
- Authentication flow tests
- Real-time update tests

## 📦 Deployment

### Debug Build
```bash
./gradlew assembleDebug
```

### Release Build
```bash
./gradlew assembleRelease
```

### Play Store Release
1. Generate signed APK
2. Complete Play Console setup
3. Upload to internal testing
4. Roll out to production

## 🔧 Troubleshooting

### Common Issues

#### Connection Failed
- Check server IP and port
- Verify network connectivity
- Confirm API server is running
- Check firewall settings

#### Upload Failed
- Verify file size limits
- Check available storage
- Ensure stable network connection
- Review server logs

#### Analysis Not Starting
- Verify server has sufficient resources
- Check analysis tool dependencies
- Review API server logs
- Confirm authentication

### Debug Mode
Enable debug logging in the app:
```java
if (BuildConfig.DEBUG) {
    Logging.enableLogging();
}
```

## 📞 Support

For issues and support:
- **Documentation**: Check this README and API docs
- **Issues**: Report on GitHub Issues
- **Email**: support@apk-reverse-tool.com
- **Community**: Join our Discord server

---

**Coming Soon**: Full Android app implementation with complete UI/UX design and production-ready features!