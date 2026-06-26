import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/camera_model.dart';

class CameraService {
  static const String _baseUrl = 'https://cctv.miot-its.org/api';
  static const String _imageBaseUrl = 'https://cctv.miot-its.org';

  Future<List<CameraGroup>> fetchCameraGroups(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // TAMBAHAN DEBUG: Cek /api/camera-statuses dan /api/user/cameras
      try {
        final debugUri1 = Uri.parse('$_baseUrl/camera-statuses');
        final debugRes1 = await http.get(
          debugUri1,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        print(
          'DEBUG: TEST /api/camera-statuses Status: ${debugRes1.statusCode}',
        );
        print('DEBUG: TEST /api/camera-statuses Body: ${debugRes1.body}');

        final debugUri2 = Uri.parse('$_baseUrl/user/cameras');
        final debugRes2 = await http.get(
          debugUri2,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        print('DEBUG: TEST /api/user/cameras Status: ${debugRes2.statusCode}');
        print('DEBUG: TEST /api/user/cameras Body: ${debugRes2.body}');
      } catch (e) {}

      print('DEBUG: fetchCameraGroups URL: $uri');
      print('DEBUG: fetchCameraGroups Status: ${response.statusCode}');
      print('DEBUG: fetchCameraGroups Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        dynamic data;
        if (body is Map<String, dynamic>) {
          if (body.containsKey('data')) {
            data = body['data'];
          } else {
            data = body;
          }
        }

        if (data != null) {
          List<CameraGroup> finalGroups = [];

          if (data['groups'] != null && data['groups'] is List) {
            final List<dynamic> groupsJson = data['groups'];
            finalGroups = groupsJson
                .map((g) => CameraGroup.fromJson(g))
                .toList();

            finalGroups.removeWhere((g) => g.cameras.isEmpty);
          }

          if (data['ungrouped_cameras'] != null &&
              data['ungrouped_cameras'] is List) {
            final List<dynamic> ungroupedJson = data['ungrouped_cameras'];
            final List<Camera> ungroupedList = ungroupedJson
                .map((c) => Camera.fromJson(c))
                .toList();

            if (ungroupedList.isNotEmpty) {
              finalGroups.add(
                CameraGroup(
                  id: null,
                  name: 'Tanpa Grup',
                  cameras: ungroupedList,
                ),
              );
            }
          }

          finalGroups.sort((a, b) {
            if (a.name == 'Tanpa Grup') return 1;
            if (b.name == 'Tanpa Grup') return -1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          return finalGroups;
        }
      }
      return [];
    } catch (e) {
      print('DEBUG: Error fetching groups: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createGroupApi(
    String token,
    String groupName,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'group_name': groupName}),
      );

      final body = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data = body['data'] ?? body;
        return {
          'success': true,
          'id': data['group_id'] ?? data['id'],
          'message': body['message'] ?? 'Grup berhasil dibuat.',
        };
      }

      return {
        'success': false,
        'message': body['message'] ?? 'Gagal membuat grup.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateGroupApi(
    String token,
    String oldGroupName,
    String newGroupName,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups/update');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'old_group_name': oldGroupName,
          'new_group_name': newGroupName,
        }),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Berhasil diubah',
        };
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal mengubah nama grup.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteGroupApi(
    String token,
    String groupName,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups/delete');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'group_name': groupName}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Grup berhasil dihapus.',
        };
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menghapus grup.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> assignCameraToGroup(
    String token,
    String groupName,
    int cameraId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups/assign');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'group_name': groupName, 'camera_id': cameraId}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Berhasil'};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menambahkan kamera ke grup.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<Map<String, dynamic>> removeCameraFromGroup(
    String token,
    int cameraId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/camera-groups/remove');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'camera_id': cameraId}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Berhasil'};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Gagal menghapus kamera dari grup.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  Future<List<Map<String, dynamic>>> getCameras(String token) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/cameras');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DEBUG: getCameras URL: $uri');
      print('DEBUG: getCameras Status: ${response.statusCode}');
      print('DEBUG: getCameras Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        dynamic listData;
        if (body['data'] != null) {
          if (body['data'] is Map && body['data']['data'] is List) {
            listData = body['data']['data'];
          } else if (body['data'] is List) {
            listData = body['data'];
          }
        } else if (body is List) {
          listData = body;
        }

        if (listData != null && listData is List) {
          return List<Map<String, dynamic>>.from(listData);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> updateCamera(
    String token,
    String cameraId,
    String name, {
    String? description,
    String? groupName,
    int? groupId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/cameras/$cameraId');
      final Map<String, dynamic> bodyData = {'name': name};
      if (description != null) bodyData['description'] = description;
      if (groupId != null)
        bodyData['group_id'] = groupId;
      else if (groupName != null)
        bodyData['group_name'] = groupName;

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Berhasil.'};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Gagal.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error.'};
    }
  }

  Future<Map<String, dynamic>> deleteCamera(String token, String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/cameras/$id');
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Berhasil dihapus.',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal menghapus.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error.'};
    }
  }

  Future<Map<String, dynamic>> addCamera(
    String token,
    String deviceId, {
    String? description,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/user/cameras');
      final Map<String, dynamic> bodyData = {'device_id': deviceId};
      if (description != null && description.isNotEmpty)
        bodyData['description'] = description;

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyData),
      );
      final body = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Berhasil ditambahkan.',
        };
      } else {
        return {'success': false, 'message': body['message'] ?? 'Gagal.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi error.'};
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryImages({
    required String token,
    required String cameraId,
    required String date,
    required String hour,
    required String minute,
    int chunk = 1,
  }) async {
    try {
      final queryParams = {
        'date': date,
        'hour': hour,
        'minute': minute,
        'chunk': chunk.toString(),
      };
      final uri = Uri.parse(
        '$_baseUrl/images/$cameraId/history',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null) {
          List<dynamic> items = data['items'];
          return items
              .map((item) {
                String rawUrl = item['url'] ?? '';
                String fullUrl = rawUrl.startsWith('http')
                    ? rawUrl
                    : '$_imageBaseUrl$rawUrl';
                return {
                  'id': item['id'],
                  'url': fullUrl,
                  'captured_at': item['captured_at'],
                  'file_name': item['file_name'],
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getHistoryStats(
    String token,
    String cameraId, {
    String? date,
    String? hour,
    String? minute,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (date != null) queryParams['date'] = date;
      if (hour != null) queryParams['hour'] = hour;
      if (minute != null) queryParams['minute'] = minute;

      final uri = Uri.parse(
        '$_baseUrl/images/$cameraId/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching history stats: $e');
      return {};
    }
  }

  Future<String?> getLatestImage(String token, String cameraId) async {
    try {
      final uri = Uri.parse('$_baseUrl/cameras/$cameraId/latest-image');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['success'] == true && body['image_url'] != null) {
          String imageUrl = body['image_url'];

          return imageUrl.startsWith('http')
              ? imageUrl
              : '$_imageBaseUrl$imageUrl';
        }
      }
      return null;
    } catch (e) {
      print('Error fetching latest image: $e');
      return null;
    }
  }
}
