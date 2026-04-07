class LinkExtractor {
  static String? extractLink(String text) {
    if (text.isEmpty) return null;

    // 正常网址格式
    final normalUrlPattern = RegExp(r'https://www\.douyin\.com/video/\d+');
    final normalMatch = normalUrlPattern.firstMatch(text);
    if (normalMatch != null) {
      return normalMatch.group(0);
    }

    // 发现页网址格式
    final discoverPattern = RegExp(r'https://www\.douyin\.com/discover\?modal_id=(\d+)');
    final discoverMatch = discoverPattern.firstMatch(text);
    if (discoverMatch != null) {
      final modalId = discoverMatch.group(1);
      return 'https://www.douyin.com/video/$modalId';
    }

    // 短网址格式
    final shortUrlPattern = RegExp(r'https://v\.douyin\.com/[A-Za-z0-9]+');
    final shortMatch = shortUrlPattern.firstMatch(text);
    if (shortMatch != null) {
      return shortMatch.group(0);
    }

    return null;
  }
}
