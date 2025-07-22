import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:core/models/user.dart' as app;
import 'package:core/services/auth_service.dart';
import 'package:core/services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  app.User? _user;
  bool _isLoading = false;
  String _error = '';

  app.User? get user => _user;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _authService.currentUser != null;

  UserProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        _isLoading = true;
        notifyListeners();

        try {
          final userData = await _authService.getUserData(firebaseUser.uid);
          _user = userData;
          _error = '';
        } catch (e) {
          _error = e.toString();
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password,
      {GlobalKey<NavigatorState>? navigatorKey}) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // Initialize the notification service to set up FCM token
      if (navigatorKey != null) {
        await NotificationService().init(navigatorKey: navigatorKey);
      }
      _setError('');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String universityId,
    required String universityName,
    required String phoneNumber,
    String role = 'student',
  }) async {
    _setLoading(true);
    try {
      final userData = {
        'fullName': fullName,
        'universityId': universityId,
        'universityName': universityName,
        'phoneNumber': phoneNumber,
        'role': role,
        'walletBalance': 0.0,
        'profileImageUrl': '',
      };

      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        userData: userData,
      );

      // Vendor document creation is now handled by Firebase Cloud Function
      // when a user with role 'vendor' is created

      _setError('');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Clear FCM token in NotificationService
      await NotificationService().clearToken();
      // Sign out user
      await _authService.signOut();
      _user = null;
      _setError('');
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _setError('');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? universityId,
    String? universityName,
    String? profileImageUrl,
    double? walletBalance,
    String? role,
  }) async {
    if (_user == null || _authService.currentUser == null) return false;

    _setLoading(true);
    try {
      final userId = _authService.currentUser!.uid;

      // Create a map of user data to update
      final userData = <String, dynamic>{};
      if (fullName != null) userData['fullName'] = fullName;
      if (phoneNumber != null) userData['phoneNumber'] = phoneNumber;
      if (universityId != null) userData['universityId'] = universityId;
      if (universityName != null) userData['universityName'] = universityName;
      if (profileImageUrl != null)
        userData['profileImageUrl'] = profileImageUrl;
      if (walletBalance != null) userData['walletBalance'] = walletBalance;
      if (role != null) userData['role'] = role;

      await _authService.updateUserProfile(
        userId: userId,
        userData: userData,
      );

      // Update local user data
      final updatedUser = await _authService.getUserData(userId);
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send verification email
  Future<bool> sendVerificationEmail() async {
    if (_authService.currentUser == null) return false;

    _setLoading(true);
    try {
      await _authService.sendEmailVerification();
      _setError('');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerification() async {
    if (_authService.currentUser == null) return false;

    _setLoading(true);
    try {
      final isVerified = await _authService.isEmailVerified();

      if (isVerified && _user != null && !_user!.isEmailVerified) {
        // If email is verified but our local user object doesn't reflect that,
        // update Firestore and reload the user data
        await _authService.updateEmailVerificationStatus(
            _authService.currentUser!.uid, true);
        final updatedUser =
            await _authService.getUserData(_authService.currentUser!.uid);
        if (updatedUser != null) {
          _user = updatedUser;
          notifyListeners();
        }
      }

      _setError('');
      return isVerified;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createVendorAccount({
    required String email,
    required String password,
    required String fullName,
    required String universityId,
    required String universityName,
    required String phoneNumber,
  }) async {
    _setLoading(true);
    try {
      // Call the cloud function to create vendor account without signing in
      final httpsCallable =
          FirebaseFunctions.instance.httpsCallable('createVendorAccount');

      final result = await httpsCallable.call({
        'email': email,
        'password': password,
        'fullName': fullName,
        'universityId': universityId,
        'universityName': universityName,
        'phoneNumber': phoneNumber,
      });

      if (result.data['success'] == true) {
        _setError('');
        return true;
      } else {
        _setError(result.data['message'] ?? 'Failed to create vendor account');
        return false;
      }
    } catch (e) {
      if (e.toString().contains('already-exists')) {
        _setError('A user with this email already exists');
      } else if (e.toString().contains('invalid-argument')) {
        _setError('Invalid input data provided');
      } else if (e.toString().contains('permission-denied')) {
        _setError('You do not have permission to create vendor accounts');
      } else {
        _setError('Failed to create vendor account: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createVendorDocumentManually({required String vendorId}) async {
    _setLoading(true);
    try {
      // Call the cloud function to create vendor document with subcollections
      final httpsCallable = FirebaseFunctions.instance
          .httpsCallable('createVendorDocumentManually');

      final result = await httpsCallable.call({
        'vendorId': vendorId,
      });

      if (result.data['success'] == true) {
        _setError('');
        return true;
      } else {
        _setError(result.data['message'] ?? 'Failed to create vendor document');
        return false;
      }
    } catch (e) {
      if (e.toString().contains('already-exists')) {
        _setError('Vendor document already exists');
      } else if (e.toString().contains('not-found')) {
        _setError('User not found');
      } else if (e.toString().contains('invalid-argument')) {
        _setError('User is not a vendor or invalid vendor ID');
      } else if (e.toString().contains('permission-denied')) {
        _setError('You do not have permission to create vendor documents');
      } else {
        _setError('Failed to create vendor document: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
