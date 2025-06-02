# Motion Tracker App 🎯

An AI-powered mobile application that mimics After Effects' motion tracking capabilities, built with Flutter and OpenCV. Track objects in videos and attach dynamic overlays that follow the motion.

## ✨ Features

### 🎥 Video Processing
- **Import & Record**: Load videos from gallery or record new ones
- **Frame-by-frame Navigation**: Precise timeline control with zoom
- **Multiple Format Support**: MP4, MOV, AVI import and export

### 🎯 Motion Tracking
- **Auto Feature Detection**: AI-powered detection of trackable points using OpenCV
- **Manual Point Addition**: Tap to add custom tracking points
- **Optical Flow Tracking**: Real-time Lucas-Kanade optical flow tracking
- **Path Smoothing**: Intelligent smoothing algorithms for stable tracking

### 🎨 Dynamic Overlays
- **Multiple Overlay Types**: Images, videos, emojis, and text
- **Transform Controls**: Scale, rotation, position, and opacity
- **Anchor Points**: Precise positioning relative to tracked objects
- **Timeline Management**: Frame-accurate overlay timing

### 🚀 AI Enhancement
- **Smart Object Detection**: Optional MediaPipe/TensorFlow Lite integration
- **Adaptive Tracking**: AI-assisted tracking adjustment
- **Feature Quality Assessment**: Automatic tracking point validation

### 📱 Export & Sharing
- **High-Quality Export**: Multiple resolution options (SD, HD, FHD, Original)
- **Format Options**: MP4, MOV, AVI with customizable bitrates
- **Audio Preservation**: Optional audio track inclusion
- **Progress Monitoring**: Real-time export progress tracking

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.10+** - Cross-platform UI framework
- **Provider** - State management
- **Video Player** - Video playback and control

### Computer Vision
- **OpenCV 4.x** - Feature detection and optical flow tracking
- **FFmpeg** - Video processing and export
- **MediaPipe** (Optional) - Enhanced object detection
- **TensorFlow Lite** (Optional) - On-device AI inference

### Native Integration
- **Platform Channels** - Flutter-native communication
- **Android NDK** - Native OpenCV integration
- **iOS Metal** - GPU-accelerated processing

## 📋 Prerequisites

### Development Environment
- Flutter SDK 3.10 or higher
- Android Studio / Xcode
- OpenCV Android/iOS SDK
- FFmpeg mobile libraries

### Device Requirements
- **Android**: API level 21+ (Android 5.0)
- **iOS**: iOS 11.0+
- **RAM**: 4GB+ recommended
- **Storage**: 2GB+ free space for processing

## 🚀 Installation

### 1. Clone Repository
```bash
git clone https://github.com/your-username/motion-tracker-app.git
cd motion-tracker-app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup OpenCV

#### Android
1. Download OpenCV Android SDK
2. Extract to `android/opencv/`
3. Add to `android/settings.gradle`:
```gradle
include ':opencv'
project(':opencv').projectDir = new File('opencv/sdk')
```

#### iOS
1. Download OpenCV iOS framework
2. Add to `ios/Frameworks/`
3. Configure in Xcode project

### 4. Configure FFmpeg
```bash
# Android
flutter pub add ffmpeg_kit_flutter

# iOS - Additional setup required
```

### 5. Run Application
```bash
flutter run
```

## 📖 Usage Guide

### 1. Import Video
- Tap "Import Video" to select from gallery
- Or tap "Record Video" to capture new footage
- Supported formats: MP4, MOV, AVI

### 2. Auto-Detect Features
- Tap "Auto Detect" to find trackable points
- Adjust detection settings in Control Panel:
  - **Max Features**: Number of points to detect (10-200)
  - **Quality Level**: Feature detection threshold (0.001-0.1)
  - **Min Distance**: Minimum distance between points (5-50px)

### 3. Manual Tracking
- Tap anywhere on video to add custom track points
- Drag points to adjust position
- Select points to attach overlays

### 4. Add Overlays
- Select a track point
- Choose overlay type: Image, Emoji, Text, or Video
- Customize properties:
  - **Scale**: 0.1x to 3.0x
  - **Rotation**: 0° to 360°
  - **Opacity**: 0% to 100%
  - **Anchor**: Position relative to track point

### 5. Timeline Control
- Use timeline scrubber for frame navigation
- Zoom in/out for precise editing
- Play/pause for real-time preview

### 6. Export Video
- Tap "Export" when ready
- Choose quality: SD, HD, FHD, or Original
- Select format: MP4, MOV, AVI
- Monitor export progress
- Share or save to gallery

## ⚙️ Configuration

### Tracking Settings
```dart
// Auto-detection parameters
maxFeatures: 50,           // Maximum trackable points
qualityLevel: 0.01,        // Feature detection threshold
minDistance: 10.0,         // Minimum distance between features

// Tracking parameters
smoothingEnabled: true,    // Enable path smoothing
smoothingSigma: 1.0,      // Smoothing strength
```

### Export Settings
```dart
// Quality presets
'SD': {'width': 854, 'height': 480, 'bitrate': '1M'},
'HD': {'width': 1280, 'height': 720, 'bitrate': '2.5M'},
'FHD': {'width': 1920, 'height': 1080, 'bitrate': '5M'},
'Original': {'width': -1, 'height': -1, 'bitrate': '8M'},
```

## 🔧 Advanced Features

### Custom AI Models
Integrate your own TensorFlow Lite models:

```dart
// Add to pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.4

// Load custom model
final interpreter = await Interpreter.fromAsset('model.tflite');
```

### Cloud Processing
Optional server-side processing for heavy computations:

```dart
// Configure cloud endpoint
const String cloudEndpoint = 'https://your-api.com/process';

// Upload for processing
final result = await CloudProcessor.processVideo(videoFile);
```

## 🎯 Performance Optimization

### Memory Management
- Automatic frame caching with LRU eviction
- Efficient bitmap recycling
- Background processing for heavy operations

### GPU Acceleration
- OpenCV GPU modules for supported devices
- Metal Performance Shaders on iOS
- Vulkan API support on Android

### Battery Optimization
- Adaptive processing based on battery level
- Background processing limitations
- Thermal throttling awareness

## 🐛 Troubleshooting

### Common Issues

#### OpenCV Not Loading
```bash
# Check OpenCV installation
flutter clean
flutter pub get
# Rebuild native modules
```

#### Export Failures
```bash
# Verify FFmpeg installation
flutter pub deps
# Check device storage space
# Reduce export quality if needed
```

#### Tracking Accuracy
- Ensure good lighting conditions
- Use high-contrast objects for tracking
- Avoid rapid camera movements
- Enable smoothing for better results

### Performance Issues
- Close other apps to free memory
- Reduce video resolution for processing
- Lower tracking point count
- Use hardware acceleration when available

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

### Code Style
- Follow [Flutter Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable names
- Add comments for complex algorithms
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OpenCV Community** - Computer vision algorithms
- **Flutter Team** - Cross-platform framework
- **FFmpeg Project** - Video processing capabilities
- **MediaPipe Team** - AI-powered tracking solutions

## 📞 Support

- **Documentation**: [Wiki](https://github.com/your-username/motion-tracker-app/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-username/motion-tracker-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/motion-tracker-app/discussions)
- **Email**: support@motiontracker.app

## 🗺️ Roadmap

### Version 2.0
- [ ] Real-time tracking during recording
- [ ] 3D object tracking
- [ ] Advanced AI models (YOLO, DeepSORT)
- [ ] Collaborative editing
- [ ] Cloud sync and backup

### Version 2.1
- [ ] AR overlay preview
- [ ] Batch processing
- [ ] Plugin system for custom effects
- [ ] Professional export options

---

**Built with ❤️ using Flutter and OpenCV**

*Transform your videos with AI-powered motion tracking!* 🚀

