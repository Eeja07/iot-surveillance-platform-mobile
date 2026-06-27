class OverviewModel {
  final int onlineCameras;
  final int totalCameras;
  final int detectionsToday;
  final int motionsToday;
  final int storageUsageGb;
  final int avgRssi;
  final int avgHeap;
  final int uptimeAvg;

  OverviewModel({
    required this.onlineCameras,
    required this.totalCameras,
    required this.detectionsToday,
    required this.motionsToday,
    required this.storageUsageGb,
    required this.avgRssi,
    required this.avgHeap,
    required this.uptimeAvg,
  });

  factory OverviewModel.fromJson(Map<String, dynamic> json) {
    return OverviewModel(
      onlineCameras: json['online_cameras'] as int? ?? 0,
      totalCameras: json['total_cameras'] as int? ?? 0,
      detectionsToday: json['detections_today'] as int? ?? 0,
      motionsToday: json['motions_today'] as int? ?? 0,
      storageUsageGb: json['storage_usage_gb'] as int? ?? 0,
      avgRssi: json['avg_rssi'] as int? ?? 0,
      avgHeap: json['avg_heap'] as int? ?? 0,
      uptimeAvg: json['uptime_avg'] as int? ?? 0,
    );
  }

  OverviewModel copyWith({
    int? onlineCameras,
    int? totalCameras,
    int? detectionsToday,
    int? motionsToday,
    int? storageUsageGb,
    int? avgRssi,
    int? avgHeap,
    int? uptimeAvg,
  }) {
    return OverviewModel(
      onlineCameras: onlineCameras ?? this.onlineCameras,
      totalCameras: totalCameras ?? this.totalCameras,
      detectionsToday: detectionsToday ?? this.detectionsToday,
      motionsToday: motionsToday ?? this.motionsToday,
      storageUsageGb: storageUsageGb ?? this.storageUsageGb,
      avgRssi: avgRssi ?? this.avgRssi,
      avgHeap: avgHeap ?? this.avgHeap,
      uptimeAvg: uptimeAvg ?? this.uptimeAvg,
    );
  }
}
