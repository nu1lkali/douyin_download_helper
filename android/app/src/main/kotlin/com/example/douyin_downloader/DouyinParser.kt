package com.example.douyin_downloader

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object DouyinParser {
    // 必须用 iPhone UA，iesdouyin 才会返回 _ROUTER_DATA
    const val UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) " +
            "EdgiOS/121.0.2277.107 Version/17.0 Mobile/15E148 Safari/604.1"

    data class ParseResult(
        val title: String,
        val author: String,
        val videoUrl: String,
        val images: List<String>,
        val shortId: String = "",
        val isLive: Boolean = false,
        val albumName: String = "便捷下载",
    ) {
        // 视频或实况都走视频下载逻辑
        val isVideo get() = images.isEmpty() || isLive
    }

    fun parse(text: String): ParseResult {
        val awemeId = extractAwemeId(text)
        return fetchInfo(awemeId)
    }

    private fun extractAwemeId(text: String): String {
        // 先提取短链
        val shortUrlRegex = Regex("""https://v\.douyin\.com/[\w\-/]+""")
        val shortUrl = shortUrlRegex.find(text)?.value

        val realUrl = if (shortUrl != null) followRedirect(shortUrl) else text

        // 从真实URL提取ID
        listOf(
            Regex("""/video/(\d+)"""),
            Regex("""/note/(\d+)"""),
            Regex("""modal_id=(\d+)"""),
            Regex("""[?&]vid=(\d+)"""),
        ).forEach { r ->
            r.find(realUrl)?.groupValues?.get(1)?.let { return it }
        }

        // 直接是数字ID
        if (Regex("""^\d{16,}$""").matches(text.trim())) return text.trim()

        throw Exception("无法提取视频ID")
    }

    private fun followRedirect(url: String): String {
        var current = url
        repeat(10) {
            val conn = URL(current).openConnection() as HttpURLConnection
            conn.instanceFollowRedirects = false
            conn.setRequestProperty("User-Agent", UA)
            conn.connect()
            val code = conn.responseCode
            if (code in 300..399) {
                val loc = conn.getHeaderField("Location") ?: return current
                current = if (loc.startsWith("http")) loc
                else URL(URL(current), loc).toString()
                conn.disconnect()
            } else {
                conn.disconnect()
                return current
            }
        }
        return current
    }

    private fun fetchInfo(awemeId: String): ParseResult {
        val url = "https://www.iesdouyin.com/share/video/$awemeId/"
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.setRequestProperty("User-Agent", UA)
        conn.setRequestProperty("Accept", "text/html,application/xhtml+xml,*/*;q=0.8")
        conn.setRequestProperty("Accept-Language", "zh-CN,zh;q=0.9")
        conn.connectTimeout = 15000
        conn.readTimeout = 15000
        conn.connect()

        val html = conn.inputStream.bufferedReader().readText()
        conn.disconnect()

        // 提取 window._ROUTER_DATA = {...}</script>
        val match = Regex("""window\._ROUTER_DATA\s*=\s*(.*?)</script>""", RegexOption.DOT_MATCHES_ALL)
            .find(html) ?: throw Exception("无法从页面提取数据")

        val jsonStr = match.groupValues[1].trim()
        val root = JSONObject(jsonStr)
        val loaderData = root.getJSONObject("loaderData")

        val pageData = when {
            loaderData.has("video_(id)/page") -> loaderData.getJSONObject("video_(id)/page")
            loaderData.has("note_(id)/page") -> loaderData.getJSONObject("note_(id)/page")
            else -> throw Exception("无法解析页面数据")
        }

        val itemList = pageData.getJSONObject("videoInfoRes").getJSONArray("item_list")
        if (itemList.length() == 0) throw Exception("未找到视频信息")
        val item = itemList.getJSONObject(0)

        val author = item.optJSONObject("author")
        val video = item.optJSONObject("video")
        val awemeType = item.optInt("aweme_type", 0)
        val isImage = awemeType == 2 || awemeType == 68

        val title = item.optString("desc", "")
        val authorName = author?.optString("nickname", "") ?: ""
        val shortId = author?.optString("short_id", "") ?: ""

        // 无水印视频URL
        var videoUrl = ""
        if (!isImage && video != null) {
            val playAddr = video.optJSONObject("play_addr")
            val urlList = playAddr?.optJSONArray("url_list")
            if (urlList != null && urlList.length() > 0) {
                videoUrl = urlList.getString(0)
                    .replace("playwm", "play")
                    .replace("ratio=720p", "ratio=1080p")
                    .replace("ratio=540p", "ratio=1080p")
                    .replace("ratio=480p", "ratio=1080p")
            }
            if (videoUrl.isEmpty()) {
                val uri = playAddr?.optString("uri", "") ?: ""
                if (uri.isNotEmpty()) {
                    videoUrl = "https://aweme.snssdk.com/aweme/v1/play/?video_id=$uri&ratio=1080p&line=0"
                }
            }
        }

        // 图集
        val images = mutableListOf<String>()
        if (isImage) {
            val rawImages = item.optJSONArray("images")
            if (rawImages != null) {
                for (i in 0 until rawImages.length()) {
                    val img = rawImages.getJSONObject(i)
                    val urlList = img.optJSONArray("url_list")
                    if (urlList != null && urlList.length() > 0) {
                        images.add(urlList.getString(0))
                    }
                }
            }
        }

        return ParseResult(
            title = title,
            author = authorName,
            shortId = shortId,
            videoUrl = videoUrl,
            images = images,
        )
    }

    /** 构建文件名：prefix_yyyyMMdd_HHmmss_标题_作者_shortId.ext */
    fun buildFileName(prefix: String, ext: String, title: String, author: String, shortId: String): String {
        val now = java.util.Calendar.getInstance()
        val ts = "%04d%02d%02d_%02d%02d%02d".format(
            now.get(java.util.Calendar.YEAR),
            now.get(java.util.Calendar.MONTH) + 1,
            now.get(java.util.Calendar.DAY_OF_MONTH),
            now.get(java.util.Calendar.HOUR_OF_DAY),
            now.get(java.util.Calendar.MINUTE),
            now.get(java.util.Calendar.SECOND)
        )
        val illegal = Regex("""[\\/:*?"<>|\n\r]""")
        val cleanTitle = title.replace(Regex("#\\S+"), "").trim()
            .replace(illegal, "_").take(20).trim()
        val parts = mutableListOf(prefix, ts)
        if (cleanTitle.isNotEmpty()) parts.add(cleanTitle)
        if (author.isNotEmpty()) parts.add(author.replace(illegal, "_"))
        if (shortId.isNotEmpty()) parts.add(shortId)
        return "${parts.joinToString("_")}.$ext"
    }
}
