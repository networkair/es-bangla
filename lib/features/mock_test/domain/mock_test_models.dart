class SubjectModel {
  final String subjectId;
  final String name;
  final String nameEn;
  final int order;
  final String iconUrl;
  final int topicCount;
  final bool hasPremium;

  SubjectModel({
    required this.subjectId,
    required this.name,
    required this.nameEn,
    required this.order,
    required this.iconUrl,
    required this.topicCount,
    required this.hasPremium,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      subjectId: json['subject_id'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? '',
      order: json['order'] is int ? json['order'] : 1,
      iconUrl: json['icon_url'] ?? '',
      topicCount: json['topic_count'] is int ? json['topic_count'] : 0,
      hasPremium: json['has_premium'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'subject_id': subjectId,
    'name': name,
    'name_en': nameEn,
    'order': order,
    'icon_url': iconUrl,
    'topic_count': topicCount,
    'has_premium': hasPremium,
  };
}

class TestSetModel {
  final String setFile;
  final String title;
  final int setNumber;
  final int questionCount;
  final double totalMarks;
  final bool isPremium;
  final bool hasTimer;
  final int durationMinutes;
  final String version;

  TestSetModel({
    required this.setFile,
    required this.title,
    required this.setNumber,
    required this.questionCount,
    required this.totalMarks,
    required this.isPremium,
    required this.hasTimer,
    required this.durationMinutes,
    required this.version,
  });

  factory TestSetModel.fromJson(Map<String, dynamic> json) {
    return TestSetModel(
      setFile: json['set_file'] ?? '',
      title: json['title'] ?? '',
      setNumber: json['set_number'] is int ? json['set_number'] : 1,
      questionCount: json['question_count'] is int ? json['question_count'] : 10,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 10.0,
      isPremium: json['is_premium'] == true,
      hasTimer: json['has_timer'] == true,
      durationMinutes: json['duration_minutes'] is int ? json['duration_minutes'] : 0,
      version: json['version'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'set_file': setFile,
    'title': title,
    'set_number': setNumber,
    'question_count': questionCount,
    'total_marks': totalMarks,
    'is_premium': isPremium,
    'has_timer': hasTimer,
    'duration_minutes': durationMinutes,
    'version': version,
  };
}

class TopicModel {
  final String topicId;
  final String name;
  final int order;
  final List<TestSetModel> sets;

  TopicModel({
    required this.topicId,
    required this.name,
    required this.order,
    required this.sets,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    final setsList = (json['sets'] as List?)
            ?.map((s) => TestSetModel.fromJson(Map<String, dynamic>.from(s)))
            .toList() ??
        [];
    return TopicModel(
      topicId: json['topic_id'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] is int ? json['order'] : 1,
      sets: setsList,
    );
  }
}

class QuestionModel {
  final String qId;
  final String questionText;
  final String imageUrl;
  final Map<String, String> options;
  final String correctOption;
  final String explanation;

  QuestionModel({
    required this.qId,
    required this.questionText,
    required this.imageUrl,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as Map<String, dynamic>? ?? {};
    final mappedOptions = rawOptions.map((k, v) => MapEntry(k, v.toString()));

    return QuestionModel(
      qId: json['q_id'] ?? '',
      questionText: json['question_text'] ?? '',
      imageUrl: json['image_url'] ?? '',
      options: mappedOptions,
      correctOption: json['correct_option'] ?? 'A',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'q_id': qId,
    'question_text': questionText,
    'image_url': imageUrl,
    'options': options,
    'correct_option': correctOption,
    'explanation': explanation,
  };
}

class TestMetadataModel {
  final String testId;
  final String className;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicName;
  final String setFile;
  final int setNumber;
  final String title;
  final String provider;
  final int questionCount;
  final double totalMarks;
  final double positiveMark;
  final double negativeMark;
  final bool hasTimer;
  final int durationMinutes;
  final String version;
  final bool isPremium;

  TestMetadataModel({
    required this.testId,
    required this.className,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.setFile,
    required this.setNumber,
    required this.title,
    required this.provider,
    required this.questionCount,
    required this.totalMarks,
    required this.positiveMark,
    required this.negativeMark,
    required this.hasTimer,
    required this.durationMinutes,
    required this.version,
    required this.isPremium,
  });

  factory TestMetadataModel.fromJson(Map<String, dynamic> json) {
    return TestMetadataModel(
      testId: json['test_id'] ?? '',
      className: json['class'] ?? '12',
      semester: json['semester'] is int ? json['semester'] : 3,
      subjectId: json['subject_id'] ?? '',
      subjectName: json['subject_name'] ?? json['subject'] ?? '',
      topicId: json['topic_id'] ?? '',
      topicName: json['topic_name'] ?? '',
      setFile: json['set_file'] ?? '',
      setNumber: json['set_number'] is int ? json['set_number'] : 1,
      title: json['title'] ?? '',
      provider: json['provider'] ?? 'RK son',
      questionCount: json['question_count'] is int ? json['question_count'] : 10,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 10.0,
      positiveMark: (json['positive_mark'] as num?)?.toDouble() ?? 1.0,
      negativeMark: (json['negative_mark'] as num?)?.toDouble() ?? 0.25,
      hasTimer: json['has_timer'] == true,
      durationMinutes: json['duration_minutes'] is int ? json['duration_minutes'] : 0,
      version: json['version'] ?? '',
      isPremium: json['is_premium'] == true,
    );
  }
}

class TestPaperModel {
  final TestMetadataModel metadata;
  final List<QuestionModel> questions;

  TestPaperModel({
    required this.metadata,
    required this.questions,
  });

  factory TestPaperModel.fromJson(Map<String, dynamic> json) {
    final meta = TestMetadataModel.fromJson(json['test_metadata'] ?? {});
    final qList = (json['questions'] as List?)
            ?.map((q) => QuestionModel.fromJson(Map<String, dynamic>.from(q)))
            .toList() ??
        [];
    return TestPaperModel(metadata: meta, questions: qList);
  }
}
