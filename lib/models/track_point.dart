import 'dart:ui';

class TrackPoint {
  final String id;
  final List<Offset> positions; // Position for each frame
  final Color color;
  final double confidence;
  bool isSelected;
  
  TrackPoint({
    required this.id,
    required this.positions,
    this.color = const Color(0xFF00FF00),
    this.confidence = 1.0,
    this.isSelected = false,
  });
  
  // Get position at specific frame
  Offset? getPositionAtFrame(int frameIndex) {
    if (frameIndex >= 0 && frameIndex < positions.length) {
      return positions[frameIndex];
    }
    return null;
  }
  
  // Add position for new frame
  void addPosition(Offset position) {
    positions.add(position);
  }
  
  // Update position at specific frame
  void updatePosition(int frameIndex, Offset position) {
    if (frameIndex >= 0 && frameIndex < positions.length) {
      positions[frameIndex] = position;
    }
  }
  
  // Get interpolated position between frames
  Offset? getInterpolatedPosition(double frameIndex) {
    if (positions.isEmpty) return null;
    
    int floorIndex = frameIndex.floor();
    int ceilIndex = frameIndex.ceil();
    
    if (floorIndex == ceilIndex) {
      return getPositionAtFrame(floorIndex);
    }
    
    Offset? pos1 = getPositionAtFrame(floorIndex);
    Offset? pos2 = getPositionAtFrame(ceilIndex);
    
    if (pos1 == null || pos2 == null) return pos1 ?? pos2;
    
    double t = frameIndex - floorIndex;
    return Offset.lerp(pos1, pos2, t)!;
  }
  
  TrackPoint copyWith({
    String? id,
    List<Offset>? positions,
    Color? color,
    double? confidence,
    bool? isSelected,
  }) {
    return TrackPoint(
      id: id ?? this.id,
      positions: positions ?? List.from(this.positions),
      color: color ?? this.color,
      confidence: confidence ?? this.confidence,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

