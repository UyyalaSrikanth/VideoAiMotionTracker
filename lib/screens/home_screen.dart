import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/video_provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/overlay_provider.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/track_points_overlay.dart';
import '../widgets/control_panel.dart';
import '../widgets/overlay_panel.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _showControlPanel = true;
  bool _showOverlayPanel = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _pickVideo,
            tooltip: 'Import Video',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
          Consumer<VideoProvider>(
            builder: (context, videoProvider, child) {
              return IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: videoProvider.hasVideo ? _exportVideo : null,
                tooltip: 'Export Video',
              );
            },
          ),
        ],
      ),
      body: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (!videoProvider.hasVideo) {
            return _buildWelcomeScreen();
          }
          
          return Column(
            children: [
              // Main video area
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // Video player with overlays
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            VideoPlayerWidget(),
                            TrackPointsOverlay(),
                            // Overlay items would be rendered here
                          ],
                        ),
                      ),
                    ),
                    
                    // Side panels
                    if (_showControlPanel)
                      Container(
                        width: 300,
                        color: const Color(0xFF2D2D2D),
                        child: const ControlPanel(),
                      ),
                    
                    if (_showOverlayPanel)
                      Container(
                        width: 300,
                        color: const Color(0xFF2D2D2D),
                        child: const OverlayPanel(),
                      ),
                  ],
                ),
              ),
              
              // Timeline
              Container(
                height: 120,
                color: const Color(0xFF1E1E1E),
                child: const TimelineWidget(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          if (!videoProvider.hasVideo) return const SizedBox.shrink();
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'overlay_panel',
                onPressed: () {
                  setState(() {
                    _showOverlayPanel = !_showOverlayPanel;
                  });
                },
                backgroundColor: _showOverlayPanel ? Colors.blue : Colors.grey[700],
                child: const Icon(Icons.layers),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'control_panel',
                onPressed: () {
                  setState(() {
                    _showControlPanel = !_showControlPanel;
                  });
                },
                backgroundColor: _showControlPanel ? Colors.blue : Colors.grey[700],
                child: const Icon(Icons.tune),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 120,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Motion Tracker',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Import a video to start tracking motion and adding overlays',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
            label: const Text('Import Video'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _recordVideo,
            icon: const Icon(Icons.videocam),
            label: const Text('Record Video'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await context.read<VideoProvider>().loadVideo(file);
        
        // Clear previous tracking data
        context.read<TrackingProvider>().clearAllTrackPoints();
        context.read<OverlayProvider>().clearAllOverlays();
      }
    } catch (e) {
      _showErrorDialog('Failed to import video: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final file = File(video.path);
        await context.read<VideoProvider>().loadVideo(file);
        
        // Clear previous tracking data
        context.read<TrackingProvider>().clearAllTrackPoints();
        context.read<OverlayProvider>().clearAllOverlays();
      }
    } catch (e) {
      _showErrorDialog('Failed to record video: $e');
    }
  }

  void _exportVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExportScreen(),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Consumer<TrackingProvider>(
          builder: (context, trackingProvider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Auto-detect Features'),
                  value: trackingProvider.autoDetectEnabled,
                  onChanged: trackingProvider.setAutoDetectEnabled,
                ),
                ListTile(
                  title: const Text('Max Features'),
                  subtitle: Slider(
                    value: trackingProvider.maxFeatures.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: trackingProvider.maxFeatures.toString(),
                    onChanged: (value) => trackingProvider.setMaxFeatures(value.round()),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Smoothing'),
                  value: trackingProvider.smoothingEnabled,
                  onChanged: trackingProvider.setSmoothingEnabled,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

