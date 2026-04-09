package com.example.douyin_downloader

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.nio.charset.Charset

object SelfHostedParser {

    fun parse(text: String, base: String, token: String, cookie: String): DouyinParser.ParseResult {
        // 使用合并接口 /douyin/share_detail，一次请求完成
        val body = """{"text":${json(text)},"cookie":${json(cookie)},"proxy":"","source":false}"""
        val resp = postJson("$base/douyin/share_detail", token, body)
        val root = JSONObject(resp)

        if (!root.optString("message", "").contains("成功")) {
            throw Exception(root.optString("message", "获取详情失败"))
        }

        val d = root.getJSONObject("data")
        return parseData(d)
    }

    private fun json(s: String) = "\"${s.replace("\\", "\\\\").replace("\"", "\\\"")}\""

    private fun parseData(d: JSONObject): DouyinParser.ParseResult {
        val type = d.optString("type", "")
        val isVideo = type == "视频"
        val isLive = type == "实况"

        val downloads = d.opt("downloads")
        var videoUrl = ""
        val images = mutableListOf<String>()

        when {
            isVideo -> videoUrl = downloads as? String ?: ""
            isLive -> {
                val arr = d.optJSONArray("downloads")
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
                videoUrl = videoClips.firstOrNull() ?: ""
                images.addAll(videoClips + imageClips)
            }
            else -> {
                val arr = d.optJSONArray("downloads")
                if (arr != null) {
                    for (i in 0 until arr.length()) images.add(arr.getString(i))
                }
            }
        }

        return DouyinParser.ParseResult(
            title = d.optString("desc", ""),
            author = d.optString("nickname", ""),
            shortId = d.optString("uid", ""),
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
