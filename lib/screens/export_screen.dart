import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/video_provider.dart';
import '../providers/tracking_provider.dart';
import '../providers/overlay_provider.dart';
import '../services/video_export_service.dart';
import '../models/overlay_item.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportStatus = '';
  String? _outputPath;
  
  // Export settings
  String _selectedQuality = 'HD';
  String _selectedFormat = 'MP4';
  bool _includeAudio = true;
  int _frameRate = 30;

  final Map<String, Map<String, dynamic>> _qualitySettings = {
    'SD': {'width': 854, 'height': 480, 'bitrate': '1M'},
    'HD': {'width': 1280, 'height': 720, 'bitrate': '2.5M'},
    'FHD': {'width': 1920, 'height': 1080, 'bitrate': '5M'},
    'Original': {'width': -1, 'height': -1, 'bitrate': '8M'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Video'),
        actions: [
          if (_outputPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareVideo,
              tooltip: 'Share Video',
            ),
        ],
      ),
      body: Consumer3<VideoProvider, TrackingProvider, OverlayProvider>(
        builder: (context, videoProvider, trackingProvider, overlayProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export settings
                if (!_isExporting) ...[
                  _buildExportSettings(),
                  const SizedBox(height: 24),
                  _buildProjectSummary(trackingProvider, overlayProvider),
                  const SizedBox(height: 24),
                ],
                
                // Export progress
                if (_isExporting) ...[
                  _buildExportProgress(),
                  const SizedBox(height: 24),
                ],
                
                // Export result
                if (_outputPath != null) ...[
                  _buildExportResult(),
                  const SizedBox(height: 24),
                ],
                
                const Spacer(),
                
                // Action buttons
                _buildActionButtons(videoProvider, trackingProvider, overlayProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExportSettings() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quality selection
            Row(
              children: [
                const Text('Quality:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: _qualitySettings.keys.map((quality) {
                      final settings = _qualitySettings[quality]!;
                      return ButtonSegment<String>(
                        value: quality,
                        label: Text(quality),
                        tooltip: quality == 'Original' 
                          ? 'Keep original resolution'
                          : '${settings['width']}x${settings['height']}',
                      );
                    }).toList(),
                    selected: {_selectedQuality},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedQuality = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Format selection
            Row(
              children: [
                const Text('Format:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFormat,
                  dropdownColor: const Color(0xFF2D2D2D),
                  style: const TextStyle(color: Colors.white),
                  items: ['MP4', 'MOV', 'AVI'].map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(format),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFormat = value;
                      });
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Frame rate
            Row(
              children: [
                const Text('Frame Rate:', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _frameRate.toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 9,
                    label: '${_frameRate} fps',
                    onChanged: (value) {
                      setState(() {
                        _frameRate = value.round();
                      });
                    },
                  ),
                ),
                Text('${_frameRate} fps', style: const TextStyle(color: Colors.white)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Include audio
            SwitchListTile(
              title: const Text('Include Audio', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Keep original audio track', style: TextStyle(color: Colors.grey)),
              value: _includeAudio,
              onChanged: (value) {
                setState(() {
                  _includeAudio = value;
                });
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSummary(TrackingProvider trackingProvider, OverlayProvider overlayProvider) {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _SummaryRow(
              icon: Icons.track_changes,
              label: 'Track Points',
              value: '${trackingProvider.trackPoints.length}',
            ),
            
            _SummaryRow(
              icon: Icons.layers,
              label: 'Overlays',
              value: '${overlayProvider.overlays.length}',
            ),
            
            _SummaryRow(
              icon: Icons.emoji_emotions,
              label: 'Emojis',
              value: '${overlayProvider.overlays.where((o) => o.type == OverlayType.emoji).length}',
            ),
            
            _SummaryRow(
              icon: Icons.text_fields,
              label: 'Text Overlays',
              value: '${overlayProvider.overlays.where((o) => o.type == OverlayType.text).length}',
            ),
            
            _SummaryRow(
              icon: Icons.image,
              label: 'Images',
              value: '${overlayProvider.overlays.where((o) => o.type == OverlayType.image).length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportProgress() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporting Video...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: _exportProgress,
              backgroundColor: Colors.grey[600],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _exportStatus,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${(_exportProgress * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportResult() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Export Complete!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_file, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Output File',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _outputPath!.split('/').last,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open, color: Colors.blue),
                    onPressed: _openFileLocation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(VideoProvider videoProvider, TrackingProvider trackingProvider, OverlayProvider overlayProvider) {
    if (_isExporting) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          child: const Text('Exporting...'),
        ),
      );
    }

    if (_outputPath != null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareVideo,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _startExport(videoProvider, trackingProvider, overlayProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Export Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startExport(videoProvider, trackingProvider, overlayProvider),
        icon: const Icon(Icons.file_download),
        label: const Text('Start Export'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _startExport(VideoProvider videoProvider, TrackingProvider trackingProvider, OverlayProvider overlayProvider) async {
    if (!videoProvider.hasVideo) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStatus = 'Initializing export...';
      _outputPath = null;
    });

    try {
      final exportService = VideoExportService();
      
      // Get output directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/motion_tracker_export_$timestamp.${_selectedFormat.toLowerCase()}';
      
      // Export configuration
      final exportConfig = VideoExportConfig(
        inputVideoPath: videoProvider.videoFile!.path,
        outputPath: outputPath,
        quality: _selectedQuality,
        format: _selectedFormat,
        frameRate: _frameRate,
        includeAudio: _includeAudio,
        trackPoints: trackingProvider.trackPoints,
        overlays: overlayProvider.overlays,
      );
      
      // Start export with progress callback
      await exportService.exportVideo(
        config: exportConfig,
        onProgress: (progress, status) {
          setState(() {
            _exportProgress = progress;
            _exportStatus = status;
          });
        },
      );
      
      setState(() {
        _isExporting = false;
        _outputPath = outputPath;
      });
      
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportStatus = 'Export failed: $e';
      });
      
      _showErrorDialog('Export failed: $e');
    }
  }

  void _shareVideo() {
    if (_outputPath != null) {
      // Implementation would use share_plus package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share functionality would be implemented here')),
      );
    }
  }

  void _openFileLocation() {
    if (_outputPath != null) {
      // Implementation would open file manager
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved to: $_outputPath')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
