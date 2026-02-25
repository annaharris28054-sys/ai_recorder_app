

# 🛠️ 纯本地 AI 智能录音机 - 技术架构与开发文档 (Flutter)

## 1. 架构原则 (Architecture Principles)

* **100% 离线运行 (Offline-First)**：无后端 API，不产生任何网络请求（除了首次下载 AI 模型文件）。
* **极简组件流 (Component-Driven)**：严禁手搓底层音频处理或大模型推理代码，必须调用指定的 `pub.dev` 成熟包。
* **端侧性能优先 (Performance)**：AI 模型必须采用量化版本（GGML/GGUF 格式），并在独立 Isolate（子线程）中运行，防止 UI 卡顿。

## 2. 核心技术栈与包名指定 (Tech Stack & Packages)

请在 `pubspec.yaml` 中严格使用以下成熟的开源依赖库：

### 2.1 基础框架与 UI

* **框架**：Flutter (SDK >= 3.19), 启用 Material 3。
* **状态管理**：`provider` (最成熟稳定，Cursor 生成代码准确率最高) 或 `flutter_riverpod`。
* **路由**：`go_router` (处理页面跳转和传参)。
* **图标与样式**：`cupertino_icons`, 使用 Flutter 自带的 `ThemeData` 配置颜色。

### 2.2 本地数据与文件存储

* **本地数据库**：`isar` 和 `isar_flutter_libs`。
* *理由*：极其极速的本地 NoSQL 数据库，完美支持全文搜索（全文检索转写内容的需求），远比 SQLite/sqflite 好用，且无需手写 SQL 语句。


* **本地 KV 存储**：`shared_preferences` (用于存储降噪设置、用户模板)。
* **文件路径管理**：`path_provider` (获取手机本地应用沙盒目录，存储录音和大模型文件)。

### 2.3 核心业务：录音与播放

* **录音引擎**：`record`
* *理由*：支持后台录音，支持直接输出 `.m4a` 或 `.wav`，支持实时输出音频振幅（Amplitude）数据供 UI 画图。


* **音频播放**：`audioplayers`
* *理由*：成熟稳定，支持倍速播放（0.5x - 2.0x）、快进快退。


* **声波动效 UI**：`audio_waveforms`
* *理由*：开箱即用的可视化录音/播放波形图 UI 组件，无需手绘 Canvas。



### 2.4 核心业务：端侧 AI 引擎 (重点)

* **本地语音转文字 (STT)**：`whisper_flutter_plus` 或 `whisper_dart`
* *底层*：基于开源的 `whisper.cpp`。
* *模型要求*：在应用初始化时，需加载量化版本的 whisper 模型（推荐使用 `ggml-tiny.bin` 或 `ggml-base.bin`，体积在 70MB~140MB 左右，兼顾速度与准确率）。


* **本地大语言模型总结 (LLM)**：`fllama` 或 `smuggle` (Llama.cpp 的 Flutter 绑定)
* *底层*：基于开源的 `llama.cpp`。
* *模型要求*：使用极端量化的小模型，推荐阿里 **Qwen2-1.5B-Instruct-GGUF** (Q4_K_M 量化版，体积约 1.1GB) 或 **Gemma-2B-GGUF**。将转写出的文本作为 Prompt 输入，让其输出 JSON 总结。



---

## 3. 本地业务逻辑流 (Data Flow)

请 Cursor 在编写业务逻辑时，遵循以下流水线（Pipeline）：

### 环节 A：录音与打点

1. 用户点击大麦克风按钮。
2. 调用 `record` 包开始录音，保存路径为 `path_provider` 提供的应用文档目录。
3. UI 监听 `record` 的 Stream，将振幅传给 `audio_waveforms` 渲染波形。
4. 用户点击“打点”，将当前 `duration` 时间戳记录到内存 List 中。
5. 结束录音，生成 `RecordItem` 对象保存至 `isar` 数据库。

### 环节 B：离线转写 (Isolate 子线程处理)

1. 录音结束后，启动一个 Flutter Isolate（避免主线程卡死）。
2. 将录音文件路径传给 `whisper_flutter_plus` 进行推理。
3. 引擎返回带有时间戳的片段（Segments）。
4. 将内存中的“打点”时间与片段比对，生成带有标记的 `TranscriptItem` 列表。
5. 批量存入 `isar` 数据库，并更新主记录状态为“转写完成”。

### 环节 C：离线 AI 总结

1. 转写完成后，拼接全部转写文本。
2. 构造 Prompt：`"根据以下内容生成总结，必须以严格的JSON格式返回，包含tags, conclusions, todos字段：\n\n[转写文本]"`。
3. 调用 `fllama` 加载本地 GGUF 模型进行推理。
4. 解析 LLM 返回的 JSON 字符串，存入 `isar` 数据库的 `AISummaries` 集合中。
5. 通知 UI 刷新（状态变为：已生成 AI 总结）。

---

## 4. 给 Cursor 的分步开发指令 (Cursor Prompts)

**为了避免 Cursor 一次性写太多导致混乱，请按以下阶段向 Cursor 发送 Prompt：**

* **Phase 1: 基础设施搭建**
> "请读取 `Tech_Architecture.md`。帮我初始化一个 Flutter 项目。配置好 `pubspec.yaml` 中的依赖（包括 isar, record, audioplayers, provider 等）。然后创建 `isar` 的 Collections 数据模型（RecordItem, TranscriptItem, SummaryItem），并生成 `.g.dart` 文件。最后搭建好基本的路由和主页底部的导航栏UI。"


* **Phase 2: 录音与波形 UI**
> "请实现 `RecordingScreen`。使用 `record` 包实现后台录音功能，录音文件保存到本地。使用 `audio_waveforms` 实现中间的动态声波。包含底部的打点、暂停、完成按钮。完成录音后，将基础信息存入 Isar 数据库并返回主页。"


* **Phase 3: 本地 STT 集成**
> "引入 `whisper_flutter_plus`。写一个后台服务类 `LocalAIEngine`。当录音完成后，调用该类的转写方法。请确保转写操作在隔离的 Isolate 中运行，并监听进度。转写结果分段存入 Isar 数据库的 Transcript 集合。"


* **Phase 4: 本地 LLM 与 详情页 UI**
> "根据 `UI_Design_System.md` 中的设计，实现 `RecordDetailScreen`。包含顶部的双 Tab（AI总结 / 全文转写）。实现底部的播放器控制器（关联 `audioplayers`）。最后，集成本地 LLM 库处理转写文本，生成总结并渲染到 UI 的卡片上。"



