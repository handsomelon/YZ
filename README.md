# YZ

**把你的技术，变成一个能持续获客的生意。**

YZ 是一个原生 macOS 工作台，给做 3D / CG 技术支持的人用：Blender、UE、Godot 的建模师、绑定师、渲染工程师、插件作者。它每天帮你把散落在 GitHub Issue 和各个 CG 社区里的**真实需求**捞出来，用你本机的 AI 起草一份够专业的诊断，你审一遍，去原帖亲自答。

答得多了，你在这个圈子里就有了名字。有人私信你，有人找你做项目——**单是自己来的**。

> Apple silicon · macOS 14+ · 本机运行 · 数据不出你的电脑
> [下载 v0.4.0](https://github.com/handsomelon/YZ/releases/latest) · [完整安装说明](docs/releases/v0.4.0.md)

---

## 为什么需要它

靠技术吃饭的人，最难的不是技术，是**让别人知道你行**。

- 你去社区答疑，是最有效的获客方式——帮人解决问题，别人记住了你。但这条路的成本全在「找题、读题、查版本、写回复」上，一天认真答三个就是极限。
- 渠道又太碎：GitHub、Blender Artists、Blender 开发者论坛、UE 论坛、Godot 论坛、Reddit、Discord、小红书、B站……每个都要刷，刷完还记不住哪条答过。
- 最亏的是：**答完就散了**。你付出的判断力没有沉淀，下次遇到同类问题还得从头想。

结果就是——你的技术很好，但传播面只有身边几个人。

YZ 把这三件事一起解决：**把题找齐、把答案备好、把过程留底。**

---

## 赚钱路径：一条漏斗，五个环节

这不是"AI 自动发广告拉客"。真实的路径是这样，每一步都标了现在是什么状态：

| # | 环节 | 谁来做 | 现状 |
| --- | --- | --- | --- |
| 01 | **捞需求** — 从 22 个渠道收进真实提问 | YZ 自动 | ✅ 已接 |
| 02 | **筛价值** — 判断这条值不值得答、能不能答 | 你看一眼 | ✅ 已接 |
| 03 | **备弹药** — AI 起草诊断：缺失信息、复现路径、核验项、回复草稿 | YZ 自动 | ✅ 已接（需模型网关） |
| 04 | **真人答** — 审完，你去原帖发 | 你 | ✅ 已接（人工发布） |
| 05 | **收信任** — 变成私信、加好友、接单、卖服务或课程 | 你 | 🚧 商品与收款渠道已登记，成交在平台侧 |

**关键在 01–03 的提速。** 原来找一道题 + 想清楚怎么答要 20 分钟，现在压到几分钟。同样一天，你能覆盖的题量翻几倍——**传播面就是这么扩大的**，靠的是量变引起的质变，不是刷屏。

第 05 步的转化不在 App 里发生，也不该在 App 里发生。技术人的信任只能用真解答换，YZ 帮你把前面铺好，最后那步得你自己走。

---

## 四个页面，对应漏斗的每一环

### 问题收件箱 → 捞需求 + 筛价值

顶部填 `owner/repo` 和关键词，点「扫描 GitHub」，命中的 Issue 自动变成工单入账：

```
owner/repo: KhronosGroup/glTF-Blender-IO      ← 默认值，可换成任何公开仓库
关键词:     export, material, rigging
```

自动跳过 Pull Request。社区帖不能直接扫，粘链接存进来。选中工单，右侧看原帖正文 + 活动记录 + 草稿 + 审核状态，一眼判断值不值得答。

### 来源与登录 → 22 个获客渠道

内置来源分四组，每个都有「打开站点」和「登录」入口，走系统浏览器：

| 分组 | 数量 | 覆盖 |
| --- | --- | --- |
| 项目与技术社区 | 8 | GitHub Issue 扫描；Blender Artists / Blender 开发者论坛 / UE Character & Animation / UE Question / Godot 论坛五路公开 RSS |
| 国内社区与视频 | 5 | 小红书、百度贴吧、B站、抖音、视频号 |
| 国际视频与社区 | 3 | YouTube、Reddit、Discord |
| 商品与收款 | 6 | Patreon、Payhip、Fab、Superhive、微信支付、支付宝商家 |

点「扫描公开社区」手动扫五路 RSS：最近 14 天 + CG 技术关键词，每路最多 5 条候选，UE 两路按站点主题 ID 去重。每个源这次读到几条、匹配几条、错在哪，都直说——**不假装成功**。

### 执行管线 → 全流程跟踪

五道工序按工单推进：01 来源与进件 ✅ / 02 DSH 诊断 ✅ / 03 精神 APP·Blender（启动入口就绪，派单待接 🚧）/ 04 尺度 APP·视频（同上 🚧）/ 05 审核与回复 ✅。

03/04 是给已安装的 `jingshen.app` 和 `chidu.app` 的跳转入口，一键开工。

### 模型与设置 → 接上你的 AI

填网关地址、模型 ID、API Key，密钥存进 **macOS 钥匙串**，不落明文文件。任何兼容 Chat Completions 的网关都行。

想用 DSH 对话桥的七个工具，就在这里也能一键「检查本机 DSH」。登记 `project-repo.json` 后还会显示项目仓库和发布页入口。

---

## 用 AI 把答案备到「几乎能直接发」

这是 YZ 和「收藏夹 + 待办清单」的根本区别。点一条工单生成草稿，AI 输出四块：

1. **缺失信息** — 提问者没给版本号、没给文件、没给报错原文，该问什么
2. **最小复现建议** — 怎么用最少步骤把问题稳定复现
3. **人工核验项** — 哪些结论未经复现，必须你自己验证，不许猜
4. **社区回复草稿** — 与提问者语言一致，可以直接改改就发

第 3 条是这套提示词里最关键的：它**明确要求对未复现的结论标注出来**。技术圈最掉信誉的事就是 AI 一本正经胡说，YZ 的设计假设是"帮你组织，不替你断言"。

---

## 和 DSH 对话桥配合：躺在对话里干活

工作台核心以插件形式挂进 DeepSeek Harness（`dsh-plugin/index.mjs`），在 DSH 对话里直接操作工单账本：

| 工具 | 作用 |
| --- | --- |
| `yz_status` | 应用与值守状态 |
| `yz_scan` | 扫描指定公开仓库 Issue |
| `yz_community_scan` | 扫五路社区 RSS，按题号去重 |
| `yz_list` / `yz_read` | 列最近工单 / 读单条工单 |
| `yz_save_draft` | 把当前会话的诊断存成待审草稿（**不发布**） |
| `yz_release_status` | 查已登记仓库的最近版本（只读） |

对话里说「扫一下 glTF 导出相关的 Issue」「把这条诊断存成草稿」，它就去干。配置里 `watch: true` 让 DSH 开着的时候每 15 分钟自动巡检一次，YZ 界面每 30 秒刷新。

> 注意：DSH 是本地 AI 框架，不是云托管平台。**YZ 的数据不上云**，`dsh-plugin/index.mjs` 跑在你自己的 DSH 里，用的是你选的模型。

---

## 下载与安装

Apple silicon Mac（M 系列），macOS 14 或更高。

```bash
curl -LO https://github.com/handsomelon/YZ/releases/download/v0.4.0/YZ-0.4.0-macOS-arm64.zip
curl -LO https://github.com/handsomelon/YZ/releases/download/v0.4.0/YZ-0.4.0-macOS-arm64.zip.sha256
shasum -a 256 -c YZ-0.4.0-macOS-arm64.zip.sha256   # 必须看到 OK
unzip YZ-0.4.0-macOS-arm64.zip && mv YZ.app /Applications/
open /Applications/YZ.app
```

也可以直接双击 zip、把 `YZ.app` 拖进「应用程序」。

**首次打开会被 Gatekeeper 拦一次**（包里是 ad-hoc 签名、没做公证，`spctl` 会判 `rejected`）。这是预期行为，不是文件坏了——先做上面的 SHA-256 校验确认包完整，然后：

- 去「系统设置 → 隐私与安全性」，页面下方点 **仍要打开**；或
- 已校验过包的话：`xattr -dr com.apple.quarantine /Applications/YZ.app`

**运行前提**：系统 `python3`（`xcode-select --install` 即可，不用完整 Xcode）；生成 AI 草稿额外需要 `dsh 0.2.1-rc.5` 和一个兼容 Chat Completions 的模型网关。

> 详细版说明（每页操作、命令行、数据位置、卸载）见 [docs/releases/v0.4.0.md](docs/releases/v0.4.0.md)。

---

## 它明确不做什么

这一节比功能列表重要。YZ 的边界是刻意画死的：

- ❌ **不自动发帖、不自动回复、不群发私信。** 代码里对外的网络请求只有只读 GET（GitHub API 和 RSS），没有任何写接口。答案永远由你亲手发。
- ❌ **不抓登录态。** 需要登录的站，YZ 只给你一个跳转链接，用系统浏览器自己登。
- ❌ **不上传你的数据。** 工单是本机 SQLite，密钥在系统钥匙串，模型调用直连你配的网关。
- ❌ **不替你下结论。** 草稿里的未复现项要求标注，最终判断在你这。
- ❌ **不承诺收入。** 它省的是找题和写作的时间，能不能接到单取决于你的答案质量。

反过来说——**正因为不刷屏，你的号才不会被封，你的名字才值钱。**

---

## 数据放在哪

| 内容 | 位置 |
| --- | --- |
| 工单账本 | `~/Library/Application Support/yizhi/tickets.sqlite3` |
| 值守状态 / 项目登记 | 同目录 `github-watch.json`、`project-repo.json` |
| 草稿运行临时目录 | 同目录 `runtime/`（用完即删） |
| 模型 API Key | macOS 钥匙串（`com.cova.yizhi`） |
| 自定义链接、网关地址 | 应用偏好设置 |

bundle ID 沿用 `com.cova.yizhi`，覆盖安装不丢工单和偏好。升级前备份整个 `yizhi` 目录最稳。模型 API 出错只落一条通用诊断，不把请求内容写进数据库。

---

## 源码结构

```
YZ.swift                       SwiftUI 界面（四页 + 钥匙串）
workbench.py                   工单核心：进件、扫描、SQLite、AI 草稿
sources.json                   来源目录（4 组 22 个站点）
dsh-plugin/index.mjs           DSH 对话桥插件（七个工具 + 值守轮询）
build.sh                       本机构建
scripts/package-release.sh     发布包打包与校验
.github/workflows/release.yml  推版本号到 main 自动发布
tests/                         会话桥集成测试、样例 Issue
docs/releases/                 各版本说明
```

需要 Xcode Command Line Tools：

```bash
git clone https://github.com/handsomelon/YZ.git && cd YZ
bash build.sh                     # → build/YZ.app，本机签名并校验
bash scripts/package-release.sh   # 打 zip + 架构/语法检查 + SHA-256
python3 tests/test_dsh_session.py # 会话桥集成测试（真实工具循环 + 模拟模型）
```

发布流程：改 `Info.plist` 的 `CFBundleShortVersionString` 并递增 `CFBundleVersion`，推到 `main`，GitHub Actions 自动构建发布。普通提交不触发。

---

## 当前限制（v0.4.0）

1. **未公证** — 首次打开需手动放行一次（见上）。
2. **仅 Apple silicon** — 发布资产是 `arm64` 单架构，Intel Mac 不能跑。
3. **写回未接** — 本版是只读进件 + 本地审核，不做自动回复。要做自有项目的自动写回，需按项目授权启用独立适配器。
4. **DSH 版本钉死** — 草稿生成校验 `dsh 0.2.1-rc.5`，其他版本明确报错，不静默降级。
5. **03 / 04 工序未接** — 精神和尺度只有启动入口，派单链路待接。
6. **国内渠道手动** — 小红书、B站、抖音等没有公开 API，靠手动收件 + 保存原帖链接。

---

## 许可证

当前仓库未附许可证文件，默认保留所有权利。计划中的版本会补上开源许可证。
