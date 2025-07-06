import 'dart:convert';
import 'package:flutter/services.dart';

class SimpleBibleService {
  static Map<String, String>? _bibleData;

  static Future<void> _loadBibleData() async {
    if (_bibleData != null) return;

    try {
      print('🔍 Loading Bible data from assets/bible/bible.json');
      final String response =
          await rootBundle.loadString('assets/bible/bible.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      _bibleData =
          jsonData.map((key, value) => MapEntry(key, value.toString()));
      print(
          '✅ Bible data loaded successfully. Total verses: ${_bibleData?.length}');

      // 처음 5개 키 출력해서 구조 확인
      if (_bibleData != null && _bibleData!.isNotEmpty) {
        print('📋 Sample keys from JSON:');
        _bibleData!.keys.take(5).forEach((key) {
          print('   $key: ${_bibleData![key]?.substring(0, 20)}...');
        });
      }
    } catch (e) {
      print('❌ Error loading Bible data: $e');
      _bibleData = {};
    }
  }

  static Future<String?> getVerse(
      String bookAbbr, int chapter, int verse) async {
    await _loadBibleData();

    final key = '$bookAbbr$chapter:$verse';
    print('🔎 Searching for key: "$key"');

    final result = _bibleData?[key];

    print(result);
    if (result != null) {
      print('✅ Found verse: $key = "${result.substring(0, 30)}..."');
    } else {
      print('❌ Verse not found for key: "$key"');
      print('📝 Available similar keys:');
      _bibleData?.keys
          .where((k) => k.startsWith(bookAbbr))
          .take(3)
          .forEach((k) {
        print('   $k');
      });
    }

    return result;
  }

  static Future<String> getVerseRange(
      String bookAbbr, int chapter, int startVerse, int? endVerse) async {
    await _loadBibleData();

    if (endVerse == null || endVerse == startVerse) {
      final verse = await getVerse(bookAbbr, chapter, startVerse);
      return verse ?? '성경 본문을 직접 입력해주세요.';
    }

    List<String> verses = [];
    for (int v = startVerse; v <= endVerse; v++) {
      final key = '$bookAbbr$chapter:$v';
      final verseText = _bibleData?[key];
      if (verseText != null) {
        verses.add(verseText);
      }
    }

    if (verses.isNotEmpty) {
      print('✅ Found verse range: $bookAbbr$chapter:$startVerse-$endVerse (${verses.length} verses)');
      return verses.join(' ');
    }

    print('❌ No verses found for range: $bookAbbr$chapter:$startVerse-$endVerse');
    return '성경 본문을 직접 입력해주세요.';
  }

  static Future<String> getCrossChapterRange(
      String bookAbbr, int startChapter, int startVerse, int endChapter, int endVerse) async {
    await _loadBibleData();

    List<String> verses = [];
    
    for (int ch = startChapter; ch <= endChapter; ch++) {
      int startV = (ch == startChapter) ? startVerse : 1;
      int endV = (ch == endChapter) ? endVerse : 999; // High number to get all verses in chapter
      
      for (int v = startV; v <= endV; v++) {
        final key = '$bookAbbr$ch:$v';
        final verseText = _bibleData?[key];
        if (verseText != null) {
          verses.add(verseText);
        } else if (v > startV) {
          // If we can't find a verse and we're past the start, assume we've reached the end of the chapter
          break;
        }
      }
    }

    if (verses.isNotEmpty) {
      print('✅ Found cross-chapter range: $bookAbbr$startChapter:$startVerse-$endChapter:$endVerse (${verses.length} verses)');
      return verses.join(' ');
    }

    print('❌ No verses found for cross-chapter range: $bookAbbr$startChapter:$startVerse-$endChapter:$endVerse');
    return '성경 본문을 직접 입력해주세요.';
  }

  // 성경책 이름을 약어로 변환
  static String getBookAbbreviation(String bookName) {
    print('📖 Converting book name: "$bookName"');
    final Map<String, String> bookMap = {
      '창세기': '창',
      '출애굽기': '출',
      '레위기': '레',
      '민수기': '민',
      '신명기': '신',
      '여호수아': '수',
      '사사기': '사사',
      '룻기': '룻',
      '사무엘상': '삼상',
      '사무엘하': '삼하',
      '열왕기상': '왕상',
      '열왕기하': '왕하',
      '역대상': '대상',
      '역대하': '대하',
      '에스라': '스',
      '느헤미야': '느',
      '에스더': '에',
      '욥기': '욥',
      '시편': '시',
      '잠언': '잠',
      '전도서': '전',
      '아가': '아',
      '이사야': '사',
      '예레미야': '렘',
      '예레미야애가': '애',
      '에스겔': '겔',
      '다니엘': '단',
      '호세아': '호',
      '요엘': '욜',
      '아모스': '암',
      '오바댜': '옵',
      '요나': '욘',
      '미가': '미',
      '나훔': '나',
      '하박국': '합',
      '스바냐': '습',
      '학개': '학',
      '스가랴': '슥',
      '말라기': '말',
      '마태복음': '마',
      '마가복음': '막',
      '누가복음': '눅',
      '요한복음': '요',
      '사도행전': '행',
      '로마서': '롬',
      '고린도전서': '고전',
      '고린도후서': '고후',
      '갈라디아서': '갈',
      '에베소서': '엡',
      '빌립보서': '빌',
      '골로새서': '골',
      '데살로니가전서': '살전',
      '데살로니가후서': '살후',
      '디모데전서': '딤전',
      '디모데후서': '딤후',
      '디도서': '딛',
      '빌레몬서': '몬',
      '히브리서': '히',
      '야고보서': '약',
      '베드로전서': '벧전',
      '베드로후서': '벧후',
      '요한일서': '요일',
      '요한이서': '요이',
      '요한삼서': '요삼',
      '유다서': '유',
      '요한계시록': '계',
    };

    final abbreviation = bookMap[bookName] ?? bookName;
    print('✏️ "$bookName" → "$abbreviation"');
    return abbreviation;
  }
}
