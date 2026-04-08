package com.example.douyin_downloader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.douyin_downloader/floating"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> {
                    result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                            Settings.canDrawOverlays(this)
                        else true
                    )
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        startActivity(Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ))
                    }
                    result.success(null)
                }
                "startFloatingWindow" -> {
                    val compactMode = call.argument<Boolean>("compact_mode") ?: false
                    val intent = Intent(this, FloatingWindowService::class.java).apply {
                        putExtra("compact_mode", compactMode)
                    }
                    startService(intent)
                    result.success(null)
                }
                "stopFloatingWindow" -> {
                    stopService(Intent(this, FloatingWindowService::class.java))
                    result.success(null)
                }
                "saveFileToGallery" -> {
                    val filePath = call.argument<String>("filePath")!!
                    val albumName = call.argument<String>("albumName") ?: "抖音下载"
                    val fileName = call.argument<String>("fileName")!!
                    try {
                        saveToGallery(filePath, albumName, fileName)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                "compactParseResult" -> {
                    // 简洁模式现在完全在 Service 里处理，此方法保留兼容
                    result.success(null)
                }
                "compactDownloadDone" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToGallery(filePath: String, albumName: String, fileName: String) {
        val file = File(filePath)
        val isVideo = fileName.endsWith(".mp4")
        val mimeType = if (isVideo) "video/mp4" else "image/jpeg"
        // 清理路径中 MediaStore 不支持的字符，保留斜杠（子目录分隔符）
        val safePath = albumName.replace(Regex("[*?\"<>|]"), "_")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = if (isVideo)
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

            val baseDir = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            val relativePath = "$baseDir/$safePath"

            val values = ContentValues().apply {
                put(if (isVideo) MediaStore.Video.Media.DISPLAY_NAME else MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(if (isVideo) MediaStore.Video.Media.MIME_TYPE else MediaStore.Images.Media.MIME_TYPE, mimeType)
                put(if (isVideo) MediaStore.Video.Media.RELATIVE_PATH else MediaStore.Images.Media.RELATIVE_PATH, relativePath)
                put(if (isVideo) MediaStore.Video.Media.IS_PENDING else MediaStore.Images.Media.IS_PENDING, 1)
            }

            val uri = contentResolver.insert(collection, values)
                ?: throw Exception("MediaStore insert 失败，路径: $relativePath")
            contentResolver.openOutputStream(uri)?.use { output ->
                FileInputStream(file).use { input -> input.copyTo(output) }
            }
            values.clear()
            values.put(if (isVideo) MediaStore.Video.Media.IS_PENDING else MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
        } else {
            val baseDir = Environment.getExternalStoragePublicDirectory(
                if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            )
            // Android 9 及以下：safePath 可能含斜杠，逐级创建目录
            val dir = File(baseDir, safePath)
            if (!dir.exists()) dir.mkdirs()
            val dest = File(dir, fileName)
            file.copyTo(dest, overwrite = true)
            sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(dest)))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val handler = android.os.Handler(android.os.Looper.getMainLooper())

        // 普通模式：读剪贴板
        if (intent.getBooleanExtra("read_clipboard", false)) {
            handler.postDelayed({
                val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                val clipText = clipboard.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
                if (clipText.isNotEmpty()) {
                    flutterEngine?.dartExecutor?.binaryMessenger?.let {
                        io.flutter.plugin.common.MethodChannel(it, CHANNEL)
                            .invokeMethod("onClipboardText", clipText)
                    }
                }
            }, 300)
        }

        // 简洁模式：解析
        val compactText = intent.getStringExtra("compact_parse")
        if (!compactText.isNullOrEmpty()) {
            handler.postDelayed({
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    io.flutter.plugin.common.MethodChannel(it, CHANNEL)
                        .invokeMethod("onCompactParse", compactText)
                }
            }, 300)
        }

        // 简洁模式：下载
        val compactUrl = intent.getStringExtra("compact_download")
        if (!compactUrl.isNullOrEmpty()) {
            val albumName = intent.getStringExtra("compact_album") ?: "便捷下载"
            val isImages = intent.getBooleanExtra("compact_is_images", false)
            handler.postDelayed({
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    io.flutter.plugin.common.MethodChannel(it, CHANNEL)
                        .invokeMethod("onCompactDownload", mapOf(
                            "url" to compactUrl,
                            "album" to albumName,
                            "isImages" to isImages
                        ))
                }
            }, 300)
        }

        // 兼容旧方式
        val clipText = intent.getStringExtra("clipboard_text") ?: ""
        if (clipText.isNotEmpty()) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                io.flutter.plugin.common.MethodChannel(it, CHANNEL)
                    .invokeMethod("onClipboardText", clipText)
            }
        }
    }
}
