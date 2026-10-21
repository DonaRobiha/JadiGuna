import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isBiometricsSupported = false;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBiometricsSupported => _isBiometricsSupported;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isBiometricsSupported = await _biometricService.isBiometricsSupported();
      _user = await _authService.initSession();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? city,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        city: city,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    _isLoading = true;
    notifyListeners();

    final success = await _authService.loginWithBiometrics();
    if (success) {
      _user = _authService.currentUser;
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateProfile({
    required String name,
    String? bio,
    String? city,
    String? phone,
    String? photoPath,
  }) async {
    try {
      _user = await _authService.updateProfile(
        name: name,
        bio: bio,
        city: city,
        phone: phone,
        photoPath: photoPath,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
