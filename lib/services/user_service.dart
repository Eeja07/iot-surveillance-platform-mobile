import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String _baseUrl = 'https://cctv.miot-its.org/api';

  Future<User?> getUser(String token) async {
    try {
      print('DEBUG: Getting User Profile...');
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('DEBUG: Profile Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('user')) {
          return User.fromJson(data['user']);
        }

        if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data'].containsKey('user')) {
          return User.fromJson(data['data']['user']);
        }

        if (data.containsKey('id') && data.containsKey('email')) {
          return User.fromJson(data);
        }

        return null;
      } else {
        print('Failed to load user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<bool> updateUser(String token, String name, String email) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name': name, 'email': email}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String token,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseBody['message'] ??
              'Password berhasil diubah. Silakan login kembali.',
        };
      } else {
        String errorMessage =
            responseBody['message'] ?? 'Gagal mengubah password.';
        if (responseBody.containsKey('errors')) {
          errorMessage += " ${responseBody['errors'].toString()}";
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi.'};
    }
  }
}
