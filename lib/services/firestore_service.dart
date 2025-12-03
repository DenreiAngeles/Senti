import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create User Profile after Sign Up
  Future<void> createUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String status,
    required String goal,
  }) async {
    await _db.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'financialStatus': status, // e.g. "Student"
      'primaryGoal': goal,       // e.g. "New Laptop"
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}