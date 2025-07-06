import 'package:uuid/uuid.dart';

enum PostCategory {
  devotionSharing,
  sermonSharing,
  prayerRequest,
  testimony,
  question,
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final PostCategory category;
  final String? scriptureReference;
  final int amenCount;
  final List<String> amenUserIds;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    String? id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.category,
    this.scriptureReference,
    this.amenCount = 0,
    List<String>? amenUserIds,
    this.commentCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        amenUserIds = amenUserIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'category': category.name,
      'scriptureReference': scriptureReference,
      'amenCount': amenCount,
      'amenUserIds': amenUserIds,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      title: json['title'],
      content: json['content'],
      category: PostCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PostCategory.devotionSharing,
      ),
      scriptureReference: json['scriptureReference'],
      amenCount: json['amenCount'] ?? 0,
      amenUserIds: List<String>.from(json['amenUserIds'] ?? []),
      commentCount: json['commentCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    PostCategory? category,
    String? scriptureReference,
    int? amenCount,
    List<String>? amenUserIds,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      amenCount: amenCount ?? this.amenCount,
      amenUserIds: amenUserIds ?? this.amenUserIds,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case PostCategory.devotionSharing:
        return '큐티나눔';
      case PostCategory.sermonSharing:
        return '설교나눔';
      case PostCategory.prayerRequest:
        return '기도요청';
      case PostCategory.testimony:
        return '간증';
      case PostCategory.question:
        return '질문';
    }
  }
}