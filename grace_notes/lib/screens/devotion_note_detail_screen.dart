import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_theme.dart';
import '../models/devotion_note.dart';
import '../services/storage_service.dart';
import 'devotion_note_form_screen.dart';
import 'main_screen.dart';

class DevotionNoteDetailScreen extends StatefulWidget {
  final DevotionNote note;

  const DevotionNoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<DevotionNoteDetailScreen> createState() =>
      _DevotionNoteDetailScreenState();
}

class _DevotionNoteDetailScreenState extends State<DevotionNoteDetailScreen> {
  late DevotionNote _note;
  bool _wasUpdated = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Handle back button press
          if (_wasUpdated) {
            MainScreen.of(context)?.refreshCurrentScreen();
          }
          Navigator.pop(context, _wasUpdated);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.ivory,
        appBar: AppBar(
          title: const Text(
            '큐티노트',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          backgroundColor: AppTheme.ivory,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
            onPressed: () {
              if (_wasUpdated) {
                MainScreen.of(context)?.refreshCurrentScreen();
              }
              Navigator.pop(context, _wasUpdated);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.sageGreen),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DevotionNoteFormScreen(note: _note),
                  ),
                );
                if (result != null && result is DevotionNote) {
                  setState(() {
                    _note = result;
                    _wasUpdated = true; // Mark as updated
                  });
                }
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('삭제'),
                    ],
                  ),
                  onTap: () => _deleteNote(),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildScripture(),
              const SizedBox(height: 24),
              _buildSOAPSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sageGreen.withValues(alpha: 0.9),
            AppTheme.mint.withValues(alpha: 0.8),
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
                  color: AppTheme.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _note.scriptureReference.isNotEmpty
                          ? _note.scriptureReference
                          : '큐티노트',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy년 M월 d일').format(_note.date),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withValues(alpha: 0.9),
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

  Widget _buildScripture() {
    if (_note.scriptureReference.isEmpty && _note.scriptureText.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  color: AppTheme.sageGreen.withValues(alpha: 0.2),
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
                '본문 말씀',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          if (_note.scriptureReference.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _note.scriptureReference,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (_note.scriptureText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.sageGreen.withValues(alpha: 0.3)),
              ),
              child: Text(
                _note.scriptureText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSOAPSection() {
    return Column(
      children: [
        if (_note.interpretation.isNotEmpty)
          _buildSOAPCard(
            title: 'Interpretation',
            subtitle: '말씀의 의미',
            content: _note.interpretation,
            icon: Icons.menu_book,
            color: AppTheme.mint,
            emoji: '📖',
          ),
        if (_note.observation.isNotEmpty)
          _buildSOAPCard(
            title: 'Observation',
            subtitle: '내가 보는 것',
            content: _note.observation,
            icon: Icons.visibility,
            color: AppTheme.sageGreen,
            emoji: '👀',
          ),
        if (_note.application.isNotEmpty)
          _buildSOAPCard(
            title: 'Application',
            subtitle: '내가 적용할 것',
            content: _note.application,
            icon: Icons.lightbulb_outline,
            color: AppTheme.primaryPurple,
            emoji: '💡',
          ),
        if (_note.prayer.isNotEmpty)
          _buildSOAPCard(
            title: 'Prayer',
            subtitle: '내가 기도할 것',
            content: _note.prayer,
            icon: Icons.church,
            color: AppTheme.lavender,
            emoji: '🙏',
          ),
      ],
    );
  }

  Widget _buildSOAPCard({
    required String title,
    required String subtitle,
    required String content,
    required IconData icon,
    required Color color,
    required String emoji,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.softGray.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textDark,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareNote() {
    final dateString = DateFormat('yyyy년 MM월 dd일').format(_note.date);
    final title = _note.title.isNotEmpty ? _note.title : _note.scriptureReference;
    
    final shareText = '''
📖 큐티노트

📅 날짜: $dateString
🏷️ 제목: $title
📜 본문: ${_note.scriptureReference}

${_note.scriptureText.isNotEmpty ? '📖 성경 말씀:\n${_note.scriptureText}\n\n' : ''}${_note.observation.isNotEmpty ? '👀 관찰 (Observation):\n${_note.observation}\n\n' : ''}${_note.interpretation.isNotEmpty ? '💡 해석 (Interpretation):\n${_note.interpretation}\n\n' : ''}${_note.application.isNotEmpty ? '✅ 적용 (Application):\n${_note.application}\n\n' : ''}${_note.prayer.isNotEmpty ? '🙏 기도 (Prayer):\n${_note.prayer}\n\n' : ''}---
Grace Notes 앱으로 작성
    '''.trim();

    Share.share(
      shareText,
      subject: '큐티노트 - $title',
    );
  }

  void _deleteNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('정말로 이 노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.deleteDevotionNote(_note.id);
              Navigator.pop(context); // Close dialog
              MainScreen.of(context)?.refreshCurrentScreen();
              Navigator.pop(context, true); // Return to previous screen
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
