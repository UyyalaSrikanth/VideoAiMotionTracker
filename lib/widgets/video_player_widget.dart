import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_provider.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        if (videoProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (videoProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading video',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  videoProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!videoProvider.hasVideo) {
          return const Center(
            child: Text(
              'No video loaded',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Stack(
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: videoProvider.controller!.value.aspectRatio,
                child: VideoPlayer(videoProvider.controller!),
              ),
            ),
            
            // Video controls overlay
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _VideoControls(),
            ),
            
            // Frame info overlay
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frame: ${videoProvider.currentFrame + 1}/${videoProvider.totalFrames}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Time: ${_formatDuration(videoProvider.position)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Speed indicator
            if (videoProvider.playbackSpeed != 1.0)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${videoProvider.playbackSpeed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMilliseconds = twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
    return '$twoDigitMinutes:$twoDigitSeconds.$twoDigitMilliseconds';
  }
}

class _VideoControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, videoProvider, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              Row(
                children: [
                  Text(
                    _formatDuration(videoProvider.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: videoProvider.position.inMilliseconds.toDouble(),
                      max: videoProvider.duration.inMilliseconds.toDouble(),
                      onChanged: (value) {
                        final newPosition = Duration(milliseconds: value.round());
                        videoProvider.seekToTime(newPosition);
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDuration(videoProvider.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Go to start
                  IconButton(
                    onPressed: videoProvider.goToStart,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    iconSize: 20,
                  ),
                  
                  // Step backward
                  IconButton(
                    onPressed: videoProvider.stepBackward,
                    icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
                    iconSize: 24,
                  ),
                  
                  // Play/Pause
                  IconButton(
                    onPressed: videoProvider.isPlaying ? videoProvider.pause : videoProvider.play,
                    icon: Icon(
                      videoProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                  ),
                  
                  // Step forward
                  IconButton(
                    onPressed: videoProvider.stepForward,
                    icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white),
                    iconSize: 24,
                  ),
                  
                  // Go to end
                  IconButton(
                    onPressed: videoProvider.goToEnd,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    iconSize: 20,
                  ),
                  
                  // Speed control
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed, color: Colors.white, size: 20),
                    onSelected: videoProvider.setPlaybackSpeed,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.25, child: Text('0.25x')),
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(value: 1.0, child: Text('1x')),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      const PopupMenuItem(value: 2.0, child: Text('2x')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}

