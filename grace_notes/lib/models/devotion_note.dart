import 'package:uuid/uuid.dart';

class DevotionNote {
  final String id;
  final DateTime date;
  final String title;
  final String scriptureReference;
  final String scriptureText;
  final String observation;
  final String interpretation;
  final String application;
  final String prayer;
  final DateTime createdAt;
  final DateTime updatedAt;

  DevotionNote({
    String? id,
    required this.date,
    this.title = '',
    required this.scriptureReference,
    required this.scriptureText,
    required this.observation,
    required this.interpretation,
    required this.application,
    required this.prayer,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'scriptureReference': scriptureReference,
      'scriptureText': scriptureText,
      'observation': observation,
      'interpretation': interpretation,
      'application': application,
      'prayer': prayer,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DevotionNote.fromJson(Map<String, dynamic> json) {
    return DevotionNote(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      scriptureReference: json['scriptureReference'],
      scriptureText: json['scriptureText'],
      observation: json['observation'],
      interpretation: json['interpretation'],
      application: json['application'],
      prayer: json['prayer'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  DevotionNote copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? scriptureReference,
    String? scriptureText,
    String? observation,
    String? interpretation,
    String? application,
    String? prayer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DevotionNote(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      scriptureText: scriptureText ?? this.scriptureText,
      observation: observation ?? this.observation,
      interpretation: interpretation ?? this.interpretation,
      application: application ?? this.application,
      prayer: prayer ?? this.prayer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}