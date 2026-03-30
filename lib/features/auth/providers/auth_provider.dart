import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = true;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> signUp(String email, String password, String username) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _firestore.collection('users').doc(_user!.uid).update({'isOnline': true});
  }

  Future<void> signOut() async {
    await _firestore.collection('users').doc(_user!.uid).update({'isOnline': false});
    await _auth.signOut();
  }
}
