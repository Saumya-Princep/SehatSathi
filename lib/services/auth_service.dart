import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart' as model;

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      return const Stream.empty();
    }
  }

  Future<model.UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return model.UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  Future<model.UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        return await getUserData(result.user!.uid);
      }
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  Future<model.UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        // Check if user document exists in firestore
        var userDoc = await getUserData(user.uid);
        if (userDoc == null) {
          // Register as patient if new
          final newUser = model.UserModel(
            uid: user.uid,
            name: user.displayName ?? 'Google User',
            role: model.UserRole.patient,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
          return newUser;
        }
        return userDoc;
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
    return null;
  }

  Future<model.UserModel?> register({
    required String email,
    required String password,
    required String name,
    required model.UserRole role,
    String? phcId,
    String? doctorRegId,
    String? hospitalRegNo,
    String? pharmacistRegNo,
    String? specialty,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        final newUser = model.UserModel(
          uid: result.user!.uid,
          name: name,
          role: role,
          assignedPhcId: phcId,
          doctorRegistrationId: doctorRegId,
          hospitalRegistrationNumber: hospitalRegNo,
          pharmacistRegistrationNumber: pharmacistRegNo,
          specialty: specialty,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(result.user!.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
    return null;
  }
}
