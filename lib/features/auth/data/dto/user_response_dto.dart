class UserResponseDto {
  final int? id;
  final String? name;
  final String? email;
  final String? role;

  UserResponseDto({this.id, this.name, this.email, this.role});

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    return UserResponseDto(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }
}
