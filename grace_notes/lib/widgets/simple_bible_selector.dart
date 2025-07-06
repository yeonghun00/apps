import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/simple_bible_service.dart';

class SimpleBibleSelector extends StatefulWidget {
  final String? initialReference;
  final String? initialText;
  final Function(String reference, String text) onSelected;
  
  const SimpleBibleSelector({
    super.key,
    this.initialReference,
    this.initialText,
    required this.onSelected,
  });

  @override
  State<SimpleBibleSelector> createState() => _SimpleBibleSelectorState();
}

class _SimpleBibleSelectorState extends State<SimpleBibleSelector> {
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedBook;
  bool _showBookList = false;
  bool _showDirectInput = false;
  String _chapter = '';
  String _verse = '';
  String _endVerse = '';
  String _endChapter = '';
  final List<Map<String, dynamic>> _bibleQuotes = [];
  bool _showMultipleQuotes = false;
  
  final List<String> _bibleBooks = [
    '창세기', '출애굽기', '레위기', '민수기', '신명기',
    '여호수아', '사사기', '룻기', '사무엘상', '사무엘하',
    '열왕기상', '열왕기하', '역대상', '역대하', '에스라',
    '느헤미야', '에스더', '욥기', '시편', '잠언',
    '전도서', '아가', '이사야', '예레미야', '예레미야애가',
    '에스겔', '다니엘', '호세아', '요엘', '아모스',
    '오바댜', '요나', '미가', '나훔', '하박국',
    '스바냐', '학개', '스가랴', '말라기',
    '마태복음', '마가복음', '누가복음', '요한복음',
    '사도행전', '로마서', '고린도전서', '고린도후서',
    '갈라디아서', '에베소서', '빌립보서', '골로새서',
    '데살로니가전서', '데살로니가후서', '디모데전서', '디모데후서',
    '디도서', '빌레몬서', '히브리서', '야고보서',
    '베드로전서', '베드로후서', '요한일서', '요한이서',
    '요한삼서', '유다서', '요한계시록'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialReference != null) {
      _referenceController.text = widget.initialReference!;
    }
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredBooks {
    if (_searchController.text.isEmpty) return _bibleBooks;
    return _bibleBooks
        .where((book) => book.contains(_searchController.text))
        .toList();
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
              Icon(Icons.auto_stories, color: AppTheme.darkPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                '성경 본문',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 성경책 선택
          GestureDetector(
            onTap: () {
              setState(() {
                _showBookList = !_showBookList;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkPurple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedBook ?? '성경책을 선택하세요',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedBook != null ? AppTheme.textDark : AppTheme.softGray,
                      ),
                    ),
                  ),
                  Icon(
                    _showBookList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.darkPurple,
                  ),
                ],
              ),
            ),
          ),
          
          // 성경책 목록
          if (_showBookList) ...[
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkPurple.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.cream,
              ),
              child: Column(
                children: [
                  // 검색
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '성경책 검색 (예: 마태, 요한...)',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.white,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  
                  // 성경책 리스트
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final bookName = _filteredBooks[index];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedBook = bookName;
                              _showBookList = false;
                              _searchController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: _selectedBook == bookName ? AppTheme.darkPurple.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              bookName,
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedBook == bookName ? AppTheme.darkPurple : AppTheme.textDark,
                                fontWeight: _selectedBook == bookName ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // 장:절 입력 (선택된 책이 있을 때만 표시)
          if (_selectedBook != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '장',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _chapter = value;
                      if (value.isNotEmpty) _updateReference();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '절',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _verse = value;
                      if (value.isNotEmpty) _updateReference();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('-', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '끝절',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _endVerse = value;
                      _updateReference();
                    },
                  ),
                ),
              ],
            ),
            
            // Cross-chapter input
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMultipleQuotes = !_showMultipleQuotes;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _showMultipleQuotes ? AppTheme.darkPurple.withOpacity(0.1) : AppTheme.cream,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _showMultipleQuotes ? AppTheme.darkPurple : AppTheme.softGray.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showMultipleQuotes ? Icons.keyboard_arrow_up : Icons.add,
                      color: AppTheme.darkPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showMultipleQuotes ? '닫기' : '더 많은 구절 추가',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_showMultipleQuotes) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.darkPurple.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여러 구절을 함께 사용하기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._bibleQuotes.asMap().entries.map((entry) {
                      int index = entry.key;
                      return _buildAdditionalQuoteSelector(index);
                    }).toList(),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _bibleQuotes.add({
                            'selectedBook': null,
                            'chapter': '',
                            'verse': '',
                            'endVerse': '',
                            'reference': '',
                            'text': ''
                          });
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('구절 더하기', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkPurple.withOpacity(0.1),
                        foregroundColor: AppTheme.darkPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          
          // 직접 입력 토글 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _showDirectInput = !_showDirectInput;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showDirectInput ? AppTheme.darkPurple.withOpacity(0.1) : AppTheme.cream,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _showDirectInput ? AppTheme.darkPurple : AppTheme.softGray.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showDirectInput ? Icons.keyboard_arrow_up : Icons.edit,
                    color: AppTheme.darkPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showDirectInput ? '직접 입력 숨기기' : '직접 입력하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 직접 입력 필드
          if (_showDirectInput) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                hintText: '예) 요한복음 3:16, 마태복음 5:3-12, 창세기 1:1-2:3',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (value) {
                widget.onSelected(value, _textController.text);
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          // 성경 본문 입력
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: '성경 본문',
              hintText: '성경 구절의 내용을 입력하세요',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            onChanged: (value) {
              widget.onSelected(_referenceController.text, value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateReference() async {
    if (_selectedBook != null && _chapter.isNotEmpty && _verse.isNotEmpty) {
      String reference = '$_selectedBook $_chapter:$_verse';
      
      // Handle verse ranges within same chapter
      if (_endVerse.isNotEmpty && _endVerse != _verse) {
        reference += '-$_endVerse';
      }
      
      // 성경 구절 자동 입력
      _referenceController.text = reference;
      
      // Bible JSON에서 실제 본문 가져오기
      String text = await _getVerseFromBible(_selectedBook!, _chapter, _verse, _endVerse);
      _textController.text = text;
      
      // Update main reference (this will handle combining with additional quotes)
      _updateMainReference();
    }
  }
  
  Future<String> _getVerseFromBible(String book, String chapter, String verse, String endVerse) async {
    try {
      print('🎯 Getting verse: $book $chapter:$verse');
      
      // 성경책 이름을 약어로 변환 (예: 창세기 -> 창)
      final bookAbbr = SimpleBibleService.getBookAbbreviation(book);
      
      String verseText;
      
      if (endVerse.isNotEmpty) {
        // Use verse range (handles both single verse and range cases)
        verseText = await SimpleBibleService.getVerseRange(
          bookAbbr,
          int.parse(chapter),
          int.parse(verse),
          int.parse(endVerse)
        );
      } else {
        // Single verse
        final singleVerse = await SimpleBibleService.getVerse(
          bookAbbr, 
          int.parse(chapter), 
          int.parse(verse)
        );
        verseText = singleVerse ?? '성경 본문을 직접 입력해주세요.';
      }
      
      if (verseText.isNotEmpty && verseText != '성경 본문을 직접 입력해주세요.') {
        print('🎉 Success! Returning verse text: "${verseText.length > 30 ? verseText.substring(0, 30) : verseText}..."');
        return verseText;
      }
      
      print('⚠️ No verse found, showing default message');
      return '성경 본문을 직접 입력해주세요.';
    } catch (e) {
      print('💥 Error in _getVerseFromBible: $e');
      return '성경 본문을 직접 입력해주세요.';
    }
  }

  Widget _buildAdditionalQuoteSelector(int index) {
    final quote = _bibleQuotes[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '구절 ${index + 2}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkPurple,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                onPressed: () {
                  setState(() {
                    _bibleQuotes.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 성경책 선택
          GestureDetector(
            onTap: () {
              setState(() {
                quote['showBookList'] = !(quote['showBookList'] ?? false);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkPurple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.cream,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      quote['selectedBook'] ?? '성경책을 선택하세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: quote['selectedBook'] != null ? AppTheme.textDark : AppTheme.softGray,
                      ),
                    ),
                  ),
                  Icon(
                    (quote['showBookList'] ?? false) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.darkPurple,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          // 성경책 목록
          if (quote['showBookList'] ?? false) ...[
            const SizedBox(height: 6),
            Container(
              height: 120,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.darkPurple.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.cream,
              ),
              child: ListView.builder(
                itemCount: _bibleBooks.length,
                itemBuilder: (context, bookIndex) {
                  final bookName = _bibleBooks[bookIndex];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        quote['selectedBook'] = bookName;
                        quote['showBookList'] = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        color: quote['selectedBook'] == bookName ? AppTheme.darkPurple.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        bookName,
                        style: TextStyle(
                          fontSize: 12,
                          color: quote['selectedBook'] == bookName ? AppTheme.darkPurple : AppTheme.textDark,
                          fontWeight: quote['selectedBook'] == bookName ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // 장:절 입력
          if (quote['selectedBook'] != null) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '장',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      quote['chapter'] = value;
                      _updateAdditionalQuote(index);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text(':', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '절',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      quote['verse'] = value;
                      _updateAdditionalQuote(index);
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Text('-', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '끝절',
                      hintText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    style: const TextStyle(fontSize: 12),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      quote['endVerse'] = value;
                      _updateAdditionalQuote(index);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // 성경 본문 (읽기 전용)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.softGray.withOpacity(0.3)),
            ),
            child: Text(
              quote['text'] ?? '성경 본문을 직접 입력해주세요.',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textDark,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAdditionalQuote(int index) async {
    final quote = _bibleQuotes[index];
    if (quote['selectedBook'] != null && 
        quote['chapter']?.isNotEmpty == true && 
        quote['verse']?.isNotEmpty == true) {
      
      String reference = '${quote['selectedBook']} ${quote['chapter']}:${quote['verse']}';
      if (quote['endVerse']?.isNotEmpty == true && quote['endVerse'] != quote['verse']) {
        reference += '-${quote['endVerse']}';
      }
      
      quote['reference'] = reference;
      
      // Bible JSON에서 실제 본문 가져오기
      String text = await _getVerseFromBible(
        quote['selectedBook'], 
        quote['chapter'], 
        quote['verse'], 
        quote['endVerse'] ?? ''
      );
      quote['text'] = text;
      
      setState(() {});
      
      // Update main widget
      _updateMainReference();
    }
  }

  void _updateMainReference() {
    if (_selectedBook != null && _chapter.isNotEmpty && _verse.isNotEmpty) {
      String reference = '$_selectedBook $_chapter:$_verse';
      if (_endVerse.isNotEmpty && _endVerse != _verse) {
        reference += '-$_endVerse';
      }
      
      String combinedReference = reference;
      String combinedText = _textController.text;
      
      for (var quote in _bibleQuotes) {
        if (quote['reference']?.isNotEmpty == true && quote['text']?.isNotEmpty == true) {
          combinedReference += '; ${quote['reference']}';
          combinedText += '\n\n${quote['text']}';
        }
      }
      
      widget.onSelected(combinedReference, combinedText);
    }
  }
}