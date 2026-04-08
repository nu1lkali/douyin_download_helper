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
import androidx.core.content.ContextCompat

class FloatingWindowService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var compactPanel: View? = null
    private var compactParams: WindowManager.LayoutParams? = null
    private var isCompactMode = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isCompactMode = intent?.getBooleanExtra("compact_mode", false) ?: false
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        floatingView = DouyinFloatButton(this)

        val params = WindowManager.LayoutParams(
            140, 140,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 20
            y = 300
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
                            // 简洁模式：读取剪贴板，弹出悬浮面板
                            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            val clipText = clipboard.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
                            showCompactPanel(clipText)
                        } else {
                            // 普通模式：跳转 MainActivity
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

    private fun showCompactPanel(clipText: String) {
        // 如果已有面板，先移除
        dismissCompactPanel()

        val panel = LayoutInflater.from(this).inflate(R.layout.floating_compact_panel, null)
        val wm = windowManager

        val p = WindowManager.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.88).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        compactPanel = panel
        compactParams = p

        // 关闭按钮
        panel.findViewById<ImageButton>(R.id.btn_close).setOnClickListener {
            dismissCompactPanel()
        }

        val tvStatus = panel.findViewById<TextView>(R.id.tv_status)
        val tvTitle = panel.findViewById<TextView>(R.id.tv_title)
        val tvAuthor = panel.findViewById<TextView>(R.id.tv_author)
        val btnDownloadVideo = panel.findViewById<Button>(R.id.btn_download_video)
        val btnDownloadImages = panel.findViewById<Button>(R.id.btn_download_images)
        val progressBar = panel.findViewById<ProgressBar>(R.id.progress_bar)

        tvStatus.text = "正在解析..."
        progressBar.visibility = View.VISIBLE
        btnDownloadVideo.visibility = View.GONE
        btnDownloadImages.visibility = View.GONE

        wm.addView(panel, p)

        // 通知 Flutter 解析
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("compact_parse", clipText)
        }

        // 通过广播通知 Flutter 解析，结果回调到面板
        CompactPanelManager.setCallback { result ->
            Handler(Looper.getMainLooper()).post {
                progressBar.visibility = View.GONE
                if (result.isSuccess) {
                    val info = result.getOrNull()!!
                    tvStatus.text = "解析成功"
                    tvTitle.text = info.title
                    tvAuthor.text = info.author
                    tvTitle.visibility = View.VISIBLE
                    tvAuthor.visibility = View.VISIBLE

                    if (info.isVideo) {
                        btnDownloadVideo.visibility = View.VISIBLE
                        btnDownloadVideo.setOnClickListener {
                            btnDownloadVideo.isEnabled = false
                            btnDownloadVideo.text = "下载中..."
                            notifyFlutterDownload(info.videoUrl, info.albumName, false)
                        }
                    } else {
                        btnDownloadImages.visibility = View.VISIBLE
                        btnDownloadImages.text = "下载全部图片(${info.imageCount}张)"
                        btnDownloadImages.setOnClickListener {
                            btnDownloadImages.isEnabled = false
                            btnDownloadImages.text = "下载中..."
                            notifyFlutterDownload(info.videoUrl, info.albumName, true)
                        }
                    }
                } else {
                    tvStatus.text = "解析失败: ${result.exceptionOrNull()?.message}"
                }
            }
        }

        // 启动解析
        startActivity(intent)
    }

    private fun notifyFlutterDownload(url: String, albumName: String, isImages: Boolean) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("compact_download", url)
            putExtra("compact_album", albumName)
            putExtra("compact_is_images", isImages)
        }
        startActivity(intent)

        CompactPanelManager.setDownloadCallback {
            Handler(Looper.getMainLooper()).post {
                compactPanel?.let { panel ->
                    panel.findViewById<Button>(R.id.btn_download_video)?.text = "下载完成 ✓"
                    panel.findViewById<Button>(R.id.btn_download_images)?.text = "下载完成 ✓"
                }
            }
        }
    }

    fun dismissCompactPanel() {
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

// 简单的回调管理器
object CompactPanelManager {
    data class ParseResult(
        val title: String,
        val author: String,
        val videoUrl: String,
        val albumName: String,
        val isVideo: Boolean,
        val imageCount: Int,
    )

    private var parseCallback: ((Result<ParseResult>) -> Unit)? = null
    private var downloadCallback: (() -> Unit)? = null

    fun setCallback(cb: (Result<ParseResult>) -> Unit) { parseCallback = cb }
    fun setDownloadCallback(cb: () -> Unit) { downloadCallback = cb }

    fun onParseResult(result: Result<ParseResult>) {
        parseCallback?.invoke(result)
        parseCallback = null
    }

    fun onDownloadDone() {
        downloadCallback?.invoke()
        downloadCallback = null
    }
}

/** 悬浮按钮自绘 */
class DouyinFloatButton(context: Context) : View(context) {
    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#1677FF")
        style = Paint.Style.FILL
    }
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#441677FF")
        style = Paint.Style.FILL
        maskFilter = BlurMaskFilter(18f, BlurMaskFilter.Blur.NORMAL)
    }
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f; val cy = height / 2f
        val r = minOf(width, height) / 2f - 8f
        canvas.drawCircle(cx, cy + 4f, r, shadowPaint)
        canvas.drawCircle(cx, cy, r, bgPaint)
        val s = r * 0.45f
        iconPaint.strokeWidth = r * 0.13f
        canvas.drawLine(cx, cy - s * 0.8f, cx, cy + s * 0.3f, iconPaint)
        canvas.drawLine(cx, cy + s * 0.3f, cx - s * 0.55f, cy - s * 0.2f, iconPaint)
        canvas.drawLine(cx, cy + s * 0.3f, cx + s * 0.55f, cy - s * 0.2f, iconPaint)
        canvas.drawLine(cx - s * 0.7f, cy + s * 0.75f, cx + s * 0.7f, cy + s * 0.75f, iconPaint)
    }
}
