import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../models/track_point.dart';
import '../models/overlay_item.dart';

class VideoExportConfig {
  final String inputVideoPath;
  final String outputPath;
  final String quality;
  final String format;
  final int frameRate;
  final bool includeAudio;
  final List<TrackPoint> trackPoints;
  final List<OverlayItem> overlays;

  VideoExportConfig({
    required this.inputVideoPath,
    required this.outputPath,
    required this.quality,
    required this.format,
    required this.frameRate,
    required this.includeAudio,
    required this.trackPoints,
    required this.overlays,
  });
}

class VideoExportService {
  static const Map<String, Map<String, dynamic>> _qualitySettings = {
    'SD': {'width': 854, 'height': 480, 'bitrate': '1M'},
    'HD': {'width': 1280, 'height': 720, 'bitrate': '2.5M'},
    'FHD': {'width': 1920, 'height': 1080, 'bitrate': '5M'},
    'Original': {'width': -1, 'height': -1, 'bitrate': '8M'},
  };

  Future<void> exportVideo({
    required VideoExportConfig config,
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      onProgress(0.1, 'Analyzing video...');
      
      // Get video information
      final videoInfo = await _getVideoInfo(config.inputVideoPath);
      if (videoInfo == null) {
        throw Exception('Failed to analyze input video');
      }
      
      onProgress(0.2, 'Preparing overlays...');
      
      // Generate overlay frames if there are overlays
      String? overlayVideoPath;
      if (config.overlays.isNotEmpty) {
        overlayVideoPath = await _generateOverlayVideo(
          config,
          videoInfo,
          (progress) => onProgress(0.2 + (progress * 0.4), 'Rendering overlays...'),
        );
      }
      
      onProgress(0.6, 'Compositing video...');
      
      // Composite final video
      await _compositeVideo(
        config,
        videoInfo,
        overlayVideoPath,
        (progress) => onProgress(0.6 + (progress * 0.4), 'Finalizing export...'),
      );
      
      onProgress(1.0, 'Export complete!');
      
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _getVideoInfo(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -f null -'
      );
      
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        // Parse video information from FFmpeg output
        // This is a simplified version - real implementation would parse the actual output
        return {
          'width': 1920,
          'height': 1080,
          'duration': 10.0,
          'frameRate': 30.0,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }

  Future<String?> _generateOverlayVideo(
    VideoExportConfig config,
    Map<String, dynamic> videoInfo,
    Function(double) onProgress,
  ) async {
    try {
      final tempDir = Directory.systemTemp;
      final overlayVideoPath = '${tempDir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // Create overlay frames
      final frameCount = (videoInfo['duration'] * videoInfo['frameRate']).round();
      final overlayFrames = <String>[];
      
      for (int frame = 0; frame < frameCount; frame++) {
        final framePath = await _generateOverlayFrame(
          config.overlays,
          config.trackPoints,
          frame,
          videoInfo['width'],
          videoInfo['height'],
        );
        
        if (framePath != null) {
          overlayFrames.add(framePath);
        }
        
        onProgress(frame / frameCount);
      }
      
      if (overlayFrames.isEmpty) {
        return null;
      }
      
      // Create video from overlay frames
      final framePattern = '${tempDir.path}/overlay_frame_%04d.png';
      final command = '-framerate ${config.frameRate} -i "$framePattern" -c:v libx264 -pix_fmt yuv420p "$overlayVideoPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return overlayVideoPath;
      }
      
      return null;
    } catch (e) {
      print('Error generating overlay video: $e');
      return null;
    }
  }

  Future<String?> _generateOverlayFrame(
    List<OverlayItem> overlays,
    List<TrackPoint> trackPoints,
    int frameIndex,
    int width,
    int height,
  ) async {
    // This would generate a transparent PNG frame with overlays
    // For now, return null to indicate no overlay frame
    // Real implementation would:
    // 1. Create a transparent canvas
    // 2. For each active overlay at this frame:
    //    - Get the track point position
    //    - Apply transforms (scale, rotation, anchor)
    //    - Draw the overlay content (image, text, emoji)
    // 3. Save as PNG
    
    return null;
  }

  Future<void> _compositeVideo(
    VideoExportConfig config,
    Map<String, dynamic> videoInfo,
    String? overlayVideoPath,
    Function(double) onProgress,
  ) async {
    try {
      final qualitySettings = _qualitySettings[config.quality]!;
      
      // Build FFmpeg command
      List<String> commandParts = [];
      
      // Input video
      commandParts.add('-i "${config.inputVideoPath}"');
      
      // Overlay video if exists
      if (overlayVideoPath != null) {
        commandParts.add('-i "$overlayVideoPath"');
      }
      
      // Video filters
      List<String> filters = [];
      
      // Scale filter if not original quality
      if (config.quality != 'Original') {
        filters.add('scale=${qualitySettings['width']}:${qualitySettings['height']}');
      }
      
      // Overlay filter if overlay video exists
      if (overlayVideoPath != null) {
        if (filters.isNotEmpty) {
          filters.add('[0:v]${filters.join(',')}[scaled]');
          filters.add('[scaled][1:v]overlay=0:0[output]');
        } else {
          filters.add('[0:v][1:v]overlay=0:0[output]');
        }
      }
      
      if (filters.isNotEmpty) {
        commandParts.add('-filter_complex "${filters.join(';')}"');
        if (overlayVideoPath != null) {
          commandParts.add('-map "[output]"');
        }
      }
      
      // Audio handling
      if (config.includeAudio) {
        commandParts.add('-c:a aac');
        commandParts.add('-map 0:a?');
      } else {
        commandParts.add('-an');
      }
      
      // Video encoding
      commandParts.add('-c:v libx264');
      commandParts.add('-b:v ${qualitySettings['bitrate']}');
      commandParts.add('-r ${config.frameRate}');
      commandParts.add('-pix_fmt yuv420p');
      
      // Output
      commandParts.add('"${config.outputPath}"');
      
      final command = commandParts.join(' ');
      print('FFmpeg command: $command');
      
      // Execute FFmpeg command
      final session = await FFmpegKit.execute(command);
      
      // Monitor progress (simplified)
      session.getLogsAsString().then((logs) {
        // Parse logs for progress information
        // Real implementation would parse time progress from logs
        onProgress(1.0);
      });
      
      final returnCode = await session.getReturnCode();
      
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getLogsAsString();
        throw Exception('FFmpeg failed: $logs');
      }
      
    } catch (e) {
      throw Exception('Compositing failed: $e');
    }
  }

  // Utility method to create a simple overlay frame for testing
  Future<String?> createTestOverlayFrame(int width, int height, String outputPath) async {
    try {
      // Create a simple test overlay using FFmpeg
      final command = '-f lavfi -i "color=c=black@0.0:size=${width}x$height:d=1" -vf "drawtext=text=\'Test Overlay\':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2" -frames:v 1 "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      }
      
      return null;
    } catch (e) {
      print('Error creating test overlay frame: $e');
      return null;
    }
  }
}

