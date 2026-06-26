import 'package:flutter/material.dart';
import '../domain/model/user_model.dart';
import '../domain/repository/auth_repository.dart';
import '../../../../core/storage/session_service.dart';
import '../../../../core/network/api_result.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({
    required AuthRepository authRepository,
    required SessionService sessionService,
  }) : _authRepository = authRepository,
       _sessionService = sessionService {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    final hasSession = await _sessionService.isLoggedIn();
    if (hasSession) {
      final cache = await _sessionService.getUserCache();
      if (cache != null) {
        _currentUser = UserModel(
          id: 0,
          name: cache['name'] as String? ?? '',
          email: cache['email'] as String? ?? '',
          role: cache['role'] as String? ?? 'user',
        );
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(
      email: email,
      password: password,
    );
    _isLoading = false;

    if (result is ApiSuccess<UserModel>) {
      _currentUser = result.data;
      notifyListeners();
      return true;
    } else if (result is ApiFailure<UserModel>) {
      _errorMessage = result.exception.message;
      notifyListeners();
      return false;
    }
    return false;
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.logout();
    _isLoading = false;

    if (result is ApiSuccess) {
      _currentUser = null;
      notifyListeners();
      return true;
    } else if (result is ApiFailure) {
      _errorMessage = result.exception.message;
      notifyListeners();
      return false;
    }
    return false;
  }

  Future<void> clearError() async {
    _errorMessage = null;
    notifyListeners();
  }
}
