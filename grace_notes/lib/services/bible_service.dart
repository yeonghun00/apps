import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class BibleService {
  static Map<String, dynamic>? _bibleData;
  static List<Map<String, dynamic>>? _allBooks;
  static List<Map<String, dynamic>>? _allVerses;
  
  static Future<void> _loadBibleData() async {
    if (_bibleData != null) return;
    
    try {
      final String response = await rootBundle.loadString('assets/bible/bible.json');
      _bibleData = json.decode(response);
      
      _allBooks = [];
      _allVerses = [];
      
      for (var book in _bibleData!['books']) {
        _allBooks!.add({
          'name': book['name'],
          'abbr': book['abbr'],
          'chapters': book['chapters'].length,
        });
        
        for (int chapterIndex = 0; chapterIndex < book['chapters'].length; chapterIndex++) {
          final chapter = book['chapters'][chapterIndex];
          for (int verseIndex = 0; verseIndex < chapter['verses'].length; verseIndex++) {
            _allVerses!.add({
              'book': book['name'],
              'abbr': book['abbr'],
              'chapter': chapterIndex + 1,
              'verse': verseIndex + 1,
              'text': chapter['verses'][verseIndex],
            });
          }
        }
      }
    } catch (e) {
      print('Error loading Bible data: $e');
      _bibleData = {};
      _allBooks = [];
      _allVerses = [];
    }
  }
  
  static Future<String> getDailyVerse() async {
    await _loadBibleData();
    
    if (_allVerses == null || _allVerses!.isEmpty) {
      return "여호와는 나의 목자시니 내게 부족함이 없으리로다 - 시편 23:1";
    }
    
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final randomIndex = Random(dayOfYear).nextInt(_allVerses!.length);
    
    final verse = _allVerses![randomIndex];
    return "${verse['text']} - ${verse['book']} ${verse['chapter']}:${verse['verse']}";
  }
  
  static Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    await _loadBibleData();
    
    if (_allBooks == null || query.isEmpty) return [];
    
    return _allBooks!
        .where((book) =>
            book['name'].toLowerCase().contains(query.toLowerCase()) ||
            book['abbr'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
  
  static Future<List<int>> getChaptersForBook(String bookName) async {
    await _loadBibleData();
    
    if (_bibleData == null) return [];
    
    for (var book in _bibleData!['books']) {
      if (book['name'] == bookName) {
        return List.generate(book['chapters'].length, (index) => index + 1);
      }
    }
    return [];
  }
  
  static Future<List<int>> getVersesForChapter(String bookName, int chapter) async {
    await _loadBibleData();
    
    if (_bibleData == null) return [];
    
    for (var book in _bibleData!['books']) {
      if (book['name'] == bookName && chapter <= book['chapters'].length) {
        return List.generate(book['chapters'][chapter - 1]['verses'].length, (index) => index + 1);
      }
    }
    return [];
  }
  
  static Future<String> getVerseText(String bookName, int chapter, int verse) async {
    await _loadBibleData();
    
    if (_bibleData == null) return '';
    
    for (var book in _bibleData!['books']) {
      if (book['name'] == bookName && 
          chapter <= book['chapters'].length && 
          verse <= book['chapters'][chapter - 1]['verses'].length) {
        return book['chapters'][chapter - 1]['verses'][verse - 1];
      }
    }
    return '';
  }
  
  static Future<String> getVerseRange(String bookName, int chapter, int startVerse, int endVerse) async {
    await _loadBibleData();
    
    if (_bibleData == null) return '';
    
    for (var book in _bibleData!['books']) {
      if (book['name'] == bookName && chapter <= book['chapters'].length) {
        final chapterData = book['chapters'][chapter - 1];
        if (startVerse <= chapterData['verses'].length && endVerse <= chapterData['verses'].length) {
          final verses = <String>[];
          for (int i = startVerse - 1; i < endVerse; i++) {
            verses.add(chapterData['verses'][i]);
          }
          return verses.join(' ');
        }
      }
    }
    return '';
  }
  
  static Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    await _loadBibleData();
    
    if (_allVerses == null || query.isEmpty) return [];
    
    return _allVerses!
        .where((verse) => verse['text'].toLowerCase().contains(query.toLowerCase()))
        .take(20)
        .toList();
  }
}