import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/sermon_note.dart';
import '../services/storage_service.dart';
import '../widgets/simple_bible_selector.dart';
import '../widgets/note_success_dialog.dart';

class SermonNoteFormScreen extends StatefulWidget {
  final SermonNote? note;
  
  const SermonNoteFormScreen({super.key, this.note});

  @override
  State<SermonNoteFormScreen> createState() => _SermonNoteFormScreenState();
}

class _SermonNoteFormScreenState extends State<SermonNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _churchController = TextEditingController();
  final _preacherController = TextEditingController();
  final _titleController = TextEditingController();
  final _scriptureReferenceController = TextEditingController();
  final _scriptureTextController = TextEditingController();
  final _mainPointsController = TextEditingController();
  final _personalReflectionController = TextEditingController();
  final _applicationPointsController = TextEditingController();
  final _prayerRequestsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _loadNoteData();
    } else {
      _loadDefaultValues();
    }
  }

  Future<void> _loadDefaultValues() async {
    try {
      final settings = await StorageService.getSettings();
      setState(() {
        _churchController.text = settings['defaultChurch'] ?? '';
        _preacherController.text = settings['defaultPreacher'] ?? '';
      });
    } catch (e) {
      print('Error loading default values: $e');
    }
  }

  void _loadNoteData() {
    final note = widget.note!;
    _churchController.text = note.church;
    _preacherController.text = note.preacher;
    _titleController.text = note.title;
    _scriptureReferenceController.text = note.scriptureReference;
    _scriptureTextController.text = note.scriptureText;
    _mainPointsController.text = note.mainPoints;
    _personalReflectionController.text = note.personalReflection;
    _applicationPointsController.text = note.applicationPoints;
    _prayerRequestsController.text = note.prayerRequests;
    _selectedDate = note.date;
  }

  @override
  void dispose() {
    _churchController.dispose();
    _preacherController.dispose();
    _titleController.dispose();
    _scriptureReferenceController.dispose();
    _scriptureTextController.dispose();
    _mainPointsController.dispose();
    _personalReflectionController.dispose();
    _applicationPointsController.dispose();
    _prayerRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: Text(
          widget.note == null ? '설교노트 작성' : '설교노트 편집',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: AppTheme.ivory,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNote,
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
                      color: AppTheme.darkPurple,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildScriptureSection(),
              const SizedBox(height: 24),
              _buildContentSection(),
              const SizedBox(height: 24),
              _buildReflectionSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기본 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _churchController,
                  decoration: const InputDecoration(
                    labelText: '교회명',
                    hintText: '예) 새벽교회',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '교회명을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _preacherController,
                  decoration: const InputDecoration(
                    labelText: '설교자',
                    hintText: '예) 김목사',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '설교자를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.darkPurple),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '설교 제목',
              hintText: '예) 하나님의 사랑',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '설교 제목을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureSection() {
    return SimpleBibleSelector(
      initialReference: _scriptureReferenceController.text,
      initialText: _scriptureTextController.text,
      onSelected: (reference, text) {
        setState(() {
          _scriptureReferenceController.text = reference;
          _scriptureTextController.text = text;
        });
      },
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '설교 내용',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mainPointsController,
            decoration: const InputDecoration(
              labelText: '주요 내용',
              hintText: '설교의 핵심 내용을 적어주세요',
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '개인 묵상',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _personalReflectionController,
            decoration: const InputDecoration(
              labelText: '개인 묵상',
              hintText: '받은 은혜나 느낀 점을 적어주세요',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _applicationPointsController,
            decoration: const InputDecoration(
              labelText: '적용 포인트',
              hintText: '삶에 적용할 점들을 적어주세요',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _prayerRequestsController,
            decoration: const InputDecoration(
              labelText: '기도 제목',
              hintText: '기도하고 싶은 내용을 적어주세요',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveNote() async {
    // Hide keyboard first to prevent navigation issues
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final note = SermonNote(
        id: widget.note?.id,
        date: _selectedDate,
        church: _churchController.text,
        preacher: _preacherController.text,
        title: _titleController.text,
        scriptureReference: _scriptureReferenceController.text,
        scriptureText: _scriptureTextController.text,
        mainPoints: _mainPointsController.text,
        personalReflection: _personalReflectionController.text,
        applicationPoints: _applicationPointsController.text,
        prayerRequests: _prayerRequestsController.text,
        createdAt: widget.note?.createdAt,
      );

      await StorageService.saveSermonNote(note);

      // Save default values for future use
      await _saveDefaultValues();

      if (mounted) {
        // Show success dialog
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => NoteSuccessDialog(
            noteType: 'sermon',
            title: note.title,
            content: note.mainPoints,
            scriptureReference: note.scriptureReference,
          ),
        );
        
        // After dialog closes, navigate back to previous screen
        if (mounted) {
          Navigator.pop(context, note);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDefaultValues() async {
    try {
      final settings = await StorageService.getSettings();
      final updatedSettings = {
        ...settings,
        'defaultChurch': _churchController.text,
        'defaultPreacher': _preacherController.text,
      };
      await StorageService.saveSettings(updatedSettings);
    } catch (e) {
      print('Error saving default values: $e');
    }
  }
}