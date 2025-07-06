import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.auto_stories,
      iconGradient: [AppTheme.primaryPurple, AppTheme.lavender],
      title: '은혜로운 순간을\n아름답게 기록하세요',
      description: '예배와 큐티를 통해 받은 하나님의 말씀과\n마음 깊이 새겨지는 은혜를 소중히 기록해보세요',
      emoji: '💜',
    ),
    OnboardingPage(
      icon: Icons.people_alt,
      iconGradient: [AppTheme.sageGreen, AppTheme.mint],
      title: '믿음의 자매들과\n함께 나누어요',
      description: '기도 제목을 나누고 서로 격려하며\n함께 신앙의 여정을 걸어가세요',
      emoji: '🤲',
    ),
    OnboardingPage(
      icon: Icons.favorite,
      iconGradient: [AppTheme.coral, AppTheme.lavender],
      title: '성장하는 나의\n신앙 여정을 확인하세요',
      description: '캘린더와 통계를 통해 신앙 성장의 발걸음을\n한눈에 확인하고 격려받으세요',
      emoji: '✨',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.ivory,
              AppTheme.cream.withOpacity(0.8),
              AppTheme.lavender.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Animated Icon
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.iconGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.iconGradient.first.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: Colors.white,
            ),
          ).animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, delay: 200.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 60),

          // Animated Text
          Column(
            children: [
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark.withOpacity(0.8),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ],
          ).animate()
              .fadeIn(duration: 600.ms, delay: 500.ms)
              .slideY(begin: 0.3, duration: 600.ms, delay: 500.ms, curve: Curves.easeOut),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 32 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppTheme.primaryPurple
                      : AppTheme.primaryPurple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Navigation buttons
          Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      side: const BorderSide(color: AppTheme.primaryPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '이전',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 16),
              Expanded(
                flex: _currentIndex == 0 ? 1 : 1,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentIndex == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == _pages.length - 1 ? '시작하기' : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Skip button
          (_currentIndex < _pages.length - 1)
              ? TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    '건너뛰기',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textDark.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: () {},
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String description;
  final String emoji;

  OnboardingPage({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.description,
    required this.emoji,
  });
}
