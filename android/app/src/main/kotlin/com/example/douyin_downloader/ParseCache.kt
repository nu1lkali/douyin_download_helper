package com.example.douyin_downloader

object ParseCache {
    private const val TTL_MS = 30 * 60 * 1000L // 30分钟

    private data class Entry(val result: DouyinParser.ParseResult, val expireAt: Long)

    private val cache = mutableMapOf<String, Entry>()

    fun get(key: String): DouyinParser.ParseResult? {
        val entry = cache[key] ?: return null
        if (System.currentTimeMillis() > entry.expireAt) {
            cache.remove(key)
            return null
        }
        return entry.result
    }

    fun put(key: String, result: DouyinParser.ParseResult) {
        cache[key] = Entry(result, System.currentTimeMillis() + TTL_MS)
        // 顺手清理过期条目，避免内存泄漏
        val now = System.currentTimeMillis()
        cache.entries.removeAll { it.value.expireAt < now }
    }
}
