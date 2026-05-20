import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as model;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  model.UserModel? _userModel;
  bool _isLoading = false;

  model.UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userModel != null;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _userModel = await _authService.getUserData(user.uid);
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _userModel = await _authService.signIn(email, password);
      _setLoading(false);
      return _userModel != null;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _userModel = await _authService.signInWithGoogle();
      _setLoading(false);
      return _userModel != null;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required model.UserRole role,
    String? phcId,
    String? doctorRegId,
    String? hospitalRegNo,
    String? pharmacistRegNo,
  }) async {
    _setLoading(true);
    try {
      _userModel = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phcId: phcId,
        doctorRegId: doctorRegId,
        hospitalRegNo: hospitalRegNo,
        pharmacistRegNo: pharmacistRegNo,
      );
      _setLoading(false);
      if (_userModel == null) throw Exception('Failed to register.');
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
