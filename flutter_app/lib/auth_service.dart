import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Handle successful sign-up
      return userCredential; // Return the UserCredential object
    } catch (e) {
      // Handle sign-up failure
      print('Error signing up: $e');
      throw e; // Throw the error to propagate it up
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true; // Sign in successful
    } catch (e) {
      print('Error signing in: $e');
      return false; // Sign in failed
    }
  }

  Future<void> signOutAndDeleteAccount() async {
    try {
      await _auth.currentUser?.delete(); // Delete the user's account
      await _auth.signOut(); // Sign out the user
    } catch (e) {
      print('Error signing out and deleting account: $e');
      // Handle sign-out and account deletion failure
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw e; // Throw the error to propagate it up
    }
  }
}
