import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/track_point.dart';
import '../services/opencv_service.dart';

class TrackingProvider extends ChangeNotifier {
  List<TrackPoint> _trackPoints = [];
  bool _isTracking = false;
  bool _isDetecting = false;
  String? _error;
  
  // Auto-detection settings
  bool _autoDetectEnabled = true;
  int _maxFeatures = 50;
  double _qualityLevel = 0.01;
  double _minDistance = 10.0;
  
  // Tracking settings
  bool _smoothingEnabled = true;
  double _smoothingSigma = 1.0;
  
  // Getters
  List<TrackPoint> get trackPoints => List.unmodifiable(_trackPoints);
  bool get isTracking => _isTracking;
  bool get isDetecting => _isDetecting;
  String? get error => _error;
  bool get autoDetectEnabled => _autoDetectEnabled;
  int get maxFeatures => _maxFeatures;
  double get qualityLevel => _qualityLevel;
  double get minDistance => _minDistance;
  bool get smoothingEnabled => _smoothingEnabled;
  double get smoothingSigma => _smoothingSigma;
  
  TrackPoint? get selectedTrackPoint {
    try {
      return _trackPoints.firstWhere((point) => point.isSelected);
    } catch (e) {
      return null;
    }
  }
  
  // Auto-detect trackable features in current frame
  Future<void> detectFeatures(
    Uint8List frameData,
    int width,
    int height,
  ) async {
    if (_isDetecting) return;
    
    _setDetecting(true);
    _clearError();
    
    try {
      final features = await OpenCVService.detectFeatures(
        frameData,
        width,
        height,
        maxCorners: _maxFeatures,
        qualityLevel: _qualityLevel,
        minDistance: _minDistance,
      );
      
      // Convert detected features to track points
      _trackPoints.clear();
      for (int i = 0; i < features.length; i++) {
        final trackPoint = TrackPoint(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_$i',
          positions: [features[i]],
          color: _generateRandomColor(),
          confidence: 1.0,
        );
        _trackPoints.add(trackPoint);
      }
      
      _setDetecting(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to detect features: $e');
      _setDetecting(false);
    }
  }
  
  // Add manual track point
  void addTrackPoint(Offset position, {int frameIndex = 0}) {
    final trackPoint = TrackPoint(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      positions: List.generate(frameIndex + 1, (i) => i == frameIndex ? position : Offset.zero),
      color: _generateRandomColor(),
      confidence: 1.0,
    );
    
    _trackPoints.add(trackPoint);
    notifyListeners();
  }
  
  // Remove track point
  void removeTrackPoint(String trackPointId) {
    _trackPoints.removeWhere((point) => point.id == trackPointId);
    notifyListeners();
  }
  
  // Select/deselect track point
  void selectTrackPoint(String? trackPointId) {
    for (var point in _trackPoints) {
      point.isSelected = point.id == trackPointId;
    }
    notifyListeners();
  }
  
  // Track all points to next frame
  Future<void> trackToNextFrame(
    Uint8List prevFrameData,
    Uint8List currFrameData,
    int width,
    int height,
  ) async {
    if (_isTracking || _trackPoints.isEmpty) return;
    
    _setTracking(true);
    _clearError();
    
    try {
      // Get current positions of all track points
      List<Offset> currentPositions = [];
      int currentFrame = _trackPoints.first.positions.length - 1;
      
      for (var point in _trackPoints) {
        Offset? pos = point.getPositionAtFrame(currentFrame);
        if (pos != null) {
          currentPositions.add(pos);
        }
      }
      
      if (currentPositions.isNotEmpty) {
        // Track using optical flow
        final trackedPositions = await OpenCVService.trackOpticalFlow(
          prevFrameData,
          currFrameData,
          currentPositions,
          width,
          height,
        );
        
        // Update track points with new positions
        for (int i = 0; i < _trackPoints.length && i < trackedPositions.length; i++) {
          Offset? newPos = trackedPositions[i];
          if (newPos != null) {
            _trackPoints[i].addPosition(newPos);
          } else {
            // Tracking lost, use interpolation or mark as lost
            Offset? lastPos = _trackPoints[i].getPositionAtFrame(currentFrame);
            _trackPoints[i].addPosition(lastPos ?? Offset.zero);
          }
        }
        
        // Apply smoothing if enabled
        if (_smoothingEnabled) {
          await _applySmoothingToAllPoints();
        }
      }
      
      _setTracking(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to track points: $e');
      _setTracking(false);
    }
  }
  
  // Apply smoothing to all track points
  Future<void> _applySmoothingToAllPoints() async {
    for (var point in _trackPoints) {
      if (point.positions.length > 2) {
        final smoothedPositions = await OpenCVService.smoothTrackingPath(
          point.positions,
          sigma: _smoothingSigma,
        );
        point.positions.clear();
        point.positions.addAll(smoothedPositions);
      }
    }
  }
  
  // Update track point position manually
  void updateTrackPointPosition(String trackPointId, int frameIndex, Offset position) {
    final point = _trackPoints.where((p) => p.id == trackPointId).firstOrNull;
    if (point != null) {
      point.updatePosition(frameIndex, position);
      notifyListeners();
    }
  }
  
  // Get track point at specific position
  TrackPoint? getTrackPointAt(Offset position, int frameIndex, {double threshold = 20.0}) {
    for (var point in _trackPoints) {
      Offset? pointPos = point.getPositionAtFrame(frameIndex);
      if (pointPos != null) {
        double distance = (pointPos - position).distance;
        if (distance <= threshold) {
          return point;
        }
      }
    }
    return null;
  }
  
  // Clear all track points
  void clearAllTrackPoints() {
    _trackPoints.clear();
    notifyListeners();
  }
  
  // Settings methods
  void setAutoDetectEnabled(bool enabled) {
    _autoDetectEnabled = enabled;
    notifyListeners();
  }
  
  void setMaxFeatures(int maxFeatures) {
    _maxFeatures = maxFeatures.clamp(10, 200);
    notifyListeners();
  }
  
  void setQualityLevel(double qualityLevel) {
    _qualityLevel = qualityLevel.clamp(0.001, 0.1);
    notifyListeners();
  }
  
  void setMinDistance(double minDistance) {
    _minDistance = minDistance.clamp(5.0, 50.0);
    notifyListeners();
  }
  
  void setSmoothingEnabled(bool enabled) {
    _smoothingEnabled = enabled;
    notifyListeners();
  }
  
  void setSmoothingSigma(double sigma) {
    _smoothingSigma = sigma.clamp(0.1, 5.0);
    notifyListeners();
  }
  
  // Utility methods
  Color _generateRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      100 + random.nextInt(156), // Avoid too dark colors
      100 + random.nextInt(156),
      100 + random.nextInt(156),
    );
  }
  
  void _setTracking(bool tracking) {
    _isTracking = tracking;
    notifyListeners();
  }
  
  void _setDetecting(bool detecting) {
    _isDetecting = detecting;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // Export tracking data
  Map<String, dynamic> exportTrackingData() {
    return {
      'trackPoints': _trackPoints.map((point) => {
        'id': point.id,
        'positions': point.positions.map((pos) => {'x': pos.dx, 'y': pos.dy}).toList(),
        'color': point.color.value,
        'confidence': point.confidence,
      }).toList(),
      'settings': {
        'maxFeatures': _maxFeatures,
        'qualityLevel': _qualityLevel,
        'minDistance': _minDistance,
        'smoothingEnabled': _smoothingEnabled,
        'smoothingSigma': _smoothingSigma,
      },
    };
  }
  
  // Import tracking data
  void importTrackingData(Map<String, dynamic> data) {
    _trackPoints.clear();
    
    if (data['trackPoints'] != null) {
      for (var pointData in data['trackPoints']) {
        List<Offset> positions = [];
        for (var posData in pointData['positions']) {
          positions.add(Offset(posData['x'], posData['y']));
        }
        
        _trackPoints.add(TrackPoint(
          id: pointData['id'],
          positions: positions,
          color: Color(pointData['color']),
          confidence: pointData['confidence'],
        ));
      }
    }
    
    if (data['settings'] != null) {
      var settings = data['settings'];
      _maxFeatures = settings['maxFeatures'] ?? _maxFeatures;
      _qualityLevel = settings['qualityLevel'] ?? _qualityLevel;
      _minDistance = settings['minDistance'] ?? _minDistance;
      _smoothingEnabled = settings['smoothingEnabled'] ?? _smoothingEnabled;
      _smoothingSigma = settings['smoothingSigma'] ?? _smoothingSigma;
    }
    
    notifyListeners();
  }
}

