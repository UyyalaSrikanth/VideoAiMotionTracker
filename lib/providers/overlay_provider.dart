import 'dart:io';
import 'package:flutter/material.dart';
import '../models/overlay_item.dart';

class OverlayProvider extends ChangeNotifier {
  List<OverlayItem> _overlays = [];
  OverlayItem? _selectedOverlay;
  bool _isEditing = false;
  
  // Getters
  List<OverlayItem> get overlays => List.unmodifiable(_overlays);
  OverlayItem? get selectedOverlay => _selectedOverlay;
  bool get isEditing => _isEditing;
  
  // Get overlays for specific track point
  List<OverlayItem> getOverlaysForTrackPoint(String trackPointId) {
    return _overlays.where((overlay) => overlay.trackPointId == trackPointId).toList();
  }
  
  // Get active overlays for current frame
  List<OverlayItem> getActiveOverlaysAtFrame(int frameIndex) {
    return _overlays.where((overlay) => overlay.isActiveAtFrame(frameIndex)).toList();
  }
  
  // Add new overlay
  void addOverlay(OverlayItem overlay) {
    _overlays.add(overlay);
    notifyListeners();
  }
  
  // Create image overlay
  Future<void> createImageOverlay(String imagePath, String trackPointId) async {
    final overlay = OverlayItem(
      id: 'img_${DateTime.now().millisecondsSinceEpoch}',
      type: OverlayType.image,
      content: imagePath,
      trackPointId: trackPointId,
    );
    
    addOverlay(overlay);
  }
  
  // Create emoji overlay
  void createEmojiOverlay(String emoji, String trackPointId) {
    final overlay = OverlayItem(
      id: 'emoji_${DateTime.now().millisecondsSinceEpoch}',
      type: OverlayType.emoji,
      content: emoji,
      trackPointId: trackPointId,
      fontSize: 48.0,
    );
    
    addOverlay(overlay);
  }
  
  // Create text overlay
  void createTextOverlay(String text, String trackPointId) {
    final overlay = OverlayItem(
      id: 'text_${DateTime.now().millisecondsSinceEpoch}',
      type: OverlayType.text,
      content: text,
      trackPointId: trackPointId,
      fontSize: 24.0,
      textColor: Colors.white,
      fontFamily: 'Roboto',
    );
    
    addOverlay(overlay);
  }
  
  // Create video overlay
  Future<void> createVideoOverlay(String videoPath, String trackPointId) async {
    final overlay = OverlayItem(
      id: 'vid_${DateTime.now().millisecondsSinceEpoch}',
      type: OverlayType.video,
      content: videoPath,
      trackPointId: trackPointId,
    );
    
    addOverlay(overlay);
  }
  
  // Remove overlay
  void removeOverlay(String overlayId) {
    _overlays.removeWhere((overlay) => overlay.id == overlayId);
    if (_selectedOverlay?.id == overlayId) {
      _selectedOverlay = null;
    }
    notifyListeners();
  }
  
  // Select overlay
  void selectOverlay(String? overlayId) {
    if (overlayId == null) {
      _selectedOverlay = null;
    } else {
      _selectedOverlay = _overlays.where((overlay) => overlay.id == overlayId).firstOrNull;
    }
    notifyListeners();
  }
  
  // Update overlay properties
  void updateOverlay(String overlayId, OverlayItem updatedOverlay) {
    final index = _overlays.indexWhere((overlay) => overlay.id == overlayId);
    if (index != -1) {
      _overlays[index] = updatedOverlay;
      if (_selectedOverlay?.id == overlayId) {
        _selectedOverlay = updatedOverlay;
      }
      notifyListeners();
    }
  }
  
  // Transform methods for selected overlay
  void updateScale(double scale) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(scale: scale);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateRotation(double rotation) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(rotation: rotation);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateAnchor(Offset anchor) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(anchor: anchor);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateOpacity(double opacity) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(opacity: opacity);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateVisibility(bool isVisible) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(isVisible: isVisible);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateTimeRange(int startFrame, int endFrame) {
    if (_selectedOverlay != null) {
      final updated = _selectedOverlay!.copyWith(
        startFrame: startFrame,
        endFrame: endFrame,
      );
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  // Text-specific updates
  void updateTextColor(Color color) {
    if (_selectedOverlay != null && _selectedOverlay!.type == OverlayType.text) {
      final updated = _selectedOverlay!.copyWith(textColor: color);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateFontSize(double fontSize) {
    if (_selectedOverlay != null && 
        (_selectedOverlay!.type == OverlayType.text || _selectedOverlay!.type == OverlayType.emoji)) {
      final updated = _selectedOverlay!.copyWith(fontSize: fontSize);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  void updateFontFamily(String fontFamily) {
    if (_selectedOverlay != null && _selectedOverlay!.type == OverlayType.text) {
      final updated = _selectedOverlay!.copyWith(fontFamily: fontFamily);
      updateOverlay(_selectedOverlay!.id, updated);
    }
  }
  
  // Editing mode
  void setEditingMode(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }
  
  // Duplicate overlay
  void duplicateOverlay(String overlayId) {
    final original = _overlays.where((overlay) => overlay.id == overlayId).firstOrNull;
    if (original != null) {
      final duplicate = OverlayItem(
        id: '${original.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
        type: original.type,
        content: original.content,
        trackPointId: original.trackPointId,
        scale: original.scale,
        rotation: original.rotation,
        anchor: original.anchor + const Offset(0.1, 0.1), // Slight offset
        opacity: original.opacity,
        startFrame: original.startFrame,
        endFrame: original.endFrame,
        isVisible: original.isVisible,
        textColor: original.textColor,
        fontSize: original.fontSize,
        fontFamily: original.fontFamily,
      );
      
      addOverlay(duplicate);
    }
  }
  
  // Clear all overlays
  void clearAllOverlays() {
    _overlays.clear();
    _selectedOverlay = null;
    notifyListeners();
  }
  
  // Clear overlays for specific track point
  void clearOverlaysForTrackPoint(String trackPointId) {
    _overlays.removeWhere((overlay) => overlay.trackPointId == trackPointId);
    if (_selectedOverlay?.trackPointId == trackPointId) {
      _selectedOverlay = null;
    }
    notifyListeners();
  }
  
  // Reorder overlays (for layering)
  void reorderOverlay(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final overlay = _overlays.removeAt(oldIndex);
    _overlays.insert(newIndex, overlay);
    notifyListeners();
  }
  
  // Get overlay at position (for selection)
  OverlayItem? getOverlayAt(Offset position, int frameIndex) {
    // Return the topmost overlay at the given position
    for (int i = _overlays.length - 1; i >= 0; i--) {
      final overlay = _overlays[i];
      if (overlay.isActiveAtFrame(frameIndex)) {
        // This would need more sophisticated hit testing based on overlay type and transform
        // For now, just return the first active overlay
        return overlay;
      }
    }
    return null;
  }
  
  // Export overlay data
  Map<String, dynamic> exportOverlayData() {
    return {
      'overlays': _overlays.map((overlay) => overlay.toJson()).toList(),
    };
  }
  
  // Import overlay data
  void importOverlayData(Map<String, dynamic> data) {
    _overlays.clear();
    _selectedOverlay = null;
    
    if (data['overlays'] != null) {
      for (var overlayData in data['overlays']) {
        _overlays.add(OverlayItem.fromJson(overlayData));
      }
    }
    
    notifyListeners();
  }
  
  // Validate overlay content (check if files exist)
  Future<void> validateOverlays() async {
    List<OverlayItem> invalidOverlays = [];
    
    for (var overlay in _overlays) {
      if (overlay.type == OverlayType.image || overlay.type == OverlayType.video) {
        final file = File(overlay.content);
        if (!await file.exists()) {
          invalidOverlays.add(overlay);
        }
      }
    }
    
    // Remove invalid overlays
    for (var invalid in invalidOverlays) {
      removeOverlay(invalid.id);
    }
  }
}

