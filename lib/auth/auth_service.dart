import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String username,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .signInWithEmailAndPassword(email: username, password: password);
    return userCredential;
  }

  //Register Add Account
  Future<UserCredential> createAccount({
    required String username,
    required String display,
    required String password,
    String role = "user",
  }) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: username, password: password);

    await firestore.collection("users").doc(userCredential.user!.uid).set({
      "displayname": display,
      "role": role,
      "username": username,
    });

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String username}) async {
    await firebaseAuth.sendPasswordResetEmail(email: username);
  }

  // Update user's display name
  Future<void> updateUserName(String displayName) async {
    final user = firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(displayName);
        await firestore.collection("users").doc(user.uid).update({
          "displayname": displayName,
        });
      } on FirebaseException catch (e) {
        debugPrint("Firebase Error: ${e.code}");
        debugPrint(e.message);
        rethrow;
      } catch (e) {
        debugPrint("Error updating user name: $e");
        rethrow;
      }
    }
  }
}
