import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      print('Error compressing profile image: $e');
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
      
      // Update user profile with Google data if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _updateUserProfile(
          displayName: googleUser.displayName,
          photoURL: googleUser.photoUrl,
        );
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('Error: No authenticated user found');
        return null;
      }

      print('Uploading profile image for user: $userId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');

      // Compress the image before upload
      final compressedImageData = await _compressProfileImage(imageFile);
      print('Compressed image size: ${compressedImageData.length} bytes');
      
      final storageRef = _storage.ref().child('profile_images/$userId.jpg');
      print('Storage reference path: ${storageRef.fullPath}');
      
      final uploadTask = storageRef.putData(compressedImageData);
      final snapshot = await uploadTask;
      print('Upload completed successfully');
      
      final downloadURL = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadURL');
      
      return downloadURL;
    } catch (e) {
      print('Error uploading profile image: $e');
      print('Error type: ${e.runtimeType}');
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
      print('Error updating user profile: $e');
    }
  }

  // Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      print('Error updating display name: $e');
      throw e;
    }
  }

  // Update user photo URL
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      print('Error updating photo URL: $e');
      throw e;
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
      print('Error updating profile image: $e');
      throw e;
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
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password, String displayName) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    
    // Update display name (now required)
    await _updateUserProfile(displayName: displayName);
    
    return userCredential;
  }
}