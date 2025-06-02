import 'dart:io';
import 'dart:ui';

enum OverlayType {
  image,
  video,
  emoji,
  text,
}

class OverlayItem {
  final String id;
  final OverlayType type;
  final String content; // File path for image/video, emoji character, or text
  final String trackPointId; // Associated track point
  
  // Transform properties
  double scale;
  double rotation; // in radians
  Offset anchor; // Relative to track point (-1 to 1)
  double opacity;
  
  // Animation properties
  int startFrame;
  int endFrame;
  bool isVisible;
  
  // Additional properties for different types
  Color? textColor;
  double? fontSize;
  String? fontFamily;
  
  OverlayItem({
    required this.id,
    required this.type,
    required this.content,
    required this.trackPointId,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.anchor = Offset.zero,
    this.opacity = 1.0,
    this.startFrame = 0,
    this.endFrame = -1, // -1 means until end of video
    this.isVisible = true,
    this.textColor,
    this.fontSize,
    this.fontFamily,
  });
  
  bool isActiveAtFrame(int frameIndex) {
    if (!isVisible) return false;
    if (frameIndex < startFrame) return false;
    if (endFrame >= 0 && frameIndex > endFrame) return false;
    return true;
  }
  
  OverlayItem copyWith({
    String? id,
    OverlayType? type,
    String? content,
    String? trackPointId,
    double? scale,
    double? rotation,
    Offset? anchor,
    double? opacity,
    int? startFrame,
    int? endFrame,
    bool? isVisible,
    Color? textColor,
    double? fontSize,
    String? fontFamily,
  }) {
    return OverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      trackPointId: trackPointId ?? this.trackPointId,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      anchor: anchor ?? this.anchor,
      opacity: opacity ?? this.opacity,
      startFrame: startFrame ?? this.startFrame,
      endFrame: endFrame ?? this.endFrame,
      isVisible: isVisible ?? this.isVisible,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'content': content,
      'trackPointId': trackPointId,
      'scale': scale,
      'rotation': rotation,
      'anchor': {'dx': anchor.dx, 'dy': anchor.dy},
      'opacity': opacity,
      'startFrame': startFrame,
      'endFrame': endFrame,
      'isVisible': isVisible,
      'textColor': textColor?.value,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
    };
  }
  
  factory OverlayItem.fromJson(Map<String, dynamic> json) {
    return OverlayItem(
      id: json['id'],
      type: OverlayType.values[json['type']],
      content: json['content'],
      trackPointId: json['trackPointId'],
      scale: json['scale']?.toDouble() ?? 1.0,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      anchor: Offset(
        json['anchor']['dx']?.toDouble() ?? 0.0,
        json['anchor']['dy']?.toDouble() ?? 0.0,
      ),
      opacity: json['opacity']?.toDouble() ?? 1.0,
      startFrame: json['startFrame'] ?? 0,
      endFrame: json['endFrame'] ?? -1,
      isVisible: json['isVisible'] ?? true,
      textColor: json['textColor'] != null ? Color(json['textColor']) : null,
      fontSize: json['fontSize']?.toDouble(),
      fontFamily: json['fontFamily'],
    );
  }
}

