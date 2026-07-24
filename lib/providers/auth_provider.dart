import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as model;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  model.UserModel? _userModel;
  model.UserModel? _activeDependent;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.light;

  model.UserModel? get userModel => _userModel;
  model.UserModel? get activePatient => _activeDependent ?? _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userModel != null;
  ThemeMode get themeMode => _themeMode;

  void switchActivePatient(model.UserModel? dependent) {
    _activeDependent = dependent;
    notifyListeners();
  }

  AuthProvider() {
    _initAuthListener();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode != ThemeMode.dark);
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
      rethrow;
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
    String? hospitalName,
    String? doctorRegId,
    String? hospitalRegNo,
    String? pharmacistRegNo,
    String? specialty,
    int? age,
    String? gender,
    String? bloodGroup,
    String? address,
    String? emergencyContact,
  }) async {
    _setLoading(true);
    try {
      _userModel = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phcId: phcId,
        hospitalName: hospitalName,
        doctorRegId: doctorRegId,
        hospitalRegNo: hospitalRegNo,
        pharmacistRegNo: pharmacistRegNo,
        specialty: specialty,
        age: age,
        gender: gender,
        bloodGroup: bloodGroup,
        address: address,
        emergencyContact: emergencyContact,
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

  Future<void> uploadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
      if (pickedFile == null) return;

      _setLoading(true);
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final downloadUrl = 'data:image/jpeg;base64,$base64Image';

      final targetUid = _activeDependent != null ? _activeDependent!.uid : user.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .update({'profilePicUrl': downloadUrl});

      if (targetUid == user.uid) {
        _userModel = await _authService.getUserData(user.uid);
      }
      if (_activeDependent != null && _activeDependent!.uid == targetUid) {
        _activeDependent = await _authService.getUserData(targetUid);
      }
      notifyListeners();
    } catch (e) {
      print('Error uploading profile picture: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(model.UserModel updatedUser) async {
    _setLoading(true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());
          
      // Update local state if it's the main user or active dependent
      if (_userModel?.uid == updatedUser.uid) {
        _userModel = updatedUser;
      }
      if (_activeDependent?.uid == updatedUser.uid) {
        _activeDependent = updatedUser;
      }
      
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      _setLoading(false);
      return false;
    }
  }
}
