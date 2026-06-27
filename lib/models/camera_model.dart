class Camera {
  final dynamic id;
  final String name;
  final bool isOnline;
  final String groupName;
  final int? groupId;
  final String? deviceId;
  final String? description;
  final String? thumbnailUrl;

  final String? websocketChannelId;

  static const String _imageBaseUrl = 'https://cctv.miot-its.org';

  factory Camera.fromJson(Map<String, dynamic> json) {
    String? thumb =
        json['thumbnail_url'] ??
        json['latest_image_url'];

    if (thumb == null) {
      final path = json['latest_image_path'];
      if (path != null && path.toString().isNotEmpty) {
        final cleanPath = path.toString().startsWith('/')
            ? path.toString().substring(1)
            : path.toString();
        thumb = 'https://apiminio.miot-its.org/cctv/$cleanPath';
      }
    }

    if (thumb != null && thumb.isNotEmpty && !thumb.startsWith('http')) {
      thumb = '$_imageBaseUrl$thumb';
    }

    return Camera(
      id: json['id'],
      name: json['name'] ?? 'Kamera Tanpa Nama',
      isOnline: json['is_active'] == true,
      groupName:
          (json['group_name'] != null &&
              json['group_name'].toString().isNotEmpty)
          ? json['group_name']
          : 'Tanpa Grup',
      groupId: json['group_id'],
      deviceId: json['device_id'],
      description: json['description'],
      thumbnailUrl: thumb,
      websocketChannelId: json['websocket_channel_id'],
    );
  }

  Camera({
    required this.id,
    required this.name,
    this.isOnline = false,
    required this.groupName,
    this.groupId,
    this.deviceId,
    this.description,
    this.thumbnailUrl,
    this.websocketChannelId,
  });
}

class CameraGroup {
  final int? id;
  final String name;
  final List<Camera> cameras;
  bool isExpanded;

  factory CameraGroup.fromJson(Map<String, dynamic> json) {
    String gName = json['group_name'] ?? 'Grup Tanpa Nama';
    int? gId = json['group_id'];

    var list = json['cameras'] as List? ?? [];

    List<Camera> parsedCameras = list.map((c) {
      if (c is Map<String, dynamic>) {
        if (c['group_name'] == null) c['group_name'] = gName;
        if (c['group_id'] == null) c['group_id'] = gId;
      }
      return Camera.fromJson(c);
    }).toList();

    return CameraGroup(id: gId, name: gName, cameras: parsedCameras);
  }

  CameraGroup({
    this.id,
    required this.name,
    required this.cameras,
    this.isExpanded = false,
  });
}
