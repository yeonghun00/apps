import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/sermon_note.dart';
import '../services/storage_service.dart';
import 'sermon_note_form_screen.dart';
import 'main_screen.dart';

class SermonNoteDetailScreen extends StatefulWidget {
  final SermonNote note;

  const SermonNoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<SermonNoteDetailScreen> createState() => _SermonNoteDetailScreenState();
}

class _SermonNoteDetailScreenState extends State<SermonNoteDetailScreen> {
  late SermonNote _note;
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
            '설교노트',
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
              icon: const Icon(Icons.edit, color: AppTheme.primaryPurple),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SermonNoteFormScreen(note: _note),
                  ),
                );
                if (result != null && result is SermonNote) {
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
              _buildSermonContent(),
              const SizedBox(height: 24),
              _buildReflection(),
              const SizedBox(height: 24),
              _buildPrayerRequest(),
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
            AppTheme.primaryPurple.withOpacity(0.9),
            AppTheme.lavender.withOpacity(0.8),
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
                  Icons.church,
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
                      _note.title.isNotEmpty ? _note.title : '제목 없음',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_note.church} • ${_note.preacher}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy년 M월 d일').format(_note.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.white.withOpacity(0.7),
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
                color: AppTheme.mint.withOpacity(0.3),
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
                border: Border.all(color: AppTheme.sageGreen.withOpacity(0.3)),
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

  Widget _buildSermonContent() {
    if (_note.mainPoints.isEmpty) {
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
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notes,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '주요 내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _note.mainPoints,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReflection() {
    if (_note.personalReflection.isEmpty) {
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
                  color: AppTheme.mint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.sageGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '개인 묵상',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _note.personalReflection,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRequest() {
    if (_note.prayerRequests.isEmpty) {
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
                  color: AppTheme.lavender.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.church,
                  color: AppTheme.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '기도 제목',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _note.prayerRequests,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
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
              await StorageService.deleteSermonNote(_note.id);
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
