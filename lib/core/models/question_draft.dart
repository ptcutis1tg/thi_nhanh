import 'package:flutter/material.dart';

enum QuestionType {
  singleChoice('single_choice', '1 đáp án đúng', Icons.radio_button_checked),
  multipleChoice('multiple_choice', 'Nhiều đáp án đúng', Icons.check_box_outlined),
  trueFalse('true_false', 'Đúng / Sai', Icons.flaky_outlined),
  shortAnswer('short_answer', 'Điền đáp án ngắn', Icons.edit_note_outlined);

  final String value;
  final String label;
  final IconData icon;
  const QuestionType(this.value, this.label, this.icon);

  static QuestionType fromString(String? val) {
    return QuestionType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => QuestionType.singleChoice,
    );
  }
}

class QuestionDraft {
  QuestionDraft({
    required this.id,
    this.type = QuestionType.singleChoice,
    this.body = '',
    List<String>? answers,
    List<int>? correctAnswers,
    this.points = '1',
    this.timeLimitSeconds,
    this.explanation = '',
    this.imageUrl,
  })  : answers = answers ?? List.filled(4, ''),
        correctAnswers = correctAnswers ?? [0];

  final String id;
  QuestionType type;
  String body;
  List<String> answers;
  List<int> correctAnswers;
  String points;
  int? timeLimitSeconds;
  String explanation;
  String? imageUrl;

  QuestionDraft copyWith({
    String? id,
    QuestionType? type,
    String? body,
    List<String>? answers,
    List<int>? correctAnswers,
    String? points,
    int? timeLimitSeconds,
    String? explanation,
    String? imageUrl,
  }) {
    return QuestionDraft(
      id: id ?? this.id,
      type: type ?? this.type,
      body: body ?? this.body,
      answers: answers != null ? List.from(answers) : List.from(this.answers),
      correctAnswers: correctAnswers != null ? List.from(correctAnswers) : List.from(this.correctAnswers),
      points: points ?? this.points,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      explanation: explanation ?? this.explanation,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory QuestionDraft.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? json['question_type'] as String? ?? 'single_choice';
    final type = QuestionType.fromString(typeStr);

    List<String> answers = [];
    if (json['answers'] is List) {
      answers = (json['answers'] as List).map((e) => e.toString()).toList();
    } else {
      answers = List.filled(4, '');
    }

    List<int> correctAnswers = [];
    if (json['correctAnswers'] is List) {
      correctAnswers = (json['correctAnswers'] as List).map((e) => (e as num).toInt()).toList();
    } else if (json['correctAnswer'] != null) {
      correctAnswers = [(json['correctAnswer'] as num).toInt()];
    } else {
      correctAnswers = [0];
    }

    return QuestionDraft(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      body: json['body'] as String? ?? '',
      answers: answers,
      correctAnswers: correctAnswers,
      points: '${json['points'] ?? 1}',
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      explanation: json['explanation'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    'body': body,
    'answers': answers,
    'correctAnswers': correctAnswers,
    'correctAnswer': correctAnswers.isNotEmpty ? correctAnswers.first : 0,
    'points': points,
    'timeLimitSeconds': timeLimitSeconds,
    'explanation': explanation,
    'imageUrl': imageUrl,
  };
}
