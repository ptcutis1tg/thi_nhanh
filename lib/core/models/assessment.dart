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

class ReviewOption {
  const ReviewOption({
    required this.id,
    required this.position,
    required this.body,
    required this.isCorrect,
  });

  final String id;
  final int position;
  final String body;
  final bool isCorrect;

  factory ReviewOption.fromJson(Map<String, dynamic> json) => ReviewOption(
        id: json['id'] as String,
        position: (json['position'] as num).toInt(),
        body: json['body'] as String,
        isCorrect: (json['isCorrect'] as bool?) ?? false,
      );
}

class ReviewQuestion {
  const ReviewQuestion({
    required this.id,
    required this.position,
    required this.body,
    required this.points,
    required this.explanation,
    this.selectedOptionId,
    this.correctOptionId,
    required this.options,
  });

  final String id;
  final int position;
  final String body;
  final num points;
  final String explanation;
  final String? selectedOptionId;
  final String? correctOptionId;
  final List<ReviewOption> options;

  bool get isCorrect => selectedOptionId != null && selectedOptionId == correctOptionId;
  bool get isSkipped => selectedOptionId == null;
  bool get isWrong => !isSkipped && !isCorrect;

  factory ReviewQuestion.fromJson(Map<String, dynamic> json) => ReviewQuestion(
        id: json['id'] as String,
        position: (json['position'] as num).toInt(),
        body: json['body'] as String,
        points: (json['points'] as num?) ?? 1,
        explanation: (json['explanation'] as String?) ?? '',
        selectedOptionId: json['selectedOptionId'] as String?,
        correctOptionId: json['correctOptionId'] as String?,
        options: ((json['options'] as List<dynamic>?) ?? const [])
            .map((item) => ReviewOption.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}

class AttemptReviewPayload {
  const AttemptReviewPayload({
    required this.attemptId,
    this.roomId,
    required this.examId,
    required this.title,
    required this.subject,
    required this.status,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.totalQuestions,
    this.durationSeconds,
    this.submittedAt,
    required this.questions,
  });

  final String attemptId;
  final String? roomId;
  final String examId;
  final String title;
  final String subject;
  final String status;
  final double score;
  final double maxScore;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int totalQuestions;
  final int? durationSeconds;
  final String? submittedAt;
  final List<ReviewQuestion> questions;

  String get durationFormatted {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory AttemptReviewPayload.fromJson(Map<String, dynamic> json) => AttemptReviewPayload(
        attemptId: json['attemptId'] as String,
        roomId: json['roomId'] as String?,
        examId: (json['examId'] as String?) ?? '',
        title: (json['title'] as String?) ?? 'Bài kiểm tra',
        subject: (json['subject'] as String?) ?? 'Chung',
        status: (json['status'] as String?) ?? 'submitted',
        score: ((json['score'] as num?) ?? 0).toDouble(),
        maxScore: ((json['maxScore'] as num?) ?? 10.0).toDouble(),
        correctCount: ((json['correctCount'] as num?) ?? 0).toInt(),
        wrongCount: ((json['wrongCount'] as num?) ?? 0).toInt(),
        skippedCount: ((json['skippedCount'] as num?) ?? 0).toInt(),
        totalQuestions: ((json['totalQuestions'] as num?) ?? 0).toInt(),
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        submittedAt: json['submittedAt'] as String?,
        questions: ((json['questions'] as List<dynamic>?) ?? const [])
            .map((item) => ReviewQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
      );
}
