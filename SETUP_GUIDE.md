# Women Safety App - Shake to Help Feature

## 🚨 How to Use the Shake-to-Help Feature

1. **Open the app** on your device
2. **Shake your phone 3 times** rapidly
3. The app will automatically:
   - Get your exact high-accuracy location
   - Send an emergency email with your location to the configured recipient
   - Show you a confirmation

## ⚙️ Setup Instructions

### 1. Configure Resend API
Before building the APK, you need to configure the email service:

1. Sign up for [Resend](https://resend.com/) and get your API key
2. Verify your sender email/domain in Resend dashboard
3. Open `lib/services/email_service.dart` and update:
   ```dart
   static const String _resendApiKey = 'YOUR_RESEND_API_KEY_HERE';
   static const String _fromEmail = 'your-verified-email@yourdomain.com';
   static const String _recipientEmail = 'trusted-contact@example.com';
   ```

### 2. Build the APK

Since you don't have Flutter installed locally, use GitHub Actions:

#### Option A: Using GitHub Actions (Recommended)
1. **Push this code to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Add shake-to-help feature"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Go to your GitHub repository** → **Actions** tab
3. The workflow will automatically start building the APK
4. Once complete, **download the APK** from the Artifacts section

#### Option B: Using Online Flutter Compiler
1. Go to [DartPad](https://dartpad.dev/) or [FlutLab](https://flutlab.io/)
2. Create a new Flutter project
3. Copy all files from this project
4. Build the APK from the online IDE

#### Option C: Ask a Friend with Flutter
If you have a friend with Flutter installed:
```bash
cd prjyot
flutter pub get
flutter build apk --release
```
The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Installation
1. Download the APK from GitHub Actions artifacts
2. Transfer to your Android device
3. Enable "Install from Unknown Sources" in Settings
4. Install the APK
5. Grant location permissions when prompted

## 🧪 Testing
1. Open the app
2. Make sure you have internet connection
3. Shake your phone 3 times rapidly
4. Check if you receive a toast notification
5. Check the recipient email for the help alert

## 🔒 Permissions Required
- **Location** (for getting exact coordinates)
- **Internet** (for sending emails via Resend API)
- **Storage** (for app data)

## ⚡ Features
- **Shake Detection**: Detects 3 rapid shakes to trigger alert
- **High-Accuracy Location**: Uses GPS for precise coordinates
- **Email with Maps Link**: Sends clickable Google Maps link
- **Cooldown Period**: 30-second cooldown to prevent accidental alerts
- **Visual Confirmation**: Shows dialog when alert is sent
- **Offline Fallback**: Queues email if internet is temporarily unavailable

## 🛠️ Troubleshooting

### Email Not Sending
- Check Resend API key is correct
- Verify sender email is verified in Resend
- Check internet connection
- Look at app logs for error messages

### Shake Not Detected
- Shake more vigorously (3 rapid shakes)
- Check if app is in foreground
- Restart the app

### Location Not Working
- Enable location services in device settings
- Grant location permission to app
- Ensure GPS is enabled
