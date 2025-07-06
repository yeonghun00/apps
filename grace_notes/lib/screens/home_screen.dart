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
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '오늘의 말씀',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingVerse)
            const Center(child: CircularProgressIndicator())
          else
            Text(
              _todaysVerse,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textDark,
                height: 1.6,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '빠른 작성',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            if (isSunday || isMorning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSunday ? '주일이에요! 🌅' : '오늘도 말씀과 함께해요! 🌇',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.church,
                title: '설교노트',
                subtitle: isSunday ? '오늘 주일 예배 💒' : '설교 말씀 기록',
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.auto_stories,
                title: '큐티노트',
                subtitle: isMorning ? '아침 묵상 시간 🌿' : '오늘의 묵상',
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
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
        padding: const EdgeInsets.all(16),
        decoration: isHighlighted
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lavender.withOpacity(0.3),
                      AppTheme.cream.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.lavender.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lavender.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        size: 32,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '아직 은혜의 기록이 없어요 💜',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '예배나 큐티를 통해 받은 은혜를\n소중히 기록해보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.softGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                            icon: const Icon(Icons.church, size: 18),
                            label: const Text('설교노트 쓰기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
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
                            icon: const Icon(Icons.book, size: 18),
                            label: const Text('큐티노트 쓰기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryPurple,
                              side: const BorderSide(
                                  color: AppTheme.primaryPurple),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
