import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // --- EMAIL/PASSWORD ---
  
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign up.";
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign in.";
    }
  }

  // --- GOOGLE SIGN IN ---
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign In Error: $e");
      throw "Google Sign In Failed. Check your network or SHA-1 key.";
    }
  }

    Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors (e.g., user not found, invalid email)
      throw e.message ?? "An error occurred while sending reset email.";
    }
  }

  // --- SIGN OUT ---
  
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Sign out of Google too
    await _auth.signOut();
  }

}