package com.example.douyin_downloader

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object SelfHostedV2Parser {

    fun parse(text: String, base: String, token: String, cookie: String): DouyinParser.ParseResult {
        val encodedUrl = java.net.URLEncoder.encode(text, "UTF-8")
        val fullUrl = "$base/api/hybrid/video_data?url=$encodedUrl"
        val resp = getJson(fullUrl, token, cookie)
        val root = JSONObject(resp)

        if (root.optInt("code", 0) != 200) {
            throw Exception(root.optString("message", root.optString("msg", "V2 接口返回错误")))
        }

        val item = root.getJSONObject("data")
        return parseItem(item)
    }

    private fun parseItem(item: JSONObject): DouyinParser.ParseResult {
        val author = item.optJSONObject("author") ?: JSONObject()
        val video = item.optJSONObject("video") ?: JSONObject()
        val music = item.optJSONObject("music") ?: JSONObject()
        val statistics = item.optJSONObject("statistics") ?: JSONObject()

        val awemeType = item.optInt("aweme_type", 0)
        val isImage = awemeType == 2 || awemeType == 68

        // 视频 URL
        var videoUrl = ""
        var cover = ""
        var duration = 0

        if (!isImage) {
            duration = video.optInt("duration", 0)
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
            // 封面
            val originCover = video.optJSONObject("origin_cover")
            val coverFallback = video.optJSONObject("cover")
            val originList = originCover?.optJSONArray("url_list")
            val coverList = coverFallback?.optJSONArray("url_list")
            cover = if (originList != null && originList.length() > 0) originList.getString(0)
                    else if (coverList != null && coverList.length() > 0) coverList.getString(0)
                    else ""
        }

        // 图集 / 实况
        val images = mutableListOf<String>()
        var isLive = false
        if (isImage) {
            val rawImages = item.optJSONArray("images")
            if (rawImages != null && rawImages.length() > 0) {
                val firstImg = rawImages.getJSONObject(0)
                // 判断实况：第一个 image 的 video.play_addr.url_list 有内容
                val firstVideo = firstImg.optJSONObject("video")
                val firstPlayAddr = firstVideo?.optJSONObject("play_addr")
                val firstVideoUrls = firstPlayAddr?.optJSONArray("url_list")
                val hasVideo = firstVideoUrls != null && firstVideoUrls.length() > 0
                if (hasVideo) {
                    isLive = true
                    val videoClips = mutableListOf<String>()
                    val staticImgs = mutableListOf<String>()
                    for (i in 0 until rawImages.length()) {
                        val img = rawImages.getJSONObject(i)
                        // 每个 image 单独判断：有视频片段取视频，没有取静图
                        val clipVideo = img.optJSONObject("video")
                        val clipPlayAddr = clipVideo?.optJSONObject("play_addr")
                        val clipUrls = clipPlayAddr?.optJSONArray("url_list")
                        if (clipUrls != null && clipUrls.length() > 0) {
                            videoClips.add(clipUrls.getString(0))
                        } else {
                            val imgUrls = img.optJSONArray("url_list")
                            if (imgUrls != null && imgUrls.length() > 0) {
                                staticImgs.add(imgUrls.getString(0))
                            }
                        }
                    }
                    images.addAll(videoClips)
                    images.addAll(staticImgs)
                    videoUrl = videoClips.firstOrNull() ?: ""
                    if (cover.isEmpty()) cover = staticImgs.firstOrNull() ?: ""
                } else {
                    for (i in 0 until rawImages.length()) {
                        val img = rawImages.getJSONObject(i)
                        val imgUrls = img.optJSONArray("url_list")
                        if (imgUrls != null && imgUrls.length() > 0) {
                            images.add(imgUrls.getString(0))
                        }
                    }
                    if (cover.isEmpty()) cover = images.firstOrNull() ?: ""
                }
            }
        }

        // 音乐
        val musicTitle = music.optString("title", "")
        val musicAuthor = music.optString("author", "")
        val musicPlayUrl = music.optJSONObject("play_url")
        val musicUrlList = musicPlayUrl?.optJSONArray("url_list")
        val musicUrl = if (musicUrlList != null && musicUrlList.length() > 0) musicUrlList.getString(0) else ""

        // 作者
        val authorName = author.optString("nickname", "")
        val shortId = author.optString("short_id", "").let {
            if (it.isNotEmpty() && it != "0") it else author.optString("unique_id", "")
        }

        return DouyinParser.ParseResult(
            title = item.optString("desc", ""),
            author = authorName,
            shortId = shortId,
            videoUrl = videoUrl,
            images = images,
            cover = cover,
            isLive = isLive,
            like = statistics.optLong("digg_count", 0),
            time = item.optLong("create_time", 0),
            duration = duration,
            musicTitle = musicTitle,
            musicAuthor = musicAuthor,
            musicUrl = musicUrl,
        )
    }

    private fun getJson(url: String, token: String, cookie: String): String {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "GET"
        conn.setRequestProperty("token", token)
        if (cookie.isNotEmpty()) conn.setRequestProperty("Cookie", cookie)
        conn.connectTimeout = 30000
        conn.readTimeout = 60000
        conn.connect()
        if (conn.responseCode !in 200..299) throw Exception("HTTP ${conn.responseCode}")
        val bytes = conn.inputStream.use { it.readBytes() }
        conn.disconnect()
        return String(bytes, Charsets.UTF_8)
    }
}
