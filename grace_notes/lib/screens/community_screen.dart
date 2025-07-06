import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/community_post.dart';
import '../models/comment.dart';
import '../services/firebase_community_service.dart';
import '../services/auth_service.dart';
import '../widgets/simple_bible_selector.dart';
import 'auth/login_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  PostCategory? _selectedCategory;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _isLoggedIn = AuthService.isSignedIn;
    });
  }

  void _showLoginScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    ).then((_) {
      _checkAuthStatus(); // Refresh auth status when returning
    });
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.signOut();
      _checkAuthStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.9),
                    AppTheme.lavender.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.people,
                    size: 64,
                    color: AppTheme.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '믿음 나눔에 참여하세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '기도 요청을 나누고\n함께 은혜를 경험해보세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showLoginScreen,
              icon: const Icon(Icons.login),
              label: const Text('로그인하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: AppTheme.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsStream() {
    return StreamBuilder<List<CommunityPost>>(
      stream:
          FirebaseCommunityService.getPostsStream(category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.softGray,
                ),
                const SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.softGray,
                  ),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(post);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: const Text(
          '믿음 나눔',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
        actions: [
          if (_isLoggedIn) ...[
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.textDark),
              onPressed: _handleSignOut,
            ),
          ] else ...[
            TextButton(
              onPressed: _showLoginScreen,
              child: const Text(
                '로그인',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          if (!_isLoggedIn) _buildLoginBanner(),
          Expanded(
            child: _buildPostsStream(),
          ),
        ],
      ),
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              heroTag: "community_fab",
              onPressed: () => _showCreatePostDialog(),
              backgroundColor: AppTheme.mint,
              child: const Icon(Icons.add, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildLoginBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.lavender.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.login,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '로그인하고 참여해보세요! 💜',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '게시글 작성과 댓글 참여를 위해 로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showLoginScreen,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.login,
              color: AppTheme.primaryPurple,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              '로그인이 필요합니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          '게시글 상세보기, 댓글 작성, 아멘 반응을 위해서는 로그인이 필요합니다.\n\n지금 로그인하시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(
                color: AppTheme.softGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showLoginScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '로그인하기',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('전체', null),
            const SizedBox(width: 8),
            _buildCategoryChip('큐티나눔', PostCategory.devotionSharing),
            const SizedBox(width: 8),
            _buildCategoryChip('설교나눔', PostCategory.sermonSharing),
            const SizedBox(width: 8),
            _buildCategoryChip('기도요청', PostCategory.prayerRequest),
            const SizedBox(width: 8),
            _buildCategoryChip('간증', PostCategory.testimony),
            const SizedBox(width: 8),
            _buildCategoryChip('질문', PostCategory.question),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, PostCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: AppTheme.white,
      selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryPurple : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  String _getCategoryDisplayName(PostCategory? category) {
    if (category == null) return '전체';
    switch (category) {
      case PostCategory.devotionSharing:
        return '큐티나눔';
      case PostCategory.sermonSharing:
        return '설교나눔';
      case PostCategory.prayerRequest:
        return '기도요청';
      case PostCategory.testimony:
        return '간증';
      case PostCategory.question:
        return '질문';
    }
  }

  Widget _buildEmptyState() {
    final categoryName = _getCategoryDisplayName(_selectedCategory);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.8),
                    AppTheme.lavender.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _selectedCategory == null
                  ? '함께 나누는 첫 번째 이야기를 시작해보세요 💜'
                  : '$categoryName에서 첫 번째 이야기를 나눠보세요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 36),
            Container(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _showCreatePostDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.edit_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      '첫 번째 글 작성하기',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_selectedCategory) {
      case PostCategory.devotionSharing:
        return '오늘 큐티에서 받은 은혜를\n자매들과 함께 나누어보세요';
      case PostCategory.sermonSharing:
        return '주일 설교에서 받은 감동을\n다른 분들께도 전해주세요';
      case PostCategory.prayerRequest:
        return '함께 기도해 줄 자매들이\n여기에서 기다리고 있어요';
      case PostCategory.testimony:
        return '하나님의 놀라운 역사하심을\n간증으로 나누어주세요';
      case PostCategory.question:
        return '궁금한 것이 있으시면\n언제든 편하게 물어보세요';
      default:
        return '서로의 믿음을 격려하고\n함께 성장해나가는 공간이에요';
    }
  }

  Widget _buildPostCard(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _isLoggedIn ? _showPostDetails(post) : _showLoginRequiredDialog(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _getCategoryColor(post.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.categoryDisplayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(post.category),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.softGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.scriptureReference != null &&
                        post.scriptureReference!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.sageGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.scriptureReference!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.sageGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.volunteer_activism,
                              size: 16,
                              color: AppTheme.primaryPurple.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '아멘 ${post.amenCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryPurple.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 16,
                              color: AppTheme.sageGreen.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '댓글 ${post.commentCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.sageGreen.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.softGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Overlay for non-logged users
            if (!_isLoggedIn)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '로그인하여 보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.devotionSharing:
        return AppTheme.sageGreen;
      case PostCategory.sermonSharing:
        return AppTheme.primaryPurple;
      case PostCategory.prayerRequest:
        return AppTheme.coral;
      case PostCategory.testimony:
        return AppTheme.mint;
      case PostCategory.question:
        return AppTheme.lavender;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostDialog(
        onPostCreated: () {
          // Posts will automatically update via stream
        },
      ),
    );
  }

  void _showPostDetails(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StreamBuilder<List<CommunityPost>>(
        stream: FirebaseCommunityService.getPostsStream(),
        builder: (context, snapshot) {
          // Find the current post in the stream data
          CommunityPost currentPost = post;
          if (snapshot.hasData) {
            final updatedPost = snapshot.data!.firstWhere(
              (p) => p.id == post.id,
              orElse: () => post,
            );
            currentPost = updatedPost;
          }

          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxHeight = screenHeight * 0.9;
          final minHeight = screenHeight * 0.5;
          final dynamicHeight = (screenHeight * 0.8) - keyboardHeight;
          
          return Container(
            height: dynamicHeight.clamp(minHeight, maxHeight),
            decoration: const BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(currentPost.category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentPost.categoryDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(currentPost.category),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          // Delete button (only for post author) - check both uid and email for backward compatibility
                          if (AuthService.currentUser?.uid == currentPost.authorId || AuthService.currentUser?.email == currentPost.authorId)
                            GestureDetector(
                              onTap: () => _showDeleteConfirmation(currentPost),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          if (AuthService.currentUser?.uid == currentPost.authorId || AuthService.currentUser?.email == currentPost.authorId)
                            const SizedBox(width: 8),
                          // Amen button
                          GestureDetector(
                            onTap: () => _toggleAmen(currentPost),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryPurple,
                                    AppTheme.lavender,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.volunteer_activism,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '아멘 ${currentPost.amenCount}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPost.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (currentPost.scriptureReference?.isNotEmpty == true) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.lavender.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lavender.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: 16,
                                      color: AppTheme.primaryPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currentPost.scriptureReference!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          currentPost.content,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textDark,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              currentPost.authorName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _getTimeAgo(currentPost.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.softGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          '댓글',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<Comment>>(
                          stream: FirebaseCommunityService.getCommentsStream(currentPost.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text('오류: ${snapshot.error}');
                            }

                            final comments = snapshot.data ?? [];

                            if (comments.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const Text(
                                  '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!',
                                  style: TextStyle(
                                    color: AppTheme.softGray,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return Column(
                              children: comments.map((comment) => _buildCommentCard(comment)).toList(),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoggedIn)
                  _buildCommentInput(currentPost.id),
              ],
            ),
          );
        }
        ),
      ),
    );
  }

  Widget _buildCommentsSection(String postId) {
    return StreamBuilder<List<Comment>>(
      stream: FirebaseCommunityService.getCommentsStream(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('오류: ${snapshot.error}');
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!',
              style: TextStyle(
                color: AppTheme.softGray,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          children:
              comments.map((comment) => _buildCommentCard(comment)).toList(),
        );
      },
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getTimeAgo(comment.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.softGray,
                ),
              ),
              const Spacer(),
              // Check both uid and email for backward compatibility
              if (AuthService.currentUser?.uid == comment.authorId || AuthService.currentUser?.email == comment.authorId)
                GestureDetector(
                  onTap: () => _deleteComment(comment),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleCommentAmen(comment),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.volunteer_activism,
                        size: 14,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '아멘 ${comment.amenCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(String postId) {
    final commentController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppTheme.primaryPurple,
              cursorWidth: 2.0,
              cursorHeight: 20.0,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: const TextStyle(
                  color: AppTheme.softGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryPurple,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryPurple,
                    width: 2.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              maxLines: null,
              minLines: 1,
              textInputAction: TextInputAction.send,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              onTap: () {
                // Ensure the input field scrolls into view when tapped
                Future.delayed(const Duration(milliseconds: 300), () {
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addComment(postId, value.trim());
                  commentController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (commentController.text.trim().isNotEmpty) {
                _addComment(postId, commentController.text.trim());
                commentController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(String postId, String content) async {
    try {
      await FirebaseCommunityService.addComment(
        postId: postId,
        content: content,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('댓글 작성 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseCommunityService.deleteComment(comment.id, comment.postId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 삭제되었습니다'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 삭제 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleCommentAmen(Comment comment) async {
    try {
      await FirebaseCommunityService.toggleCommentAmenReaction(comment.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아멘 반응 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(CommunityPost post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseCommunityService.deletePost(post.id);
        Navigator.of(context).pop(); // Close the post details modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAmen(CommunityPost post) async {
    try {
      await FirebaseCommunityService.toggleAmenReaction(post.id);
      // The StreamBuilder will automatically update the main list
      // Modal stays open with current data - no jarring close/reopen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('아멘 반응 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CreatePostDialog extends StatefulWidget {
  final VoidCallback onPostCreated;

  const _CreatePostDialog({required this.onPostCreated});

  @override
  State<_CreatePostDialog> createState() => __CreatePostDialogState();
}

class __CreatePostDialogState extends State<_CreatePostDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scriptureController = TextEditingController();
  final _scriptureTextController = TextEditingController();

  PostCategory _selectedCategory = PostCategory.devotionSharing;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scriptureController.dispose();
    _scriptureTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '글 작성하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : _submitPost,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '게시',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mint,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PostCategory.values.map((category) {
                        return ChoiceChip(
                          label: Text(_getCategoryDisplayName(category)),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            }
                          },
                          backgroundColor: AppTheme.cream,
                          selectedColor: AppTheme.mint.withOpacity(0.3),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? AppTheme.mint
                                : AppTheme.textDark,
                            fontWeight: _selectedCategory == category
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        hintText: '제목을 입력해주세요',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '제목을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SimpleBibleSelector(
                      initialReference: _scriptureController.text,
                      initialText: _scriptureTextController.text,
                      onSelected: (reference, text) {
                        setState(() {
                          _scriptureController.text = reference;
                          _scriptureTextController.text = text;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        hintText: '내용을 입력해주세요',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '내용을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(PostCategory category) {
    switch (category) {
      case PostCategory.devotionSharing:
        return '큐티나눔';
      case PostCategory.sermonSharing:
        return '설교나눔';
      case PostCategory.prayerRequest:
        return '기도요청';
      case PostCategory.testimony:
        return '간증';
      case PostCategory.question:
        return '질문';
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Enhance content with scripture text if available
      String finalContent = _contentController.text;
      if (_scriptureTextController.text.isNotEmpty) {
        finalContent +=
            '\n\n📖 ${_scriptureController.text}\n"${_scriptureTextController.text}"';
      }

      await FirebaseCommunityService.createPost(
        title: _titleController.text,
        content: finalContent,
        category: _selectedCategory,
        scriptureReference: _scriptureController.text.isNotEmpty
            ? _scriptureController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onPostCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 작성 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
