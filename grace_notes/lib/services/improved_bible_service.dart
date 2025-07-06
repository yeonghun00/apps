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
    await _loadBibleData();
    
    if (_allPopularVerses == null || _allPopularVerses!.isEmpty) {
      return "여호와는 나의 목자시니 내게 부족함이 없으리로다 - 시편 23:1";
    }
    
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final randomIndex = Random(dayOfYear).nextInt(_allPopularVerses!.length);
    
    final verse = _allPopularVerses![randomIndex];
    return "${verse['text']} - ${verse['full_ref']}";
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