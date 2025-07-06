import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/sermon_note.dart';
import '../services/storage_service.dart';
import 'sermon_note_form_screen.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key});

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen>
    with TickerProviderStateMixin {
  List<SermonNote> _notes = [];
  List<SermonNote> _filteredNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedView = 'journey'; // 'journey', 'list', 'calendar'
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadNotes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = await StorageService.getSermonNotes();
      setState(() {
        _notes = notes..sort((a, b) => b.date.compareTo(a.date));
        _filteredNotes = _notes;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          final titleMatch =
              note.title.toLowerCase().contains(query.toLowerCase());
          final scriptureMatch = note.scriptureReference
              .toLowerCase()
              .contains(query.toLowerCase());
          final scriptureTextMatch =
              note.scriptureText.toLowerCase().contains(query.toLowerCase());
          final mainPointsMatch =
              note.mainPoints.toLowerCase().contains(query.toLowerCase());
          final reflectionMatch = note.personalReflection
              .toLowerCase()
              .contains(query.toLowerCase());
          final prayerMatch =
              note.prayerRequests.toLowerCase().contains(query.toLowerCase());
          final applicationMatch = note.applicationPoints
              .toLowerCase()
              .contains(query.toLowerCase());
          final churchMatch =
              note.church.toLowerCase().contains(query.toLowerCase());
          final preacherMatch =
              note.preacher.toLowerCase().contains(query.toLowerCase());

          return titleMatch ||
              scriptureMatch ||
              scriptureTextMatch ||
              mainPointsMatch ||
              reflectionMatch ||
              prayerMatch ||
              applicationMatch ||
              churchMatch ||
              preacherMatch;
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterNotes('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '말씀이나 기록으로 검색...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.softGray),
                ),
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                ),
                onChanged: _filterNotes,
              )
            : const Text(
                '설교노트',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                onPressed: _toggleSearch,
              )
            : null,
        actions: [
          if (!_isSearching) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.view_module, color: AppTheme.textDark),
              onSelected: (value) {
                setState(() {
                  _selectedView = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'journey',
                  child: Row(
                    children: [
                      Icon(Icons.favorite,
                          size: 20, color: AppTheme.primaryPurple),
                      SizedBox(width: 8),
                      Text('은혜의 여정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'list',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 20, color: AppTheme.primaryPurple),
                      SizedBox(width: 8),
                      Text('목록'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'calendar',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month,
                          size: 20, color: AppTheme.primaryPurple),
                      SizedBox(width: 8),
                      Text('달력'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.textDark),
              onPressed: _toggleSearch,
            ),
          ] else ...[
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textDark),
                onPressed: () {
                  _searchController.clear();
                  _filterNotes('');
                },
              ),
          ],
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          if (_isSearching && _searchQuery.isNotEmpty)
                            _buildSearchResults(),
                          Expanded(child: _buildSelectedView()),
                        ],
                      ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "sermon_fab",
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SermonNoteFormScreen(),
            ),
          );
          if (result == true) {
            _loadNotes();
          }
        },
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: AppTheme.white),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cream,
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: AppTheme.primaryPurple,
          ),
          const SizedBox(width: 8),
          Text(
            '${_filteredNotes.length}개의 검색 결과',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_filteredNotes.isEmpty) ...[
            const Spacer(),
            const Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.softGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedView() {
    if (_isSearching && _filteredNotes.isEmpty && _searchQuery.isNotEmpty) {
      return _buildNoSearchResults();
    }

    switch (_selectedView) {
      case 'journey':
        return _buildJourneyView();
      case 'list':
        return _buildNotesList();
      case 'calendar':
        return _buildCalendarView();
      default:
        return _buildNotesList();
    }
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.softGray.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.softGray,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '"$_searchQuery"에 대한\\n검색 결과가 없어요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '다른 키워드로 검색해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.softGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.2),
                    AppTheme.lavender.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.church,
                size: 72,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '예배 은혜의 첫 기록을 시작해보세요 💜',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '하나님께서 주시는 특별한 말씀과\n마음에 와 닿는 은혜의 순간들을\n소중히 기록해보세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.softGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.lavender],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SermonNoteFormScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadNotes();
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text(
                  '첫 설교노트 작성하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '설교 제목, 성경 본문, 받은 은혜를\n간단히 기록해보세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
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

  Widget _buildJourneyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJourneyHeader(),
          const SizedBox(height: 24),
          _buildGraceSection(),
          const SizedBox(height: 24),
          _buildFaithInsights(),
          const SizedBox(height: 24),
          _buildGraceTimeline(),
        ],
      ),
    );
  }

  Widget _buildJourneyHeader() {
    final totalNotes = _isSearching ? _filteredNotes.length : _notes.length;
    final daysInWorship = _getDaysInWorship();
    final currentStreak = _getCurrentStreak();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple.withOpacity(0.8),
            AppTheme.lavender.withOpacity(0.9),
            AppTheme.mint.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.church,
                  color: AppTheme.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나의 은혜 여정 💜',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '예배를 통해 받은 $daysInWorship일의 은혜',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildGraceStatCard('받은 은혜', '$totalNotes회', Icons.favorite),
              const SizedBox(width: 12),
              _buildGraceStatCard(
                  '연속 예배', '$currentStreak주', Icons.calendar_month),
              const SizedBox(width: 12),
              _buildGraceStatCard(
                  '함께한 날', '$daysInWorship일', Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraceStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.white, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraceSection() {
    final currentStreak = _getCurrentStreak();
    final longestStreak = _getLongestStreak();
    final thisMonthCount = _getThisMonthCount();
    final monthlyGoal = 4; // 월 4회 목표

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cream.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '꾸준한 예배생활 💕',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGraceCard(
                  '현재 연속',
                  '$currentStreak주',
                  currentStreak >= 4 ? '💜' : '🌸',
                  currentStreak >= 4
                      ? AppTheme.primaryPurple
                      : AppTheme.lavender,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGraceCard(
                  '최고 기록',
                  '$longestStreak주',
                  '👑',
                  AppTheme.sageGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '이번 달 목표',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$thisMonthCount/$monthlyGoal회',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: thisMonthCount >= monthlyGoal
                      ? AppTheme.primaryPurple
                      : AppTheme.softGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (thisMonthCount / monthlyGoal).clamp(0.0, 1.0),
            backgroundColor: AppTheme.cream,
            valueColor: AlwaysStoppedAnimation(
              thisMonthCount >= monthlyGoal
                  ? AppTheme.primaryPurple
                  : AppTheme.lavender,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildGraceCard(
      String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaithInsights() {
    final monthlyData = _getMonthlyInsights();
    final favoriteChurches = _getFavoriteChurches();
    final favoritePreachers = _getFavoritePreachers();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cream.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lavender.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '나의 신앙 인사이트 ✨',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (favoriteChurches.isNotEmpty) ...[
            Text(
              '자주 방문하는 교회',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favoriteChurches
                  .take(2)
                  .map((church) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.primaryPurple.withOpacity(0.5),
                              width: 1),
                        ),
                        child: Text(
                          '${church['name']} (${church['count']}회)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryPurple.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (favoritePreachers.isNotEmpty) ...[
            Text(
              '많이 들은 설교자',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favoritePreachers
                  .take(2)
                  .map((preacher) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.sageGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.sageGreen.withOpacity(0.5),
                              width: 1),
                        ),
                        child: Text(
                          '${preacher['name']} (${preacher['count']}회)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.sageGreen.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (monthlyData['thisMonth']! > 0) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 달',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.softGray,
                        ),
                      ),
                      Text(
                        '${monthlyData['thisMonth']}회',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지난 달',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.softGray,
                        ),
                      ),
                      Text(
                        '${monthlyData['lastMonth']}회',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.softGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: monthlyData['growth']! > 0
                        ? AppTheme.primaryPurple.withOpacity(0.2)
                        : AppTheme.softGray.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    monthlyData['growth']! > 0
                        ? '+${monthlyData['growth']}%'
                        : '${monthlyData['growth']}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: monthlyData['growth']! > 0
                          ? AppTheme.primaryPurple
                          : AppTheme.softGray,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraceTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '받은 은혜의 기록 💐',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...(_isSearching ? _filteredNotes : _notes)
            .take(10)
            .map((note) => _buildTimelineItem(note)),
      ],
    );
  }

  Widget _buildTimelineItem(SermonNote note) {
    final isRecent = DateTime.now().difference(note.date).inDays < 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isRecent ? AppTheme.primaryPurple : AppTheme.lavender,
                  shape: BoxShape.circle,
                  boxShadow: isRecent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: AppTheme.cream,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _showNoteDetails(note),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRecent
                      ? AppTheme.primaryPurple.withOpacity(0.05)
                      : AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRecent
                        ? AppTheme.primaryPurple.withOpacity(0.3)
                        : AppTheme.cream,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isRecent)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            note.title.isNotEmpty ? note.title : '제목 없음',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('M/d').format(note.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.softGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${note.church} • ${note.preacher}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.softGray,
                      ),
                    ),
                    if (note.personalReflection.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note.personalReflection,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final groupedNotes = <String, List<SermonNote>>{};
    for (final note in _notes) {
      final monthKey = DateFormat('yyyy-MM').format(note.date);
      groupedNotes.putIfAbsent(monthKey, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotes.keys.length,
      itemBuilder: (context, index) {
        final monthKey = groupedNotes.keys.elementAt(index);
        final monthNotes = groupedNotes[monthKey]!;
        final monthDate = DateTime.parse('$monthKey-01');

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('yyyy년 M월').format(monthDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...monthNotes.map((note) => _buildCompactNoteCard(note)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactNoteCard(SermonNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cream),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title.isNotEmpty ? note.title : '제목 없음',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.church} • ${note.preacher}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.softGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('d일').format(note.date),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.softGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _isSearching ? _filteredNotes.length : _notes.length,
      itemBuilder: (context, index) {
        final note = _isSearching ? _filteredNotes[index] : _notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(SermonNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showNoteDetails(note),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        Icons.church,
                        color: AppTheme.primaryPurple,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title.isNotEmpty ? note.title : '제목 없음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${note.church} • ${note.preacher}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.softGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MM/dd').format(note.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.softGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (note.scriptureReference.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sageGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.scriptureReference,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.sageGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (note.personalReflection.isNotEmpty)
                  Text(
                    note.personalReflection,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(SermonNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.ivory,
              AppTheme.white,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Beautiful header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.lavender.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.softGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.church,
                          color: AppTheme.primaryPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title.isNotEmpty ? note.title : '제목 없음',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${note.church} • ${note.preacher}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryPurple.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppTheme.primaryPurple),
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SermonNoteFormScreen(note: note),
                                  ),
                                );
                                if (result == true) {
                                  _loadNotes();
                                }
                              },
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppTheme.cream,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNote(note),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBeautifulDetailSection(
                      '📅 날짜',
                      DateFormat('yyyy년 MM월 dd일').format(note.date),
                      AppTheme.primaryPurple,
                    ),
                    if (note.scriptureReference.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '📖 본문',
                        note.scriptureReference,
                        AppTheme.sageGreen,
                      ),
                    if (note.scriptureText.isNotEmpty)
                      _buildScriptureSection(note.scriptureText),
                    if (note.mainPoints.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '✨ 주요 내용',
                        note.mainPoints,
                        AppTheme.primaryPurple,
                      ),
                    if (note.personalReflection.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '💭 개인 묵상',
                        note.personalReflection,
                        AppTheme.lavender,
                      ),
                    if (note.applicationPoints.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '🎯 적용 포인트',
                        note.applicationPoints,
                        AppTheme.sageGreen,
                      ),
                    if (note.prayerRequests.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '🙏 기도 제목',
                        note.prayerRequests,
                        AppTheme.primaryPurple,
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

  Widget _buildBeautifulDetailSection(
      String title, String content, Color color) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureSection(String scriptureText) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sageGreen.withOpacity(0.1),
            AppTheme.mint.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.sageGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.sageGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '📜 성경 구절',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sageGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$scriptureText"',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textDark,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryPurple,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _deleteNote(SermonNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('정말 이 설교노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.deleteSermonNote(note.id);
              Navigator.pop(context);
              Navigator.pop(context);
              _loadNotes();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // Helper methods for journey view
  int _getDaysInWorship() {
    if (_notes.isEmpty) return 0;
    final firstNote = _notes.last.date;
    final lastNote = _notes.first.date;
    return lastNote.difference(firstNote).inDays + 1;
  }

  int _getCurrentStreak() {
    if (_notes.isEmpty) return 0;

    final sortedNotes = List<SermonNote>.from(_notes)
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime currentWeekStart = _getWeekStart(DateTime.now());

    for (final note in sortedNotes) {
      final noteWeekStart = _getWeekStart(note.date);
      final weeksApart = currentWeekStart.difference(noteWeekStart).inDays ~/ 7;

      if (weeksApart == streak) {
        streak++;
        currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getLongestStreak() {
    if (_notes.isEmpty) return 0;

    final sortedNotes = List<SermonNote>.from(_notes)
      ..sort((a, b) => a.date.compareTo(b.date));

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedNotes.length; i++) {
      final prevWeekStart = _getWeekStart(sortedNotes[i - 1].date);
      final currentWeekStart = _getWeekStart(sortedNotes[i].date);
      final weeksDiff = currentWeekStart.difference(prevWeekStart).inDays ~/ 7;

      if (weeksDiff <= 1) {
        currentStreak++;
      } else {
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
        currentStreak = 1;
      }
    }

    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return _notes.where((note) {
      return note.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          note.date.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  Map<String, int> _getMonthlyInsights() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));

    final thisMonthCount = _notes.where((note) {
      return note.date
              .isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
          note.date.isBefore(now.add(const Duration(days: 1)));
    }).length;

    final lastMonthCount = _notes.where((note) {
      return note.date
              .isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
          note.date.isBefore(lastMonthEnd.add(const Duration(days: 1)));
    }).length;

    final growth = lastMonthCount > 0
        ? ((thisMonthCount - lastMonthCount) / lastMonthCount * 100).round()
        : 0;

    return {
      'thisMonth': thisMonthCount,
      'lastMonth': lastMonthCount,
      'growth': growth,
    };
  }

  List<Map<String, dynamic>> _getFavoriteChurches() {
    final churchCounts = <String, int>{};

    for (final note in _notes) {
      if (note.church.isNotEmpty) {
        churchCounts[note.church] = (churchCounts[note.church] ?? 0) + 1;
      }
    }

    final sortedChurches = churchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedChurches
        .map((entry) => {
              'name': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  List<Map<String, dynamic>> _getFavoritePreachers() {
    final preacherCounts = <String, int>{};

    for (final note in _notes) {
      if (note.preacher.isNotEmpty) {
        preacherCounts[note.preacher] =
            (preacherCounts[note.preacher] ?? 0) + 1;
      }
    }

    final sortedPreachers = preacherCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPreachers
        .map((entry) => {
              'name': entry.key,
              'count': entry.value,
            })
        .toList();
  }
}
