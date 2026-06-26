import '../../../../core/network/base_mapper.dart';
import '../../domain/model/user_model.dart';
import '../dto/user_response_dto.dart';

class UserMapper implements BaseMapper<UserModel, UserResponseDto> {
  @override
  UserModel toModel(UserResponseDto dto) {
    return UserModel(
      id: dto.id ?? 0,
      name: dto.name ?? 'Guest',
      email: dto.email ?? '',
      role: dto.role ?? 'user',
    );
  }
}
