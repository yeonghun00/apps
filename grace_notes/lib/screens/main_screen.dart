import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'sermon_notes_screen.dart';
import 'devotion_notes_screen.dart';
import 'calendar_screen.dart';
import 'community_screen.dart';
import '../constants/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
  
  static _MainScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenState>();
  }
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  void navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  void refreshCurrentScreen() {
    setState(() {
      // This will trigger a rebuild of the current screen
    });
  }
  
  Widget _getCurrentScreen() {
    // Force unique keys to ensure AnimatedSwitcher always animates
    switch (_currentIndex) {
      case 0:
        return HomeScreen(key: ValueKey('home_$_currentIndex'));
      case 1:
        return SermonNotesScreen(key: ValueKey('sermon_$_currentIndex'));
      case 2:
        return DevotionNotesScreen(key: ValueKey('devotion_$_currentIndex'));
      case 3:
        return CalendarScreen(key: ValueKey('calendar_$_currentIndex'));
      case 4:
        return CommunityScreen(key: ValueKey('community_$_currentIndex'));
      default:
        return HomeScreen(key: ValueKey('home_$_currentIndex'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _getCurrentScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.softGray.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
              refreshCurrentScreen();
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.white,
            selectedItemColor: AppTheme.primaryPurple,
            unselectedItemColor: AppTheme.softGray.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _currentIndex == 0 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                      size: 24,
                      color: _currentIndex == 0 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGray.withOpacity(0.6),
                    ),
                  ),
                ),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _currentIndex == 1 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      _currentIndex == 1 ? Icons.church : Icons.church_outlined,
                      size: 24,
                      color: _currentIndex == 1 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGray.withOpacity(0.6),
                    ),
                  ),
                ),
                label: '설교노트',
              ),
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _currentIndex == 2 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      _currentIndex == 2 ? Icons.book : Icons.book_outlined,
                      size: 24,
                      color: _currentIndex == 2 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGray.withOpacity(0.6),
                    ),
                  ),
                ),
                label: '큐티',
              ),
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _currentIndex == 3 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      _currentIndex == 3 ? Icons.calendar_month : Icons.calendar_month_outlined,
                      size: 24,
                      color: _currentIndex == 3 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGray.withOpacity(0.6),
                    ),
                  ),
                ),
                label: '캘린더',
              ),
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _currentIndex == 4 ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      _currentIndex == 4 ? Icons.people : Icons.people_outline,
                      size: 24,
                      color: _currentIndex == 4 
                          ? AppTheme.primaryPurple 
                          : AppTheme.softGray.withOpacity(0.6),
                    ),
                  ),
                ),
                label: '믿음 나눔',
              ),
            ],
          ),
        ),
      ),
    );
  }
}