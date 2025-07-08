import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/devotion_note.dart';
import '../services/storage_service.dart';
import '../widgets/simple_bible_selector.dart';
import '../widgets/note_success_dialog.dart';

class DevotionNoteFormScreen extends StatefulWidget {
  final DevotionNote? note;
  
  const DevotionNoteFormScreen({super.key, this.note});

  @override
  State<DevotionNoteFormScreen> createState() => _DevotionNoteFormScreenState();
}

class _DevotionNoteFormScreenState extends State<DevotionNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _scriptureReferenceController = TextEditingController();
  final _scriptureTextController = TextEditingController();
  final _observationController = TextEditingController();
  final _interpretationController = TextEditingController();
  final _applicationController = TextEditingController();
  final _prayerController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _loadNoteData();
    }
  }

  void _loadNoteData() {
    final note = widget.note!;
    _titleController.text = note.title;
    _scriptureReferenceController.text = note.scriptureReference;
    _scriptureTextController.text = note.scriptureText;
    _observationController.text = note.observation;
    _interpretationController.text = note.interpretation;
    _applicationController.text = note.application;
    _prayerController.text = note.prayer;
    _selectedDate = note.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scriptureReferenceController.dispose();
    _scriptureTextController.dispose();
    _observationController.dispose();
    _interpretationController.dispose();
    _applicationController.dispose();
    _prayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ivory,
      appBar: AppBar(
        title: Text(
          widget.note == null ? '큐티노트 작성' : '큐티노트 편집',
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
                      color: AppTheme.sageGreen,
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
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildTitleSection(),
              const SizedBox(height: 16),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildScriptureSection(),
              const SizedBox(height: 24),
              _buildSOAPSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sageGreen.withOpacity(0.8),
            AppTheme.mint.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOAP 큐티법',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• S (Scripture): 성경 본문 읽기\n• O (Observation): 관찰하기\n• A (Application): 적용하기\n• P (Prayer): 기도하기',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '제목',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '제목',
              hintText: '비워두면 성경구절이 제목이 됩니다',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            maxLength: 50,
          ),
        ],
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
                  Icon(Icons.calendar_today, color: AppTheme.darkGreen),
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
        ],
      ),
    );
  }

  Widget _buildScriptureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.darkPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'S',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Scripture - 성경',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SimpleBibleSelector(
            initialReference: _scriptureReferenceController.text,
            initialText: _scriptureTextController.text,
            onSelected: (reference, text) {
              setState(() {
                _scriptureReferenceController.text = reference;
                _scriptureTextController.text = text;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSOAPSection() {
    return Column(
      children: [
        _buildSOAPCard(
          'O',
          'Observation - 관찰',
          '본문에서 무엇을 보았나요?',
          '누가, 언제, 어디서, 무엇을, 어떻게에 대해 관찰해보세요',
          _observationController,
          AppTheme.darkGreen,
        ),
        const SizedBox(height: 16),
        _buildSOAPCard(
          'I',
          'Interpretation - 해석',
          '이 말씀이 무엇을 의미하나요?',
          '본문의 의미와 하나님의 메시지를 생각해보세요',
          _interpretationController,
          AppTheme.darkPurple,
        ),
        const SizedBox(height: 16),
        _buildSOAPCard(
          'A',
          'Application - 적용',
          '내 삶에 어떻게 적용할까요?',
          '구체적으로 실천할 수 있는 내용을 적어보세요',
          _applicationController,
          AppTheme.darkMint,
        ),
        const SizedBox(height: 16),
        _buildSOAPCard(
          'P',
          'Prayer - 기도',
          '어떤 기도를 드리시나요?',
          '말씀을 통해 하나님께 드리고 싶은 기도를 적어보세요',
          _prayerController,
          AppTheme.deepLavender,
        ),
      ],
    );
  }

  Widget _buildSOAPCard(
    String letter,
    String title,
    String question,
    String hint,
    TextEditingController controller,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
            ),
            maxLines: 4,
            validator: letter == 'O' ? (value) {
              if (value == null || value.isEmpty) {
                return '관찰 내용을 입력해주세요';
              }
              return null;
            } : null,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final note = DevotionNote(
        id: widget.note?.id,
        date: _selectedDate,
        title: _titleController.text.trim(),
        scriptureReference: _scriptureReferenceController.text,
        scriptureText: _scriptureTextController.text,
        observation: _observationController.text,
        interpretation: _interpretationController.text,
        application: _applicationController.text,
        prayer: _prayerController.text,
        createdAt: widget.note?.createdAt,
      );

      await StorageService.saveDevotionNote(note);

      if (mounted) {
        // Show success dialog
        final shouldReturn = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => NoteSuccessDialog(
            noteType: 'devotion',
            title: note.title.isNotEmpty ? note.title : note.scriptureReference,
            content: note.observation,
            scriptureReference: note.scriptureReference,
            onContinue: () {
              Navigator.pop(context, true); // Close dialog and return true
            },
          ),
        );
        
        if (shouldReturn == true && mounted) {
          Navigator.pop(context, note); // Close form and return updated note
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
}