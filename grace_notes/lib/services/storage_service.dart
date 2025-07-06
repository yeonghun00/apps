import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sermon_note.dart';
import '../models/devotion_note.dart';
import '../models/community_post.dart';

class StorageService {
  static const String _sermonNotesKey = 'sermon_notes';
  static const String _devotionNotesKey = 'devotion_notes';
  static const String _communityPostsKey = 'community_posts';
  static const String _userSettingsKey = 'user_settings';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<List<SermonNote>> getSermonNotes() async {
    final String? notesJson = _prefs?.getString(_sermonNotesKey);
    if (notesJson == null) return [];
    
    final List<dynamic> notesList = json.decode(notesJson);
    return notesList.map((json) => SermonNote.fromJson(json)).toList();
  }

  static Future<void> saveSermonNote(SermonNote note) async {
    final notes = await getSermonNotes();
    final existingIndex = notes.indexWhere((n) => n.id == note.id);
    
    if (existingIndex != -1) {
      notes[existingIndex] = note;
    } else {
      notes.add(note);
    }
    
    final String notesJson = json.encode(notes.map((n) => n.toJson()).toList());
    await _prefs?.setString(_sermonNotesKey, notesJson);
  }

  static Future<void> deleteSermonNote(String id) async {
    final notes = await getSermonNotes();
    notes.removeWhere((note) => note.id == id);
    
    final String notesJson = json.encode(notes.map((n) => n.toJson()).toList());
    await _prefs?.setString(_sermonNotesKey, notesJson);
  }

  static Future<List<DevotionNote>> getDevotionNotes() async {
    final String? notesJson = _prefs?.getString(_devotionNotesKey);
    if (notesJson == null) return [];
    
    final List<dynamic> notesList = json.decode(notesJson);
    return notesList.map((json) => DevotionNote.fromJson(json)).toList();
  }

  static Future<void> saveDevotionNote(DevotionNote note) async {
    final notes = await getDevotionNotes();
    final existingIndex = notes.indexWhere((n) => n.id == note.id);
    
    if (existingIndex != -1) {
      notes[existingIndex] = note;
    } else {
      notes.add(note);
    }
    
    final String notesJson = json.encode(notes.map((n) => n.toJson()).toList());
    await _prefs?.setString(_devotionNotesKey, notesJson);
  }

  static Future<void> deleteDevotionNote(String id) async {
    final notes = await getDevotionNotes();
    notes.removeWhere((note) => note.id == id);
    
    final String notesJson = json.encode(notes.map((n) => n.toJson()).toList());
    await _prefs?.setString(_devotionNotesKey, notesJson);
  }

  static Future<List<CommunityPost>> getCommunityPosts() async {
    final String? postsJson = _prefs?.getString(_communityPostsKey);
    if (postsJson == null) return [];
    
    final List<dynamic> postsList = json.decode(postsJson);
    return postsList.map((json) => CommunityPost.fromJson(json)).toList();
  }

  static Future<void> saveCommunityPost(CommunityPost post) async {
    final posts = await getCommunityPosts();
    final existingIndex = posts.indexWhere((p) => p.id == post.id);
    
    if (existingIndex != -1) {
      posts[existingIndex] = post;
    } else {
      posts.add(post);
    }
    
    final String postsJson = json.encode(posts.map((p) => p.toJson()).toList());
    await _prefs?.setString(_communityPostsKey, postsJson);
  }

  static Future<void> deleteCommunityPost(String id) async {
    final posts = await getCommunityPosts();
    posts.removeWhere((post) => post.id == id);
    
    final String postsJson = json.encode(posts.map((p) => p.toJson()).toList());
    await _prefs?.setString(_communityPostsKey, postsJson);
  }

  static Future<Map<String, dynamic>> getUserSettings() async {
    final String? settingsJson = _prefs?.getString(_userSettingsKey);
    if (settingsJson == null) return {};
    
    return json.decode(settingsJson);
  }

  static Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final String settingsJson = json.encode(settings);
    await _prefs?.setString(_userSettingsKey, settingsJson);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    return await getUserSettings();
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    return await saveUserSettings(settings);
  }
}