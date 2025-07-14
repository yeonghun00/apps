import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/improved_bible_service.dart';

class ImprovedBibleSelector extends StatefulWidget {
  final String? initialReference;
  final String? initialText;
  final Function(String reference, String text) onSelected;
  
  const ImprovedBibleSelector({
    super.key,
    this.initialReference,
    this.initialText,
    required this.onSelected,
  });

  @override
  State<ImprovedBibleSelector> createState() => _ImprovedBibleSelectorState();
}

class _ImprovedBibleSelectorState extends State<ImprovedBibleSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customReferenceController = TextEditingController();
  final TextEditingController _customTextController = TextEditingController();
  
  String? _selectedBook;
  int? _selectedChapter;
  int? _selectedStartVerse;
  int? _selectedEndVerse;
  
  final Map<String, List<String>> _bibleBooks = {
    '구약': [
      '창세기', '출애굽기', '레위기', '민수기', '신명기',
      '여호수아', '사사기', '룻기', '사무엘상', '사무엘하',
      '열왕기상', '열왕기하', '역대상', '역대하', '에스라',
      '느헤미야', '에스더', '욥기', '시편', '잠언',
      '전도서', '아가', '이사야', '예레미야', '예레미야애가',
      '에스겔', '다니엘', '호세아', '요엘', '아모스',
      '오바댜', '요나', '미가', '나훔', '하박국',
      '스바냐', '학개', '스가랴', '말라기'
    ],
    '신약': [
      '마태복음', '마가복음', '누가복음', '요한복음',
      '사도행전', '로마서', '고린도전서', '고린도후서',
      '갈라디아서', '에베소서', '빌립보서', '골로새서',
      '데살로니가전서', '데살로니가후서', '디모데전서', '디모데후서',
      '디도서', '빌레몬서', '히브리서', '야고보서',
      '베드로전서', '베드로후서', '요한일서', '요한이서',
      '요한삼서', '유다서', '요한계시록'
    ]
  };
  
  List<Map<String, dynamic>> _allBooks = [];
  List<Map<String, dynamic>> _popularVerses = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.initialReference != null) {
      _customReferenceController.text = widget.initialReference!;
    }
    if (widget.initialText != null) {
      _customTextController.text = widget.initialText!;
    }
    
    _loadBibleData();
  }
  
  Future<void> _loadBibleData() async {
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      final books = await ImprovedBibleService.getAllBooks();
      final verses = await ImprovedBibleService.getAllPopularVerses();
      
      setState(() {
        _allBooks = books;
        _popularVerses = verses;
      });
    } catch (e) {
      print('Error loading Bible data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customReferenceController.dispose();
    _customTextController.dispose();
    super.dispose();
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
              Icon(Icons.auto_stories, color: AppTheme.darkPurple, size: 24),
              const SizedBox(width: 12),
              const Text(
                '성경 본문 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.darkPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: AppTheme.white,
              unselectedLabelColor: AppTheme.textDark,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: '인기 구절'),
                Tab(text: '책별 선택'),
                Tab(text: '직접 입력'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tab Views
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPopularVersesTab(),
                _buildBookSelectionTab(),
                _buildCustomInputTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularVersesTab() {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 사용되는 말씀을 선택하세요',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.softGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._popularVerses.map((verse) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectVerseFromData(verse),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.darkPurple.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          verse['full_ref'] ?? '${verse['book']} ${verse['ref']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildBookSelectionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성경책을 선택하고 장, 절을 입력하세요',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.softGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        Expanded(
          child: Row(
            children: [
              // Old Testament & New Testament
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildTestamentSection('구약', _bibleBooks['구약']!),
                    const SizedBox(height: 16),
                    _buildTestamentSection('신약', _bibleBooks['신약']!),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Chapter and Verse Selection
              Expanded(
                flex: 1,
                child: _buildChapterVerseSelection(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTestamentSection(String title, List<String> books) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkPurple,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final bookName = books[index];
                  final isSelected = _selectedBook == bookName;
                  
                  return InkWell(
                    onTap: () => _selectBook(bookName),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.darkPurple : AppTheme.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.darkPurple : AppTheme.softGray.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          bookName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.white : AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
  
  Widget _buildChapterVerseSelection() {
    if (_selectedBook == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '📖\n\n성경책을\n먼저 선택해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.softGray,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedBook!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkPurple,
            ),
          ),
          const SizedBox(height: 16),
          
          // Chapter input
          TextField(
            decoration: InputDecoration(
              labelText: '장',
              hintText: '예: 3',
              filled: true,
              fillColor: AppTheme.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _selectedChapter = int.tryParse(value);
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Verse inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '시작 절',
                    hintText: '16',
                    filled: true,
                    fillColor: AppTheme.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _selectedStartVerse = int.tryParse(value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '끝 절',
                    hintText: '선택',
                    filled: true,
                    fillColor: AppTheme.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _selectedEndVerse = int.tryParse(value);
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canGenerateReference() ? _generateReference : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPurple,
                foregroundColor: AppTheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '구절 생성',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomInputTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성경 구절과 내용을 직접 입력하세요',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.softGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _customReferenceController,
          decoration: const InputDecoration(
            labelText: '성경 구절',
            hintText: '예: 요한복음 3:16',
            prefixIcon: Icon(Icons.book),
          ),
          onChanged: (value) {
            widget.onSelected(value, _customTextController.text);
          },
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _customTextController,
          decoration: const InputDecoration(
            labelText: '성경 본문',
            hintText: '성경 본문 내용을 입력하세요',
            prefixIcon: Icon(Icons.text_fields),
          ),
          maxLines: 8,
          onChanged: (value) {
            widget.onSelected(_customReferenceController.text, value);
          },
        ),
      ],
    );
  }
  
  void _selectBook(String book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _selectedStartVerse = null;
      _selectedEndVerse = null;
    });
  }
  
  void _selectVerse(String book, String ref, String text) {
    final reference = '$book $ref';
    widget.onSelected(reference, text);
    
    // Update custom input tab as well
    _customReferenceController.text = reference;
    _customTextController.text = text;
  }
  
  void _selectVerseFromData(Map<String, dynamic> verse) {
    final reference = verse['full_ref'] ?? '${verse['book']} ${verse['ref']}';
    final text = verse['text'] ?? '';
    
    widget.onSelected(reference, text);
    
    // Update custom input tab as well
    _customReferenceController.text = reference;
    _customTextController.text = text;
  }
  
  bool _canGenerateReference() {
    return _selectedBook != null && 
           _selectedChapter != null && 
           _selectedStartVerse != null;
  }
  
  void _generateReference() {
    if (!_canGenerateReference()) return;
    
    String reference = '$_selectedBook $_selectedChapter:$_selectedStartVerse';
    if (_selectedEndVerse != null && _selectedEndVerse != _selectedStartVerse) {
      reference += '-$_selectedEndVerse';
    }
    
    // For demo purposes, generate a placeholder text
    String text = '선택한 구절의 내용이 여기에 표시됩니다. 실제로는 해당 구절의 성경 본문이 자동으로 입력됩니다.';
    
    widget.onSelected(reference, text);
    
    // Update custom input tab
    _customReferenceController.text = reference;
    _customTextController.text = text;
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$reference 구절이 선택되었습니다'),
        backgroundColor: AppTheme.darkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}