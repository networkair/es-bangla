class YoutubeHelper {
  /// Extracts the 11-character YouTube video ID from various formats:
  /// - Full URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
  /// - Short URL: https://youtu.be/dQw4w9WgXcQ
  /// - Embed code: <iframe src="https://www.youtube.com/embed/dQw4w9WgXcQ" ...>
  /// - Direct embed URL: https://www.youtube.com/embed/dQw4w9WgXcQ
  /// - Raw ID: dQw4w9WgXcQ
  static String extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // If it's an iframe / embed code, extract the src URL first
    final iframeSrcMatch = RegExp(r'src=["\x27]([^"\x27]+)["\x27]').firstMatch(trimmed);
    final textToMatch = iframeSrcMatch != null ? iframeSrcMatch.group(1)! : trimmed;

    // Standard regex to find 11-char YouTube ID
    final regex = RegExp(
      r'(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(textToMatch);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }

    // If it's already an 11-char ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }

    return trimmed;
  }
}
