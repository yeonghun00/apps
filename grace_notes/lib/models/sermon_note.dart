import 'package:uuid/uuid.dart';

class SermonNote {
  final String id;
  final DateTime date;
  final String church;
  final String preacher;
  final String title;
  final String scriptureText;
  final String scriptureReference;
  final String mainPoints;
  final String personalReflection;
  final String prayerRequests;
  final String applicationPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  SermonNote({
    String? id,
    required this.date,
    required this.church,
    required this.preacher,
    required this.title,
    required this.scriptureText,
    required this.scriptureReference,
    required this.mainPoints,
    required this.personalReflection,
    required this.prayerRequests,
    required this.applicationPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'church': church,
      'preacher': preacher,
      'title': title,
      'scriptureText': scriptureText,
      'scriptureReference': scriptureReference,
      'mainPoints': mainPoints,
      'personalReflection': personalReflection,
      'prayerRequests': prayerRequests,
      'applicationPoints': applicationPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    return SermonNote(
      id: json['id'],
      date: DateTime.parse(json['date']),
      church: json['church'],
      preacher: json['preacher'],
      title: json['title'],
      scriptureText: json['scriptureText'],
      scriptureReference: json['scriptureReference'],
      mainPoints: json['mainPoints'],
      personalReflection: json['personalReflection'],
      prayerRequests: json['prayerRequests'],
      applicationPoints: json['applicationPoints'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  SermonNote copyWith({
    String? id,
    DateTime? date,
    String? church,
    String? preacher,
    String? title,
    String? scriptureText,
    String? scriptureReference,
    String? mainPoints,
    String? personalReflection,
    String? prayerRequests,
    String? applicationPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SermonNote(
      id: id ?? this.id,
      date: date ?? this.date,
      church: church ?? this.church,
      preacher: preacher ?? this.preacher,
      title: title ?? this.title,
      scriptureText: scriptureText ?? this.scriptureText,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      mainPoints: mainPoints ?? this.mainPoints,
      personalReflection: personalReflection ?? this.personalReflection,
      prayerRequests: prayerRequests ?? this.prayerRequests,
      applicationPoints: applicationPoints ?? this.applicationPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}