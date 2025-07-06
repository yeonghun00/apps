import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/devotion_note.dart';
import '../services/storage_service.dart';
import 'devotion_note_form_screen.dart';

class DevotionNotesScreen extends StatefulWidget {
  const DevotionNotesScreen({super.key});

  @override
  State<DevotionNotesScreen> createState() => _DevotionNotesScreenState();
}

class _DevotionNotesScreenState extends State<DevotionNotesScreen> {
  List<DevotionNote> _notes = [];
  List<DevotionNote> _filteredNotes = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedView = 'journey'; // 'journey', 'list', 'calendar'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notes = await StorageService.getDevotionNotes();
      setState(() {
        _notes = notes..sort((a, b) => b.date.compareTo(a.date));
        _filteredNotes = _notes;
        _isLoading = false;
      });
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
          final scriptureRefMatch = note.scriptureReference.toLowerCase().contains(query.toLowerCase());
          final scriptureTextMatch = note.scriptureText.toLowerCase().contains(query.toLowerCase());
          final interpretationMatch = note.interpretation.toLowerCase().contains(query.toLowerCase());
          final observationMatch = note.observation.toLowerCase().contains(query.toLowerCase());
          final applicationMatch = note.application.toLowerCase().contains(query.toLowerCase());
          final prayerMatch = note.prayer.toLowerCase().contains(query.toLowerCase());
          
          return scriptureRefMatch || scriptureTextMatch || interpretationMatch || 
                 observationMatch || applicationMatch || prayerMatch;
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
                '큐티노트',
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
                      Icon(Icons.timeline, size: 20, color: AppTheme.sageGreen),
                      SizedBox(width: 8),
                      Text('영적 여정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'list',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 20, color: AppTheme.sageGreen),
                      SizedBox(width: 8),
                      Text('목록'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'calendar',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, size: 20, color: AppTheme.sageGreen),
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
      body: _isLoading
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
      floatingActionButton: FloatingActionButton(
        heroTag: "devotion_fab",
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DevotionNoteFormScreen(),
            ),
          );
          if (result == true) {
            _loadNotes();
          }
        },
        backgroundColor: AppTheme.sageGreen,
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
            color: AppTheme.sageGreen,
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
                    AppTheme.sageGreen.withOpacity(0.2),
                    AppTheme.mint.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sageGreen.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 72,
                color: AppTheme.sageGreen,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '조용한 묵상의 시간을 시작해보세요 🌿',
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
              '하루를 여는 하나님의 말씀과\n마음 깊이 새겨지는 묵상을\n아름답게 기록해보세요',
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
                  colors: [AppTheme.sageGreen, AppTheme.mint],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sageGreen.withOpacity(0.3),
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
                      builder: (context) => const DevotionNoteFormScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadNotes();
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text(
                  '첫 큐티노트 작성하기',
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
                  color: AppTheme.sageGreen.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sageGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: AppTheme.sageGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '성경 본문, 관찰, 적용, 기도를\n차근차근 기록해보세요',
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
          _buildStreakSection(),
          const SizedBox(height: 24),
          _buildGrowthInsights(),
          const SizedBox(height: 24),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildJourneyHeader() {
    final totalNotes = _isSearching ? _filteredNotes.length : _notes.length;
    final daysActive = _getDaysActive();
    final currentStreak = _getCurrentStreak();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sageGreen.withOpacity(0.9),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나의 큐티 여정',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '하나님과 함께한 $daysActive일',
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
              _buildJourneyStatCard('총 노트', '$totalNotes개', Icons.notes),
              const SizedBox(width: 12),
              _buildJourneyStatCard('현재 연속', '${currentStreak}일', Icons.local_fire_department),
              const SizedBox(width: 12),
              _buildJourneyStatCard('활동 기간', '${daysActive}일', Icons.calendar_today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.white, size: 20),
            const SizedBox(height: 4),
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

  Widget _buildStreakSection() {
    final currentStreak = _getCurrentStreak();
    final longestStreak = _getLongestStreak();
    final weeklyGoal = 5; // Can be made configurable
    final thisWeekCount = _getThisWeekCount();
    
    return Container(
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
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '꾸준함의 힘 🔥',
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
                child: _buildStreakCard(
                  '현재 연속',
                  '$currentStreak일',
                  currentStreak >= 7 ? '🔥' : '💪',
                  currentStreak >= 7 ? Colors.orange : AppTheme.sageGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  '최고 기록',
                  '$longestStreak일',
                  '🏆',
                  AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '이번 주 목표',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$thisWeekCount/$weeklyGoal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: thisWeekCount >= weeklyGoal ? AppTheme.sageGreen : AppTheme.softGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: thisWeekCount / weeklyGoal,
            backgroundColor: AppTheme.cream,
            valueColor: AlwaysStoppedAnimation(
              thisWeekCount >= weeklyGoal ? AppTheme.sageGreen : AppTheme.primaryPurple,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(String title, String value, String emoji, Color color) {
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

  Widget _buildGrowthInsights() {
    final monthlyData = _getMonthlyInsights();
    final favoriteBooks = _getFavoriteBooks();
    
    return Container(
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
                  Icons.insights,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '나의 성장 인사이트 📈',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (favoriteBooks.isNotEmpty) ...[
            Text(
              '가장 많이 묵상한 성경책',
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
              children: favoriteBooks.take(3).map((book) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  '${book['book']} (${book['count']}회)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryPurple.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
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
                        '${monthlyData['thisMonth']}개',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.sageGreen,
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
                        '${monthlyData['lastMonth']}개',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: monthlyData['growth']! > 0 
                        ? AppTheme.sageGreen.withOpacity(0.2)
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
                          ? AppTheme.sageGreen
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

  Widget _buildTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 여정 ✨',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ...(_isSearching ? _filteredNotes : _notes).take(10).map((note) => _buildTimelineItem(note)).toList(),
      ],
    );
  }

  Widget _buildTimelineItem(DevotionNote note) {
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
                  color: isRecent ? AppTheme.sageGreen : AppTheme.softGray,
                  shape: BoxShape.circle,
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
                  color: isRecent ? AppTheme.sageGreen.withOpacity(0.05) : AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRecent 
                        ? AppTheme.sageGreen.withOpacity(0.3)
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.sageGreen,
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
                            note.scriptureReference.isNotEmpty 
                                ? note.scriptureReference 
                                : '큐티노트',
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
                    if (note.observation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        note.observation,
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
    // Group notes by month
    final groupedNotes = <String, List<DevotionNote>>{};
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('yyyy년 M월').format(monthDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.sageGreen,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...monthNotes.map((note) => _buildCompactNoteCard(note)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactNoteCard(DevotionNote note) {
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
              color: AppTheme.sageGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.scriptureReference.isNotEmpty 
                      ? note.scriptureReference 
                      : '큐티노트',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (note.observation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.observation,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.softGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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

  Widget _buildNoteCard(DevotionNote note) {
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
                        color: AppTheme.sageGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: AppTheme.sageGreen,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        note.scriptureReference.isNotEmpty 
                            ? note.scriptureReference 
                            : '큐티노트',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                if (note.scriptureText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      note.scriptureText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                if (note.observation.isNotEmpty)
                  Text(
                    '관찰: ${note.observation}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (note.application.isNotEmpty)
                  Text(
                    '적용: ${note.application}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDetails(DevotionNote note) {
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
              color: AppTheme.sageGreen.withOpacity(0.1),
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
                    AppTheme.sageGreen.withOpacity(0.1),
                    AppTheme.mint.withOpacity(0.2),
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
                          color: AppTheme.sageGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: AppTheme.sageGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.scriptureReference.isNotEmpty 
                                  ? note.scriptureReference 
                                  : '큐티노트',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy년 M월 d일').format(note.date),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.sageGreen.withOpacity(0.7),
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
                              color: AppTheme.sageGreen.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppTheme.sageGreen),
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DevotionNoteFormScreen(note: note),
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
                    if (note.scriptureReference.isNotEmpty)
                      _buildBeautifulDetailSection(
                        '📖 본문', 
                        note.scriptureReference,
                        AppTheme.sageGreen,
                      ),
                    if (note.scriptureText.isNotEmpty)
                      _buildDevotionScriptureSection(note.scriptureText),
                    if (note.observation.isNotEmpty)
                      _buildSOAPSection(
                        'S', 
                        '👀 관찰 (Observation)', 
                        note.observation,
                        AppTheme.sageGreen,
                      ),
                    if (note.interpretation.isNotEmpty)
                      _buildSOAPSection(
                        'O', 
                        '💭 해석 (Interpretation)', 
                        note.interpretation,
                        AppTheme.primaryPurple,
                      ),
                    if (note.application.isNotEmpty)
                      _buildSOAPSection(
                        'A', 
                        '🎯 적용 (Application)', 
                        note.application,
                        AppTheme.darkMint,
                      ),
                    if (note.prayer.isNotEmpty)
                      _buildSOAPSection(
                        'P', 
                        '🙏 기도 (Prayer)', 
                        note.prayer,
                        AppTheme.deepLavender,
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

  Widget _buildBeautifulDetailSection(String title, String content, Color color) {
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

  Widget _buildDevotionScriptureSection(String scriptureText) {
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
                '📜 성경 말씀',
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

  Widget _buildSOAPSection(String letter, String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, {bool isScripture = false}) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.sageGreen,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: isScripture ? const EdgeInsets.all(12) : EdgeInsets.zero,
          decoration: isScripture ? BoxDecoration(
            color: AppTheme.primaryPurple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              width: 1,
            ),
          ) : null,
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.5,
              fontStyle: isScripture ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _deleteNote(DevotionNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('정말 이 큐티노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.deleteDevotionNote(note.id);
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
  int _getDaysActive() {
    if (_notes.isEmpty) return 0;
    final firstNote = _notes.last.date;
    final lastNote = _notes.first.date;
    return lastNote.difference(firstNote).inDays + 1;
  }

  int _getCurrentStreak() {
    if (_notes.isEmpty) return 0;
    
    final today = DateTime.now();
    final sortedNotes = List<DevotionNote>.from(_notes)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime currentDate = today;
    
    for (final note in sortedNotes) {
      final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
      final checkDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      if (noteDate.isAtSameMomentAs(checkDate) || 
          noteDate.isAtSameMomentAs(checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  int _getLongestStreak() {
    if (_notes.isEmpty) return 0;
    
    final sortedNotes = List<DevotionNote>.from(_notes)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedNotes.length; i++) {
      final prevDate = DateTime(
        sortedNotes[i-1].date.year,
        sortedNotes[i-1].date.month,
        sortedNotes[i-1].date.day,
      );
      final currentDate = DateTime(
        sortedNotes[i].date.year,
        sortedNotes[i].date.month,
        sortedNotes[i].date.day,
      );
      
      if (currentDate.difference(prevDate).inDays <= 1) {
        currentStreak++;
      } else {
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
        currentStreak = 1;
      }
    }
    
    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

  int _getThisWeekCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return _notes.where((note) {
      return note.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             note.date.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  Map<String, int> _getMonthlyInsights() {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = thisMonthStart.subtract(const Duration(days: 1));
    
    final thisMonthCount = _notes.where((note) {
      return note.date.isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
             note.date.isBefore(now.add(const Duration(days: 1)));
    }).length;
    
    final lastMonthCount = _notes.where((note) {
      return note.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
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

  List<Map<String, dynamic>> _getFavoriteBooks() {
    final bookCounts = <String, int>{};
    
    for (final note in _notes) {
      if (note.scriptureReference.isNotEmpty) {
        // Extract book name from reference (e.g., "창세기 1:1" -> "창세기")
        final parts = note.scriptureReference.split(' ');
        if (parts.isNotEmpty) {
          final book = parts.first;
          bookCounts[book] = (bookCounts[book] ?? 0) + 1;
        }
      }
    }
    
    final sortedBooks = bookCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedBooks.map((entry) => {
      'book': entry.key,
      'count': entry.value,
    }).toList();
  }
}