import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/opencv_service.dart';

class VideoProvider extends ChangeNotifier {
  VideoPlayerController? _controller;
  VideoInfo? _videoInfo;
  File? _videoFile;
  bool _isLoading = false;
  String? _error;
  
  // Playback state
  int _currentFrame = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  
  // Getters
  VideoPlayerController? get controller => _controller;
  VideoInfo? get videoInfo => _videoInfo;
  File? get videoFile => _videoFile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentFrame => _currentFrame;
  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  bool get hasVideo => _controller != null && _controller!.value.isInitialized;
  
  // Video duration and frame info
  Duration get duration => _controller?.value.duration ?? Duration.zero;
  Duration get position => _controller?.value.position ?? Duration.zero;
  int get totalFrames => _videoInfo?.frameCount ?? 0;
  double get frameRate => _videoInfo?.frameRate ?? 30.0;
  
  Future<void> loadVideo(File videoFile) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Dispose previous controller
      await _disposeController();
      
      _videoFile = videoFile;
      
      // Initialize video player
      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      
      // Get video information using OpenCV
      _videoInfo = await OpenCVService.getVideoInfo(videoFile.path);
      
      // Listen to position changes
      _controller!.addListener(_onVideoPositionChanged);
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load video: $e');
      _setLoading(false);
    }
  }
  
  void _onVideoPositionChanged() {
    if (_controller != null && _videoInfo != null) {
      final position = _controller!.value.position;
      final newFrame = (position.inMilliseconds / 1000.0 * frameRate).round();
      
      if (newFrame != _currentFrame) {
        _currentFrame = newFrame.clamp(0, totalFrames - 1);
        notifyListeners();
      }
      
      _isPlaying = _controller!.value.isPlaying;
    }
  }
  
  Future<void> play() async {
    if (_controller != null) {
      await _controller!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }
  
  Future<void> pause() async {
    if (_controller != null) {
      await _controller!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  Future<void> seekToFrame(int frameIndex) async {
    if (_controller != null && _videoInfo != null) {
      final targetFrame = frameIndex.clamp(0, totalFrames - 1);
      final targetTime = Duration(
        milliseconds: (targetFrame / frameRate * 1000).round(),
      );
      
      await _controller!.seekTo(targetTime);
      _currentFrame = targetFrame;
      notifyListeners();
    }
  }
  
  Future<void> seekToTime(Duration time) async {
    if (_controller != null) {
      await _controller!.seekTo(time);
      notifyListeners();
    }
  }
  
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.1, 3.0);
    if (_controller != null) {
      _controller!.setPlaybackSpeed(_playbackSpeed);
    }
    notifyListeners();
  }
  
  Future<void> stepForward() async {
    if (hasVideo) {
      await seekToFrame(_currentFrame + 1);
    }
  }
  
  Future<void> stepBackward() async {
    if (hasVideo) {
      await seekToFrame(_currentFrame - 1);
    }
  }
  
  Future<void> goToStart() async {
    if (hasVideo) {
      await seekToFrame(0);
    }
  }
  
  Future<void> goToEnd() async {
    if (hasVideo) {
      await seekToFrame(totalFrames - 1);
    }
  }
  
  // Get current frame as image data
  Future<void> getCurrentFrameData() async {
    // This would extract the current frame as image data
    // Implementation would depend on the video processing library
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  Future<void> _disposeController() async {
    if (_controller != null) {
      _controller!.removeListener(_onVideoPositionChanged);
      await _controller!.dispose();
      _controller = null;
    }
  }
  
  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}

