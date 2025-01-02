import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import GoogleSignIn
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:kwc_app/models/user.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn =
      GoogleSignIn(); // Create a GoogleSignIn instance
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Create user obj based on FirebaseUser
  Users? _userFromFirebaseUser(User? us) {
    return us != null ? Users(uid: us.uid) : null;
  }

  // Auth change user stream
  Stream<Users?> get user {
    return auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Sign in anonymously
  Future signInAnon() async {
    try {
      UserCredential result = await auth.signInAnonymously();
      User? u = result.user;
      return _userFromFirebaseUser(u!);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign in with email & password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? u = result.user;
      return _userFromFirebaseUser(u);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register with email & password
  Future registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create Firestore document for the user
        await firestore.collection('users').doc(user.uid).set({
          'balance': 0,
          'role': 'user',
          'transactions': [],
        });

        return _userFromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print("Error registering user: $e");
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      return null;
    }
  }

  // Sign out for all auth methods (email, anon, and Google)
  Future signOut() async {
    try {
      await auth.signOut();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Method to get the user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  // Method to update the user profile
  Future<bool> updateUserProfile(String uid, String name, String username,
      String address, String age) async {
    try {
      await firestore.collection('users').doc(uid).set(
          {
            'name': name,
            'username': username,
            'address': address,
            'age': age,
          },
          SetOptions(
              merge:
                  true)); // Merging data to avoid overwriting entire document
      return true;
    } catch (e) {
      print("Error updating user profile: $e");
      return false;
    }
  }

  // Update the user's email
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Ensure the user is reauthenticated if needed
        await user.verifyBeforeUpdateEmail(newEmail);
      } else {
        throw Exception("No user is currently signed in.");
      }
    } catch (e) {
      throw Exception("Error updating email: $e");
    }
  }

  // Send a password reset email
  Future<void> resetPassword(String currentPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Send password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      } else {
        throw Exception("No user is currently signed in.");
      }
    } catch (e) {
      throw Exception("Error sending password reset email: $e");
    }
  }
}
