import 'user_response_dto.dart';

class LoginResponseDto {
  final String? token;
  final UserResponseDto? user;

  LoginResponseDto({this.token, this.user});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    String? token = json['token'] as String? ?? json['access_token'] as String?;
    if (token == null &&
        json['data'] != null &&
        json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      token = dataMap['token'] as String? ?? dataMap['access_token'] as String?;
    }

    Map<String, dynamic>? userMap;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
    } else if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      final dataMap = json['data'] as Map<String, dynamic>;
      if (dataMap['user'] != null && dataMap['user'] is Map<String, dynamic>) {
        userMap = dataMap['user'] as Map<String, dynamic>;
      }
    }

    return LoginResponseDto(
      token: token,
      user: userMap != null ? UserResponseDto.fromJson(userMap) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user?.toJson()};
  }
}
