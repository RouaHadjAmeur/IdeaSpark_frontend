import 'package:flutter/material.dart';
import '../models/social_post.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';

class SocialViewModel extends ChangeNotifier {
  final SocialService _socialService = SocialService();

  List<SocialPost> _feed = [];
  List<AppUser> _suggestions = [];
  final List<AppUser> _searchResults = [];
  List<AppUser> _pendingRequests = [];
  Set<String> _followingIds = {};
  final Set<String> _requestedIds = {};
  Set<String> _followerIds = {};
  List<AppUser> _followers = [];
  List<AppUser> _following = [];
  final List<dynamic> _sharedPlans = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = false;
  String? _error;

  List<SocialPost> get feed => _feed;
  List<AppUser> get suggestions => _suggestions;
  List<AppUser> get searchResults => _searchResults;
  List<AppUser> get pendingRequests => _pendingRequests;
  List<AppUser> get followers => _followers;
  List<AppUser> get following => _following;
  List<dynamic> get sharedPlans => _sharedPlans;
  List<Map<String, dynamic>> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool isFollowing(String userId) => _followingIds.contains(userId);
  bool isRequested(String userId) => _requestedIds.contains(userId);
  bool isFollower(String userId) => _followerIds.contains(userId);

  Future<void> fetchInitialData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _socialService.getFeed(),
        _socialService.getSuggestions(),
        _socialService.getFollowing(), // Backend now returns accepted only
        _socialService.getPendingRequests(), // Requests I received
        _socialService.getFollowers(), // People who follow me
      ]);

      _feed = results[0] as List<SocialPost>;
      _suggestions = results[1] as List<AppUser>;
      final followingList = results[2] as List<AppUser>;
      _followingIds = followingList.map((u) => u.id).toSet();
      _pendingRequests = results[3] as List<AppUser>;
      final followersList = results[4] as List<AppUser>;
      _followerIds = followersList.map((u) => u.id).toSet();
      
      // We don't have a direct "requests I sent" endpoint in the plan yet, 
      // but toggleFollow will manage the local _requestedIds state for now.
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingRequests() async {
    try {
      _pendingRequests = await _socialService.getPendingRequests();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String followerId) async {
    try {
      final ok = await _socialService.acceptFollowRequest(followerId);
      if (ok) {
        _pendingRequests.removeWhere((u) => u.id == followerId);
        notifyListeners();
        // Refresh everything (followers, feed, etc.) after accepting
        refreshFeed();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFollow(String userId) async {
    final following = isFollowing(userId);
    final requested = isRequested(userId);
    
    try {
      if (following || requested) {
        await _socialService.unfollowUser(userId);
        _followingIds.remove(userId);
        _requestedIds.remove(userId);
      } else {
        await _socialService.followUser(userId);
        _requestedIds.add(userId);
      }
      notifyListeners();
      refreshFeed();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshFeed() => fetchInitialData();

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _socialService.searchUsers(query);
      _searchResults.clear();
      _searchResults.addAll(results);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchSocialLists(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _socialService.getFollowersById(userId),
        _socialService.getFollowingById(userId),
      ]);
      _followers = results[0];
      _following = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _friends = await _socialService.getFriends();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Shared plans logic was removed in the collaboration service refactor
  // Future<void> fetchSharedPlans(String targetId) async { ... }
}
