import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CreatedExam {
  const CreatedExam({
    required this.id,
    required this.title,
    required this.subject,
    required this.durationMinutes,
    required this.questionCount,
    required this.status,
    required this.questions,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subject;
  final int durationMinutes;
  final int questionCount;
  final String status;
  final List<CreatedQuestion> questions;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'durationMinutes': durationMinutes,
        'questionCount': questionCount,
        'status': status,
        'questions': questions.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CreatedExam.fromJson(Map<String, dynamic> json) => CreatedExam(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        questionCount: (json['questionCount'] as num).toInt(),
        status: json['status'] as String? ?? 'draft',
        questions: ((json['questions'] as List<dynamic>?) ?? const [])
            .map((item) => CreatedQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CreatedQuestion {
  const CreatedQuestion({required this.id, required this.body, required this.answers, required this.correctAnswer, required this.difficulty, required this.points});

  final String id;
  final String body;
  final List<String> answers;
  final int correctAnswer;
  final String difficulty;
  final String points;

  Map<String, dynamic> toJson() => {'id': id, 'body': body, 'answers': answers, 'correctAnswer': correctAnswer, 'difficulty': difficulty, 'points': points};

  factory CreatedQuestion.fromJson(Map<String, dynamic> json) => CreatedQuestion(
        id: json['id'] as String,
        body: json['body'] as String,
        answers: List<String>.from(json['answers'] as List<dynamic>),
        correctAnswer: (json['correctAnswer'] as num).toInt(),
        difficulty: json['difficulty'] as String? ?? 'medium',
        points: json['points'] as String? ?? '1',
      );
}

class CreatedExamStore {
  static const _storageKey = 'teacher_created_exams';

  Future<List<CreatedExam>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return [];
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((value) => CreatedExam.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(CreatedExam exam) async {
    final exams = await load();
    exams.removeWhere((item) => item.id == exam.id);
    exams.add(exam);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(exams.map((item) => item.toJson()).toList()));
  }

  Future<CreatedExam?> find(String id) async {
    final exams = await load();
    for (final exam in exams) {
      if (exam.id == id) return exam;
    }
    return null;
  }

  Future<void> publish(String id) async {
    final exams = await load();
    final index = exams.indexWhere((exam) => exam.id == id);
    if (index < 0) return;
    final exam = exams[index];
    exams[index] = CreatedExam(id: exam.id, title: exam.title, subject: exam.subject, durationMinutes: exam.durationMinutes, questionCount: exam.questionCount, status: 'published', questions: exam.questions, createdAt: exam.createdAt);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(exams.map((item) => item.toJson()).toList()));
  }
}
