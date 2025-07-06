import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';
import '../services/storage_service.dart';
import '../services/firebase_community_service.dart';

class NoteSuccessDialog extends StatefulWidget {
  final String noteType; // 'sermon' or 'devotion'
  final String title;
  final String content;
  final String scriptureReference;
  final VoidCallback? onContinue;

  const NoteSuccessDialog({
    super.key,
    required this.noteType,
    required this.title,
    required this.content,
    required this.scriptureReference,
    this.onContinue,
  });

  @override
  State<NoteSuccessDialog> createState() => _NoteSuccessDialogState();
}

class _NoteSuccessDialogState extends State<NoteSuccessDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _streakController;
  late Animation<double> _streakAnimation;
  
  int _currentStreak = 0;
  bool _isNewStreakRecord = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _streakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.elasticOut),
    );
    
    _loadStreakData();
    _showCelebration();
  }

  Future<void> _loadStreakData() async {
    try {
      final settings = await StorageService.getSettings();
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      // Check if we already showed streak dialog today for this note type
      final lastShownKey = '${widget.noteType}StreakShownDate';
      final lastShownDate = settings[lastShownKey];
      
      if (lastShownDate == todayString) {
        // Already shown today, close dialog without showing
        if (mounted) {
          Navigator.of(context).pop();
          widget.onContinue?.call();
        }
        return;
      }
      
      // Handle different streak types
      if (widget.noteType == 'devotion') {
        await _handleDevotionStreak(settings, today, todayString);
      } else if (widget.noteType == 'sermon') {
        await _handleSermonStreak(settings, today, todayString);
      }
      
      _streakController.forward();
    } catch (e) {
      print('Error loading streak data: $e');
    }
  }
  
  Future<void> _handleDevotionStreak(Map<String, dynamic> settings, DateTime today, String todayString) async {
    final lastDevotionDate = settings['lastDevotionDate'];
    final devotionStreak = settings['devotionStreak'] ?? 0;
    final bestDevotionStreak = settings['bestDevotionStreak'] ?? 0;
    
    int newStreak = devotionStreak;
    bool isNewRecord = false;
    
    if (lastDevotionDate == null) {
      // First time user
      newStreak = 1;
    } else {
      final lastDate = DateTime.tryParse(lastDevotionDate);
      if (lastDate != null) {
        final daysDifference = today.difference(lastDate).inDays;
        
        if (daysDifference == 0) {
          // Same day, keep current streak
          newStreak = devotionStreak;
        } else if (daysDifference == 1) {
          // Next day, increment streak
          newStreak = devotionStreak + 1;
        } else {
          // Streak broken, reset to 1
          newStreak = 1;
        }
      }
    }
    
    if (newStreak > bestDevotionStreak) {
      isNewRecord = true;
    }
    
    // Save updated streak data
    await StorageService.saveSettings({
      ...settings,
      'lastDevotionDate': todayString,
      'devotionStreakShownDate': todayString,
      'devotionStreak': newStreak,
      'bestDevotionStreak': isNewRecord ? newStreak : bestDevotionStreak,
    });
    
    setState(() {
      _currentStreak = newStreak;
      _isNewStreakRecord = isNewRecord;
    });
  }
  
  Future<void> _handleSermonStreak(Map<String, dynamic> settings, DateTime today, String todayString) async {
    final lastSermonDate = settings['lastSermonDate'];
    final sermonStreak = settings['sermonStreak'] ?? 0;
    final bestSermonStreak = settings['bestSermonStreak'] ?? 0;
    
    int newStreak = sermonStreak;
    bool isNewRecord = false;
    
    if (lastSermonDate == null) {
      // First time user
      newStreak = 1;
    } else {
      final lastDate = DateTime.tryParse(lastSermonDate);
      if (lastDate != null) {
        final weeksDifference = today.difference(lastDate).inDays ~/ 7;
        
        if (weeksDifference == 0) {
          // Same week, keep current streak
          newStreak = sermonStreak;
        } else if (weeksDifference == 1) {
          // Next week, increment streak
          newStreak = sermonStreak + 1;
        } else {
          // Streak broken, reset to 1
          newStreak = 1;
        }
      }
    }
    
    if (newStreak > bestSermonStreak) {
      isNewRecord = true;
    }
    
    // Save updated streak data
    await StorageService.saveSettings({
      ...settings,
      'lastSermonDate': todayString,
      'sermonStreakShownDate': todayString,
      'sermonStreak': newStreak,
      'bestSermonStreak': isNewRecord ? newStreak : bestSermonStreak,
    });
    
    setState(() {
      _currentStreak = newStreak;
      _isNewStreakRecord = isNewRecord;
    });
  }

  void _showCelebration() {
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.5708, // Downward
              maxBlastForce: 15,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                AppTheme.darkPurple,
                AppTheme.darkGreen,
                AppTheme.darkMint,
                AppTheme.deepLavender,
              ],
            ),
          ),
          
          // Main Dialog Content
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.softGray.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with Animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.darkGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.noteType == 'sermon' ? Icons.church : Icons.book,
                    size: 40,
                    color: AppTheme.darkGreen,
                  ),
                ).animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .then(delay: 200.ms)
                    .shake(duration: 400.ms),
                
                const SizedBox(height: 20),
                
                // Success Message
                Text(
                  '🎉 축하합니다!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ).animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 8),
                
                Text(
                  widget.noteType == 'sermon' ? '설교노트가 저장되었습니다' : '큐티노트가 저장되었습니다',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.softGray,
                  ),
                ).animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),
                
                const SizedBox(height: 24),
                
                // Streak Display
                AnimatedBuilder(
                  animation: _streakAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _streakAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.darkPurple.withOpacity(0.1),
                              AppTheme.darkMint.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isNewStreakRecord ? AppTheme.darkGreen : AppTheme.darkPurple,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: _isNewStreakRecord ? AppTheme.darkGreen : AppTheme.darkPurple,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.noteType == 'sermon' ? '$_currentStreak주 연속' : '$_currentStreak일 연속',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _isNewStreakRecord ? AppTheme.darkGreen : AppTheme.darkPurple,
                                  ),
                                ),
                              ],
                            ),
                            if (_isNewStreakRecord) ...[
                              const SizedBox(height: 4),
                              Text(
                                '🏆 새로운 기록!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareNote,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('공유하기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkPurple,
                          side: BorderSide(color: AppTheme.darkPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onContinue?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkPurple,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ).animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 16),
                
                // Motivational Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getMotivationalMessage(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.softGray,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage() {
    if (_isNewStreakRecord) {
      return '새로운 기록을 세우셨네요! 꾸준함이 가장 큰 힘입니다. 🌟';
    } else if (_currentStreak >= 7) {
      return '일주일 연속 기록! 정말 대단해요. 계속해서 주님과 동행하세요! 🙏';
    } else if (_currentStreak >= 3) {
      return '3일 연속! 좋은 습관이 만들어지고 있어요. 화이팅! 💪';
    } else {
      return '오늘도 말씀과 함께해주셔서 감사해요. 내일도 만나요! ❤️';
    }
  }

  void _shareNote() {
    _showShareOptions();
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.softGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '공유 방법을 선택하세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            
            // Share to external apps
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share, color: AppTheme.primaryPurple),
              ),
              title: const Text('외부 앱으로 공유'),
              subtitle: const Text('카카오톡, 메시지 등으로 공유'),
              onTap: () {
                Navigator.pop(context);
                _shareToExternal();
              },
            ),
            
            const SizedBox(height: 12),
            
            // Share to community
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.groups, color: AppTheme.sageGreen),
              ),
              title: const Text('믿음 나눔에 게시'),
              subtitle: const Text('앱 내 커뮤니티에 자동으로 게시'),
              onTap: () {
                Navigator.pop(context);
                _shareToCommunity();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _shareToExternal() {
    final shareText = '''
🙏 ${widget.noteType == 'sermon' ? '설교노트' : '큐티노트'} 나눔 🙏

📖 ${widget.scriptureReference}

${widget.content.length > 200 ? '${widget.content.substring(0, 200)}...' : widget.content}

✨ Grace Notes 앱에서 더 많은 은혜로운 나눔을 경험해보세요!
📱 앱 다운로드: https://play.google.com/store/apps/details?id=com.thousandemfla.grace_notes

#은혜나눔 #기독교앱 #GraceNotes
''';

    Share.share(
      shareText,
      subject: '${widget.noteType == 'sermon' ? '설교노트' : '큐티노트'} 나눔',
    );
  }

  void _shareToCommunity() async {
    try {
      final postId = await FirebaseCommunityService.createPostFromNote(
        noteType: widget.noteType,
        title: widget.title,
        content: widget.content,
        scriptureReference: widget.scriptureReference,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('믿음 나눔에 게시되었습니다! 🙏'),
                ),
              ],
            ),
            backgroundColor: AppTheme.sageGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Close the dialog after successful sharing
        Navigator.of(context).pop();
        widget.onContinue?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}