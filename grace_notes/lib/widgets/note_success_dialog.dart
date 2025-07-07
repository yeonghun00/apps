import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
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
  late AnimationController _specialMilestoneController;
  late Animation<double> _streakAnimation;
  late Animation<double> _specialMilestoneAnimation;

  int _currentStreak = 0;
  bool _isNewStreakRecord = false;
  bool _isSpecialMilestone = false;
  String _milestoneType = '';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _specialMilestoneController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _streakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakController, curve: Curves.elasticOut),
    );
    _specialMilestoneAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _specialMilestoneController, curve: Curves.easeOutBack),
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

  Future<void> _handleDevotionStreak(
      Map<String, dynamic> settings, DateTime today, String todayString) async {
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

    // Check for special milestones
    final milestoneInfo = _checkSpecialMilestone(newStreak, 'devotion');

    setState(() {
      _currentStreak = newStreak;
      _isNewStreakRecord = isNewRecord;
      _isSpecialMilestone = milestoneInfo['isSpecial'];
      _milestoneType = milestoneInfo['type'];
    });
  }

  Future<void> _handleSermonStreak(
      Map<String, dynamic> settings, DateTime today, String todayString) async {
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

    // Check for special milestones
    final milestoneInfo = _checkSpecialMilestone(newStreak, 'sermon');

    setState(() {
      _currentStreak = newStreak;
      _isNewStreakRecord = isNewRecord;
      _isSpecialMilestone = milestoneInfo['isSpecial'];
      _milestoneType = milestoneInfo['type'];
    });
  }

  Map<String, dynamic> _checkSpecialMilestone(int streak, String noteType) {
    if (noteType == 'devotion') {
      if (streak == 365) return {'isSpecial': true, 'type': 'royal'};
      if (streak == 100) return {'isSpecial': true, 'type': 'crystal'};
      if (streak == 30) return {'isSpecial': true, 'type': 'starfall'};
      if (streak == 10) return {'isSpecial': true, 'type': 'fire'};
    } else if (noteType == 'sermon') {
      if (streak == 100) return {'isSpecial': true, 'type': 'royal'};
      if (streak == 52) return {'isSpecial': true, 'type': 'crystal'};
      if (streak == 30) return {'isSpecial': true, 'type': 'starfall'};
      if (streak == 10) return {'isSpecial': true, 'type': 'fire'};
    }
    return {'isSpecial': false, 'type': ''};
  }

  void _showCelebration() {
    _confettiController.play();
    if (_isSpecialMilestone) {
      _specialMilestoneController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakController.dispose();
    _specialMilestoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Regular Confetti
          if (!_isSpecialMilestone)
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

          // Special Milestone Effects
          if (_isSpecialMilestone) ..._buildSpecialMilestoneEffects(),

          // Main Dialog Content
          AnimatedBuilder(
            animation: _specialMilestoneAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isSpecialMilestone
                    ? 0.8 + 0.2 * _specialMilestoneAnimation.value
                    : 1.0,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: null, // Always use gradient
                    borderRadius: BorderRadius.circular(20),
                    border: _isSpecialMilestone && _milestoneType.isNotEmpty
                        ? _getMilestoneBorder()
                        : Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.3), // 연보라 border
                            width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _isSpecialMilestone && _milestoneType.isNotEmpty
                            ? _getMilestoneGlowColor()
                            : AppTheme.primaryPurple.withOpacity(0.2), // 연보라 glow for normal
                        blurRadius:
                            _isSpecialMilestone && _milestoneType.isNotEmpty
                                ? 30
                                : 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    gradient: _getMilestoneGradient(), // Always use gradient
                  ),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon with Animation
                _buildMilestoneIcon(),
                const SizedBox(height: 20),

                // Special Milestone Title (always show if milestone is detected)
                if (_isSpecialMilestone) ...[
                  AnimatedBuilder(
                    animation: _specialMilestoneAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _specialMilestoneAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: _getMilestoneGradient(),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getMilestoneGlowColor(),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _getMilestoneTitle(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _milestoneType.isEmpty
                                  ? AppTheme.textDark
                                  : Colors
                                      .white, // Dark text for normal milestone
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Success Message
                Text(
                  _isSpecialMilestone ? _getMilestoneEmoji() : '🎉 축하합니다!',
                  style: TextStyle(
                    fontSize: _isSpecialMilestone
                        ? 26
                        : 24, // Slightly smaller to prevent wrapping
                    fontWeight: FontWeight.w700,
                    color: _isSpecialMilestone
                        ? _getMilestoneTextColor()
                        : AppTheme.textDark,
                  ),
                  textAlign: TextAlign
                      .center, // Center align to handle wrapping better
                  maxLines: 2, // Allow 2 lines if needed
                  overflow: TextOverflow.ellipsis,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),

                Text(
                  widget.noteType == 'sermon'
                      ? '설교노트가 저장되었습니다'
                      : '큐티노트가 저장되었습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isSpecialMilestone && _milestoneType.isNotEmpty
                        ? Colors.white.withOpacity(0.9)
                        : AppTheme.softGray,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                const SizedBox(height: 24),

                // Enhanced Streak Display
                _buildEnhancedStreakDisplay(),
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
                          foregroundColor: _isSpecialMilestone && _milestoneType.isNotEmpty
                              ? Colors.white
                              : AppTheme.darkPurple,
                          side: BorderSide(
                              color: _isSpecialMilestone && _milestoneType.isNotEmpty
                                  ? Colors.white
                                  : AppTheme.darkPurple),
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
                          backgroundColor: _isSpecialMilestone && _milestoneType.isNotEmpty
                              ? Colors.white.withOpacity(0.9)
                              : AppTheme.darkPurple,
                          foregroundColor: _isSpecialMilestone && _milestoneType.isNotEmpty
                              ? _getMilestoneTextColor()
                              : AppTheme.white,
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
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 16),

                // Motivational Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSpecialMilestone
                        ? Colors.white.withOpacity(0.2)
                        : AppTheme.cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getMotivationalMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSpecialMilestone && _milestoneType.isNotEmpty
                          ? Colors.white.withOpacity(0.95)
                          : AppTheme.textDark, // Changed from softGray to textDark for better visibility
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneIcon() {
    if (!_isSpecialMilestone) {
      return Container(
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
      )
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut)
          .then(delay: 200.ms)
          .shake(duration: 400.ms);
    }

    return AnimatedBuilder(
      animation: _specialMilestoneAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + 0.4 * _specialMilestoneAnimation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: _getMilestoneGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getMilestoneGlowColor(),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _getMilestoneIconWidget(),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedStreakDisplay() {
    return AnimatedBuilder(
      animation: _streakAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _streakAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: _isSpecialMilestone && _milestoneType.isNotEmpty
                  ? _getMilestoneGradient()
                  : LinearGradient(
                      colors: [
                        AppTheme.darkPurple.withOpacity(0.1),
                        AppTheme.darkMint.withOpacity(0.1),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSpecialMilestone && _milestoneType.isNotEmpty
                    ? Colors.white.withOpacity(0.3)
                    : (_isNewStreakRecord
                        ? AppTheme.darkGreen
                        : AppTheme.darkPurple),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMilestoneStreakIcon(),
                      color: _isSpecialMilestone && _milestoneType.isNotEmpty
                          ? Colors.white
                          : (_isNewStreakRecord
                              ? AppTheme.darkGreen
                              : AppTheme.darkPurple),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.noteType == 'sermon'
                          ? '$_currentStreak주 연속'
                          : '$_currentStreak일 연속',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _isSpecialMilestone && _milestoneType.isNotEmpty
                            ? Colors.white
                            : (_isNewStreakRecord
                                ? AppTheme.darkGreen
                                : AppTheme.darkPurple),
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
                      color: _isSpecialMilestone && _milestoneType.isNotEmpty
                          ? Colors.white
                          : AppTheme.darkGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMilestoneTitle() {
    switch (_milestoneType) {
      case 'fire':
        return '🔥 불타는 열정 🔥';
      case 'starfall':
        return '⭐ 별이 빛나는 성취 ⭐';
      case 'crystal':
        return '💎 보석같은 헌신 💎';
      case 'royal':
        return '👑 왕같은 신실함 👑';
      default:
        return '특별한 기록'; // Simple text for normal milestone
    }
  }

  String _getMilestoneEmoji() {
    switch (_milestoneType) {
      case 'fire':
        return '🔥 축하합니다! 🔥';
      case 'starfall':
        return '⭐ 축하합니다! ⭐';
      case 'crystal':
        return '💎 축하합니다! 💎';
      case 'royal':
        return '👑 축하합니다! 👑';
      default:
        return '축하합니다!'; // Simpler text without emojis for normal case
    }
  }

  Color _getMilestoneTextColor() {
    switch (_milestoneType) {
      case 'fire':
        return const Color(0xFF8B0000); // Dark red
      case 'starfall':
        return const Color(0xFF191970); // Midnight blue
      case 'crystal':
        return const Color(0xFF4B0082); // Indigo
      case 'royal':
        return const Color(
            0xFF1A1A1A); // Dark text for gold background visibility
      default:
        return AppTheme.textDark;
    }
  }

  LinearGradient _getMilestoneGradient() {
    switch (_milestoneType) {
      case 'fire':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFA500)],
        );
      case 'starfall':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF191970), Color(0xFF4169E1), Color(0xFF9370DB)],
        );
      case 'crystal':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00CED1), Color(0xFF9370DB), Color(0xFFFF1493)],
        );
      case 'royal':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B0082), Color(0xFF8B008B), Color(0xFFFFD700)],
        );
      default:
        // Normal app theme colors - using your beautiful palette
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.lavender, AppTheme.cream], // 라벤더 to 크림
        );
    }
  }

  Color _getMilestoneGlowColor() {
    switch (_milestoneType) {
      case 'fire':
        return const Color(0xFFFF4500).withOpacity(0.5);
      case 'starfall':
        return const Color(0xFF4169E1).withOpacity(0.5);
      case 'crystal':
        return const Color(0xFF00CED1).withOpacity(0.5);
      case 'royal':
        return const Color(0xFFFFD700).withOpacity(0.5);
      default:
        return AppTheme.darkPurple.withOpacity(0.3);
    }
  }

  Border _getMilestoneBorder() {
    switch (_milestoneType) {
      case 'fire':
        return Border.all(color: const Color(0xFFFF4500), width: 3);
      case 'starfall':
        return Border.all(color: const Color(0xFF4169E1), width: 3);
      case 'crystal':
        return Border.all(color: const Color(0xFF00CED1), width: 3);
      case 'royal':
        return Border.all(color: const Color(0xFFFFD700), width: 3);
      default:
        return Border.all(color: AppTheme.darkPurple, width: 2);
    }
  }

  Widget _getMilestoneIconWidget() {
    IconData iconData;
    switch (_milestoneType) {
      case 'fire':
        iconData = Icons.local_fire_department;
        break;
      case 'starfall':
        iconData = Icons.auto_awesome;
        break;
      case 'crystal':
        iconData = Icons.diamond;
        break;
      case 'royal':
        iconData = Icons.emoji_events;
        break;
      default:
        iconData = widget.noteType == 'sermon' ? Icons.church : Icons.book;
    }

    return AnimatedBuilder(
      animation: _specialMilestoneAnimation,
      builder: (context, child) {
        double rotation = 0;
        if (_milestoneType == 'crystal') {
          rotation = _specialMilestoneAnimation.value * 2 * math.pi;
        }

        return Transform.rotate(
          angle: rotation,
          child: Icon(
            iconData,
            size: 50,
            color: Colors.white,
          ),
        );
      },
    );
  }

  IconData _getMilestoneStreakIcon() {
    switch (_milestoneType) {
      case 'fire':
        return Icons.local_fire_department;
      case 'starfall':
        return Icons.auto_awesome;
      case 'crystal':
        return Icons.diamond;
      case 'royal':
        return Icons.emoji_events;
      default:
        return Icons.local_fire_department;
    }
  }

  String _getMotivationalMessage() {
    if (_isSpecialMilestone) {
      return _getSpecialMilestoneMessage();
    } else if (_isNewStreakRecord) {
      return '새로운 기록을 세우셨네요! 꾸준함이 가장 큰 힘입니다. 🌟';
    } else if (_currentStreak >= 7) {
      return '일주일 연속 기록! 정말 대단해요. 계속해서 주님과 동행하세요! 🙏';
    } else if (_currentStreak >= 3) {
      return '3일 연속! 좋은 습관이 만들어지고 있어요. 화이팅! 💪';
    } else {
      return '오늘도 말씀과 함께해주셔서 감사해요. 내일도 만나요! ❤️';
    }
  }

  String _getSpecialMilestoneMessage() {
    switch (_milestoneType) {
      case 'fire':
        return widget.noteType == 'devotion'
            ? '🔥 10일 연속! 불같은 열정으로 말씀과 동행하고 계시네요!'
            : '🔥 10주 연속! 불같은 헌신으로 예배를 지키고 계시네요!';
      case 'starfall':
        return widget.noteType == 'devotion'
            ? '🌟 30일 연속! 한 달의 헌신이 별처럼 빛나고 있어요!'
            : '🌟 30주 연속! 반년 이상의 신실함이 별처럼 아름다워요!';
      case 'crystal':
        return widget.noteType == 'devotion'
            ? '💎 100일 연속! 백일의 기적을 이루셨네요! 다이아몬드처럼 빛나는 신앙!'
            : '💎 52주 연속! 일 년의 예배 헌신! 크리스털처럼 순수한 마음!';
      case 'royal':
        return widget.noteType == 'devotion'
            ? '👑 365일 연속! 일 년의 신실함! 왕같은 제사장의 삶을 살고 계시네요!'
            : '👑 100주 연속! 백 주간의 경건! 하늘의 면류관이 예비되었을 거예요!';
      default:
        return '놀라운 기록을 세우셨네요! 다음 특별한 이정표를 기대해보세요! ✨';
    }
  }

  List<Widget> _buildSpecialMilestoneEffects() {
    switch (_milestoneType) {
      case 'fire':
        return _buildFireEffect();
      case 'starfall':
        return _buildStarfallEffect();
      case 'crystal':
        return _buildCrystalEffect();
      case 'royal':
        return _buildRoyalEffect();
      default:
        return [];
    }
  }

  List<Widget> _buildFireEffect() {
    return [
      // Fire particles shooting up from bottom
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: CustomPaint(
              painter: FireEffectPainter(_specialMilestoneAnimation.value),
            ),
          );
        },
      ),
      // Additional fire glow effect
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4500)
                        .withOpacity(0.3 * _specialMilestoneAnimation.value),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildStarfallEffect() {
    return [
      // Stars falling from top like meteor shower
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: CustomPaint(
              painter: StarfallEffectPainter(_specialMilestoneAnimation.value),
            ),
          );
        },
      ),
      // Starlight shimmer effect
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4169E1)
                        .withOpacity(0.4 * _specialMilestoneAnimation.value),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildCrystalEffect() {
    return [
      // Geometric crystals expanding outward
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: CustomPaint(
              painter: CrystalEffectPainter(_specialMilestoneAnimation.value),
            ),
          );
        },
      ),
      // Rainbow prism effect
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00CED1)
                        .withOpacity(0.2 * _specialMilestoneAnimation.value),
                    const Color(0xFF9370DB)
                        .withOpacity(0.2 * _specialMilestoneAnimation.value),
                    const Color(0xFFFF1493)
                        .withOpacity(0.2 * _specialMilestoneAnimation.value),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildRoyalEffect() {
    return [
      // Crown with golden rain and royal sparkles
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: CustomPaint(
              painter: RoyalEffectPainter(_specialMilestoneAnimation.value),
            ),
          );
        },
      ),
      // Royal golden glow
      AnimatedBuilder(
        animation: _specialMilestoneAnimation,
        builder: (context, child) {
          return Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700)
                        .withOpacity(0.5 * _specialMilestoneAnimation.value),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
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

${widget.content}

✨ Grace Notes 앱에서 더 많은 은혜로운 나눔을 경험해보세요!
📱 앱 다운로드: https://play.google.com/store/apps/details?id=com.thousandemfla.grace_notes
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

// Custom Painters for Special Milestone Effects

class FireEffectPainter extends CustomPainter {
  final double animationValue;

  FireEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create intense fire particles shooting up from bottom
    for (int i = 0; i < 30; i++) {
      final x = size.width * (0.05 + (i / 30) * 0.9) +
          math.sin(animationValue * math.pi * 2 + i) * 15;
      final baseY = size.height;
      final height = size.height * (0.7 + 0.3 * math.sin(i)) * animationValue;
      final y =
          baseY - height + math.sin(animationValue * math.pi * 6 + i) * 25;

      final fireSize = 6.0 + math.sin(animationValue * math.pi * 3 + i) * 5;
      final opacity = (1.0 - (height / (size.height * 0.8))) *
          animationValue *
          (0.7 + 0.3 * math.sin(i));

      // Enhanced fire colors with more variation
      final colorPhase = (height / (size.height * 0.8)).clamp(0.0, 1.0);
      Color fireColor;
      if (colorPhase < 0.2) {
        fireColor = const Color(0xFFFF0000); // Deep red
      } else if (colorPhase < 0.4) {
        fireColor = const Color(0xFFFF4500); // Red-orange
      } else if (colorPhase < 0.6) {
        fireColor = const Color(0xFFFF8C00); // Dark orange
      } else if (colorPhase < 0.8) {
        fireColor = const Color(0xFFFFA500); // Orange
      } else {
        fireColor = const Color(0xFFFFD700); // Gold
      }

      paint.color = fireColor.withOpacity(opacity.clamp(0.0, 0.9));

      // Draw flame shape instead of circle
      _drawFlame(canvas, Offset(x, y), fireSize, paint);

      // Add inner glow
      if (opacity > 0.3) {
        paint.color = Colors.white.withOpacity(opacity * 0.3);
        canvas.drawCircle(Offset(x, y), fireSize * 0.3, paint);
      }
    }
  }

  void _drawFlame(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    // Create flame shape
    path.moveTo(center.dx, center.dy + size);
    path.quadraticBezierTo(
      center.dx - size * 0.8,
      center.dy,
      center.dx - size * 0.3,
      center.dy - size * 0.7,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy - size * 1.2,
      center.dx + size * 0.3,
      center.dy - size * 0.7,
    );
    path.quadraticBezierTo(
      center.dx + size * 0.8,
      center.dy,
      center.dx,
      center.dy + size,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class StarfallEffectPainter extends CustomPainter {
  final double animationValue;

  StarfallEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create magical falling stars like meteor shower
    for (int i = 0; i < 25; i++) {
      final progress = (animationValue + i * 0.1) % 1.0;
      final x = size.width * (0.1 + (i / 25) * 0.8) +
          math.sin(progress * math.pi * 4 + i) * 20;
      final startY = -size.height * 0.3;
      final endY = size.height * 1.3;
      final y = startY + (endY - startY) * progress;

      final starSize = 4.0 + math.sin(progress * math.pi * 2 + i) * 4;
      final opacity = math.sin(progress * math.pi * 2).clamp(0.0, 1.0);

      // Enhanced star colors with more magical feel
      final colors = [
        const Color(0xFFFFFFFF), // Pure white
        const Color(0xFF87CEEB), // Sky blue
        const Color(0xFF9370DB), // Medium purple
        const Color(0xFF4169E1), // Royal blue
        const Color(0xFFB0C4DE), // Light steel blue
      ];
      final colorIndex = i % colors.length;

      paint.color = colors[colorIndex].withOpacity(opacity * 0.95);

      // Draw enhanced star shape
      _drawEnhancedStar(canvas, Offset(x, y), starSize, paint);

      // Draw longer, more dramatic trail
      final trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[colorIndex].withOpacity(0.0),
            colors[colorIndex].withOpacity(opacity * 0.6),
            colors[colorIndex].withOpacity(opacity * 0.9),
          ],
        ).createShader(Rect.fromLTWH(x - 2, y - starSize * 6, 4, starSize * 6))
        ..strokeWidth = 3;

      canvas.drawLine(
        Offset(x - 5, y - starSize * 6),
        Offset(x + 5, y + starSize),
        trailPaint,
      );

      // Add sparkle effect around bright stars
      if (opacity > 0.7) {
        _drawSparkles(
            canvas, Offset(x, y), starSize * 1.5, colors[colorIndex], opacity);
      }
    }
  }

  void _drawEnhancedStar(
      Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const int points = 5;
    const double angleStep = math.pi * 2 / points;

    for (int i = 0; i < points * 2; i++) {
      final angle = i * angleStep / 2;
      final radius = (i % 2 == 0) ? size : size * 0.4;
      final x = center.dx + radius * math.cos(angle - math.pi / 2);
      final y = center.dy + radius * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Add center glow
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, size * 0.2, paint);
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final distance = radius + math.sin(animationValue * math.pi * 4 + i) * 10;
      final x = center.dx + distance * math.cos(angle);
      final y = center.dy + distance * math.sin(angle);

      paint.color = color.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CrystalEffectPainter extends CustomPainter {
  final double animationValue;

  CrystalEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // Create multiple layers of expanding crystal formations
    for (int layer = 0; layer < 3; layer++) {
      final layerProgress = ((animationValue - layer * 0.2).clamp(0.0, 1.0));
      if (layerProgress <= 0) continue;

      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * math.pi * 2 + layerProgress * math.pi * 0.5;
        final distance = size.width * (0.2 + layer * 0.15) * layerProgress;
        final x = center.dx + math.cos(angle) * distance;
        final y = center.dy + math.sin(angle) * distance;

        final crystalSize = (10.0 + layer * 5) * layerProgress;
        final opacity = (1.0 - layerProgress * 0.7).clamp(0.0, 1.0);
        final rotation = layerProgress * math.pi * 2;

        // Enhanced crystal colors with prismatic effect
        final colors = [
          const Color(0xFF00CED1), // Dark turquoise
          const Color(0xFF9370DB), // Medium purple
          const Color(0xFFFF1493), // Deep pink
          const Color(0xFF00BFFF), // Deep sky blue
          const Color(0xFF8A2BE2), // Blue violet
          const Color(0xFFFF69B4), // Hot pink
        ];
        final colorIndex = (i + layer * 4) % colors.length;

        // Draw filled crystal with gradient
        paint.style = PaintingStyle.fill;
        paint.shader = RadialGradient(
          colors: [
            colors[colorIndex].withOpacity(opacity * 0.8),
            colors[colorIndex].withOpacity(opacity * 0.3),
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(x, y), radius: crystalSize));

        _drawPrismaticCrystal(
            canvas, Offset(x, y), crystalSize, paint, rotation);

        // Add crystal outline
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        paint.shader = null;
        paint.color = colors[colorIndex].withOpacity(opacity);
        _drawPrismaticCrystal(
            canvas, Offset(x, y), crystalSize, paint, rotation);

        // Add inner light reflection
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white.withOpacity(opacity * 0.6);
        canvas.drawCircle(Offset(x, y), crystalSize * 0.3, paint);
      }
    }

    // Central prismatic explosion
    final centralPaint = Paint()..style = PaintingStyle.fill;
    final centralRadius = 25 * animationValue;

    centralPaint.shader = RadialGradient(
      colors: [
        Colors.white.withOpacity(animationValue * 0.9),
        const Color(0xFF00CED1).withOpacity(animationValue * 0.6),
        const Color(0xFF9370DB).withOpacity(animationValue * 0.3),
      ],
    ).createShader(Rect.fromCircle(center: center, radius: centralRadius));

    canvas.drawCircle(center, centralRadius, centralPaint);

    // Add rainbow refraction lines
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final lineLength = centralRadius * 2;
      final startX = center.dx + math.cos(angle) * centralRadius * 0.5;
      final startY = center.dy + math.sin(angle) * centralRadius * 0.5;
      final endX = center.dx + math.cos(angle) * lineLength;
      final endY = center.dy + math.sin(angle) * lineLength;

      final linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(animationValue * 0.8),
            const Color(0xFF00CED1).withOpacity(animationValue * 0.3),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)))
        ..strokeWidth = 3;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }
  }

  void _drawPrismaticCrystal(
      Canvas canvas, Offset center, double size, Paint paint, double rotation) {
    final path = Path();

    // Create hexagonal crystal shape
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2 + rotation;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class RoyalEffectPainter extends CustomPainter {
  final double animationValue;

  RoyalEffectPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Majestic golden rain effect
    for (int i = 0; i < 40; i++) {
      final progress = (animationValue + i * 0.05) % 1.0;
      final x =
          size.width * (i / 40) + math.sin(progress * math.pi * 2 + i) * 10;
      final startY = -size.height * 0.4;
      final endY = size.height * 1.4;
      final y = startY + (endY - startY) * progress;

      final dropSize = 2.0 + math.sin(progress * math.pi * 3 + i) * 3;
      final opacity = math.sin(progress * math.pi * 1.5).clamp(0.0, 1.0);

      // Enhanced golden colors with more richness
      final goldColors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFA500), // Orange
        const Color(0xFFFFB300), // Amber
        const Color(0xFFDAA520), // Goldenrod
      ];
      final colorIndex = i % goldColors.length;

      paint.color = goldColors[colorIndex].withOpacity(opacity * 0.8);

      // Draw teardrop shape for golden drops
      _drawGoldenDrop(canvas, Offset(x, y), dropSize, paint);
    }

    // Floating crown effect that descends majestically
    final center =
        Offset(size.width / 2, size.height * (0.2 + 0.1 * animationValue));
    final crownSize = 50.0 * math.min(animationValue * 2, 1.0);
    final crownOpacity = math.min(animationValue * 1.5, 1.0);

    if (animationValue > 0.2) {
      _drawMajesticCrown(canvas, center, crownSize, crownOpacity);
    }

    // Royal sparkles orbiting the crown
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + animationValue * math.pi * 2;
      final orbitRadius =
          crownSize * (1.5 + 0.5 * math.sin(animationValue * math.pi * 3 + i));
      final x = center.dx + math.cos(angle) * orbitRadius;
      final y =
          center.dy + math.sin(angle) * orbitRadius * 0.7; // Elliptical orbit

      final sparkleSize = 3.0 + math.sin(animationValue * math.pi * 4 + i) * 2;
      final sparkleOpacity =
          math.sin(animationValue * math.pi * 2 + i) * 0.5 + 0.5;

      // Royal sparkle colors
      final sparkleColors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFFFFFFF), // White
        const Color(0xFFFFA500), // Orange
      ];
      final sparkleColor = sparkleColors[i % sparkleColors.length];

      paint.color = sparkleColor.withOpacity(sparkleOpacity * crownOpacity);
      _drawRoyalSparkle(canvas, Offset(x, y), sparkleSize, paint);
    }

    // Majestic light rays emanating from crown
    if (animationValue > 0.5) {
      _drawLightRays(canvas, center, crownSize * 2, crownOpacity);
    }
  }

  void _drawGoldenDrop(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    // Teardrop shape
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(
      center.dx + size * 0.7,
      center.dy - size * 0.3,
      center.dx + size * 0.5,
      center.dy + size * 0.3,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy + size,
      center.dx - size * 0.5,
      center.dy + size * 0.3,
    );
    path.quadraticBezierTo(
      center.dx - size * 0.7,
      center.dy - size * 0.3,
      center.dx,
      center.dy - size,
    );

    canvas.drawPath(path, paint);
  }

  void _drawMajesticCrown(
      Canvas canvas, Offset center, double size, double opacity) {
    final crownPaint = Paint()..style = PaintingStyle.fill;

    // Crown gradient
    crownPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFFD700).withOpacity(opacity),
        const Color(0xFFFFA500).withOpacity(opacity * 0.8),
        const Color(0xFFDAA520).withOpacity(opacity * 0.6),
      ],
    ).createShader(
        Rect.fromCenter(center: center, width: size * 2, height: size * 1.5));

    final path = Path();
    final width = size * 1.8;
    final height = size * 1.2;

    // Enhanced crown with multiple points
    path.moveTo(center.dx - width / 2, center.dy + height / 3);
    path.lineTo(center.dx + width / 2, center.dy + height / 3);

    // Multiple crown points for regal appearance
    path.lineTo(center.dx + width * 0.3, center.dy - height * 0.3);
    path.lineTo(center.dx + width * 0.15, center.dy - height * 0.1);
    path.lineTo(center.dx, center.dy - height * 0.6);
    path.lineTo(center.dx - width * 0.15, center.dy - height * 0.1);
    path.lineTo(center.dx - width * 0.3, center.dy - height * 0.3);
    path.close();

    canvas.drawPath(path, crownPaint);

    // Crown jewels
    final gemPaint = Paint()..style = PaintingStyle.fill;

    // Center ruby
    gemPaint.color = const Color(0xFFDC143C).withOpacity(opacity);
    canvas.drawCircle(
        Offset(center.dx, center.dy - height * 0.3), size * 0.15, gemPaint);

    // Side emeralds
    gemPaint.color = const Color(0xFF50C878).withOpacity(opacity);
    canvas.drawCircle(
        Offset(center.dx - width * 0.15, center.dy), size * 0.1, gemPaint);
    canvas.drawCircle(
        Offset(center.dx + width * 0.15, center.dy), size * 0.1, gemPaint);

    // Crown base decoration
    final basePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawLine(
      Offset(center.dx - width / 2, center.dy + height / 3),
      Offset(center.dx + width / 2, center.dy + height / 3),
      basePaint,
    );
  }

  void _drawRoyalSparkle(
      Canvas canvas, Offset center, double size, Paint paint) {
    // Draw 4-pointed star sparkle
    final path = Path();

    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawLightRays(
      Canvas canvas, Offset center, double radius, double opacity) {
    final rayPaint = Paint()..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final startRadius = radius * 0.3;
      final endRadius = radius;

      final startX = center.dx + math.cos(angle) * startRadius;
      final startY = center.dy + math.sin(angle) * startRadius;
      final endX = center.dx + math.cos(angle) * endRadius;
      final endY = center.dy + math.sin(angle) * endRadius;

      rayPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withOpacity(opacity * 0.8),
          const Color(0xFFFFD700).withOpacity(0.0),
        ],
      ).createShader(
          Rect.fromPoints(Offset(startX, startY), Offset(endX, endY)));

      rayPaint.strokeWidth = 4;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), rayPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
