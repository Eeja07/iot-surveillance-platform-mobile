import 'dart:async';
import '../../features/auth/data/datasource/auth_local_data_source.dart';
import '../../features/auth/domain/model/user_model.dart';
import 'session_event.dart';

class SessionService {
  final AuthLocalDataSource _localDataSource;
  final StreamController<SessionEvent> _eventController =
      StreamController<SessionEvent>.broadcast();

  SessionService(this._localDataSource);

  Stream<SessionEvent> get sessionEvents => _eventController.stream;

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    if (token.isNotEmpty) {
      await _localDataSource.saveAccessToken(token);
    }
    await _localDataSource.saveUserCache(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    );
    _eventController.add(SessionEvent.loggedIn);
  }

  Future<String?> getAccessToken() async {
    return await _localDataSource.getAccessToken();
  }

  Future<Map<String, dynamic>?> getUserCache() async {
    return await _localDataSource.getUserCache();
  }

  Future<UserModel?> getCurrentUser() async {
    final cache = await getUserCache();
    if (cache == null) return null;
    return UserModel(
      id: cache['id'] as int? ?? 0,
      name: cache['name'] as String? ?? '',
      email: cache['email'] as String? ?? '',
      role: cache['role'] as String? ?? 'user',
    );
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _localDataSource.clearSession();
    _eventController.add(SessionEvent.loggedOut);
  }

  Future<void> expireSession() async {
    await _localDataSource.clearSession();
    _eventController.add(SessionEvent.sessionExpired);
  }

  Future<void> notifyTokenRefreshed() async {
    _eventController.add(SessionEvent.tokenRefreshed);
  }

  void dispose() {
    _eventController.close();
  }
}
