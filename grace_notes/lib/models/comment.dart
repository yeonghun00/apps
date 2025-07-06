import 'package:uuid/uuid.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final int amenCount;
  final List<String> amenUserIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    String? id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.amenCount = 0,
    List<String>? amenUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        amenUserIds = amenUserIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'amenCount': amenCount,
      'amenUserIds': amenUserIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      content: json['content'],
      amenCount: json['amenCount'] ?? 0,
      amenUserIds: List<String>.from(json['amenUserIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    int? amenCount,
    List<String>? amenUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      amenCount: amenCount ?? this.amenCount,
      amenUserIds: amenUserIds ?? this.amenUserIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}