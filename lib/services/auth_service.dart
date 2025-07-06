import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:forking/utils/image_utils.dart' as image_utils;
import '../models/user_data.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserService _userService = UserService();

  // Profile photo dimensions
  static const int profilePhotoSize = 200; // 200x200px for optimal quality/size balance

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Compress and resize profile image
  Future<Uint8List> _compressProfileImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Resize la 200x200
      final finalImage = img.copyResize(
        image,
        width: profilePhotoSize,
        height: profilePhotoSize,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(finalImage, quality: 85));
    } catch (e) {
      // Fallback to original image if compression fails
      return await imageFile.readAsBytes();
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Process Google profile photo for new users
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDataForGoogleSignIn(
          userId: userCredential.user!.uid,
          googlePhotoURL: googleUser.photoUrl,
          displayName: googleUser.displayName,
        );
      }
      
      return userCredential;
    } catch (e) {
      return null;
    }
  }

  // Facebook Sign-In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the authentication flow
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );
      
      if (result.status != LoginStatus.success) {
        // User cancelled the sign-in
        return null;
      }

      // Create a credential from the access token
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Process Facebook profile data for new users
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserDataForFacebookSignIn(
          userId: userCredential.user!.uid,
          facebookPhotoURL: userCredential.user?.photoURL,
          displayName: userCredential.user?.displayName,
        );
      }
      
      return userCredential;
    } catch (e) {
      return null;
    }
  }

  /// Create user data for new Google sign-in users
  Future<void> _createUserDataForGoogleSignIn({
    required String userId,
    String? googlePhotoURL,
    String? displayName,
  }) async {
    try {
      
      // Better fallback: use email prefix if no display name
      String finalDisplayName = displayName ?? 'User';
      if (displayName == null || displayName.isEmpty) {
        final email = _auth.currentUser?.email;
        if (email != null && email.isNotEmpty) {
          // Use email prefix (before @) as display name
          finalDisplayName = email.split('@')[0];
        }
      }
      
      if (googlePhotoURL == null || googlePhotoURL.isEmpty) {
        // No photo from Google, just create user data with display name
        await _createUserData(userId, finalDisplayName);
        return;
      }

      // Create user data with Google photo URL
      await _createUserData(userId, finalDisplayName, googlePhotoURL);

    } catch (e) {
      // Fallback to creating user data without photo
      await _createUserData(userId, displayName ?? 'User');
    }
  }

  /// Create user data for new Facebook sign-in users
  Future<void> _createUserDataForFacebookSignIn({
    required String userId,
    String? facebookPhotoURL,
    String? displayName,
  }) async {
    try {
      
      // Better fallback: use email prefix if no display name
      String finalDisplayName = displayName ?? 'User';
      if (displayName == null || displayName.isEmpty) {
        final email = _auth.currentUser?.email;
        if (email != null && email.isNotEmpty) {
          // Use email prefix (before @) as display name
          finalDisplayName = email.split('@')[0];
        }
      }
      
      if (facebookPhotoURL == null || facebookPhotoURL.isEmpty) {
        // No photo from Facebook, just create user data with display name
        await _createUserData(userId, finalDisplayName);
        return;
      }

      // Create user data with Facebook photo URL (no copying)
      await _createUserData(userId, finalDisplayName, facebookPhotoURL);

    } catch (e) {
      // Fallback to creating user data without photo
      await _createUserData(userId, displayName ?? 'User');
    }
  }

  /// Create user data in centralized system
  Future<void> _createUserData(String userId, String displayName, [String? photoURL]) async {
    try {
      final userData = UserData(
        id: userId,
        displayName: displayName,
        photoURL: photoURL,
        email: _auth.currentUser?.email,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      await _userService.createOrUpdateUser(userData);
      
    } catch (e) {
      // Error creating user data 
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _facebookAuth.logOut(),
      ]);
    } catch (e) {
      // Error signing out
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return null;
      }

      // Compress the image before upload
      final compressedImageData = await _compressProfileImage(imageFile);
      
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');
      
      final metadata = SettableMetadata(contentType: image_utils.getContentTypeFromPath(imageFile.path));
      final uploadTask = storageRef.putData(compressedImageData, metadata);
      final snapshot = await uploadTask;
      
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      return downloadURL;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> _updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }
    } catch (e) {
      // Error updating user profile
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user');
      
      // Update Firebase Auth
      await _auth.currentUser?.updateDisplayName(displayName);
      
      // Update centralized user data
      await _userService.updateUserDisplayName(userId, displayName);
      
    } catch (e) {
      rethrow;
    }
  }

  // Update user photo URL
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('No authenticated user');
      
      // Update Firebase Auth
      await _auth.currentUser?.updatePhotoURL(photoURL);
      
      // Update centralized user data
      await _userService.updateUserPhotoURL(userId, photoURL);
      
    } catch (e) {
      rethrow;
    }
  }

  // Update profile image (upload and update user profile)
  Future<void> updateProfileImage(File imageFile) async {
    try {
      final downloadURL = await uploadProfileImage(imageFile);
      if (downloadURL != null) {
        await updatePhotoURL(downloadURL);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user photo URL
  String? get userPhotoURL => _auth.currentUser?.photoURL;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Legacy methods for email/password (keeping for compatibility)
  Future<UserCredential> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    
    // Ensure user data exists in centralized system for existing users
    final userId = userCredential.user?.uid;
    if (userId != null) {
      try {
        // Try to get existing user data
        await _userService.getUserData(userId);
      } catch (e) {
        // User data doesn't exist, create it
        await _createUserData(
          userId, 
          userCredential.user?.displayName ?? 'User',
          userCredential.user?.photoURL,
        );
      }
    }
    
    return userCredential;
  }

  Future<UserCredential> register(String email, String password, String displayName) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    // Update display name in Firebase Auth
    await _updateUserProfile(displayName: displayName);
    
    // Create user data in centralized system
    final userId = userCredential.user?.uid;
    if (userId != null) {
      await _createUserData(userId, displayName);
    }
    
    return userCredential;
  }
}