import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/video_provider.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TrackingProvider, VideoProvider>(
      builder: (context, trackingProvider, videoProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking Controls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Auto-detection settings
              _SectionHeader(title: 'Auto Detection'),
              const SizedBox(height: 12),
              
              SwitchListTile(
                title: const Text('Enable Auto-detect', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Automatically find trackable features', style: TextStyle(color: Colors.grey)),
                value: trackingProvider.autoDetectEnabled,
                onChanged: trackingProvider.setAutoDetectEnabled,
                activeColor: Colors.blue,
              ),
              
              if (trackingProvider.autoDetectEnabled) ...[
                const SizedBox(height: 12),
                _SliderSetting(
                  title: 'Max Features',
                  value: trackingProvider.maxFeatures.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 19,
                  onChanged: (value) => trackingProvider.setMaxFeatures(value.round()),
                  valueFormatter: (value) => value.round().toString(),
                ),
                
                _SliderSetting(
                  title: 'Quality Level',
                  value: trackingProvider.qualityLevel,
                  min: 0.001,
                  max: 0.1,
                  divisions: 99,
                  onChanged: trackingProvider.setQualityLevel,
                  valueFormatter: (value) => value.toStringAsFixed(3),
                ),
                
                _SliderSetting(
                  title: 'Min Distance',
                  value: trackingProvider.minDistance,
                  min: 5.0,
                  max: 50.0,
                  divisions: 45,
                  onChanged: trackingProvider.setMinDistance,
                  valueFormatter: (value) => value.round().toString(),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Tracking settings
              _SectionHeader(title: 'Tracking'),
              const SizedBox(height: 12),
              
              SwitchListTile(
                title: const Text('Smoothing', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Smooth tracking paths', style: TextStyle(color: Colors.grey)),
                value: trackingProvider.smoothingEnabled,
                onChanged: trackingProvider.setSmoothingEnabled,
                activeColor: Colors.blue,
              ),
              
              if (trackingProvider.smoothingEnabled) ...[
                const SizedBox(height: 12),
                _SliderSetting(
                  title: 'Smoothing Strength',
                  value: trackingProvider.smoothingSigma,
                  min: 0.1,
                  max: 5.0,
                  divisions: 49,
                  onChanged: trackingProvider.setSmoothingSigma,
                  valueFormatter: (value) => value.toStringAsFixed(1),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Track points list
              _SectionHeader(title: 'Track Points'),
              const SizedBox(height: 12),
              
              Expanded(
                child: _TrackPointsList(trackingProvider: trackingProvider),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: trackingProvider.isDetecting ? null : () => _detectFeatures(context),
                      icon: trackingProvider.isDetecting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                      label: const Text('Detect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: trackingProvider.trackPoints.isEmpty ? null : () => _clearAll(context),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _detectFeatures(BuildContext context) async {
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

  void _clearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Track Points'),
        content: const Text('Are you sure you want to remove all track points? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TrackingProvider>().clearAllTrackPoints();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double) valueFormatter;

  const _SliderSetting({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              valueFormatter(value),
              style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[600],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TrackPointsList extends StatelessWidget {
  final TrackingProvider trackingProvider;

  const _TrackPointsList({required this.trackingProvider});

  @override
  Widget build(BuildContext context) {
    if (trackingProvider.trackPoints.isEmpty) {
      return const Center(
        child: Text(
          'No track points\nTap on video to add points',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: trackingProvider.trackPoints.length,
      itemBuilder: (context, index) {
        final trackPoint = trackingProvider.trackPoints[index];
        final isSelected = trackPoint.isSelected;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.blue) : null,
          ),
          child: ListTile(
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: trackPoint.color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              'Track ${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              '${trackPoint.positions.length} frames',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.white, size: 18),
                  onPressed: () => trackingProvider.selectTrackPoint(
                    isSelected ? null : trackPoint.id,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _confirmDelete(context, trackPoint.id),
                ),
              ],
            ),
            onTap: () => trackingProvider.selectTrackPoint(
              isSelected ? null : trackPoint.id,
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String trackPointId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Track Point'),
        content: const Text('Are you sure you want to delete this track point?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              trackingProvider.removeTrackPoint(trackPointId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
