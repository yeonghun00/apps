import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../constants/app_theme.dart';
import '../services/storage_service.dart';

class StreakDisplay extends StatefulWidget {
  const StreakDisplay({super.key});

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _floatingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _floatingAnimation;
  
  int _devotionStreak = 0;
  int _sermonStreak = 0;
  int _bestDevotionStreak = 0;
  int _bestSermonStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    
    _floatingAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    _loadStreakData();
    _startAnimations();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _sparkleController.repeat();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _loadStreakData() async {
    try {
      final settings = await StorageService.getSettings();
      final devotionStreak = settings['devotionStreak'] ?? 0;
      final sermonStreak = settings['sermonStreak'] ?? 0;
      final bestDevotionStreak = settings['bestDevotionStreak'] ?? 0;
      final bestSermonStreak = settings['bestSermonStreak'] ?? 0;
      
      setState(() {
        _devotionStreak = devotionStreak;
        _sermonStreak = sermonStreak;
        _bestDevotionStreak = bestDevotionStreak;
        _bestSermonStreak = bestSermonStreak;
        _isLoading = false;
        
        // TODO: Remove this demo data after testing
        // Show demo streaks if no real data exists yet
        if (_devotionStreak == 0 && _sermonStreak == 0) {
          _devotionStreak = 5; // Demo: 5 day devotion streak
          _sermonStreak = 3;   // Demo: 3 week sermon streak
          _bestDevotionStreak = 7;
          _bestSermonStreak = 4;
        }
      });
    } catch (e) {
      print('Error loading streak data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Show motivational starter if no streaks yet
    if (_devotionStreak == 0 && _sermonStreak == 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _buildMotivationalStarter(),
      ).animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Devotion streak card with fancy animations
          if (_devotionStreak > 0)
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _floatingAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Transform.scale(
                    scale: _devotionStreak >= 3 ? _pulseAnimation.value : 1.0,
                    child: _buildDevotionCard(),
                  ),
                );
              },
            ).animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut),
          
          if (_devotionStreak > 0 && _sermonStreak > 0)
            const SizedBox(height: 12),
          
          // Sermon streak card with fancy animations
          if (_sermonStreak > 0)
            AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _floatingAnimation]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatingAnimation.value * 0.7),
                  child: Transform.scale(
                    scale: _sermonStreak >= 2 ? _pulseAnimation.value : 1.0,
                    child: _buildSermonCard(),
                  ),
                );
              },
            ).animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildMotivationalStarter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lavender.withOpacity(0.8),
            AppTheme.cream.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildFloatingParticles(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.lavender],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '연속 기록을 시작해보세요! ✨',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '큐티와 설교노트를 꾸준히 작성하면\n아름다운 연속 기록이 표시됩니다 💜',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDark.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevotionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getDevotionGradientColors(),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sageGreen.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_devotionStreak >= 7) _buildSparkleEffect(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '큐티 $_devotionStreak일 연속',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (_devotionStreak == _bestDevotionStreak && _bestDevotionStreak > 1) ...[ 
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '최고기록 🏆',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDevotionMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_devotionStreak >= 7)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSermonCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getSermonGradientColors(),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (_sermonStreak >= 4) _buildSparkleEffect(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.church,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '설교 $_sermonStreak주 연속',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        if (_sermonStreak == _bestSermonStreak && _bestSermonStreak > 1) ...[ 
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.4),
                                  Colors.white.withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '최고기록 🏆',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSermonMessage(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_sermonStreak >= 4)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkleEffect() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: SparklePainter(_sparkleAnimation.value),
          ),
        );
      },
    );
  }


  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: FloatingParticlesPainter(_floatingAnimation.value),
          ),
        );
      },
    );
  }

  List<Color> _getDevotionGradientColors() {
    if (_devotionStreak >= 30) {
      return [const Color(0xFF4facfe), const Color(0xFF00f2fe)]; // Blue for 30+ days
    } else if (_devotionStreak >= 14) {
      return [AppTheme.sageGreen, AppTheme.mint]; // Green for 14+ days
    } else if (_devotionStreak >= 7) {
      return [const Color(0xFF667eea), const Color(0xFF764ba2)]; // Purple for 7+ days
    } else if (_devotionStreak >= 3) {
      return [AppTheme.mint, AppTheme.sageGreen]; // Light green for 3+ days
    } else {
      return [AppTheme.sageGreen, AppTheme.mint]; // Default green
    }
  }

  List<Color> _getSermonGradientColors() {
    if (_sermonStreak >= 12) {
      return [AppTheme.coral, const Color(0xFFFF6B9D)]; // Coral for 12+ weeks
    } else if (_sermonStreak >= 8) {
      return [const Color(0xFFf093fb), const Color(0xFff5576c)]; // Pink for 8+ weeks
    } else if (_sermonStreak >= 4) {
      return [AppTheme.primaryPurple, AppTheme.lavender]; // Purple for 4+ weeks
    } else {
      return [AppTheme.primaryPurple, AppTheme.lavender]; // Default purple
    }
  }

  String _getDevotionMessage() {
    if (_devotionStreak >= 30) {
      return '한 달 넘게! 정말 대단한 꾸준함이에요! 🌟';
    } else if (_devotionStreak >= 14) {
      return '2주 연속! 말씀과 깊이 동행하고 계시네요! 💙';
    } else if (_devotionStreak >= 7) {
      return '일주일 연속! 좋은 습관이 만들어지고 있어요! 💚';
    } else if (_devotionStreak >= 3) {
      return '좋은 시작! 계속해보세요! 🌿';
    } else {
      return '오늘도 말씀과 함께해요! 💚';
    }
  }

  String _getSermonMessage() {
    if (_sermonStreak >= 12) {
      return '3개월 연속! 놀라운 신실함이에요! 🙌';
    } else if (_sermonStreak >= 8) {
      return '2개월 연속! 정말 멋져요! 💜';
    } else if (_sermonStreak >= 4) {
      return '한 달 연속! 꾸준한 예배 참석이네요! 🔥';
    } else if (_sermonStreak >= 2) {
      return '2주 연속! 계속해보세요! ⭐';
    } else {
      return '이번 주도 함께해요! 💜';
    }
  }
}

class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Create more sparkles for a magical effect
    final sparkles = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.95, size.height * 0.65),
      Offset(size.width * 0.05, size.height * 0.45),
      Offset(size.width * 0.65, size.height * 0.35),
      Offset(size.width * 0.35, size.height * 0.15),
    ];

    for (int i = 0; i < sparkles.length; i++) {
      final offset = sparkles[i];
      final phase = (animationValue + i * 0.15) % 1.0;
      final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(0.0, 1.0);
      final sparkleSize = 4.0 * opacity;

      paint.color = Colors.white.withOpacity(opacity * 0.9);
      
      // Draw star-shaped sparkles
      _drawStar(canvas, offset, sparkleSize, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const double angle = math.pi / 4;
    
    for (int i = 0; i < 8; i++) {
      final x = center.dx + size * math.cos(i * angle);
      final y = center.dy + size * math.sin(i * angle);
      
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


class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryPurple.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create floating particles
    final particles = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.6),
    ];

    for (int i = 0; i < particles.length; i++) {
      final offset = particles[i];
      final phase = (animationValue + i * 0.3) % 1.0;
      final floatY = math.sin(phase * math.pi * 2) * 10;
      final opacity = (math.sin(phase * math.pi) * 0.3 + 0.1).clamp(0.0, 0.4);
      final particleSize = 3.0 + math.sin(phase * math.pi * 2) * 2;

      paint.color = AppTheme.primaryPurple.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(offset.dx, offset.dy + floatY),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}