# YZ 0.4.0

YZ 是原生 macOS CG 工作台。源码包包含 SwiftUI 界面、Python 工单核心、来源目录、图标和构建脚本。

**安装包下载**：[Releases · v0.4.0](https://github.com/handsomelon/YZ/releases/tag/v0.4.0)（Apple silicon · macOS 14+ · ad-hoc 签名，未公证）。下载、安装、首次放行、使用说明与已知限制见 [`docs/releases/v0.4.0.md`](docs/releases/v0.4.0.md)。

在装有 Xcode Command Line Tools 的 Mac 上运行 `bash build.sh`，生成 `build/YZ.app` 并做本机临时签名。运行需要 PATH 上的 Python 3。生成诊断草稿还需要 `dsh 0.2.1-rc.5`，以及兼容流式 Chat Completions 的模型网关。模型设置页用 macOS 钥匙串保存密钥。

应用默认扫描 Blender glTF 导出库。你也可以输入其他公开 GitHub 仓库，或者粘贴原帖链接。GitHub Issue 可以进入工单，其他站点的链接保存在本机的原帖清单。来源页用默认浏览器打开站点与登录入口。登录是否保留取决于浏览器的会话和平台登录策略。执行页可以打开已安装的精神和尺度，生产工序在后续接入。

YZ 沿用原安装的 macOS bundle ID、钥匙串和本地数据目录，以保留工单和偏好。工单 SQLite 位于 `~/Library/Application Support/yizhi/`。自定义链接和网关地址存放在应用偏好设置中。把工作台从一个版本更新到另一个版本时，可先保留这两部分数据。

本版为手动触发的公开只读进件和本地审核。部署自有项目的写回或常驻连接器时，按项目授权并启用独立适配器。


## DSH 对话桥

日常 DSH Desktop 配置已挂载 `dsh-plugin/index.mjs`。对话模型可用 `yz_status`、`yz_scan`、`yz_list`、`yz_read`、`yz_save_draft`、`yz_release_status`。它们使用已安装应用的工作台核心和同一份本机数据库。直接用 DSH 对话保存草稿时使用该会话已经选择的模型，App 无需再配置一把模型密钥。

配置中的 `watch: true` 让本地 DeepSeek Harness 桌面应用在打开期间每 15 分钟轮询公开 GitHub 议题，以及 Blender Artists、Blender 开发者论坛、UE Character & Animation、UE Question 和 Godot 的五路 RSS。YZ 每 30 秒刷新本机工单和上次扫描状态。工作台部署仅使用本地桌面 DSH。

在安装 YZ 0.4.0 后，`python3 tests/test_dsh_session.py` 使用 DSH 真实的会话工具循环和本机模拟模型，验证草稿保存到隔离 SQLite。


## 社区来源

桌面 DSH 工具 `yz_community_scan` 支持按来源或全部扫描。APP 的「来源与登录」提供手动扫描按钮，并展示各源读取、匹配和错误状态。社区主题和 GitHub 议题使用同一份 SQLite 工单账本，UE 的两个订阅按同一站点主题 ID 去重。自动筛选使用最近 14 天的 RSS 条目和 CG 技术关键词，每路最多纳入 5 条候选。候选是否仍需帮助由人工看原帖确认，回复从原帖人工发布。


## 自动发布

修改 `Info.plist` 的 `CFBundleShortVersionString`（例如 `0.4.1`），同时递增 `CFBundleVersion`，把版本提交推到 `main`。GitHub Actions 编译 Apple silicon macOS ZIP，生成 SHA-256 校验文件，并发布对应版本。普通开发提交不会发布。已有正式版本会跳过，构建失败可重跑同版本。发布包采用临时签名，适合私有测试，公开分发需要 Developer ID 签名和公证。

本地 DSH 可以参与项目准备，发布由仓库工作流完成。YZ「模型与设置」显示项目仓库和 Releases 入口（在本地账本目录登记 `project-repo.json` 后）。
