class TextUtils {
  static String sanitize(String input) {
    return input
        .replaceAll(
            RegExp(r'[\u0000-\u0008\u000B-\u000C\u000E-\u001F\u007F]'), '')
        .trim();
  }

  static int countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  static int estimateReadingTimeMinutes(String text, {int wpm = 180}) {
    final words = countWords(text);
    return (words / wpm).ceil().clamp(1, 9999);
  }

  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
}
