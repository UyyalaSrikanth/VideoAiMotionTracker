import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/tracking_provider.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  double _zoomLevel = 1.0;
  ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VideoProvider, TrackingProvider>(
      builder: (context, videoProvider, trackingProvider, child) {
        if (!videoProvider.hasVideo) {
          return Container(
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: Text(
                'No video loaded',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              // Timeline header
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    
                    // Zoom controls
                    IconButton(
                      onPressed: () => _setZoom(_zoomLevel * 0.8),
                      icon: const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                    ),
                    Text(
                      '${(_zoomLevel * 100).round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    IconButton(
                      onPressed: () => _setZoom(_zoomLevel * 1.25),
                      icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Auto-detect button
                    ElevatedButton.icon(
                      onPressed: trackingProvider.isDetecting ? null : _autoDetectFeatures,
                      icon: trackingProvider.isDetecting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Auto Detect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timeline content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: _getTimelineWidth(videoProvider.totalFrames),
                    child: CustomPaint(
                      painter: TimelinePainter(
                        totalFrames: videoProvider.totalFrames,
                        currentFrame: videoProvider.currentFrame,
                        frameRate: videoProvider.frameRate,
                        zoomLevel: _zoomLevel,
                        trackPoints: trackingProvider.trackPoints,
                      ),
                      child: GestureDetector(
                        onTapDown: (details) => _handleTimelineTap(details, videoProvider),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setZoom(double zoom) {
    setState(() {
      _zoomLevel = zoom.clamp(0.1, 5.0);
    });
  }

  double _getTimelineWidth(int totalFrames) {
    return (totalFrames * 4 * _zoomLevel).clamp(400.0, double.infinity);
  }

  void _handleTimelineTap(TapDownDetails details, VideoProvider videoProvider) {
    final totalFrames = videoProvider.totalFrames;
    final timelineWidth = _getTimelineWidth(totalFrames);
    final frameIndex = (details.localPosition.dx / timelineWidth * totalFrames).round();
    
    videoProvider.seekToFrame(frameIndex.clamp(0, totalFrames - 1));
  }

  void _autoDetectFeatures() async {
    final videoProvider = context.read<VideoProvider>();
    final trackingProvider = context.read<TrackingProvider>();
    
    if (!videoProvider.hasVideo) return;
    
    // This would extract current frame data and detect features
    // For now, just simulate the process
    await trackingProvider.detectFeatures(
      // Mock frame data - in real implementation, extract from video
      Uint8List(0),
      videoProvider.videoInfo?.width ?? 1920,
      videoProvider.videoInfo?.height ?? 1080,
    );
  }
}

class TimelinePainter extends CustomPainter {
  final int totalFrames;
  final int currentFrame;
  final double frameRate;
  final double zoomLevel;
  final List trackPoints;

  TimelinePainter({
    required this.totalFrames,
    required this.currentFrame,
    required this.frameRate,
    required this.zoomLevel,
    required this.trackPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintTimelineBackground(canvas, size);
    _paintTimeMarkers(canvas, size);
    _paintCurrentFrameIndicator(canvas, size);
    _paintTrackPointIndicators(canvas, size);
  }

  void _paintTimelineBackground(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFF2A2A2A);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  }

  void _paintTimeMarkers(Canvas canvas, Size size) {
    final markerPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw frame markers
    final frameWidth = size.width / totalFrames;
    for (int i = 0; i < totalFrames; i += (10 / zoomLevel).round().clamp(1, 100)) {
      final x = i * frameWidth;
      
      // Draw marker line
      canvas.drawLine(
        Offset(x, size.height - 20),
        Offset(x, size.height),
        markerPaint,
      );
      
      // Draw time label
      final timeInSeconds = i / frameRate;
      final minutes = (timeInSeconds / 60).floor();
      final seconds = (timeInSeconds % 60).floor();
      final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      
      textPainter.text = TextSpan(
        text: timeText,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 35),
      );
    }
  }

  void _paintCurrentFrameIndicator(Canvas canvas, Size size) {
    final indicatorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    final x = (currentFrame / totalFrames) * size.width;
    
    // Draw current frame line
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      indicatorPaint,
    );
    
    // Draw current frame handle
    final handlePaint = Paint()
      ..color = Colors.red;
    
    canvas.drawCircle(
      Offset(x, 10),
      6,
      handlePaint,
    );
  }

  void _paintTrackPointIndicators(Canvas canvas, Size size) {
    // Draw track point activity indicators
    for (int i = 0; i < trackPoints.length; i++) {
      final trackPoint = trackPoints[i];
      final y = 40 + (i * 8);
      
      if (y > size.height - 20) break; // Don't draw outside timeline
      
      final indicatorPaint = Paint()
        ..color = trackPoint.color.withOpacity(0.7)
        ..strokeWidth = 4;
      
      // Draw track point timeline
      for (int frame = 0; frame < trackPoint.positions.length && frame < totalFrames; frame++) {
        final x = (frame / totalFrames) * size.width;
        canvas.drawCircle(Offset(x, y), 2, indicatorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.totalFrames != totalFrames ||
           oldDelegate.currentFrame != currentFrame ||
           oldDelegate.zoomLevel != zoomLevel ||
           oldDelegate.trackPoints != trackPoints;
  }
}
