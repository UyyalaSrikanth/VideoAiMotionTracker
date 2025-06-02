# Contributing to Motion Tracker App

Thank you for your interest in contributing to the Motion Tracker App! This document provides guidelines and information for contributors.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Android Studio / Xcode
- Git
- Basic knowledge of Flutter, Dart, and computer vision concepts

### Development Setup
1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/motion-tracker-app.git`
3. Install dependencies: `flutter pub get`
4. Set up OpenCV (see README.md)
5. Run the app: `flutter run`

## 📋 How to Contribute

### Reporting Bugs
1. Check existing issues first
2. Use the bug report template
3. Include:
   - Device information
   - Flutter version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots/videos if applicable

### Suggesting Features
1. Check existing feature requests
2. Use the feature request template
3. Describe:
   - Use case and motivation
   - Proposed solution
   - Alternative solutions considered
   - Additional context

### Code Contributions

#### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring

#### Commit Messages
Follow conventional commits:
```
type(scope): description

feat(tracking): add optical flow smoothing
fix(export): resolve memory leak in video processing
docs(readme): update installation instructions
```

#### Pull Request Process
1. Create feature branch from `main`
2. Make your changes
3. Add tests for new functionality
4. Update documentation
5. Ensure all tests pass
6. Submit pull request with:
   - Clear description
   - Screenshots/videos for UI changes
   - Link to related issues

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage
- Aim for >80% code coverage
- Include unit tests for business logic
- Add widget tests for UI components
- Create integration tests for critical flows

### Test Structure
```dart
group('TrackingProvider', () {
  late TrackingProvider provider;
  
  setUp(() {
    provider = TrackingProvider();
  });
  
  test('should add track point', () {
    // Test implementation
  });
});
```

## 📝 Code Style

### Dart/Flutter Guidelines
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` to check code quality
- Format code with `dart format`

### Naming Conventions
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Files: `snake_case.dart`

### Documentation
- Add dartdoc comments for public APIs
- Include code examples for complex functions
- Update README.md for new features

```dart
/// Tracks motion points using optical flow algorithm.
/// 
/// [prevFrame] and [currFrame] should be grayscale images.
/// Returns list of tracked points or null if tracking failed.
/// 
/// Example:
/// ```dart
/// final points = await trackOpticalFlow(prev, curr, points);
/// ```
Future<List<Offset>?> trackOpticalFlow(
  Uint8List prevFrame,
  Uint8List currFrame,
  List<Offset> points,
) async {
  // Implementation
}
```

## 🏗️ Architecture Guidelines

### Project Structure
```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── services/        # Business logic
└── utils/           # Helper functions
```

### State Management
- Use Provider for state management
- Keep providers focused and single-responsibility
- Avoid business logic in widgets

### Error Handling
- Use try-catch for async operations
- Provide meaningful error messages
- Log errors for debugging

```dart
try {
  final result = await heavyOperation();
  return result;
} catch (e) {
  logger.error('Operation failed: $e');
  throw OperationException('Failed to process: ${e.message}');
}
```

## 🔧 Native Development

### Android (Kotlin)
- Follow Android coding standards
- Use coroutines for async operations
- Implement proper error handling

### iOS (Swift)
- Follow Swift style guide
- Use async/await for modern concurrency
- Handle memory management properly

### OpenCV Integration
- Minimize memory allocations
- Release Mat objects properly
- Use appropriate data types

## 📚 Documentation

### Code Documentation
- Document all public APIs
- Include parameter descriptions
- Provide usage examples

### User Documentation
- Update README.md for new features
- Create tutorials for complex workflows
- Maintain changelog

## 🐛 Debugging

### Common Issues
- Memory leaks in video processing
- OpenCV initialization failures
- Platform channel communication errors

### Debugging Tools
- Flutter Inspector for UI debugging
- Observatory for performance profiling
- Native debuggers for platform-specific issues

## 🚀 Performance

### Optimization Guidelines
- Profile before optimizing
- Use appropriate data structures
- Minimize widget rebuilds
- Optimize image processing pipelines

### Memory Management
- Dispose controllers and streams
- Use object pooling for frequent allocations
- Monitor memory usage during video processing

## 📦 Dependencies

### Adding Dependencies
1. Check if dependency is necessary
2. Evaluate alternatives
3. Consider bundle size impact
4. Update documentation

### Version Management
- Use specific version ranges
- Test with latest versions
- Document breaking changes

## 🔒 Security

### Best Practices
- Validate all user inputs
- Sanitize file paths
- Handle permissions properly
- Protect sensitive data

### Privacy
- Minimize data collection
- Respect user privacy settings
- Document data usage

## 📋 Review Process

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] No breaking changes (or properly documented)
- [ ] Performance impact considered
- [ ] Security implications reviewed

### Review Guidelines
- Be constructive and respectful
- Focus on code, not the person
- Suggest improvements with examples
- Approve when ready, request changes when needed

## 🎯 Release Process

### Version Numbering
Follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Release Checklist
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Release notes prepared

## 🤝 Community

### Communication
- Be respectful and inclusive
- Help newcomers
- Share knowledge and experiences
- Follow code of conduct

### Getting Help
- Check documentation first
- Search existing issues
- Ask in discussions
- Provide context when asking questions

## 📞 Contact

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: contributors@motiontracker.app

Thank you for contributing to Motion Tracker App! 🎉

