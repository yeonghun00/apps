import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../services/storage_service.dart';
import '../services/improved_bible_service.dart';
import '../models/sermon_note.dart';
import '../models/devotion_note.dart';
import '../models/community_post.dart';
import '../screens/settings_screen.dart';
import '../screens/sermon_note_form_screen.dart';
import '../screens/devotion_note_form_screen.dart';
import '../screens/sermon_notes_screen.dart';
import '../screens/devotion_notes_screen.dart';
import '../screens/main_screen.dart';
import '../widgets/streak_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String _todaysVerse = "여호와는 나의 목자시니 내게 부족함이 없으리로다 - 시편 23:1";
  CommunityPost? _featuredPost;
  bool _isLoadingVerse = false;
  bool _isLoadingPost = false;

  late AnimationController _greetingController;
  late AnimationController _verseController;
  late AnimationController _cardController;
  late Animation<double> _greetingAnimation;
  late Animation<double> _verseAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Refresh data when the screen is shown
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });

    // Initialize animations with feminine, gentle timing
    _greetingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _verseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _greetingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _greetingController, curve: Curves.easeOutCubic),
    );

    _verseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _verseController, curve: Curves.easeOutQuart),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    // Start animations with gentle delays
    Future.delayed(const Duration(milliseconds: 300), () {
      _greetingController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _verseController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingController.dispose();
    _verseController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    return '${now.month}월 ${now.day}일 ${weekdays[now.weekday % 7]}';
  }

  void _refreshData() {
    _loadTodaysVerse();
    _loadFeaturedPost();
    setState(() {}); // Trigger rebuild for recent notes and stats
  }

  Future<void> _loadTodaysVerse() async {
    setState(() {
      _isLoadingVerse = true;
    });

    try {
      final verse = await ImprovedBibleService.getDailyVerse();
      setState(() {
        _todaysVerse = verse;
      });
    } catch (e) {
      print('Error loading daily verse: $e');
    } finally {
      setState(() {
        _isLoadingVerse = false;
      });
    }
  }

  Future<void> _loadFeaturedPost() async {
    setState(() {
      _isLoadingPost = true;
    });

    try {
      final posts = await StorageService.getCommunityPosts();
      if (posts.isNotEmpty) {
        posts.sort((a, b) => b.amenCount.compareTo(a.amenCount));
        if (posts.first.amenCount > 0) {
          setState(() {
            _featuredPost = posts.first;
          });
        }
      }
    } catch (e) {
      print('Error loading featured post: $e');
    } finally {
      setState(() {
        _isLoadingPost = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/icons/icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.sageGreen, AppTheme.primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Grace Notes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StreakDisplay(),
            const SizedBox(height: 20),
            _buildTodaysVerseCard(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildRecentNotesSection(),
            const SizedBox(height: 24),
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12
        ? '좋은 아침'
        : now.hour < 18
            ? '좋은 오후'
            : '좋은 저녁';

    // Dynamic motivational messages based on time and day
    final motivationalMessages = [
      '오늘도 주님의 은혜가 함께하시길 바라요',
      '새로운 하루, 새로운 은혜가 기다리고 있어요',
      '하나님의 사랑이 당신의 하루를 가득 채우시길',
      '주님과 함께하는 시간이 가장 소중해요',
      '오늘 하루도 감사와 기쁨으로 가득하시길',
      '하나님의 말씀이 당신의 발걸음을 인도하시길',
    ];

    final todaysMessage =
        motivationalMessages[now.day % motivationalMessages.length];

    if (_featuredPost != null && !_isLoadingPost) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.sageGreen.withOpacity(0.8),
              AppTheme.mint.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '이번 주 인기 게시물',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: AppTheme.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_featuredPost!.amenCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _featuredPost!.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.white,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '- ${_featuredPost!.authorName}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.9),
            AppTheme.lavender.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$timeOfDay이에요! 💜',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            todaysMessage,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysVerseCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.08),
            AppTheme.lavender.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.deepLavender],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 말씀',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getFormattedDate(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingVerse)
            SizedBox(
              height: 80,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                _todaysVerse,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                  height: 1.7,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final now = DateTime.now();
    final isSunday = now.weekday == 7;
    final isMorning = now.hour < 12;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '빠른 작성',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (isSunday || isMorning)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPurple.withOpacity(0.15),
                        AppTheme.lavender.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isSunday ? '주일이에요! 🌅' : '오늘도 말씀과 함께해요! 🌇',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Full-width sermon note button
          _buildFullWidthActionButton(
            icon: Icons.church,
            title: '설교노트 작성하기',
            subtitle:
                isSunday ? '오늘 주일 예배에서 받은 은혜를 기록해보세요' : '설교 말씀을 통해 받은 은혜를 나누어요',
            color: AppTheme.primaryPurple,
            isHighlighted: isSunday,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SermonNoteFormScreen(),
                ),
              );
              if (result == true) {
                _refreshData();
              }
            },
          ),
          const SizedBox(height: 12),
          // Full-width devotion note button
          _buildFullWidthActionButton(
            icon: Icons.auto_stories,
            title: '큐티노트 작성하기',
            subtitle:
                isMorning ? '새로운 하루, 말씀과 함께 시작해보세요' : '오늘의 묵상을 통해 받은 은혜를 기록해요',
            color: AppTheme.sageGreen,
            isHighlighted: isMorning && !isSunday,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DevotionNoteFormScreen(),
                ),
              );
              if (result == true) {
                _refreshData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: isHighlighted
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.12),
                    color.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.softGray.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      )
                    : LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.1)
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.white : color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 노트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SermonNotesScreen(),
                  ),
                );
              },
              child: const Text(
                '전체보기',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<dynamic>>(
          future: _getRecentNotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryPurple.withOpacity(0.06),
                      AppTheme.lavender.withOpacity(0.12),
                      AppTheme.cream.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryPurple.withOpacity(0.8),
                            AppTheme.deepLavender.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '첫 번째 은혜의 순간을 기록해보세요 ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '하나님과의 특별한 만남의 순간들이\n소중한 기억으로 쌓여갈 거예요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SermonNoteFormScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _refreshData();
                                }
                              },
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
                                  Icon(Icons.church, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '설교노트',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DevotionNoteFormScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _refreshData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.sageGreen,
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
                                  Icon(Icons.auto_stories, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '큐티노트',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.take(3).map((note) {
                if (note is SermonNote) {
                  return _buildRecentNoteCard(
                    title: note.title,
                    subtitle:
                        '${note.church} • ${DateFormat('M/d').format(note.date)}',
                    icon: Icons.church,
                    color: AppTheme.primaryPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SermonNotesScreen(),
                        ),
                      );
                    },
                  );
                } else if (note is DevotionNote) {
                  return _buildRecentNoteCard(
                    title: note.scriptureReference,
                    subtitle: '큐티 • ${DateFormat('M/d').format(note.date)}',
                    icon: Icons.book,
                    color: AppTheme.sageGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DevotionNotesScreen(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentNoteCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이달의 기록',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: _getMonthlyStats(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data ?? {'sermon': 0, 'devotion': 0};

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.church,
                    title: '설교노트',
                    count: stats['sermon']!,
                    color: AppTheme.primaryPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SermonNotesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.book,
                    title: '큐티노트',
                    count: stats['devotion']!,
                    color: AppTheme.sageGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DevotionNotesScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.softGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> _getRecentNotes() async {
    final sermonNotes = await StorageService.getSermonNotes();
    final devotionNotes = await StorageService.getDevotionNotes();

    final allNotes = <dynamic>[];
    allNotes.addAll(sermonNotes);
    allNotes.addAll(devotionNotes);

    allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allNotes;
  }

  Future<Map<String, int>> _getMonthlyStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final sermonNotes = await StorageService.getSermonNotes();
    final devotionNotes = await StorageService.getDevotionNotes();

    final monthlySermon = sermonNotes
        .where((note) =>
            note.date.isAfter(monthStart) &&
            note.date.isBefore(now.add(const Duration(days: 1))))
        .length;

    final monthlyDevotion = devotionNotes
        .where((note) =>
            note.date.isAfter(monthStart) &&
            note.date.isBefore(now.add(const Duration(days: 1))))
        .length;

    return {
      'sermon': monthlySermon,
      'devotion': monthlyDevotion,
    };
  }
}
