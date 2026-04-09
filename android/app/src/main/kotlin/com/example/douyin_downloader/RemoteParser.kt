package com.example.douyin_downloader

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.Charset

object RemoteParser {

    /** hk0.cc 接口 */
    fun parseHk0(inputText: String): DouyinParser.ParseResult {
        // 先提取链接
        val link = extractLink(inputText) ?: throw Exception("未找到有效的抖音链接")
        val url = URL("https://api.hk0.cc/api/douyin?url=${java.net.URLEncoder.encode(link, "UTF-8")}")
        val conn = url.openConnection() as HttpURLConnection
        conn.connectTimeout = 15000
        conn.readTimeout = 15000
        conn.connect()

        val body = conn.inputStream.bufferedReader(Charsets.UTF_8).readText()
        conn.disconnect()

        // 清理PHP Warning前缀
        val jsonStart = body.indexOf('{')
        if (jsonStart == -1) throw Exception("响应格式错误")
        val root = JSONObject(body.substring(jsonStart))
        if (root.optInt("code") != 200) throw Exception(root.optString("msg", "解析失败"))

        val data = root.getJSONObject("data")
        val isImage = data.optJSONArray("images") != null &&
                data.optJSONArray("images")!!.length() > 0 &&
                data.optJSONArray("images")!!.optString(0).startsWith("http")

        val images = mutableListOf<String>()
        if (isImage) {
            val arr = data.getJSONArray("images")
            for (i in 0 until arr.length()) images.add(arr.getString(i))
        }

        return DouyinParser.ParseResult(
            title = data.optString("title", ""),
            author = data.optString("author", ""),
            shortId = data.optString("uid", ""),
            videoUrl = if (!isImage) data.optString("url", "") else "",
            images = images,
        )
    }

    /** xinyew 接口 */
    fun parseXinyew(inputText: String): DouyinParser.ParseResult {
        val link = extractLink(inputText) ?: throw Exception("未找到有效的抖音链接")
        val url = URL("https://api.xinyew.cn/api/douyinjx?url=${java.net.URLEncoder.encode(link, "UTF-8")}")
        val conn = url.openConnection() as HttpURLConnection
        conn.connectTimeout = 15000
        conn.readTimeout = 15000
        conn.connect()

        val body = conn.inputStream.bufferedReader(Charsets.UTF_8).readText()
        conn.disconnect()

        val jsonStart = body.indexOf('{')
        if (jsonStart == -1) throw Exception("响应格式错误")
        val root = JSONObject(body.substring(jsonStart))
        if (root.optInt("code") != 200) throw Exception(root.optString("msg", "解析失败"))

        val data = root.getJSONObject("data")
        val additional = data.optJSONArray("additional_data")?.optJSONObject(0) ?: JSONObject()

        val videoUrl = data.optString("video_url", "").ifEmpty { data.optString("play_url", "") }

        return DouyinParser.ParseResult(
            title = additional.optString("desc", ""),
            author = additional.optString("nickname", ""),
            shortId = "",
            videoUrl = videoUrl,
            images = emptyList(),
        )
    }

    private fun extractLink(text: String): String? {
        val patterns = listOf(
            Regex("""https://v\.douyin\.com/[\w\-/]+"""),
            Regex("""https://(?:www\.)?douyin\.com/video/(\d+)"""),
            Regex("""https://(?:www\.)?douyin\.com/note/(\d+)"""),
        )
        for (p in patterns) {
            val m = p.find(text)
            if (m != null) return m.value
        }
        return null
    }
}
