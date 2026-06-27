import 'dart:convert';

/// Lightweight value object parsed from a `person.detected` Reverb payload.
///
/// Created by [RealtimeDispatcher] and passed directly to
/// [NotificationBridge.handleRealtimeDetection] so notifications are
/// event-driven rather than state-diff-driven.
class DetectionEvent {
  final int id;
  final String cameraName;
  final String message;
  final String? imageUrl;
  final String? confidence;

  const DetectionEvent({
    required this.id,
    required this.cameraName,
    required this.message,
    this.imageUrl,
    this.confidence,
  });

  /// Parse from the raw `event.data` payload (String JSON or Map).
  static DetectionEvent? tryParse(dynamic raw) {
    try {
      final Map<String, dynamic> data = raw is String
          ? json.decode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);

      final id = int.tryParse(data['id']?.toString() ?? '');
      if (id == null) return null;

      final cameraName = data['camera_name']?.toString() ?? 'Kamera';
      final confidence = data['confidence']?.toString();
      final imageUrl = data['image_url']?.toString();

      final body = confidence != null && confidence.isNotEmpty
          ? 'Person detected on $cameraName ($confidence)'
          : 'Person detected on $cameraName';

      return DetectionEvent(
        id: id,
        cameraName: cameraName,
        message: body,
        imageUrl: imageUrl,
        confidence: confidence,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'DetectionEvent(id: $id, camera: $cameraName, msg: $message)';
}
