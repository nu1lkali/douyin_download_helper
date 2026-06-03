# 便捷下载 - 抖音无水印视频下载工具

> Author: **HACKFUN**

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android">
  <img src="https://img.shields.io/badge/Framework-Flutter-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.0.0-blue?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

一款基于 Flutter 开发的 Android 端抖音无水印视频、图片下载工具。支持多种链接格式解析、悬浮窗快捷操作、自建接口 / 本地解析双模式，提供 Material Design 3 风格的精美 UI。

---

## ✨ 功能特性

### 核心功能
- **无水印视频下载** — 下载抖音短视频的无水印高清版本（支持 1080p / 720p 自动降级）
- **图集下载** — 一键批量下载抖音图文笔记中的所有图片
- **实况照片下载** — 支持抖音 Live 实况照片的多片段下载
- **封面下载** — 单独下载视频封面图
- **一键下载** — 视频 + 封面同时下载，省时省力

### 链接解析
支持多种抖音链接格式，自动识别并提取有效链接：
| 格式 | 示例 |
|------|------|
| 分享口令（含内嵌短链） | `xxx https://v.douyin.com/xxx/ xxx` |
| 短网址 | `https://v.douyin.com/xxx` |
| 正常视频页 | `https://www.douyin.com/video/xxx` |
| 发现页 | `https://www.douyin.com/discover?modal_id=xxx` |
| 用户主页视频 | `https://www.douyin.com/user/xxx?modal_id=xxx` |

### 解析模式
应用提供三种视频解析模式，可在设置中自由切换：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **自建接口** | 使用自建后端服务解析，需配置接口地址和 Token | 有自己服务器的用户 |
| **自建接口 V2** | 新版接口协议，返回原始抖音数据，字段更完整 | 需要更完整数据的用户 |
| **本地解析** | 直接请求抖音接口，建议配置 Cookie 提高成功率 | 无服务器、希望本地运行的用户 |

### 悬浮窗
- **标准悬浮窗** — 点击悬浮球自动读取剪贴板并解析视频
- **简洁模式** — 点击悬浮窗弹出小面板，不打断当前应用操作
- **下载后自动关闭** — 简洁模式下面板下载完成后可配置自动关闭（支持 0s / 3s / 5s / 不关闭）
- **悬浮按钮隐藏/恢复** — 支持隐藏和恢复悬浮按钮

### 其他特性
- **解析历史** — 自动记录每次解析，支持查看详情、单条删除、一键清空
- **按发布者分组** — 开启后文件按 `相册名/发布者名称(ID)/` 子文件夹分类保存
- **自定义相册名称** — 自定义下载文件保存的相册名
- **Cookie 管理** — 支持手动输入或从文件导入抖音 Cookie
- **图片查看器** — 全屏查看图集，支持双指缩放、左右滑动、长按保存
- **调试日志** — 内置请求日志查看器，方便排查问题
- **权限管理** — 启动时自动检测并引导授权存储权限

---

## 📸 使用说明

1. **复制链接** — 在抖音 App 中复制视频分享链接或分享口令
2. **粘贴解析** — 打开便捷下载，粘贴到输入框，点击「解析视频」
3. **选择下载** — 在详情页选择下载视频、封面或一键全部下载
4. **悬浮窗模式** — 在设置中开启悬浮窗后，切换到抖音 App，点击悬浮球即可自动解析

---

## 🏗️ 项目结构

```
lib/
├── main.dart                        # 应用入口，权限网关
├── models/
│   ├── video_info.dart              # 视频信息数据模型（Freezed）
│   ├── video_info.freezed.dart      # Freezed 生成代码
│   └── video_info.g.dart            # JSON 序列化生成代码
├── screens/
│   ├── home_screen.dart             # 首页（链接输入、解析按钮）
│   ├── video_detail_screen.dart     # 视频详情页（预览、下载）
│   ├── history_screen.dart          # 解析历史页面
│   └── settings_screen.dart         # 设置页面
├── services/
│   ├── api_service.dart             # API 调度器（根据模式选择解析服务）
│   ├── self_hosted_api_service.dart # 自建接口解析服务
│   ├── self_hosted_v2_api_service.dart # 自建接口 V2 解析服务
│   ├── local_parser_service.dart    # 本地解析服务
│   ├── download_service.dart        # 文件下载服务（Dio）
│   ├── floating_window_service.dart # 悬浮窗服务（MethodChannel 通信）
│   ├── history_service.dart         # 历史记录服务
│   ├── settings_service.dart        # 设置服务（SharedPreferences）
│   ├── permission_service.dart      # 权限管理服务
│   └── log_service.dart             # 调试日志服务
└── utils/
    └── link_extractor.dart          # 链接提取工具（正则匹配）

android/
└── app/src/main/kotlin/com/example/douyin_downloader/
    ├── MainActivity.kt              # Android 主 Activity
    └── FloatingWindowService.kt     # Android 原生悬浮窗服务
```

---

## 🔄 工作原理与架构

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter UI 层                       │
│  HomeScreen → VideoDetailScreen → DownloadService       │
│  HistoryScreen / SettingsScreen                         │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│                    服务层 (Services)                      │
│                                                          │
│  ┌─────────────┐    ┌──────────────────────────────────┐ │
│  │ LinkExtractor│───▶│         ApiService               │ │
│  │  (链接提取)   │    │       (解析调度器 + 缓存)          │ │
│  └─────────────┘    └──────┬────────────┬──────────┬───┘ │
│                            │            │          │     │
│              ┌─────────────▼──┐  ┌──────▼──────┐ ┌─▼───┐│
              │SelfHostedApi   │  │SelfHostedV2 │ │Local││
│              │Service         │  │ApiService   │ │Parse││
│              │(自建接口)       │  │(自建接口V2)  │ │r    ││
│              └────────────────┘  └─────────────┘ └─────┘│
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │DownloadService│  │HistoryService│  │SettingsService │ │
│  │  (文件下载)    │  │ (历史记录)    │  │  (设置管理)     │ │
│  └──────────────┘  └──────────────┘  └────────────────┘ │
└────────────────────────┬────────────────────────────────┘
                         │  MethodChannel
┌────────────────────────▼────────────────────────────────┐
│               Android 原生层 (Kotlin)                     │
│  FloatingWindowService (悬浮窗 + 文件保存到相册)            │
│  MainActivity (Activity 生命周期管理)                      │
└─────────────────────────────────────────────────────────┘
```

### 核心流程

#### 1. 链接提取（`LinkExtractor`）

用户输入的文本经过正则匹配，按优先级提取有效链接：

```
用户输入 → 正则匹配（优先级从高到低）
  ├─ ① 短网址 https://v.douyin.com/xxx     → 直接使用
  ├─ ② 正常视频页 douyin.com/video/xxx      → 直接使用
  ├─ ③ 发现页 douyin.com/discover?modal_id  → 转换为 /video/{id}
  └─ ④ 用户主页 douyin.com/user?modal_id    → 转换为 /video/{id}
```

#### 2. 视频解析调度（`ApiService`）

`ApiService` 是解析的核心调度器，具有 **30 分钟内存缓存**：

```
ApiService.parseVideo(url)
  │
  ├─ 命中缓存？ → 直接返回缓存的 VideoInfo
  │
  └─ 未命中 → 读取用户设置的 ParseMode
       ├─ ParseMode.selfHosted    → SelfHostedApiService.parse()
       ├─ ParseMode.selfHostedV2  → SelfHostedV2ApiService.parse()
       └─ ParseMode.local         → LocalParserService.parse()
            │
            └─ 结果写入缓存（30 分钟过期）
```

#### 3. 三种解析接口详解

##### 📡 自建接口（`SelfHostedApiService`）

使用自建后端服务，通过**一次 POST 请求**完成解析：

```
POST {base_url}/douyin/share_detail

请求头：
  Content-Type: application/json
  token: {用户配置的 Token}

请求体：
{
  "text": "用户粘贴的链接或口令",
  "cookie": "抖音 Cookie（可选）",
  "proxy": "",
  "source": false
}

响应：
{
  "message": "成功",
  "data": {
    "type": "视频" | "图集" | "实况",
    "nickname": "作者昵称",
    "uid": "作者ID",
    "desc": "视频标题",
    "digg_count": 12345,
    "create_timestamp": 1700000000,
    "duration": "00:30",
    "static_cover": "封面URL",
    "dynamic_cover": "动态封面URL",
    "music_title": "音乐标题",
    "music_author": "音乐作者",
    "music_url": "音乐URL",
    "downloads": "视频URL" | ["图片URL", ...]  // 视频时为字符串，图集/实况时为数组
  }
}
```

**工作原理**：将抖音分享链接/口令发送到自建后端，后端负责解析抖音页面并返回结构化数据。客户端根据 `type` 字段判断内容类型，将 `downloads` 映射为 `VideoInfo` 模型。

##### 📡 自建接口 V2（`SelfHostedV2ApiService`）

新版接口协议，返回**原始抖音 API 数据**，字段更完整：

```
GET {base_url}/api/hybrid/video_data?url={编码后的链接}

请求头：
  token: {用户配置的 Token}（可选）
  Cookie: {抖音 Cookie}（可选）

响应：
{
  "code": 200,
  "data": {
    "aweme_type": 0,           // 0=视频, 2/68=图集/实况
    "desc": "视频标题",
    "create_time": 1700000000,
    "author": {
      "nickname": "作者昵称",
      "short_id": "短ID",
      "unique_id": "唯一ID",
      "uid": "用户ID",
      "avatar_thumb": { "url_list": ["头像URL"] }
    },
    "video": {
      "play_addr": { "uri": "视频ID", "url_list": ["播放URL"] },
      "origin_cover": { "url_list": ["原始封面URL"] },
      "cover": { "url_list": ["封面URL"] },
      "duration": 30000
    },
    "images": [                    // 仅图集/实况时存在
      { "url_list": ["图片URL"], "video": { "play_addr": {...} } }
    ],
    "music": {
      "title": "音乐标题",
      "author": "音乐作者",
      "cover_large": { "url_list": ["封面URL"] },
      "play_url": { "url_list": ["播放URL"] }
    },
    "statistics": { "digg_count": 12345 }
  }
}
```

**工作原理**：
- 通过 `aweme_type` 判断内容类型（0=视频，2/68=图集或实况）
- **无水印处理**：将 `play_addr.url_list[0]` 中的 `playwm` 替换为 `play`
- **画质提升**：将 `ratio=720p/540p/480p` 替换为 `ratio=1080p`
- **实况检测**：遍历 `images` 数组，如果每个 image 节点都有 `video.play_addr`，则判定为实况照片
- **兜底方案**：如果 `url_list` 为空但 `uri` 存在，拼接 `https://aweme.snssdk.com/aweme/v1/play/?video_id={uri}&ratio=1080p&line=0`

##### 📡 本地解析（`LocalParserService`）

直接请求抖音分享页面，**无需后端服务器**，通过 HTML 页面提取数据：

```
解析流程：

  ① 短链跟随重定向
     v.douyin.com/xxx ──HTTP 302──▶ www.douyin.com/video/{aweme_id}
     （最多跟随 10 次重定向）

  ② 提取 aweme_id
     从 URL 中正则匹配 /video/(\d+) 或 modal_id=(\d+) 等

  ③ 请求分享页面
     GET https://www.iesdouyin.com/share/video/{aweme_id}/
     User-Agent: iPhone UA（必须，否则不返回 _ROUTER_DATA）
     Cookie: 可选，提高成功率

  ④ 提取页面数据
     从 HTML 中匹配 window._ROUTER_DATA = {...} </script>
     → 解析 JSON → loaderData['video_(id)/page'].videoInfoRes.item_list[0]

  ⑤ 解析视频信息
     与 V2 接口相同的数据结构，从原始抖音数据中提取字段
```

**关键细节**：
- **必须使用 iPhone User-Agent**，否则 `iesdouyin.com` 不返回 `_ROUTER_DATA` JSON
- 从 HTML 的 `<script>` 标签中提取 `window._ROUTER_DATA` 全局变量
- 支持 `video_(id)/page` 和 `note_(id)/page` 两种页面数据结构
- 无水印处理逻辑与 V2 接口一致

#### 4. 文件下载（`DownloadService`）

```
DownloadService.downloadFile(url, fileName, albumName, onProgress)
  │
  ├─ ① 检查存储权限（Android 13+ 需要 Photos/Videos 权限）
  │
  ├─ ② Dio 下载到临时目录
  │     ├─ 请求头：Referer: https://www.douyin.com/
  │     ├─ 1080p 下载失败 → 自动降级到 720p（替换 ratio 参数）
  │     └─ 实时回调下载进度
  │
  ├─ ③ 通过 MethodChannel 调用原生方法保存到相册
  │     FloatingWindowService.saveFileToGallery(path, name, album)
  │
  └─ ④ 清理临时文件（无论成功失败）
```

**文件命名规则**：`{类型}_{日期时间}_{标题}_{作者}_{uid}.{扩展名}`
- 日期格式：`YYYYMMDD_HHmmss`
- 标题自动清理 `#话题标签`，截断至 20 字符
- 文件名中的非法字符（`\ / : * ? " < > |`）替换为下划线

**存储路径**：
- 默认：`DCIM/{相册名}/{文件名}`
- 按作者分组：`DCIM/{相册名}/{作者名(uid)}/{文件名}`

#### 5. 悬浮窗系统

悬浮窗通过 Flutter 与 Android 原生之间的 **MethodChannel** 双向通信：

```
┌─ Flutter (floating_window_service.dart) ─┐    ┌─ Android (FloatingWindowService.kt) ──┐
│                                          │    │                                       │
│  start()              ──────────────────▶│    │ 启动悬浮窗 Service                    │
│  stop()               ──────────────────▶│    │ 停止悬浮窗 Service                    │
│  hasOverlayPermission()◀────────────────▶│    │ 检查/请求悬浮窗权限                    │
│  saveFileToGallery()  ──────────────────▶│    │ 保存文件到系统相册                     │
│                                          │    │                                       │
│  onClipboardText()    ◀──────────────────│    │ 用户点击悬浮球 → 读取剪贴板            │
│  onCompactParse()     ◀──────────────────│    │ 简洁模式 → 发送解析请求                │
│  onCompactDownload()  ◀──────────────────│    │ 简洁模式 → 发送下载请求                │
│  addHistory()         ◀──────────────────│    │ Kotlin 侧通知写入历史记录              │
│  compactParseResult() ──────────────────▶│    │ 返回解析结果给 Kotlin UI               │
│  compactDownloadDone()──────────────────▶│    │ 通知下载完成                           │
└──────────────────────────────────────────┘    └───────────────────────────────────────┘
```

**标准模式**：点击悬浮球 → 读取系统剪贴板 → 通过 `onClipboardText` 发送到 Flutter → 自动解析并跳转详情页

**简洁模式**：点击悬浮球 → 弹出原生小面板 → 用户点击解析 → 通过 `onCompactParse` 触发 Flutter 解析 → 结果回传给原生面板显示 → 用户点击下载 → 通过 `onCompactDownload` 触发下载

#### 6. 数据模型（`VideoInfo`）

使用 **Freezed** 生成不可变数据模型，统一三种解析方式的返回格式：

```dart
@freezed
class VideoInfo {
  String author;       // 作者昵称
  String uid;          // 作者ID
  String avatar;       // 作者头像 URL
  int like;            // 点赞数
  int time;            // 发布时间戳
  String title;        // 视频标题
  String cover;        // 封面 URL
  dynamic images;      // 核心字段：类型自适应
  String url;          // 无水印视频 URL
  int duration;        // 视频时长（毫秒）
  MusicInfo music;     // 背景音乐信息
}

// images 字段的类型判断逻辑：
// - String（非"实况:"开头）→ 视频，url 字段为无水印播放地址
// - String（"实况:"开头）  → 实况照片，换行分割为多个片段URL
// - List<String>           → 图集，数组中每个元素为一张图片URL
```

#### 7. 设置管理（`SettingsService`）

基于 `SharedPreferences` 的持久化键值存储，管理所有用户配置：

| 键名 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `floating_window_enabled` | bool | false | 悬浮窗开关 |
| `floating_compact_mode` | bool | false | 简洁模式开关 |
| `compact_auto_close_delay` | int | 3 | 简洁面板自动关闭延迟（秒） |
| `parse_mode` | String | 'self' | 解析模式：self / self_v2 / local |
| `self_hosted_url` | String | '' | 自建接口地址 |
| `self_hosted_token` | String | '' | 自建接口 Token |
| `self_hosted_v2_url` | String | '' | 自建接口 V2 地址 |
| `self_hosted_v2_token` | String | '' | 自建接口 V2 Token |
| `douyin_cookie` | String | '' | 抖音 Cookie |
| `album_name` | String | '便捷下载' | 相册名称 |
| `group_by_author` | bool | false | 按发布者分组 |

#### 8. 历史记录（`HistoryService`）

解析成功的视频信息自动保存到本地历史记录：
- 每次解析成功后自动添加记录
- 支持查看历史详情、单条删除、一键清空
- 悬浮窗简洁模式下的解析结果也会同步写入历史
- App 启动时会冲刷积压的历史记录（App 不在前台时缓存的）

---

## 🛠️ 技术栈

| 技术 | 用途 |
|------|------|
| **Flutter 3.x** | 跨平台 UI 框架 |
| **Dart 3.x** | 编程语言 |
| **Material Design 3** | UI 设计规范 |
| **Freezed** | 不可变数据模型代码生成 |
| **Dio** | HTTP 网络请求，支持下载进度回调 |
| **http** | 轻量 HTTP 请求（用于解析接口） |
| **SharedPreferences** | 本地持久化键值存储 |
| **MethodChannel** | Flutter ↔ Android 原生双向通信 |
| **CachedNetworkImage** | 网络图片缓存加载 |
| **FilePicker** | 文件选择器（Cookie 导入） |
| **PermissionHandler** | 运行时权限管理 |
| **DeviceInfoPlus** | 设备信息获取（Android SDK 版本判断） |

---

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android SDK（最低 Android 5.0 / API 21）

### 安装依赖

```bash
flutter pub get
```

### 生成代码（Freezed / JSON 序列化）

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
flutter run
```

### 构建 Release APK

```bash
flutter build apk --release
```

生成的 APK 文件位于 `build/app/outputs/flutter-apk/app-release.apk`。

---

## ⚙️ 配置说明

### 自建接口模式

在设置页面中选择「自建接口」模式后，需配置：
- **接口地址** — 自建后端服务地址（如 `http://your-server:port`）
- **Token** — 接口鉴权 Token

调用的接口为 `POST /douyin/share_detail`，详见上方「自建接口」章节。

### 自建接口 V2 模式

选择「自建接口 V2」模式后，配置项与自建接口相同，但使用新版接口协议：
- 调用的接口为 `GET /api/hybrid/video_data?url=...`
- 返回原始抖音 API 数据，字段更完整
- 支持更精确的实况照片检测

### 本地解析模式

选择「本地解析」模式后，建议配置抖音 Cookie 以提高解析成功率：
1. 在浏览器中打开 [抖音网页版](https://www.douyin.com) 并登录
2. 打开开发者工具（F12），在 Network 标签页中复制任意请求的 Cookie
3. 在应用设置中粘贴 Cookie，或通过「从文件导入」功能导入 `.txt` / `.json` / `.cookie` 文件

---

## 📦 相关依赖

主要依赖列表（详见 `pubspec.yaml`）：

| 包名 | 版本 | 用途 |
|------|------|------|
| `http` | ^1.1.0 | 轻量 HTTP 请求（解析接口调用） |
| `dio` | ^5.4.0 | 高级 HTTP 客户端，支持下载进度 |
| `shared_preferences` | ^2.2.2 | 本地键值存储 |
| `path_provider` | ^2.1.1 | 系统路径获取 |
| `permission_handler` | ^11.0.1 | 运行时权限 |
| `device_info_plus` | ^9.1.0 | 设备信息获取 |
| `cached_network_image` | ^3.3.1 | 网络图片缓存 |
| `file_picker` | ^6.1.1 | 文件选择器 |
| `freezed_annotation` | ^2.4.1 | 数据模型注解 |
| `json_annotation` | ^4.8.1 | JSON 序列化注解 |

---

## 📄 License

本项目仅供学习交流使用，请勿用于商业用途。下载的内容版权归原作者所有。

---

© HACKFUN