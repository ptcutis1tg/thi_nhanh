class ExamOption {
  const ExamOption({required this.id, required this.position, required this.body});

  final String id;
  final int position;
  final String body;

  factory ExamOption.fromJson(Map<String, dynamic> json) => ExamOption(
        id: json['id'] as String,
        position: (json['position'] as num).toInt(),
        body: json['body'] as String,
      );
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.position,
    required this.body,
    required this.points,
    required this.options,
  });

  final String id;
  final int position;
  final String body;
  final num points;
  final List<ExamOption> options;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] as String,
        position: (json['position'] as num).toInt(),
        body: json['body'] as String,
        points: json['points'] as num,
        options: (json['options'] as List<dynamic>)
            .map((item) => ExamOption.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class AttemptPayload {
  const AttemptPayload({
    required this.attemptId,
    required this.title,
    required this.durationMinutes,
    required this.expiresAt,
    required this.status,
    required this.questions,
    required this.answers,
  });

  final String attemptId;
  final String title;
  final int durationMinutes;
  final DateTime expiresAt;
  final String status;
  final List<ExamQuestion> questions;
  final Map<String, String> answers;

  bool get isOpen => status == 'in_progress';

  factory AttemptPayload.fromJson(Map<String, dynamic> json) {
    final rawAnswers = (json['answers'] as Map<dynamic, dynamic>? ?? const {});
    return AttemptPayload(
      attemptId: json['attemptId'] as String,
      title: json['title'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
      status: json['status'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((item) => ExamQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
      answers: rawAnswers.map((key, value) => MapEntry(key as String, value as String)),
    );
  }
}

class StartedAttempt {
  const StartedAttempt({required this.attemptId, required this.expiresAt, this.guestToken});

  final String attemptId;
  final DateTime expiresAt;
  final String? guestToken;

  factory StartedAttempt.fromJson(Map<String, dynamic> json) => StartedAttempt(
        attemptId: json['attemptId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
        guestToken: json['guestToken'] as String?,
      );
}
