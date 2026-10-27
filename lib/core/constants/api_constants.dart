class ApiConstants {
  static const String baseUrl = 'https://rkson-mock-api.pages.dev';

  // API Endpoints
  static const String manifestEndpoint = '$baseUrl/class_12/manifest.json';
  static const String reportEndpoint = '$baseUrl/api/v1/report';
  static const String legacyReportEndpoint = '$baseUrl/api/report';
  static const String healthEndpoint = '$baseUrl/api/v1/health';

  static String subjectsUrl(int semester, {String? version}) {
    final vParam = (version != null && version.isNotEmpty) ? '?v=$version' : '';
    return '$baseUrl/class_12/semester_$semester/subjects.json$vParam';
  }

  static String topicsUrl(int semester, String subjectId, {String? version}) {
    final vParam = (version != null && version.isNotEmpty) ? '?v=$version' : '';
    return '$baseUrl/class_12/semester_$semester/$subjectId/topics.json$vParam';
  }

  static String testSetUrl(int semester, String subjectId, String setFile, {String? version}) {
    final vParam = (version != null && version.isNotEmpty) ? '?v=$version' : '';
    return '$baseUrl/class_12/semester_$semester/$subjectId/tests/$setFile.json$vParam';
  }

  // Social & Support links
  static const String defaultWhatsappNumber = '+919876543210';
  static const String youtubeChannelUrl = 'https://youtube.com/@EsBangla';
  static const String facebookPageUrl = 'https://facebook.com/EsBangla';
  static const String instagramUrl = 'https://instagram.com/EsBangla';
  static const String telegramChannelUrl = 'https://t.me/EsBangla';
}
