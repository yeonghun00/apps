import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/app_user.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize Google Sign In
  static Future<void> initializeGoogleSignIn() async {
    try {
      // Initialize with explicit serverClientId for Android
      // This is your web client ID from Firebase Console
      await _googleSignIn.initialize(
        serverClientId: '1090241694132-cu1bv8ov8g44gaiklti5q8reg0s8guqt.apps.googleusercontent.com',
      );
    } catch (e) {
      print('Error initializing Google Sign In: $e');
      print('Make sure to enable Google Sign-In in Firebase Console and add the correct serverClientId');
    }
  }

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Get current app user
  static Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
      
      // Create new user document if it doesn't exist
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '익명',
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isEmailVerified: user.emailVerified,
      );
      
      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
      return appUser;
    } catch (e) {
      print('Error getting current app user: $e');
      return null;
    }
  }

  // Silent sign in (lightweight authentication)
  static Future<UserCredential?> signInSilently() async {
    try {
      await initializeGoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.attemptLightweightAuthentication();
      
      if (googleUser == null) {
        return null; // No cached user
      }
      
      return await _signInWithGoogleAccount(googleUser);
    } catch (e) {
      print('Error in silent sign in: $e');
      return null;
    }
  }

  // Sign in with Google (interactive)
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await initializeGoogleSignIn();
      
      // Check if authenticate is supported
      if (_googleSignIn.supportsAuthenticate()) {
        // Use the new authenticate method for v7.1.0+
        final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
        
        if (googleUser == null) {
          return null; // User canceled the sign-in
        }
        
        return await _signInWithGoogleAccount(googleUser);
      } else {
        // Fallback - try lightweight authentication
        return await signInSilently();
      }
    } on PlatformException catch (e) {
      print('Platform error signing in with Google: $e');
      await _googleSignIn.signOut();
      rethrow;
    } catch (e) {
      print('Error signing in with Google: $e');
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // Helper method to sign in with Google account
  static Future<UserCredential> _signInWithGoogleAccount(GoogleSignInAccount googleUser) async {
    // Get ID token for Firebase authentication
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    
    // For Firebase, we only need the ID token
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credentials
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    // Update user document in Firestore
    if (userCredential.user != null) {
      await _updateUserDocument(userCredential.user!);
    }
    
    return userCredential;
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user document in Firestore
      await _updateUserDocument(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  // Create account with email and password
  static Future<UserCredential?> createAccountWithEmailPassword(
    String email, 
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      
      // Send email verification
      await userCredential.user!.sendEmailVerification();
      
      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, displayName);
      
      return userCredential;
    } catch (e) {
      print('Error creating account: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('Error sending email verification: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  static Future<void> _createUserDocument(User user, String displayName) async {
    try {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
        isEmailVerified: user.emailVerified,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // Update user document in Firestore
  static Future<void> _updateUserDocument(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (doc.exists) {
        // Update existing user
        await userRef.update({
          'lastSignIn': DateTime.now().toIso8601String(),
          'isEmailVerified': user.emailVerified,
          'displayName': user.displayName ?? doc.data()!['displayName'],
          'photoURL': user.photoURL,
        });
      } else {
        // Create new user document
        await _createUserDocument(user, user.displayName ?? '익명');
      }
    } catch (e) {
      print('Error updating user document: $e');
      rethrow;
    }
  }

  // Update user display name
  static Future<void> updateDisplayName(String newDisplayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다.');
      
      // Update Firebase Auth display name
      await user.updateDisplayName(newDisplayName);
      
      // Update Firestore user document
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': newDisplayName,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reload user to get updated info
      await user.reload();
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  // Delete user account and all associated data
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('사용자가 로그인되어 있지 않습니다.');
      
      final userId = user.uid;
      
      // Delete user data from Firestore
      // Note: In production, consider using Cloud Functions for better data cleanup
      try {
        // Delete user document
        await _firestore.collection('users').doc(userId).delete();
        
        // Delete user's community posts
        final postsQuery = await _firestore
            .collection('community_posts')
            .where('authorId', isEqualTo: userId)
            .get();
        
        final batch = _firestore.batch();
        for (final doc in postsQuery.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete user's comments
        final commentsQuery = await _firestore
            .collection('comments')
            .where('authorId', isEqualTo: userId)
            .get();
        
        for (final doc in commentsQuery.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete user's reactions
        final reactionsQuery = await _firestore
            .collection('reactions')
            .where('userId', isEqualTo: userId)
            .get();
        
        for (final doc in reactionsQuery.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
      } catch (e) {
        print('Error deleting user data from Firestore: $e');
        // Continue with account deletion even if Firestore cleanup fails
      }
      
      // Sign out from Google if signed in with Google
      if (user.providerData.any((info) => info.providerId == 'google.com')) {
        await _googleSignIn.signOut();
      }
      
      // Delete the Firebase Auth account
      await user.delete();
      
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Get auth error message
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return '등록되지 않은 이메일입니다.';
        case 'wrong-password':
          return '비밀번호가 올바르지 않습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'weak-password':
          return '비밀번호가 너무 약합니다. 6자리 이상 입력해주세요.';
        case 'invalid-email':
          return '올바르지 않은 이메일 형식입니다.';
        case 'user-disabled':
          return '비활성화된 계정입니다.';
        case 'too-many-requests':
          return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        case 'operation-not-allowed':
          return '현재 이 로그인 방법을 사용할 수 없습니다.';
        default:
          return error.message ?? '알 수 없는 오류가 발생했습니다.';
      }
    }
    return error.toString();
  }
}