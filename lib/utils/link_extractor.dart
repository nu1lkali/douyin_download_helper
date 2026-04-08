class LinkExtractor {
  // 短网址：https://v.douyin.com/任意非空白字符（含下划线、连字符、斜杠）
  static final _shortUrl = RegExp(
    r'https://v\.douyin\.com/[\w\-/]+',
    caseSensitive: false,
  );

  // 正常视频页：https://www.douyin.com/video/数字ID
  static final _normalVideo = RegExp(
    r'https://(?:www\.)?douyin\.com/video/(\d+)',
    caseSensitive: false,
  );

  // 发现页：https://www.douyin.com/discover?modal_id=数字ID
  static final _discoverPage = RegExp(
    r'https://(?:www\.)?douyin\.com/discover[^"\s]*[?&]modal_id=(\d+)',
    caseSensitive: false,
  );

  // 用户主页视频：https://www.douyin.com/user/xxx?modal_id=数字ID
  static final _userPageVideo = RegExp(
    r'https://(?:www\.)?douyin\.com/user/[^"\s]*[?&]modal_id=(\d+)',
    caseSensitive: false,
  );

  // 分享口令里内嵌的短链（口令格式：xxx https://v.douyin.com/xxx/ xxx）
  static final _embedShortUrl = RegExp(
    r'https://v\.douyin\.com/[\w\-/]+',
    caseSensitive: false,
  );

  static String? extractLink(String text) {
    if (text.trim().isEmpty) return null;

    // 1. 优先匹配短网址（含分享口令里的短链）
    final shortMatch = _shortUrl.firstMatch(text);
    if (shortMatch != null) {
      // 去掉末尾多余的斜杠以外的非法字符，保留路径斜杠
      return shortMatch.group(0)!.replaceAll(RegExp(r'[^\w\-/:.]'), '');
    }

    // 2. 正常视频页
    final normalMatch = _normalVideo.firstMatch(text);
    if (normalMatch != null) {
      return normalMatch.group(0);
    }

    // 3. 发现页 modal_id
    final discoverMatch = _discoverPage.firstMatch(text);
    if (discoverMatch != null) {
      return 'https://www.douyin.com/video/${discoverMatch.group(1)}';
    }

    // 4. 用户主页 modal_id
    final userMatch = _userPageVideo.firstMatch(text);
    if (userMatch != null) {
      return 'https://www.douyin.com/video/${userMatch.group(1)}';
    }

    return null;
  }
}
