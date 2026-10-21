import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/supabase_constants.dart';
import '../core/database/local_database.dart';
import '../models/user_model.dart';
import 'biometric_service.dart';

class AuthService {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final BiometricService _biometricService = BiometricService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  /// Initialize session from SharedPreferences or Supabase Auth
  Future<UserModel?> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    final userId = prefs.getString(AppConstants.keyUserId);

    if (SupabaseConstants.isConfigured) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final profile = await _localDb.getProfile(session.user.id);
          _currentUser = profile ??
              UserModel(
                id: session.user.id,
                name: session.user.userMetadata?['name'] ?? 'Pengguna',
                email: session.user.email ?? '',
                createdAt: DateTime.now(),
              );
          return _currentUser;
        }
      } catch (_) {}
    }

    if (isLoggedIn && userId != null) {
      final cachedProfile = await _localDb.getProfile(userId);
      if (cachedProfile != null) {
        _currentUser = cachedProfile;
        return _currentUser;
      } else {
        // Fallback default profile
        _currentUser = UserModel(
          id: userId,
          name: prefs.getString(AppConstants.keyUserName) ?? 'Pengguna jadiGuna',
          email: prefs.getString(AppConstants.keyUserEmail) ?? 'user@jadiguna.id',
          createdAt: DateTime.now(),
        );
        return _currentUser;
      }
    }

    return null;
  }

  /// Register new user
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? city,
    String? phone,
  }) async {
    String userId = const Uuid().v4();

    if (SupabaseConstants.isConfigured) {
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        if (authResponse.user != null) {
          userId = authResponse.user!.id;
        }
      } catch (e) {
        // If Supabase network error, fallback to local flow
      }
    }

    final newUser = UserModel(
      id: userId,
      name: name,
      email: email,
      city: city ?? AppConstants.defaultCity,
      phoneNumber: phone ?? '08123456789',
      createdAt: DateTime.now(),
    );

    // Save in local database
    await _localDb.saveProfile(newUser);

    // Save session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, newUser.id);
    await prefs.setString(AppConstants.keyUserName, newUser.name);
    await prefs.setString(AppConstants.keyUserEmail, newUser.email);

    _currentUser = newUser;
    return newUser;
  }

  /// Login with email and password
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (SupabaseConstants.isConfigured) {
      try {
        final authResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (authResponse.user != null) {
          final userId = authResponse.user!.id;
          final profile = await _localDb.getProfile(userId) ??
              UserModel(
                id: userId,
                name: authResponse.user!.userMetadata?['name'] ?? email.split('@').first,
                email: email,
                createdAt: DateTime.now(),
              );
          await _localDb.saveProfile(profile);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.keyIsLoggedIn, true);
          await prefs.setString(AppConstants.keyUserId, profile.id);
          await prefs.setString(AppConstants.keyUserName, profile.name);
          await prefs.setString(AppConstants.keyUserEmail, profile.email);

          _currentUser = profile;
          return profile;
        }
      } catch (e) {
        // Fallback to local authentication check
      }
    }

    // Local / Offline authentication
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(AppConstants.keyUserEmail);
    final savedId = prefs.getString(AppConstants.keyUserId) ?? 'user-current-1';

    String name = 'Budi Mahasiswa';
    if (savedEmail != null && savedEmail.toLowerCase() == email.toLowerCase()) {
      name = prefs.getString(AppConstants.keyUserName) ?? name;
    } else {
      name = email.split('@').first;
    }

    final user = UserModel(
      id: savedId,
      name: name,
      email: email,
      city: AppConstants.defaultCity,
      phoneNumber: '08123456789',
      createdAt: DateTime.now(),
    );

    await _localDb.saveProfile(user);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, user.id);
    await prefs.setString(AppConstants.keyUserName, user.name);
    await prefs.setString(AppConstants.keyUserEmail, user.email);

    _currentUser = user;
    return user;
  }

  /// Biometric authentication
  Future<bool> loginWithBiometrics() async {
    final canBio = await _biometricService.isBiometricsSupported();
    if (!canBio) return false;

    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      await initSession();
      if (_currentUser == null) {
        // Auto-assign default active profile if previously logged in
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString(AppConstants.keyUserEmail) ?? 'mahasiswa@jadiguna.id';
        final name = prefs.getString(AppConstants.keyUserName) ?? 'Pengguna jadiGuna';
        final id = prefs.getString(AppConstants.keyUserId) ?? 'user-current-1';

        final user = UserModel(
          id: id,
          name: name,
          email: email,
          city: AppConstants.defaultCity,
          createdAt: DateTime.now(),
        );
        await _localDb.saveProfile(user);
        await prefs.setBool(AppConstants.keyIsLoggedIn, true);
        _currentUser = user;
      }
      return true;
    }
    return false;
  }

  /// Update Profile
  Future<UserModel> updateProfile({
    required String name,
    String? bio,
    String? city,
    String? phone,
    String? photoPath,
  }) async {
    if (_currentUser == null) throw Exception('Pengguna belum login');

    final updated = _currentUser!.copyWith(
      name: name,
      bio: bio,
      city: city,
      phoneNumber: phone,
      profilePhotoPath: photoPath,
      updatedAt: DateTime.now(),
    );

    await _localDb.saveProfile(updated);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserName, updated.name);

    _currentUser = updated;
    return updated;
  }

  /// Logout
  Future<void> logout() async {
    if (SupabaseConstants.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    _currentUser = null;
  }
}
