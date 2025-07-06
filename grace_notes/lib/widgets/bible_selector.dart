import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/bible_service.dart';

class BibleSelector extends StatefulWidget {
  final String? initialReference;
  final String? initialText;
  final Function(String reference, String text) onSelected;
  
  const BibleSelector({
    super.key,
    this.initialReference,
    this.initialText,
    required this.onSelected,
  });

  @override
  State<BibleSelector> createState() => _BibleSelectorState();
}

class _BibleSelectorState extends State<BibleSelector> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedStartVerse;
  int? _selectedEndVerse;
  
  List<Map<String, dynamic>> _searchResults = [];
  List<int> _availableChapters = [];
  List<int> _availableVerses = [];
  
  bool _isSearching = false;
  bool _showManualEdit = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialReference != null) {
      _parseInitialReference();
    }
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }
  
  void _parseInitialReference() {
    final ref = widget.initialReference!;
    final parts = ref.split(' ');
    if (parts.length >= 2) {
      _selectedBook = parts[0];
      final chapterVerse = parts[1].split(':');
      if (chapterVerse.length >= 2) {
        _selectedChapter = int.tryParse(chapterVerse[0]);
        final verses = chapterVerse[1].split('-');
        _selectedStartVerse = int.tryParse(verses[0]);
        if (verses.length > 1) {
          _selectedEndVerse = int.tryParse(verses[1]);
        }
      }
    }
  }
  
  String get _currentReference {
    if (_selectedBook == null || _selectedChapter == null || _selectedStartVerse == null) {
      return '';
    }
    
    String reference = '$_selectedBook $_selectedChapter:$_selectedStartVerse';
    if (_selectedEndVerse != null && _selectedEndVerse != _selectedStartVerse) {
      reference += '-$_selectedEndVerse';
    }
    return reference;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                '성경 본문 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showManualEdit = !_showManualEdit;
                  });
                },
                child: Text(
                  _showManualEdit ? '선택 모드' : '직접 입력',
                  style: const TextStyle(
                    color: AppTheme.primaryPurple,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_showManualEdit) ...[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '성경 구절을 입력하세요 (예: 요한복음 3:16)',
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) {
                widget.onSelected(value, _textController.text);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '성경 본문을 입력하세요',
                prefixIcon: Icon(Icons.text_fields),
              ),
              maxLines: 3,
              onChanged: (value) {
                widget.onSelected(_searchController.text, value);
              },
            ),
          ] else ...[
            // Book Search
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '성경 책을 검색하세요 (예: 마태복음, 마...)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchBooks,
            ),
            
            if (_isSearching) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 120,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final book = _searchResults[index];
                    return ListTile(
                      title: Text(book['name']),
                      subtitle: Text('${book['chapters']}장'),
                      onTap: () => _selectBook(book['name']),
                      selected: _selectedBook == book['name'],
                    );
                  },
                ),
              ),
            ],
            
            // Chapter and Verse Selection
            if (_selectedBook != null) ...[
              const SizedBox(height: 16),
              Text(
                '선택된 책: $_selectedBook',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedChapter,
                      decoration: const InputDecoration(
                        labelText: '장',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _availableChapters.map((chapter) {
                        return DropdownMenuItem(
                          value: chapter,
                          child: Text('$chapter장'),
                        );
                      }).toList(),
                      onChanged: _selectChapter,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedStartVerse,
                      decoration: const InputDecoration(
                        labelText: '시작 절',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _availableVerses.map((verse) {
                        return DropdownMenuItem(
                          value: verse,
                          child: Text('$verse절'),
                        );
                      }).toList(),
                      onChanged: _selectStartVerse,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedEndVerse,
                      decoration: const InputDecoration(
                        labelText: '끝 절 (선택)',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _availableVerses.map((verse) {
                        return DropdownMenuItem(
                          value: verse,
                          child: Text('$verse절'),
                        );
                      }).toList(),
                      onChanged: _selectEndVerse,
                    ),
                  ),
                ],
              ),
            ],
            
            // Current Selection Display
            if (_currentReference.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '선택된 구절: $_currentReference',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '성경 본문이 여기에 나타납니다',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        widget.onSelected(_currentReference, value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await BibleService.searchBooks(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  Future<void> _selectBook(String bookName) async {
    setState(() {
      _selectedBook = bookName;
      _selectedChapter = null;
      _selectedStartVerse = null;
      _selectedEndVerse = null;
      _searchResults = [];
      _searchController.clear();
    });
    
    final chapters = await BibleService.getChaptersForBook(bookName);
    setState(() {
      _availableChapters = chapters;
    });
  }
  
  Future<void> _selectChapter(int? chapter) async {
    if (chapter == null || _selectedBook == null) return;
    
    setState(() {
      _selectedChapter = chapter;
      _selectedStartVerse = null;
      _selectedEndVerse = null;
    });
    
    final verses = await BibleService.getVersesForChapter(_selectedBook!, chapter);
    setState(() {
      _availableVerses = verses;
    });
  }
  
  Future<void> _selectStartVerse(int? verse) async {
    if (verse == null) return;
    
    setState(() {
      _selectedStartVerse = verse;
      _selectedEndVerse = null;
    });
    
    await _loadVerseText();
  }
  
  Future<void> _selectEndVerse(int? verse) async {
    setState(() {
      _selectedEndVerse = verse;
    });
    
    await _loadVerseText();
  }
  
  Future<void> _loadVerseText() async {
    if (_selectedBook == null || _selectedChapter == null || _selectedStartVerse == null) {
      return;
    }
    
    try {
      String text;
      if (_selectedEndVerse != null && _selectedEndVerse != _selectedStartVerse) {
        text = await BibleService.getVerseRange(
          _selectedBook!,
          _selectedChapter!,
          _selectedStartVerse!,
          _selectedEndVerse!,
        );
      } else {
        text = await BibleService.getVerseText(
          _selectedBook!,
          _selectedChapter!,
          _selectedStartVerse!,
        );
      }
      
      setState(() {
        _textController.text = text;
      });
      
      widget.onSelected(_currentReference, text);
    } catch (e) {
      print('Error loading verse text: $e');
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }
}