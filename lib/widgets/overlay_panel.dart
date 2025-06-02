import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/overlay_provider.dart';
import '../providers/tracking_provider.dart';
import '../models/overlay_item.dart';

class OverlayPanel extends StatelessWidget {
  const OverlayPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<OverlayProvider, TrackingProvider>(
      builder: (context, overlayProvider, trackingProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.layers, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Overlays',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Selected overlay properties
              if (overlayProvider.selectedOverlay != null) ...[
                _OverlayProperties(overlay: overlayProvider.selectedOverlay!),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
              ],
              
              // Overlays list
              _SectionHeader(title: 'All Overlays'),
              const SizedBox(height: 12),
              
              Expanded(
                child: _OverlaysList(overlayProvider: overlayProvider),
              ),
              
              const SizedBox(height: 16),
              
              // Quick add buttons
              if (trackingProvider.selectedTrackPoint != null) ...[
                _SectionHeader(title: 'Quick Add'),
                const SizedBox(height: 12),
                _QuickAddButtons(
                  trackPointId: trackingProvider.selectedTrackPoint!.id,
                  overlayProvider: overlayProvider,
                ),
              ],
            ],
          ),
        );
      },
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

class _OverlayProperties extends StatelessWidget {
  final OverlayItem overlay;

  const _OverlayProperties({required this.overlay});

  @override
  Widget build(BuildContext context) {
    final overlayProvider = context.watch<OverlayProvider>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Selected Overlay'),
        const SizedBox(height: 12),
        
        // Overlay info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getOverlayIcon(overlay.type), color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _getOverlayTypeName(overlay.type),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Switch(
                    value: overlay.isVisible,
                    onChanged: overlayProvider.updateVisibility,
                    activeColor: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                overlay.content,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Transform controls
        _SliderControl(
          title: 'Scale',
          value: overlay.scale,
          min: 0.1,
          max: 3.0,
          onChanged: overlayProvider.updateScale,
        ),
        
        _SliderControl(
          title: 'Rotation',
          value: overlay.rotation,
          min: -3.14159,
          max: 3.14159,
          onChanged: overlayProvider.updateRotation,
          valueFormatter: (value) => '${(value * 180 / 3.14159).round()}°',
        ),
        
        _SliderControl(
          title: 'Opacity',
          value: overlay.opacity,
          min: 0.0,
          max: 1.0,
          onChanged: overlayProvider.updateOpacity,
          valueFormatter: (value) => '${(value * 100).round()}%',
        ),
        
        // Anchor position
        const SizedBox(height: 12),
        const Text('Anchor Position', style: TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final anchor = Offset(
                (localPosition.dx / 100 - 0.5) * 2,
                (localPosition.dy / 100 - 0.5) * 2,
              );
              overlayProvider.updateAnchor(anchor);
            },
            child: CustomPaint(
              painter: AnchorPainter(anchor: overlay.anchor),
              size: const Size(100, 100),
            ),
          ),
        ),
        
        // Type-specific controls
        if (overlay.type == OverlayType.text || overlay.type == OverlayType.emoji) ...[
          const SizedBox(height: 16),
          _SliderControl(
            title: 'Font Size',
            value: overlay.fontSize ?? 24.0,
            min: 8.0,
            max: 72.0,
            onChanged: overlayProvider.updateFontSize,
            valueFormatter: (value) => '${value.round()}pt',
          ),
        ],
        
        if (overlay.type == OverlayType.text) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Color', style: TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showColorPicker(context, overlay.textColor ?? Colors.white),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: overlay.textColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getOverlayIcon(OverlayType type) {
    switch (type) {
      case OverlayType.image:
        return Icons.image;
      case OverlayType.video:
        return Icons.videocam;
      case OverlayType.emoji:
        return Icons.emoji_emotions;
      case OverlayType.text:
        return Icons.text_fields;
    }
  }

  String _getOverlayTypeName(OverlayType type) {
    switch (type) {
      case OverlayType.image:
        return 'Image';
      case OverlayType.video:
        return 'Video';
      case OverlayType.emoji:
        return 'Emoji';
      case OverlayType.text:
        return 'Text';
    }
  }

  void _showColorPicker(BuildContext context, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              context.read<OverlayProvider>().updateTextColor(color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SliderControl extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  const _SliderControl({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            Text(
              valueFormatter?.call(value) ?? value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[600],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OverlaysList extends StatelessWidget {
  final OverlayProvider overlayProvider;

  const _OverlaysList({required this.overlayProvider});

  @override
  Widget build(BuildContext context) {
    if (overlayProvider.overlays.isEmpty) {
      return const Center(
        child: Text(
          'No overlays\nSelect a track point and add overlays',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: overlayProvider.overlays.length,
      onReorder: overlayProvider.reorderOverlay,
      itemBuilder: (context, index) {
        final overlay = overlayProvider.overlays[index];
        final isSelected = overlay.id == overlayProvider.selectedOverlay?.id;
        
        return Container(
          key: ValueKey(overlay.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.blue) : null,
          ),
          child: ListTile(
            leading: Icon(
              _getOverlayIcon(overlay.type),
              color: overlay.isVisible ? Colors.white : Colors.grey,
            ),
            title: Text(
              _getOverlayTypeName(overlay.type),
              style: TextStyle(
                color: overlay.isVisible ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              overlay.content,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    overlay.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => overlayProvider.updateVisibility(!overlay.isVisible),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'duplicate',
                      child: const Row(
                        children: [
                          Icon(Icons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'duplicate':
                        overlayProvider.duplicateOverlay(overlay.id);
                        break;
                      case 'delete':
                        _confirmDelete(context, overlay.id);
                        break;
                    }
                  },
                ),
              ],
            ),
            onTap: () => overlayProvider.selectOverlay(
              isSelected ? null : overlay.id,
            ),
          ),
        );
      },
    );
  }

  IconData _getOverlayIcon(OverlayType type) {
    switch (type) {
      case OverlayType.image:
        return Icons.image;
      case OverlayType.video:
        return Icons.videocam;
      case OverlayType.emoji:
        return Icons.emoji_emotions;
      case OverlayType.text:
        return Icons.text_fields;
    }
  }

  String _getOverlayTypeName(OverlayType type) {
    switch (type) {
      case OverlayType.image:
        return 'Image';
      case OverlayType.video:
        return 'Video';
      case OverlayType.emoji:
        return 'Emoji';
      case OverlayType.text:
        return 'Text';
    }
  }

  void _confirmDelete(BuildContext context, String overlayId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Overlay'),
        content: const Text('Are you sure you want to delete this overlay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              overlayProvider.removeOverlay(overlayId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButtons extends StatelessWidget {
  final String trackPointId;
  final OverlayProvider overlayProvider;

  const _QuickAddButtons({
    required this.trackPointId,
    required this.overlayProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickAddButton(
          icon: Icons.emoji_emotions,
          label: 'Emoji',
          onTap: () => _addEmoji(context),
        ),
        _QuickAddButton(
          icon: Icons.text_fields,
          label: 'Text',
          onTap: () => _addText(context),
        ),
        _QuickAddButton(
          icon: Icons.image,
          label: 'Image',
          onTap: () => _addImage(context),
        ),
      ],
    );
  }

  void _addEmoji(BuildContext context) {
    const emojis = ['😀', '😂', '😍', '🤔', '😎', '🥳', '🔥', '💯', '👍', '❤️', '⭐', '🎉'];
    overlayProvider.createEmojiOverlay(emojis[0], trackPointId);
  }

  void _addText(BuildContext context) {
    overlayProvider.createTextOverlay('Sample Text', trackPointId);
  }

  void _addImage(BuildContext context) {
    // This would show image picker
    overlayProvider.createImageOverlay('placeholder_image.png', trackPointId);
  }
}

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class AnchorPainter extends CustomPainter {
  final Offset anchor;

  AnchorPainter({required this.anchor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final x = i * size.width / 4;
      final y = i * size.height / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw center lines
    final centerPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    // Draw anchor point
    final anchorX = (anchor.dx + 1) / 2 * size.width;
    final anchorY = (anchor.dy + 1) / 2 * size.height;
    
    canvas.drawCircle(Offset(anchorX, anchorY), 6, paint);
    canvas.drawCircle(Offset(anchorX, anchorY), 6, strokePaint);
  }

  @override
  bool shouldRepaint(AnchorPainter oldDelegate) {
    return oldDelegate.anchor != anchor;
  }
}

