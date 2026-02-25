# 📱 AI 智能录音机 APP - 产品需求与开发文档 (PRD)

## 1. 项目全局概述 (Project Context)
* **项目定位**：一款面向 Android 的高颜值 AI 录音机 APK。主打本地隐私保护、高质量录音、后台免费大模型转写与智能总结。
* **核心业务规则**：
  * **账号与存储**：必须有账号登录页面，但**所有数据纯本地存储**。本地数据库通过 User ID 隔离不同用户的数据。绝对不上传录音到任何私有云。
  * **AI 服务选型**：要求免费、开源、流畅。转写采用“录音完成后在后台自动转写”的机制。
* **推荐技术栈**：
  * **前端**：Flutter (最适合实现图中的声波动效和跨平台一致性) 或 React Native。
  * **本地数据库**：SQLite / Isar (Flutter) / WatermelonDB (RN)。
  * **状态管理**：Provider/Riverpod (Flutter) 或 Zustand (RN)。

## 2. 页面路由与 UI/UX 规范 (Routing & UI/UX)
**视觉风格**：现代卡片化设计。主色调为深紫蓝色（`#4C4DDC`），圆角大。
**页面路由结构**：
1. `LoginPage` (本地模拟登录/注册)
2. `MainTabScreen` (主界面，包含底部导航栏)
   - Tab 1: `RecordListScreen` (全部录音列表 - 原型图1)
   - Middle FAB: `RecordingScreen` (录音中界面，全屏覆盖 - 原型图5)
   - Tab 2: `SettingsScreen` (设置页 - 原型图4)
3. `RecordDetailScreen` (录音详情与播放页)
   - Sub-tab 1: `AISummaryView` (AI 总结 - 原型图2)
   - Sub-tab 2: `TranscriptView` (全文转写 - 原型图3)

## 3. 详细功能模块说明 (Feature Specifications)

### 3.1 本地账号模块 (Local Auth)
* **功能**：用户打开 APP 需要输入账号密码登录。
* **逻辑**：仅在本地 SQLite 验证和创建用户。后续的所有 `Records` 数据需关联当前登录的 `user_id`。

### 3.2 录音列表与搜索 (List & Search - 对应图1)
* **UI 布局**：亮色模式。顶部搜索框，下方卡片列表。底部导航栏中心有一个凸起的超大紫色麦克风 FAB。
* **卡片元素**：标题、时长（如 45:20）、日期时间、状态标签（`✨ 已生成AI总结` 或 `转写中...`）。
* **搜索增强**：输入关键词时，执行 `LIKE %keyword%` 查询。不仅匹配 `title`，还必须联表查询 `Transcript` 和 `Summary` 里的文本。

### 3.3 录音采集页 (Recording - 对应图5)
* **UI 布局**：沉浸式深色模式（Dark Mode）。顶部显示状态和降噪模式。中央超大计时器 + 实时动态声波柱状图。底部为操作栏：打点（左）、停止录音（中大红点）、暂停（右）。
* **业务逻辑（重要）**：
  * **打点标记**：点击“打点”记录当前时间戳到本地变量，转写完成后将标记合并到对应文本段落。
  * **前后台保活**：必须使用前台服务 (Foreground Service) 确保切出 APP 时录音不中断。
  * *注：原型图5中间有一个“声纹实时转写”的预览框。根据业务规则“录音结束后后台自动转写”，开发时此处可仅保留 UI 占位（显示：录音中...结束后将自动转写），或隐藏此框放大声波动效，以节省端侧性能。*
  * 点击“停止”后：保存 `.m4a/.wav` 文件，生成一条数据库记录，关闭当前页，触发后台转写队列。

### 3.4 录音详情与播放 (Playback & Details - 对应图2、图3)
* **顶部公共区域**：返回键、标题、更多菜单。
* **Tab 1: AI 总结 (图2)**：
  * 顶部横向滚动标签栏（Tag，如 `#产品规划`）。
  * 核心结论卡片：带绿色勾图标，无序列表展示。
  * 待办事项 (To-Do) 卡片：带橙色时钟图标，复选框展示（支持点击打勾保存状态）。
* **Tab 2: 全文转写 (图3)**：
  * 聊天记录式列表。
  * 每段包含：时间戳、声纹角色名（蓝色字体，支持点击重命名）、高亮标签（黄色背景的“手动打点”或紫色背景的“AI重点”）、转写文本。
* **底部公共播放器**：
  * 进度条。左侧：倍速切换（1.0x~2.0x）。中间：退15s、播放/暂停、进15s。右侧：打点。
  * **视听联动**：音频播放时，转写列表需自动滚动并高亮当前时间戳所在的句子。

### 3.5 设置与个性化 (Settings - 对应图4)
* **UI 布局**：亮色模式，卡片化分组。
* **多模式降噪**：单选列表（关闭、智能、深度）。修改后保存到本地 `SharedPreferences/MMKV`，作用于下一次录音。
* **自定义总结模板**：列表页。用户可新增模板，本质是自定义给 LLM 的 `Prompt` 前缀。
* **专属词库管理**：用户可添加专业名词标签，生成一个 `String[]`，在调用转写引擎时作为 `hotwords/prompt` 参数传入。

## 4. AI 技术落地指南 (AI Implementation Guide for Cursor)
由于要求“免费、开源”，在代码编写时请使用以下策略进行 API 封装和解耦：

* **后台音频转写引擎 (STT)**：
  * 优先推荐接入 **Groq API** (使用 `whisper-large-v3` 模型)，速度极快且目前有免费额度。或者使用开源的 **Whisper.cpp** 在端侧本地离线跑轻量级模型。
  * 需支持传入“专属词库”以提高准确率。
* **AI 总结引擎 (LLM)**：
  * 优先接入 **DeepSeek API** 或 **Kimi (月之暗面) API**。提供出色的中文长文本处理能力，且 API 调用成本极低/免费。
  * **Prompt 工程**：需将“全文转写内容” + “用户选定的自定义模板” 组装发给大模型，并要求返回严格的 **JSON 格式**（包含 `tags`, `conclusions`, `todos`），以便前端渲染图2的卡片。

## 5. 本地数据库表结构设计 (SQLite Schema Preview)
请根据以下结构生成相应的 ORM/Model 代码：

```sql
-- 用户表 (纯本地)
CREATE TABLE Users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE,
    password_hash TEXT
);

-- 录音主表
CREATE TABLE Records (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    title TEXT,
    file_path TEXT,
    duration INTEGER, -- 秒
    status TEXT, -- 'recording', 'transcribing', 'completed'
    created_at TIMESTAMP
);

-- 转写文本片段表
CREATE TABLE Transcripts (
    id TEXT PRIMARY KEY,
    record_id TEXT,
    speaker_name TEXT, -- 如 "发言人A"
    start_time INTEGER,
    end_time INTEGER,
    text_content TEXT,
    tag_type TEXT -- NULL, 'manual_mark', 'ai_keypoint'
);

-- AI总结表
CREATE TABLE AISummaries (
    id TEXT PRIMARY KEY,
    record_id TEXT,
    tags_json TEXT,       -- ["产品规划", "AI升级"]
    conclusions_json TEXT,-- ["确定Q3主推...", "增加投入..."]
    todos_json TEXT       -- [{"task": "设计部输出原型", "done": false}]
);

-- 词库表
CREATE TABLE Vocabularies (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    word TEXT
);