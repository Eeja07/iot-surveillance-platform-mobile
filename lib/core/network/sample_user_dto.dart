import 'base_mapper.dart';

// 1. Domain Model
class UserDomainModel {
  final int id;
  final String name;
  final String email;

  UserDomainModel({required this.id, required this.name, required this.email});
}

// 2. Response DTO
class UserResponseDto {
  final int? id;
  final String? name;
  final String? email;

  UserResponseDto({this.id, this.name, this.email});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

// 3. Mapper Implementation
class UserMapper implements BaseMapper<UserDomainModel, UserResponseDto> {
  @override
  UserDomainModel toModel(UserResponseDto dto) {
    return UserDomainModel(
      id: dto.id ?? 0,
      name: dto.name ?? 'Guest',
      email: dto.email ?? '',
    );
  }
}
