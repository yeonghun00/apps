import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _churchController = TextEditingController();
  final _preacherController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String _currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await StorageService.getSettings();
      final user = AuthService.currentUser;

      setState(() {
        _churchController.text = settings['defaultChurch'] ?? '';
        _preacherController.text = settings['defaultPreacher'] ?? '';
        _usernameController.text = user?.displayName ?? '';
        _currentUserEmail = user?.email ?? '';
      });
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save app settings
      final settings = {
        'defaultChurch': _churchController.text,
        'defaultPreacher': _preacherController.text,
      };
      await StorageService.saveSettings(settings);

      // Update username if changed
      final currentUser = AuthService.currentUser;
      if (currentUser != null &&
          _usernameController.text.trim().isNotEmpty &&
          _usernameController.text.trim() != currentUser.displayName) {
        await AuthService.updateDisplayName(_usernameController.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정이 저장되었습니다'),
            backgroundColor: AppTheme.sageGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildDefaultsSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '프로필 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '사용자 이름을 변경할 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.softGray,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '사용자 이름',
              hintText: '표시될 이름을 입력하세요',
              prefixIcon: Icon(Icons.person),
            ),
            maxLength: 20,
          ),
          if (_currentUserEmail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: AppTheme.softGray),
                const SizedBox(width: 8),
                Text(
                  _currentUserEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.softGray,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본값 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '설교노트 작성 시 자동으로 입력될 기본값을 설정합니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.softGray,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _churchController,
            decoration: const InputDecoration(
              labelText: '기본 교회명',
              hintText: '예) 새벽교회',
              prefixIcon: Icon(Icons.church),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _preacherController,
            decoration: const InputDecoration(
              labelText: '기본 설교자',
              hintText: '예) 김목사',
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '앱 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.primaryPurple),
            title: Text('앱 버전'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/icons/icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            title: const Text('Grace Notes'),
            subtitle: const Text('기독교 설교노트 & 큐티 앱'),
          ),
          const ListTile(
            leading: Icon(Icons.auto_stories, color: AppTheme.primaryPurple),
            title: Text('성경 데이터'),
            subtitle: Text('Korean Bible'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _churchController.dispose();
    _preacherController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}
