import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Получить текущего пользователя
  User? get currentUser => _auth.currentUser;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  // Вход с email и паролем
  Future<UserCredential> signInWithEmailAndPassword(String email, String password, {BuildContext? context}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // После входа — синхронизация из облака
      if (context != null) {
        await Provider.of<DatabaseService>(context, listen: false).syncFromCloud();
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Регистрация с email и паролем
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Вход через Google
  Future<UserCredential?> signInWithGoogle({BuildContext? context}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      // После входа — синхронизация из облака
      if (context != null) {
        await Provider.of<DatabaseService>(context, listen: false).syncFromCloud();
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Выход
  Future<void> signOut({BuildContext? context}) async {
    // Перед выходом — синхронизация в облако
    if (context != null) {
      await Provider.of<DatabaseService>(context, listen: false).syncToCloud();
    }
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Сброс пароля
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Получить профиль пользователя
  UserProfile? getCurrentUserProfile() {
    final user = currentUser;
    if (user == null) return null;

    return UserProfile(
      id: user.uid,
      email: user.email!,
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  // Отправка подтверждения email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Проверка верификации email
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Сохранение профиля пользователя в Firebase
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profile.toMap());
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Получение профиля пользователя из Firebase
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          return UserProfile.fromMap(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
} 