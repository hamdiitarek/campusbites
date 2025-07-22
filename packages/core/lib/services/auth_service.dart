import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/models/user.dart' as app;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user
  auth.User? get currentUser => _firebaseAuth.currentUser;

  // Auth state changes stream
  Stream<auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password and store additional user info
  Future<auth.UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Create the user with email and password
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user info in Firestore
      if (credential.user != null) {
        // Make sure email is included in userData
        userData['email'] = email;
        userData['isEmailVerified'] = false; // Initially set to false

        await _storeUserData(
          userId: credential.user!.uid,
          userData: userData,
          isNewUser: true,
        );

        // Send email verification
        await credential.user!.sendEmailVerification();
      }

      return credential;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Store user data in Firestore
  Future<void> _storeUserData({
    required String userId,
    required Map<String, dynamic> userData,
    bool isNewUser = false,
  }) async {
    // Add timestamp for new users
    if (isNewUser) {
      userData['createdAt'] = FieldValue.serverTimestamp();
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .set(userData, SetOptions(merge: true));
  }

  // Get user data from Firestore
  Future<app.User?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Check if Firebase Auth email is verified
        final firebaseUser = _firebaseAuth.currentUser;
        bool firebaseEmailVerified = false;

        if (firebaseUser != null) {
          // Reload to get the latest status
          await firebaseUser.reload();
          firebaseEmailVerified = firebaseUser.emailVerified;

          // If Firebase Auth shows verified but Firestore doesn't, update Firestore
          if (firebaseEmailVerified && !(data['isEmailVerified'] ?? false)) {
            await updateEmailVerificationStatus(userId, true);
            // Update the data object to reflect the change
            data['isEmailVerified'] = true;
          }
        }

        // Create a map with all necessary fields with defaults
        Map<String, dynamic> userMap = {
          'id': userId,
          'fullName': data['fullName'] ?? '',
          'email': data['email'] ?? '',
          'universityId': data['universityId'] ?? '',
          'universityName': data['universityName'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'isEmailVerified': firebaseEmailVerified,
          'role': data['role'] ?? 'student',
          'walletBalance': (data['walletBalance'] ?? 0.0).toDouble(),
          'profileImageUrl': data['profileImageUrl'] ?? '',
        };

        // Add any additional fields from Firestore that might be added in the future
        data.forEach((key, value) {
          if (!userMap.containsKey(key) && key != 'createdAt') {
            userMap[key] = value;
          }
        });

        return _createUserFromMap(userMap);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Clear FCM token before signing out
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId != null) {
        await _storeUserData(
          userId: userId,
          userData: {'fcmToken': ''},
          isNewUser: false,
        );
      }
    } catch (e) {
      print('Error clearing FCM token: $e');
    }

    await _firebaseAuth.signOut();
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check email verification status
  Future<bool> isEmailVerified() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Reload user to get the latest status
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } on auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus(
      String userId, bool isVerified) async {
    try {
      await _storeUserData(
        userId: userId,
        userData: {'isEmailVerified': isVerified},
        isNewUser: false,
      );
    } catch (e) {
      print('Error updating email verification status: $e');
      throw Exception('Failed to update email verification status');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _storeUserData(
        userId: userId,
        userData: userData,
        isNewUser: false,
      );
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  // Update specific user fields - convenience method for simple updates
  Future<void> updateUserFields({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? universityId,
    String? universityName,
    String? profileImageUrl,
    double? walletBalance,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (universityId != null) updates['universityId'] = universityId;
      if (universityName != null) updates['universityName'] = universityName;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (walletBalance != null) updates['walletBalance'] = walletBalance;
      if (role != null) updates['role'] = role;

      if (updates.isNotEmpty) {
        await updateUserProfile(userId: userId, userData: updates);
      }
    } catch (e) {
      print('Error updating user fields: $e');
      throw Exception('Failed to update user fields');
    }
  }

  // Convert a map to a User object
  app.User _createUserFromMap(Map<String, dynamic> map) {
    return app.User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      universityId: map['universityId'] ?? '',
      universityName: map['universityName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      role: map['role'] ?? 'student',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email address is already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
