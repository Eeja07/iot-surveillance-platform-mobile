// lib/core/realtime/last_detection_provider.dart
//
// A thin state-holder for the most recently received `person.detected` payload.
// DashboardSync writes here; UI widgets listen here.
// Keeping this in the realtime package avoids coupling the service layer to
// the UI/Overlay API.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the most recently received `person.detected` event payload.
///
/// `null`  → no detection has been received yet (or it was cleared).
/// Non-null → a map with keys: `id`, `camera_name`, `confidence`, etc.
///
/// UI widgets should listen with [ref.listen] and show a toast
/// ONLY when the value becomes non-null and the widget is mounted.
final lastDetectionEventProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null, name: 'lastDetectionEventProvider');
