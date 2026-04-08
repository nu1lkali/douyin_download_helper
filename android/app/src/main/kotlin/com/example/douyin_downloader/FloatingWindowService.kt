package com.example.douyin_downloader

import android.app.Service
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.*
import android.widget.*
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import android.content.ContentValues
import android.content.SharedPreferences
import android.os.Build
import android.os.Environment
import android.provider.MediaStore

class FloatingWindowService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var compactPanel: View? = null
    private var isCompactMode = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isCompactMode = intent?.getBooleanExtra("compact_mode", false) ?: false
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // 使用哆啦A梦图标
        floatingView = ImageView(this).apply {
            setImageResource(R.drawable.float_icon)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding(4, 4, 4, 4)
        }

        val params = WindowManager.LayoutParams(
            140, 140,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 20; y = 300
        }

        var initialX = 0; var initialY = 0
        var initialTouchX = 0f; var initialTouchY = 0f
        var moved = false

        floatingView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    moved = false
                    initialX = params.x; initialY = params.y
                    initialTouchX = event.rawX; initialTouchY = event.rawY
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(dx) > 8 || Math.abs(dy) > 8) moved = true
                    params.x = initialX + dx; params.y = initialY + dy
                    windowManager.updateViewLayout(floatingView, params)
                }
                MotionEvent.ACTION_UP -> {
                    if (!moved) {
                        if (isCompactMode) {
                            // 先显示面板（获取焦点），再读剪贴板
                            showCompactPanel(null)
                        } else {
                            startActivity(Intent(this, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                                putExtra("read_clipboard", true)
                            })
                        }
                    }
                }
            }
            true
        }

        windowManager.addView(floatingView, params)
    }

    // ── 简洁面板 ──────────────────────────────────────────────

    private fun showCompactPanel(clipTextParam: String?) {
        dismissCompactPanel()

        val panel = LayoutInflater.from(this).inflate(R.layout.floating_compact_panel, null)
        // 去掉 FLAG_NOT_FOCUSABLE，让面板能获取焦点，这样才能读剪贴板
        val p = WindowManager.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.88).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply { gravity = Gravity.CENTER }

        compactPanel = panel
        windowManager.addView(panel, p)

        val tvStatus = panel.findViewById<TextView>(R.id.tv_status)
        val tvTitle = panel.findViewById<TextView>(R.id.tv_title)
        val tvAuthor = panel.findViewById<TextView>(R.id.tv_author)
        val btnVideo = panel.findViewById<Button>(R.id.btn_download_video)
        val btnImages = panel.findViewById<Button>(R.id.btn_download_images)
        val progress = panel.findViewById<ProgressBar>(R.id.progress_bar)
        val progressDownload = panel.findViewById<ProgressBar>(R.id.progress_download)
        val tvDownloadProgress = panel.findViewById<TextView>(R.id.tv_download_progress)

        panel.findViewById<ImageButton>(R.id.btn_close).setOnClickListener { dismissCompactPanel() }

        // 面板显示后延迟读剪贴板（等待窗口获得焦点）
        mainHandler.postDelayed({
            val clipText = clipTextParam ?: run {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
            }

            if (clipText.isEmpty()) {
                tvStatus.text = "剪贴板为空，请先在抖音复制分享链接"
                progress.visibility = View.GONE
                return@postDelayed
            }

            tvStatus.text = "正在解析..."
            progress.visibility = View.VISIBLE

            Thread {
                try {
                    val result = DouyinParser.parse(clipText)
                    mainHandler.post {
                        progress.visibility = View.GONE
                        tvStatus.text = "解析成功"
                        tvTitle.text = result.title
                        tvAuthor.text = result.author
                        tvTitle.visibility = View.VISIBLE
                        tvAuthor.visibility = View.VISIBLE

                        if (result.isVideo) {
                            btnVideo.visibility = View.VISIBLE
                            btnVideo.setOnClickListener {
                                btnVideo.isEnabled = false
                                btnVideo.text = "下载中..."
                                val fileName = DouyinParser.buildFileName("video", "mp4", result.title, result.author, result.shortId)
                                val album = buildAlbumPath(result.author, result.shortId)
                                btnVideo.isEnabled = false
                                btnVideo.text = "下载中..."
                                progressDownload.visibility = View.VISIBLE
                                progressDownload.progress = 0
                                tvDownloadProgress.visibility = View.VISIBLE
                                tvDownloadProgress.text = "0%"
                                downloadInBackground(result.videoUrl, false, album, fileName,
                                    onProgress = { downloaded, total ->
                                        if (total > 0) {
                                            val pct = (downloaded * 100 / total).toInt()
                                            mainHandler.post {
                                                progressDownload.progress = pct
                                                tvDownloadProgress.text = "$pct%"
                                            }
                                        }
                                    }
                                ) { ok, msg ->
                                    mainHandler.post {
                                        progressDownload.visibility = View.GONE
                                        tvDownloadProgress.visibility = View.GONE
                                        btnVideo.text = if (ok) "✓ 已保存到相册" else "下载失败: $msg"
                                        if (ok) scheduleAutoClose()
                                    }
                                }
                            }
                        } else {
                            btnImages.visibility = View.VISIBLE
                            btnImages.text = "下载全部图片(${result.images.size}张)"
                            btnImages.setOnClickListener {
                                btnImages.isEnabled = false
                                btnImages.text = "下载中..."
                                progressDownload.visibility = View.VISIBLE
                                progressDownload.progress = 0
                                tvDownloadProgress.visibility = View.VISIBLE
                                tvDownloadProgress.text = "0/${result.images.size}"
                                var done = 0
                                result.images.forEachIndexed { i, url ->
                                    val fileName = DouyinParser.buildFileName("img_$i", "jpg", result.title, result.author, result.shortId)
                                    val album = buildAlbumPath(result.author, result.shortId)
                                    downloadInBackground(url, true, album, fileName,
                                        onProgress = { downloaded, total ->
                                            if (total > 0) {
                                                val filePct = (downloaded * 100 / total).toInt()
                                                val totalPct = ((i * 100 + filePct) / result.images.size)
                                                mainHandler.post {
                                                    progressDownload.progress = totalPct
                                                    tvDownloadProgress.text = "${i + 1}/${result.images.size}  $totalPct%"
                                                }
                                            }
                                        }
                                    ) { ok, _ ->
                                        done++
                                        if (done == result.images.size) {
                                            mainHandler.post {
                                                progressDownload.visibility = View.GONE
                                                tvDownloadProgress.visibility = View.GONE
                                                btnImages.text = "✓ ${result.images.size}张已保存到相册"
                                                scheduleAutoClose()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    mainHandler.post {
                        progress.visibility = View.GONE
                        tvStatus.text = "解析失败: ${e.message}"
                    }
                }
            }.start()
        }, 200) // 等200ms让窗口获得焦点
    }

    /** 读取设置，构建完整相册路径（含分组子目录） */
    private fun buildAlbumPath(author: String, shortId: String): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val albumName = prefs.getString("flutter.album_name", "便捷下载") ?: "便捷下载"
        val groupByAuthor = prefs.getBoolean("flutter.group_by_author", false)
        if (groupByAuthor && author.isNotEmpty()) {
            val folderName = if (shortId.isNotEmpty()) "$author($shortId)" else author
            // 清理非法字符，保留括号
            val safeFolder = folderName.replace(Regex("[*?\"<>|\\\\/:]+"), "_")
            return "$albumName/$safeFolder"
        }
        return albumName
    }

    private fun downloadInBackground(
        url: String, isImage: Boolean, albumName: String, fileName: String,
        onProgress: ((Long, Long) -> Unit)? = null,
        callback: (Boolean, String?) -> Unit
    ) {
        Thread {
            try {
                val tmpFile = File(cacheDir, fileName)
                downloadUrl(url, tmpFile, onProgress)
                saveToGallery(tmpFile.absolutePath, albumName, fileName)
                tmpFile.delete()
                callback(true, null)
            } catch (e: Exception) {
                if (url.contains("ratio=1080p")) {
                    try {
                        val fallbackUrl = url.replace("ratio=1080p", "ratio=720p")
                        val tmpFile = File(cacheDir, fileName)
                        downloadUrl(fallbackUrl, tmpFile, onProgress)
                        saveToGallery(tmpFile.absolutePath, albumName, fileName)
                        tmpFile.delete()
                        callback(true, null)
                    } catch (e2: Exception) {
                        callback(false, e2.message)
                    }
                } else {
                    callback(false, e.message)
                }
            }
        }.start()
    }

    private fun downloadUrl(url: String, dest: File, onProgress: ((Long, Long) -> Unit)? = null) {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.setRequestProperty("User-Agent", DouyinParser.UA)
        conn.connectTimeout = 30000
        conn.readTimeout = 60000
        conn.connect()
        if (conn.responseCode !in 200..299) throw Exception("HTTP ${conn.responseCode}")
        val total = conn.contentLengthLong
        var downloaded = 0L
        FileOutputStream(dest).use { out ->
            conn.inputStream.use { input ->
                val buf = ByteArray(8192)
                var n: Int
                while (input.read(buf).also { n = it } != -1) {
                    out.write(buf, 0, n)
                    downloaded += n
                    onProgress?.invoke(downloaded, total)
                }
            }
        }
        conn.disconnect()
    }

    private fun saveToGallery(filePath: String, albumName: String, fileName: String) {
        val file = File(filePath)
        val isVideo = fileName.endsWith(".mp4")
        val safePath = albumName.replace(Regex("[*?\"<>|]"), "_")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = if (isVideo)
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            else
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val baseDir = if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
            val values = ContentValues().apply {
                put(if (isVideo) MediaStore.Video.Media.DISPLAY_NAME else MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(if (isVideo) MediaStore.Video.Media.MIME_TYPE else MediaStore.Images.Media.MIME_TYPE, if (isVideo) "video/mp4" else "image/jpeg")
                put(if (isVideo) MediaStore.Video.Media.RELATIVE_PATH else MediaStore.Images.Media.RELATIVE_PATH, "$baseDir/$safePath")
                put(if (isVideo) MediaStore.Video.Media.IS_PENDING else MediaStore.Images.Media.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(collection, values)
                ?: throw Exception("MediaStore insert 失败")
            contentResolver.openOutputStream(uri)?.use { out ->
                file.inputStream().use { it.copyTo(out) }
            }
            values.clear()
            values.put(if (isVideo) MediaStore.Video.Media.IS_PENDING else MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
        } else {
            val dir = File(Environment.getExternalStoragePublicDirectory(
                if (isVideo) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES), safePath)
            if (!dir.exists()) dir.mkdirs()
            file.copyTo(File(dir, fileName), overwrite = true)
        }
    }

    private fun scheduleAutoClose() {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val autoClose = prefs.getBoolean("flutter.compact_auto_close", true)
        if (!autoClose) return
        mainHandler.postDelayed({ dismissCompactPanel() }, 3000)
    }

    private fun dismissCompactPanel() {
        compactPanel?.let {
            try { windowManager.removeView(it) } catch (_: Exception) {}
            compactPanel = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        dismissCompactPanel()
        if (::floatingView.isInitialized) {
            try { windowManager.removeView(floatingView) } catch (_: Exception) {}
        }
    }
}
