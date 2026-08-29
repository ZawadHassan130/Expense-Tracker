import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges().map((user) {
        debugPrint(
          '[Auth] state changed: '
          '${user == null ? 'signed out' : 'signed in as ${user.uid}'}',
        );
        return user;
      });

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[Auth] signIn: attempting for $email');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] signIn: succeeded for ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('[Auth] signIn: failed for $email - $e');
      rethrow;
    }
  }

  static Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    debugPrint('[Auth] register: attempting for $email');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] register: succeeded for ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('[Auth] register: failed for $email - $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    final uid = currentUser?.uid;
    debugPrint('[Auth] signOut: attempting for $uid');
    try {
      await _auth.signOut();
      debugPrint('[Auth] signOut: succeeded for $uid');
    } catch (e) {
      debugPrint('[Auth] signOut: failed for $uid - $e');
      rethrow;
    }
  }
}
