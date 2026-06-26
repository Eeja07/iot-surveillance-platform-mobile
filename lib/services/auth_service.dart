
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://cctv.miot-its.org/api';
  static const String _loginUrl = '$_baseUrl/login';
  static const String _registerUrl = '$_baseUrl/register';


  static const String _userUrl = '$_baseUrl/user';

  static const String _verifyRegistrationOtpUrl = '$_baseUrl/verify-otp';
  static const String _forgotPasswordUrl = '$_baseUrl/password/email';
  static const String _verifyPasswordOtpUrl = '$_baseUrl/password/verify-otp';
  static const String _resetPasswordUrl = '$_baseUrl/password/reset';


  Future<bool> checkTokenValidity(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_userUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {

        return true;
      } else if (response.statusCode == 401) {

        print("Token ditolak server (401). Logout.");
        return false;
      } else {


        print("Server error ${response.statusCode}, tetap login.");
        return true;
      }
    } catch (e) {
      print('Error checking token validity (Connection/Timeout): $e');




      return true;
    }
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 20));

      final body = json.decode(response.body);

      if (response.statusCode == 200) {
        String? token;
        if (body['token'] != null) token = body['token'];
        else if (body['access_token'] != null) token = body['access_token'];
        else if (body['data'] != null && body['data'] is Map) {
          if (body['data']['token'] != null) token = body['data']['token'];
          else if (body['data']['access_token'] != null) token = body['data']['access_token'];
        }

        if (token != null) {
          final String role = (email == 'admin@gmail.com') ? 'admin' : 'user';
          return {'success': true, 'token': token, 'role': role};
        }
      }

      String message = body['message'] ?? 'Login gagal.';
      if (body['errors'] != null) message += " ${body['errors']}";
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }


  Future<Map<String, dynamic>> register(String name, String email, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse(_registerUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8', 'Accept': 'application/json'},
        body: jsonEncode({
          'name': name, 'email': email, 'password': password, 'password_confirmation': confirmPassword,
        }),
      ).timeout(const Duration(seconds: 20));

      final responseBody = json.decode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': responseBody['message'] ?? 'Registrasi berhasil.', 'user': responseBody['user']};
      }
      String msg = responseBody['message'] ?? 'Gagal mendaftar.';
      if (responseBody['errors'] != null) msg += " ${responseBody['errors'].toString()}";
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi.'};
    }
  }


  Future<Map<String, dynamic>> verifyRegistrationOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyRegistrationOtpUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 20));

      final body = json.decode(response.body);
      if (response.statusCode == 200) {
        String? token = body['token'] ?? body['access_token'];
        return {'success': true, 'message': body['message'] ?? 'Email diverifikasi.', 'token': token};
      } else {
        return {'success': false, 'message': body['message'] ?? 'OTP Salah.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi.'};
    }
  }


  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_forgotPasswordUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 20));
      final body = json.decode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message'] ?? 'Respon server.'};
    } catch (e) { return {'success': false, 'message': 'Koneksi error.'}; }
  }

  Future<Map<String, dynamic>> verifyPasswordOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyPasswordOtpUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 20));
      final body = json.decode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message'] ?? 'Respon server.'};
    } catch (e) { return {'success': false, 'message': 'Koneksi error.'}; }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse(_resetPasswordUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'token': otp, 'password': password, 'password_confirmation': confirmPassword}),
      ).timeout(const Duration(seconds: 20));
      final body = json.decode(response.body);
      return {'success': response.statusCode == 200, 'message': body['message'] ?? 'Respon server.'};
    } catch (e) { return {'success': false, 'message': 'Koneksi error.'}; }
  }
}