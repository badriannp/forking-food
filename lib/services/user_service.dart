import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache pentru user-ii încărcați
  final Map<String, UserData> _userCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration: 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get user data with intelligent caching
  Future<UserData> getUserData(String userId) async {
    try {
      // Check if we have valid cached data
      if (_isCacheValid(userId)) {
        print('Using cached user data for: $userId');
        return _userCache[userId]!;
      }

      print('Loading user data from Firestore for: $userId');
      
      // Load from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('User document not found: $userId');
        throw Exception('User not found: $userId');
      }

      final userData = UserData.fromMap(userDoc.data() as Map<String, dynamic>, userId);
      
      // Save to cache
      _userCache[userId] = userData;
      _cacheTimestamps[userId] = DateTime.now();
      
      print('Cached user data for: $userId - Name: ${userData.displayName}, Photo: ${userData.photoURL}');
      return userData;
      
    } catch (e) {
      print('Error loading user data for $userId: $e');
      throw Exception('Failed to load user data: $e');
    }
  }

  /// Get multiple users data efficiently
  Future<Map<String, UserData>> getMultipleUsersData(List<String> userIds) async {
    try {
      final Map<String, UserData> result = {};
      final List<String> usersToLoad = [];

      // Check cache first
      for (String userId in userIds) {
        if (_isCacheValid(userId)) {
          result[userId] = _userCache[userId]!;
        } else {
          usersToLoad.add(userId);
        }
      }

      // Load missing users from Firestore
      if (usersToLoad.isNotEmpty) {
        print('Loading ${usersToLoad.length} users from Firestore');
        
        // Load in batches of 10 (Firestore limit)
        const int batchSize = 10;
        for (int i = 0; i < usersToLoad.length; i += batchSize) {
          final batch = usersToLoad.skip(i).take(batchSize).toList();
          
          final querySnapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (DocumentSnapshot doc in querySnapshot.docs) {
            final userData = UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            result[doc.id] = userData;
            
            // Cache the data
            _userCache[doc.id] = userData;
            _cacheTimestamps[doc.id] = DateTime.now();
          }
        }
      }

      return result;
      
    } catch (e) {
      print('Error loading multiple users data: $e');
      throw Exception('Failed to load multiple users data: $e');
    }
  }

  /// Create or update user data
  Future<void> createOrUpdateUser(UserData userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userData.id)
          .set(userData.toMap(), SetOptions(merge: true));
      
      // Update cache
      _userCache[userData.id] = userData;
      _cacheTimestamps[userData.id] = DateTime.now();
      
      print('Updated user data for: ${userData.id}');
      
    } catch (e) {
      print('Error creating/updating user data: $e');
      throw Exception('Failed to create/update user data: $e');
    }
  }

  /// Update user display name
  Future<void> updateUserDisplayName(String userId, String displayName) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'displayName': displayName,
            'lastUpdated': Timestamp.now(),
          });
      
      // Update cache if exists
      if (_userCache.containsKey(userId)) {
        _userCache[userId] = _userCache[userId]!.copyWith(displayName: displayName);
        _cacheTimestamps[userId] = DateTime.now();
      }
      
      print('Updated display name for user: $userId');
      
    } catch (e) {
      print('Error updating user display name: $e');
      throw Exception('Failed to update user display name: $e');
    }
  }

  /// Update user photo URL
  Future<void> updateUserPhotoURL(String userId, String photoURL) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'photoURL': photoURL,
            'lastUpdated': Timestamp.now(),
          });
      
      // Update cache if exists
      if (_userCache.containsKey(userId)) {
        _userCache[userId] = _userCache[userId]!.copyWith(photoURL: photoURL);
        _cacheTimestamps[userId] = DateTime.now();
      }
      
      print('Updated photo URL for user: $userId');
      
    } catch (e) {
      print('Error updating user photo URL: $e');
      throw Exception('Failed to update user photo URL: $e');
    }
  }

  /// Clear cache for a specific user
  void clearUserCache(String userId) {
    _userCache.remove(userId);
    _cacheTimestamps.remove(userId);
    print('Cleared cache for user: $userId');
  }

  /// Clear all cache
  void clearAllCache() {
    _userCache.clear();
    _cacheTimestamps.clear();
    print('Cleared all user cache');
  }

  /// Check if cache is valid for a user
  bool _isCacheValid(String userId) {
    if (!_userCache.containsKey(userId) || !_cacheTimestamps.containsKey(userId)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[userId]!;
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheDuration;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedUsers': _userCache.length,
      'cacheTimestamps': _cacheTimestamps.length,
    };
  }
} 