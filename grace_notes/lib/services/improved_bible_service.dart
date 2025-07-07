import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ImprovedBibleService {
  static Map<String, dynamic>? _bibleData;
  static List<Map<String, dynamic>>? _allPopularVerses;
  
  static Future<void> _loadBibleData() async {
    if (_bibleData != null) return;
    
    try {
      final String response = await rootBundle.loadString('assets/bible/bible.json');
      _bibleData = json.decode(response);
      
      _allPopularVerses = [];
      
      for (var book in _bibleData!['books']) {
        if (book['popular_verses'] != null) {
          for (var verse in book['popular_verses']) {
            _allPopularVerses!.add({
              'book': book['name'],
              'ref': verse['ref'],
              'text': verse['text'],
              'full_ref': '${book['name']} ${verse['ref']}',
            });
          }
        }
      }
    } catch (e) {
      print('Error loading Bible data: $e');
      _bibleData = {'books': []};
      _allPopularVerses = [];
    }
  }
  
  static Future<String> getDailyVerse() async {
    // 50 diverse popular Bible verses for daily rotation
    final List<String> dailyVerses = [
      "여호와는 나의 목자시니 내게 부족함이 없으리로다 - 시편 23:1",
      "내가 산을 향하여 눈을 들리라 나의 도움이 어디서 올까 - 시편 121:1",
      "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 - 요한복음 3:16",
      "수고하고 무거운 짐 진 자들아 다 내게로 오라 내가 너희를 쉬게 하리라 - 마태복음 11:28",
      "여호와께 감사하라 그는 선하시며 그 인자하심이 영원함이로다 - 시편 136:1",
      "내가 너희에게 평안을 끼치노니 곧 나의 평안을 너희에게 주노라 - 요한복음 14:27",
      "너희는 먼저 그의 나라와 그의 의를 구하라 - 마태복음 6:33",
      "사랑하는 자들아 우리가 서로 사랑하자 사랑은 하나님께 속한 것이니라 - 요한일서 4:7",
      "여호와를 의뢰하는 자는 시온 산이 요동하지 아니함 같이 영원히 견고하리로다 - 시편 125:1",
      "주 예수를 믿으라 그리하면 너와 네 집이 구원을 받으리라 - 사도행전 16:31",
      "범사에 감사하라 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라 - 데살로니가전서 5:18",
      "두려워하지 말라 내가 너와 함께 함이라 - 이사야 41:10",
      "사람이 마음으로 자기의 길을 계획할지라도 그의 걸음을 인도하시는 이는 여호와시니라 - 잠언 16:9",
      "주의 말씀은 내 발에 등이요 내 길에 빛이니이다 - 시편 119:105",
      "너희 염려를 다 주께 맡기라 이는 그가 너희를 돌보심이라 - 베드로전서 5:7",
      "그런즉 믿음은 들음에서 나며 들음은 그리스도의 말씀으로 말미암았느니라 - 로마서 10:17",
      "사랑은 오래 참고 사랑은 온유하며 시기하지 아니하며 - 고린도전서 13:4",
      "내 영혼아 여호와를 송축하라 그의 모든 은택을 잊지 말지어다 - 시편 103:2",
      "예수께서 이르시되 내가 곧 길이요 진리요 생명이니 - 요한복음 14:6",
      "여호와의 이름은 견고한 망대라 의인은 그리로 달려가서 안전함을 얻느니라 - 잠언 18:10",
      "새 계명을 너희에게 주노니 서로 사랑하라 - 요한복음 13:34",
      "여호와는 너를 지키시는 이시라 여호와께서 네 오른쪽에서 네 그늘이 되시나니 - 시편 121:5",
      "모든 성경은 하나님의 감동으로 된 것으로 교훈과 책망과 바르게 함과 의로 교육하기에 유익하니 - 디모데후서 3:16",
      "여호와는 나의 힘이요 나의 방패시라 - 시편 28:7",
      "그러므로 이제 그리스도 예수 안에 있는 자에게는 결코 정죄함이 없나니 - 로마서 8:1",
      "내가 강건한 날에는 자족하기를 배웠노니 - 빌립보서 4:11",
      "주께서 내게 이르시기를 내 은혜가 네게 족하도다 - 고린도후서 12:9",
      "하나님의 사랑이 우리 마음에 부은 바 됨은 우리에게 주신 성령으로 말미암음이니 - 로마서 5:5",
      "여호와여 주의 인자하심이 하늘에 있고 주의 성실하심이 공중에 사무쳤으며 - 시편 36:5",
      "내가 세상 끝날까지 너희와 항상 함께 있으리라 - 마태복음 28:20",
      "주 안에서 항상 기뻐하라 내가 다시 말하노니 기뻐하라 - 빌립보서 4:4",
      "나의 하나님이 그리스도 예수 안에서 영광 가운데 그의 풍성함으로 너희 모든 쓸 것을 채우시리라 - 빌립보서 4:19",
      "여호와는 자기를 경외하는 자들을 기뻐하시며 - 시편 147:11",
      "오직 성령이 너희에게 임하시면 너희가 권능을 받고 - 사도행전 1:8",
      "하나님께로부터 난 자마다 세상을 이기느니라 - 요한일서 5:4",
      "내가 여호와께 바라는 한 가지 일 그것을 구하리니 - 시편 27:4",
      "할 수 있거든이 무슨 말이냐 믿는 자에게는 능하지 못할 일이 없느니라 - 마가복음 9:23",
      "여호와의 구원을 보라 그가 오늘 너희를 위하여 행하시리니 - 출애굽기 14:13",
      "기도와 간구로 아무것도 염려하지 말고 다만 모든 일에 감사함으로 - 빌립보서 4:6",
      "우리는 그가 만드신 바라 그리스도 예수 안에서 선한 일을 위하여 지으심을 받은 자니 - 에베소서 2:10",
      "너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라 - 잠언 3:5",
      "여호와는 마음이 상한 자를 고치시며 그들의 상처를 싸매시는도다 - 시편 147:3",
      "하나님은 우리의 피난처시요 힘이시니 환난 중에 만날 큰 도움이시라 - 시편 46:1",
      "그러므로 우리가 담대히 말하되 주는 나를 돕는 이시니 내가 무서워하지 아니하겠노라 - 히브리서 13:6",
      "여호와의 눈은 온 땅을 두루 감찰하사 자기에게 전심으로 향하는 자들을 위하여 능력을 베푸시나니 - 역대하 16:9",
      "의인의 길은 돋는 햇살 같아서 크게 빛나 한낮의 광명에 이르거니와 - 잠언 4:18",
      "사람의 마음에는 많은 계획이 있어도 오직 여호와의 뜻만이 완전히 서리라 - 잠언 19:21",
      "여호와께서 너를 위하여 싸우시리니 너는 잠잠할지니라 - 출애굽기 14:14",
      "우리가 아직 죄인 되었을 때에 그리스도께서 우리를 위하여 죽으심으로 하나님께서 우리에 대한 자기의 사랑을 확증하셨느니라 - 로마서 5:8",
      "여호와의 말씀에 나의 생각은 너희의 생각과 다르며 나의 길은 너희의 길과 다름이니라 - 이사야 55:8"
    ];
    
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final randomIndex = Random(dayOfYear).nextInt(dailyVerses.length);
    
    return dailyVerses[randomIndex];
  }
  
  static Future<List<Map<String, dynamic>>> getAllBooks() async {
    await _loadBibleData();
    
    if (_bibleData == null) return [];
    
    return (_bibleData!['books'] as List)
        .map((book) => {
              'name': book['name'],
              'abbr': book['abbr'],
              'chapters': book['chapters'],
              'popular_verses': book['popular_verses'] ?? [],
            })
        .toList();
  }
  
  static Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final books = await getAllBooks();
    
    if (query.isEmpty) return books;
    
    return books
        .where((book) =>
            book['name'].toLowerCase().contains(query.toLowerCase()) ||
            book['abbr'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
  
  static Future<Map<String, dynamic>?> getBookByName(String bookName) async {
    final books = await getAllBooks();
    
    try {
      return books.firstWhere((book) => book['name'] == bookName);
    } catch (e) {
      return null;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getPopularVersesForBook(String bookName) async {
    final book = await getBookByName(bookName);
    
    if (book == null) return [];
    
    return (book['popular_verses'] as List)
        .map((verse) => {
              'ref': verse['ref'],
              'text': verse['text'],
              'full_ref': '$bookName ${verse['ref']}',
            })
        .toList();
  }
  
  static Future<List<Map<String, dynamic>>> getAllPopularVerses() async {
    await _loadBibleData();
    
    return _allPopularVerses ?? [];
  }
  
  static Future<String> getVerseText(String bookName, int chapter, int verse) async {
    // For now, return a placeholder. In a full implementation, 
    // this would fetch the actual verse text from a complete Bible database
    return '선택한 구절의 내용이 여기에 표시됩니다. ($bookName $chapter:$verse)';
  }
  
  static Future<String> getVerseRange(String bookName, int chapter, int startVerse, int endVerse) async {
    // For now, return a placeholder. In a full implementation,
    // this would fetch the actual verse range from a complete Bible database
    return '선택한 구절 범위의 내용이 여기에 표시됩니다. ($bookName $chapter:$startVerse-$endVerse)';
  }
  
  static Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    await _loadBibleData();
    
    if (_allPopularVerses == null || query.isEmpty) return [];
    
    return _allPopularVerses!
        .where((verse) => verse['text'].toLowerCase().contains(query.toLowerCase()))
        .take(20)
        .toList();
  }
  
  // Helper method to get a random popular verse for encouragement
  static Future<Map<String, dynamic>?> getRandomPopularVerse() async {
    await _loadBibleData();
    
    if (_allPopularVerses == null || _allPopularVerses!.isEmpty) return null;
    
    final randomIndex = Random().nextInt(_allPopularVerses!.length);
    return _allPopularVerses![randomIndex];
  }
}