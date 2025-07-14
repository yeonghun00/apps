import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Welcome message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryPurple.withValues(alpha: 0.9),
                      AppTheme.lavender.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.church,
                      size: 48,
                      color: AppTheme.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '믿음 나눔에 오신 것을\n환영합니다! 💜',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '함께 기도하고 은혜를 나누어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Main login section
              const SizedBox(height: 20),
              
              // Google Sign In
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.softGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: AppTheme.textDark,
                  ),
                  label: const Text(
                    'Google로 로그인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Info text instead of signup link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Google로 간편하게 로그인하세요',
                    style: TextStyle(
                      color: AppTheme.softGray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithGoogle();
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(AuthService.getAuthErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}