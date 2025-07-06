import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post.dart';
import '../models/comment.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class FirebaseCommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _postsCollection = 'community_posts';
  static const String _usersCollection = 'users';
  static const String _reactionsCollection = 'reactions';
  static const String _commentsCollection = 'comments';

  // Get posts stream
  static Stream<List<CommunityPost>> getPostsStream({PostCategory? category}) {
    Query query = _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CommunityPost.fromJson(data);
      }).toList();
    });
  }

  // Create post
  static Future<String> createPost({
    required String title,
    required String content,
    required PostCategory category,
    String? scriptureReference,
  }) async {
    try {
      final user = await AuthService.getCurrentAppUser();
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      final post = CommunityPost(
        authorId: user.uid, // Use uid as consistent identifier
        authorName: user.displayName,
        title: title,
        content: content,
        category: category,
        scriptureReference: scriptureReference,
      );

      final docRef = await _firestore
          .collection(_postsCollection)
          .add(post.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Update post
  static Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update(updates);
    } catch (e) {
      print('Error updating post: $e');
      rethrow;
    }
  }

  // Delete post
  static Future<void> deletePost(String postId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      // Check if user owns the post
      final doc = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .get();

      if (!doc.exists) {
        throw Exception('게시글을 찾을 수 없습니다.');
      }

      final postData = doc.data()!;
      // Check both uid and email for backward compatibility
      final authorId = postData['authorId'];
      if (authorId != user.uid && authorId != user.email) {
        throw Exception('게시글을 삭제할 권한이 없습니다.');
      }

      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .delete();

      // Also delete related reactions
      final reactionsQuery = await _firestore
          .collection(_reactionsCollection)
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (final doc in reactionsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // Toggle Amen reaction
  static Future<bool> toggleAmenReaction(String postId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      final reactionId = '${user.uid}_$postId';
      final reactionRef = _firestore
          .collection(_reactionsCollection)
          .doc(reactionId);

      final reactionDoc = await reactionRef.get();
      
      if (reactionDoc.exists) {
        // Remove reaction
        await reactionRef.delete();
        await _updatePostAmenCount(postId, -1);
        return false;
      } else {
        // Add reaction
        await reactionRef.set({
          'userId': user.uid,
          'postId': postId,
          'type': 'amen',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _updatePostAmenCount(postId, 1);
        return true;
      }
    } catch (e) {
      print('Error toggling amen reaction: $e');
      rethrow;
    }
  }

  // Update post amen count
  static Future<void> _updatePostAmenCount(String postId, int delta) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update({
        'amenCount': FieldValue.increment(delta),
      });
    } catch (e) {
      print('Error updating amen count: $e');
      rethrow;
    }
  }

  // Check if user has reacted to post
  static Future<bool> hasUserReacted(String postId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      final reactionId = '${user.uid}_$postId';
      final reactionDoc = await _firestore
          .collection(_reactionsCollection)
          .doc(reactionId)
          .get();

      return reactionDoc.exists;
    } catch (e) {
      print('Error checking user reaction: $e');
      return false;
    }
  }

  // Get posts by user
  static Stream<List<CommunityPost>> getUserPostsStream(String userId) {
    return _firestore
        .collection(_postsCollection)
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CommunityPost.fromJson(data);
      }).toList();
    });
  }

  // Get popular posts (most amen reactions)
  static Stream<List<CommunityPost>> getPopularPostsStream({int limit = 10}) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('amenCount', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CommunityPost.fromJson(data);
      }).toList();
    });
  }

  // Search posts
  static Future<List<CommunityPost>> searchPosts(String query) async {
    try {
      // Firebase doesn't support full-text search natively
      // This is a simple implementation that searches in title and content
      // For production, consider using Algolia or ElasticSearch
      
      final titleResults = await _firestore
          .collection(_postsCollection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final contentResults = await _firestore
          .collection(_postsCollection)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      final Set<String> seenIds = {};
      final List<CommunityPost> posts = [];

      for (final doc in [...titleResults.docs, ...contentResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          final data = doc.data();
          data['id'] = doc.id;
          posts.add(CommunityPost.fromJson(data));
        }
      }

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      print('Error searching posts: $e');
      rethrow;
    }
  }

  // ========== COMMENTS FUNCTIONALITY ==========

  // Get comments for a post
  static Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection(_commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Comment.fromJson(data);
      }).toList();
    });
  }

  // Add comment to post
  static Future<String> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final user = await AuthService.getCurrentAppUser();
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      final comment = Comment(
        postId: postId,
        authorId: user.email, // Use email as consistent identifier
        authorName: user.displayName,
        content: content,
      );

      final docRef = await _firestore
          .collection(_commentsCollection)
          .add(comment.toJson());

      // Update post comment count
      await _updatePostCommentCount(postId, 1);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Delete comment
  static Future<void> deleteComment(String commentId, String postId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      // Check if user owns the comment
      final doc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();

      if (!doc.exists) {
        throw Exception('댓글을 찾을 수 없습니다.');
      }

      final commentData = doc.data()!;
      if (commentData['authorId'] != user.uid) {
        throw Exception('댓글을 삭제할 권한이 없습니다.');
      }

      await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .delete();

      // Update post comment count
      await _updatePostCommentCount(postId, -1);
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Toggle Amen reaction on comment
  static Future<bool> toggleCommentAmenReaction(String commentId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      final reactionId = '${user.uid}_comment_$commentId';
      final reactionRef = _firestore
          .collection(_reactionsCollection)
          .doc(reactionId);

      final reactionDoc = await reactionRef.get();
      
      if (reactionDoc.exists) {
        // Remove reaction
        await reactionRef.delete();
        await _updateCommentAmenCount(commentId, -1);
        return false;
      } else {
        // Add reaction
        await reactionRef.set({
          'userId': user.uid,
          'commentId': commentId,
          'type': 'amen',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _updateCommentAmenCount(commentId, 1);
        return true;
      }
    } catch (e) {
      print('Error toggling comment amen reaction: $e');
      rethrow;
    }
  }

  // Update post comment count
  static Future<void> _updatePostCommentCount(String postId, int delta) async {
    try {
      await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(delta),
      });
    } catch (e) {
      print('Error updating comment count: $e');
      rethrow;
    }
  }

  // Update comment amen count
  static Future<void> _updateCommentAmenCount(String commentId, int delta) async {
    try {
      await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .update({
        'amenCount': FieldValue.increment(delta),
      });
    } catch (e) {
      print('Error updating comment amen count: $e');
      rethrow;
    }
  }

  // Check if user has reacted to comment
  static Future<bool> hasUserReactedToComment(String commentId) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return false;

      final reactionId = '${user.uid}_comment_$commentId';
      final reactionDoc = await _firestore
          .collection(_reactionsCollection)
          .doc(reactionId)
          .get();

      return reactionDoc.exists;
    } catch (e) {
      print('Error checking user reaction to comment: $e');
      return false;
    }
  }

  // ========== SHARE TO COMMUNITY FUNCTIONALITY ==========

  // Create post from note sharing
  static Future<String> createPostFromNote({
    required String noteType, // 'sermon' or 'devotion'
    required String title,
    required String content,
    required String scriptureReference,
  }) async {
    try {
      final user = await AuthService.getCurrentAppUser();
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      final postTitle = noteType == 'sermon' ? '📖 설교노트 나눔: $title' : '🙏 큐티노트 나눔: $title';
      final postContent = '''$content

📖 말씀: $scriptureReference

${noteType == 'sermon' ? '주일예배에서 받은 은혜를 나눕니다.' : '오늘 큐티를 통해 받은 은혜를 나눕니다.'}''';

      final post = CommunityPost(
        authorId: user.uid,
        authorName: user.displayName,
        title: postTitle,
        content: postContent,
        category: noteType == 'sermon' ? PostCategory.sermonSharing : PostCategory.devotionSharing,
        scriptureReference: scriptureReference,
      );

      final docRef = await _firestore
          .collection(_postsCollection)
          .add(post.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating post from note: $e');
      rethrow;
    }
  }
}