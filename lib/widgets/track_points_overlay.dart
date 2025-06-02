import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/overlay_provider.dart';
import '../models/track_point.dart';

class TrackPointsOverlay extends StatefulWidget {
  const TrackPointsOverlay({super.key});

  @override
  State<TrackPointsOverlay> createState() => _TrackPointsOverlayState();
}

class _TrackPointsOverlayState extends State<TrackPointsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<VideoProvider, TrackingProvider, OverlayProvider>(
      builder: (context, videoProvider, trackingProvider, overlayProvider, child) {
        if (!videoProvider.hasVideo) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTapDown: (details) => _handleTap(details, trackingProvider, overlayProvider, videoProvider),
          onPanUpdate: (details) => _handleDrag(details, trackingProvider, videoProvider),
          child: CustomPaint(
            painter: TrackPointsPainter(
              trackPoints: trackingProvider.trackPoints,
              currentFrame: videoProvider.currentFrame,
              selectedTrackPoint: trackingProvider.selectedTrackPoint,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  void _handleTap(TapDownDetails details, TrackingProvider trackingProvider, 
                  OverlayProvider overlayProvider, VideoProvider videoProvider) {
    final localPosition = details.localPosition;
    final currentFrame = videoProvider.currentFrame;
    
    // Check if tapping on existing track point
    final tappedPoint = trackingProvider.getTrackPointAt(localPosition, currentFrame);
    
    if (tappedPoint != null) {
      // Select the track point
      trackingProvider.selectTrackPoint(tappedPoint.id);
      
      // Show overlay options if track point is selected
      _showOverlayOptions(context, tappedPoint.id, overlayProvider);
    } else {
      // Add new track point
      trackingProvider.addTrackPoint(localPosition, frameIndex: currentFrame);
    }
  }

  void _handleDrag(DragUpdateDetails details, TrackingProvider trackingProvider, VideoProvider videoProvider) {
    final selectedPoint = trackingProvider.selectedTrackPoint;
    if (selectedPoint != null) {
      final currentFrame = videoProvider.currentFrame;
      trackingProvider.updateTrackPointPosition(
        selectedPoint.id,
        currentFrame,
        details.localPosition,
      );
    }
  }

  void _showOverlayOptions(BuildContext context, String trackPointId, OverlayProvider overlayProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Overlay',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Overlay type options
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _OverlayOptionCard(
                  icon: Icons.image,
                  label: 'Image',
                  onTap: () {
                    Navigator.pop(context);
                    _addImageOverlay(context, trackPointId, overlayProvider);
                  },
                ),
                _OverlayOptionCard(
                  icon: Icons.emoji_emotions,
                  label: 'Emoji',
                  onTap: () {
                    Navigator.pop(context);
                    _addEmojiOverlay(context, trackPointId, overlayProvider);
                  },
                ),
                _OverlayOptionCard(
                  icon: Icons.text_fields,
                  label: 'Text',
                  onTap: () {
                    Navigator.pop(context);
                    _addTextOverlay(context, trackPointId, overlayProvider);
                  },
                ),
                _OverlayOptionCard(
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _addVideoOverlay(context, trackPointId, overlayProvider);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _addImageOverlay(BuildContext context, String trackPointId, OverlayProvider overlayProvider) {
    // Implementation would show image picker
    // For now, just add a placeholder
    overlayProvider.createImageOverlay('placeholder_image.png', trackPointId);
  }

  void _addEmojiOverlay(BuildContext context, String trackPointId, OverlayProvider overlayProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Emoji'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.count(
            crossAxisCount: 6,
            children: ['😀', '😂', '😍', '🤔', '😎', '🥳', '🔥', '💯', '👍', '❤️', '⭐', '🎉']
                .map((emoji) => GestureDetector(
                  onTap: () {
                    overlayProvider.createEmojiOverlay(emoji, trackPointId);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _addTextOverlay(BuildContext context, String trackPointId, OverlayProvider overlayProvider) {
    String text = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Text'),
        content: TextField(
          onChanged: (value) => text = value,
          decoration: const InputDecoration(
            hintText: 'Enter text...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (text.isNotEmpty) {
                overlayProvider.createTextOverlay(text, trackPointId);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addVideoOverlay(BuildContext context, String trackPointId, OverlayProvider overlayProvider) {
    // Implementation would show video picker
    // For now, just add a placeholder
    overlayProvider.createVideoOverlay('placeholder_video.mp4', trackPointId);
  }
}

class _OverlayOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OverlayOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackPointsPainter extends CustomPainter {
  final List<TrackPoint> trackPoints;
  final int currentFrame;
  final TrackPoint? selectedTrackPoint;

  TrackPointsPainter({
    required this.trackPoints,
    required this.currentFrame,
    this.selectedTrackPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final trackPoint in trackPoints) {
      _paintTrackPoint(canvas, trackPoint, size);
    }
  }

  void _paintTrackPoint(Canvas canvas, TrackPoint trackPoint, Size size) {
    final position = trackPoint.getPositionAtFrame(currentFrame);
    if (position == null) return;

    final isSelected = trackPoint.id == selectedTrackPoint?.id;
    final paint = Paint()
      ..color = isSelected ? Colors.yellow : trackPoint.color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw track point
    canvas.drawCircle(position, isSelected ? 8 : 6, paint);
    canvas.drawCircle(position, isSelected ? 8 : 6, strokePaint);

    // Draw track path (last 10 frames)
    if (trackPoint.positions.length > 1) {
      _paintTrackPath(canvas, trackPoint);
    }

    // Draw track point ID
    if (isSelected) {
      _paintTrackPointLabel(canvas, trackPoint, position);
    }
  }

  void _paintTrackPath(Canvas canvas, TrackPoint trackPoint) {
    final pathPaint = Paint()
      ..color = trackPoint.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool isFirst = true;

    // Draw path for last 10 frames
    final startFrame = (currentFrame - 10).clamp(0, trackPoint.positions.length);
    for (int i = startFrame; i <= currentFrame && i < trackPoint.positions.length; i++) {
      final pos = trackPoint.positions[i];
      if (isFirst) {
        path.moveTo(pos.dx, pos.dy);
        isFirst = false;
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }

    canvas.drawPath(path, pathPaint);
  }

  void _paintTrackPointLabel(Canvas canvas, TrackPoint trackPoint, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Track ${trackPoint.id.substring(0, 8)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final labelOffset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - 25,
    );

    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelOffset.dx - 4,
          labelOffset.dy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(4),
      ),
      backgroundPaint,
    );

    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(TrackPointsPainter oldDelegate) {
    return oldDelegate.trackPoints != trackPoints ||
           oldDelegate.currentFrame != currentFrame ||
           oldDelegate.selectedTrackPoint != selectedTrackPoint;
  }
}

