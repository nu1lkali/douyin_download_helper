package com.example.douyin_downloader

import android.app.Service
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView

class FloatingWindowService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        floatingView = ImageView(this).apply {
            setImageResource(R.drawable.float_icon)
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding(8, 8, 8, 8)
        }

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
                        // 不在Service里读剪贴板（Android 10+后台读取会被拦截）
                        // 直接启动MainActivity，由前台Activity自己读剪贴板
                        startActivity(Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("read_clipboard", true)
                        })
                    }
                }
            }
            true
        }

        windowManager.addView(floatingView, params)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) windowManager.removeView(floatingView)
    }
}

/** 用Canvas自绘的抖音风格悬浮按钮 */
class DouyinFloatButton(context: Context) : View(context) {

    private val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#FF2442")
        style = Paint.Style.FILL
    }
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.parseColor("#44FF2442")
        style = Paint.Style.FILL
        maskFilter = BlurMaskFilter(18f, BlurMaskFilter.Blur.NORMAL)
    }
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.FILL
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 22f
        textAlign = Paint.Align.CENTER
        typeface = Typeface.DEFAULT_BOLD
    }

    // 下载箭头路径
    private val arrowPath = Path()

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val r = minOf(width, height) / 2f - 8f

        // 阴影
        canvas.drawCircle(cx, cy + 4f, r, shadowPaint)
        // 主圆
        canvas.drawCircle(cx, cy, r, bgPaint)

        // 绘制下载图标（向下箭头 + 横线）
        val iconSize = r * 0.45f
        iconPaint.strokeWidth = r * 0.13f
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeCap = Paint.Cap.ROUND

        // 竖线
        canvas.drawLine(cx, cy - iconSize * 0.8f, cx, cy + iconSize * 0.3f, iconPaint)
        // 箭头
        canvas.drawLine(cx, cy + iconSize * 0.3f, cx - iconSize * 0.55f, cy - iconSize * 0.2f, iconPaint)
        canvas.drawLine(cx, cy + iconSize * 0.3f, cx + iconSize * 0.55f, cy - iconSize * 0.2f, iconPaint)
        // 底部横线
        iconPaint.strokeCap = Paint.Cap.ROUND
        canvas.drawLine(cx - iconSize * 0.7f, cy + iconSize * 0.75f, cx + iconSize * 0.7f, cy + iconSize * 0.75f, iconPaint)
    }
}
