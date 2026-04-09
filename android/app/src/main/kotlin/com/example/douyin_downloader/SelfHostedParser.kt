package com.example.douyin_downloader

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.Charset

object SelfHostedParser {

    fun parse(text: String, base: String, token: String, cookie: String): DouyinParser.ParseResult {
        // Step1: share
        val realUrl = getShareUrl(text, base, token)
        val awemeId = extractAwemeId(realUrl)
            ?: throw Exception("无法从链接提取ID: $realUrl")

        // Step2: detail
        return getDetail(awemeId, base, token, cookie)
    }

    private fun getShareUrl(text: String, base: String, token: String): String {
        val body = """{"text":"$text","proxy":""}"""
        val resp = postJson("$base/douyin/share", token, body)
        val json = JSONObject(resp)
        return json.optString("url").takeIf { it.isNotEmpty() }
            ?: throw Exception(json.optString("message", "获取链接失败"))
    }

    private fun extractAwemeId(url: String): String? {
        listOf(
            Regex("""/video/(\d+)"""),
            Regex("""/note/(\d+)"""),
            Regex("""modal_id=(\d+)"""),
        ).forEach { r ->
            r.find(url)?.groupValues?.get(1)?.let { return it }
        }
        return null
    }

    private fun getDetail(awemeId: String, base: String, token: String, cookie: String): DouyinParser.ParseResult {
        val body = """{"cookie":"${cookie.replace("\"", "\\\"")}","proxy":"","source":false,"detail_id":"$awemeId"}"""
        val resp = postJson("$base/douyin/detail", token, body)
        val root = JSONObject(resp)

        if (!root.optString("message", "").contains("成功")) {
            throw Exception(root.optString("message", "获取详情失败"))
        }

        val d = root.getJSONObject("data")
        val type = d.optString("type", "")
        val isVideo = type == "视频"
        val isLive = type == "实况"

        val downloads = d.opt("downloads")
        var videoUrl = ""
        val images = mutableListOf<String>()

        when {
            isVideo -> videoUrl = downloads as? String ?: ""
            isLive -> {
                // 实况：混合数组，视频URL含 video_id= 或 /play/，图片URL含 douyinpic
                val arr = downloads as? org.json.JSONArray ?: d.optJSONArray("downloads")
                val videoClips = mutableListOf<String>()
                val imageClips = mutableListOf<String>()
                if (arr != null) {
                    for (i in 0 until arr.length()) {
                        val url = arr.getString(i)
                        if (url.contains("video_id=") || url.contains("/play/")) {
                            videoClips.add(url)
                        } else {
                            imageClips.add(url)
                        }
                    }
                }
                val allClips = videoClips + imageClips
                videoUrl = videoClips.firstOrNull() ?: ""
                images.addAll(allClips)
            }
            downloads is org.json.JSONArray -> {
                val arr = downloads
                for (i in 0 until arr.length()) images.add(arr.getString(i))
            }
        }

        val shortId = d.optString("uid", "")
        val nickname = d.optString("nickname", "")

        return DouyinParser.ParseResult(
            title = d.optString("desc", ""),
            author = nickname,
            shortId = shortId,
            videoUrl = videoUrl,
            images = images,
            isLive = isLive,
        )
    }

    private fun postJson(url: String, token: String, body: String): String {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "POST"
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("token", token)
        conn.doOutput = true
        conn.connectTimeout = 30000
        conn.readTimeout = 60000
        conn.connect()
        conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
        if (conn.responseCode !in 200..299) throw Exception("HTTP ${conn.responseCode}")
        val bytes = conn.inputStream.use { it.readBytes() }
        conn.disconnect()
        return String(bytes, Charsets.UTF_8)
    }
}
