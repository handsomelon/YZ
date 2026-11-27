# 一起做 YZ

YZ 是**源码开放**项目。谁都可以看、可以改、可以免费使用、可以用它去挣钱。**但不能把它本身包装起来卖。**

这个项目自己也是站在别人肩上：SwiftUI、Python 标准库、Node.js 内置模块，以及 [DeepSeek Harness](https://deepseek.com) 的插件体系。所以没什么好藏着掖着的。**一起把工具做好，各自靠手艺去挣钱。**

---

## 你现在就能做的四件事

### 1. 直接用，不用问

fork 走、改成自己的版本，**不需要通知我，也不需要给我分钱**。

只有一条别踩：**别把这个软件本身包装起来卖**（换名字、换图标、塞进付费课、挂网盘卖都算）。这不是防你挣钱——用它接单、做咨询、开课收费都可以——是防有人拿免费的东西去骗不懂的人。详见 [LICENSE](LICENSE)。

```bash
git clone https://github.com/handsomelon/YZ.git
```

如果你做出来的东西对别人也有用，欢迎推回来。不回也没关系。

### 2. 提想法 —— 零门槛

不需要会写代码。**"我希望它能……"就是一条有效的问题。**

[开一条 Issue](https://github.com/handsomelon/YZ/issues/new) 说清楚三件事就够了：

- 你在做什么（Blender 绑定？UE 动画？Godot 导出？）
- 你卡在哪 / 缺什么
- 你希望它怎么帮你

好点子会被直接做进主版本。**提需求的人和写代码的人一样重要。**

### 3. 改代码 —— 提 PR

```bash
# 1. fork 后克隆
git clone https://github.com/<你的用户名>/YZ.git && cd YZ

# 2. 从 main 拉分支，名字说清楚做什么
git checkout -b fix/rss-timeout

# 3. 改，然后本机跑通（见下）
bash build.sh
python3 tests/test_dsh_session.py

# 4. 提交并推
git commit -m "Fix RSS timeout on slow feeds"
git push origin fix/rss-timeout
```

然后去 GitHub 开 Pull Request。

**PR 的验收标准就三条**，不看你写得多漂亮：

1. **能跑。** `bash build.sh` 出包成功；动了 `workbench.py` 就跑 `python3 tests/test_dsh_session.py`。
2. **不越界。** 不新增对外的写操作（发帖、回复、私信）。这是项目的底线，见下。
3. **说明白。** PR 描述里写清：改了什么、为什么、怎么验证的。

小改动（错字、日志、超时）直接提。大改动（新页面、新数据表、换架构）**先开 Issue 聊一版**，别写完才说。

### 4. 不用等审核 —— 直接开自己的分支版本

不想等、想法和我不同、或者你想做个完全不同的方向？

**直接 fork，随便改，自己发版。** 你的仓库你做主，不用说服任何人。这是源码开放的意思，不是客套话。

常见做法：

- **跟进主版本**：`git remote add upstream https://github.com/handsomelon/YZ.git`，然后 `git pull upstream main`
- **只拿自己要的部分**：复制 `workbench.py` 或 `dsh-plugin/index.mjs` 到自己项目，保留版权声明即可（同样不能拿去当商品卖）
- **做发行版**：改 `Info.plist` 的 bundle ID 和 `CFBundleShortVersionString`，跑 `scripts/package-release.sh`，发你自己的 Release

---

## 本机开发环境

只需要 macOS + Xcode Command Line Tools，**没有第三方依赖**（Python 只用标准库，Node 只用内置模块，Swift 只用系统框架）。

```bash
xcode-select --install     # 一次就够

bash build.sh                     # → build/YZ.app
bash scripts/package-release.sh   # → 打 zip + 校验 + SHA-256
python3 tests/test_dsh_session.py # 会话桥集成测试
```

改了 DSH 插件后要同步到本机才会生效：

```bash
cp dsh-plugin/index.mjs ~/Library/Application\ Support/yizhi/dsh/yz-workbench-v4.mjs
```

---

## 硬底线：不写自动发帖

有一种贡献一定不会合进来 —— **任何形式的自动发帖、自动回复、批量私信、刷量。**

不是技术上做不到，是这个项目的前提就是**不做**。YZ 存在的理由是"帮技术人把真解答做得更快更多"，一旦开始刷屏：

- 提问者的社区被污染
- 使用者的账号被封
- 整个工具变成垃圾

代码里对外的请求只有只读 GET（GitHub API + RSS），这条线会一直守住。想加"自动投放广告"的 PR 请直接 fork 走，别提到这里。

---

## 免费学，自愿支持

这个项目走的是**先免费学到东西，觉得值再支持**的路子。

### 免费的部分（永远免费，许可证保证）

- 全部源码，完整功能
- 说明书、发布包、构建脚本
- Issue 里提问题，有人答

许可证里明确写了：**已发布的版本永远适用发布时的条款，不会追溯变更。** 就算哪天我想做收费版，你今天拿到的这一版，以及按它分发的副本，照样能一直用下去。

### 自愿支持的部分

如果 YZ 帮你接到了第一单，或者省下了几个下午，可以支持一下。**不支持也完全不影响使用，一毛钱功能都不会少。**

支持方式（后续版本会补上正式入口）：

- 在 Issue 里帮别人答问题 —— 这是最有价值的支持
- 提 PR、写文档、做个教程
- 或者直接赞助（入口待定，会在这里和 App 的「模型与设置」页公布）

> 说实话：我更希望你在社区里把技术练出来、自己接单挣到钱，然后回来提个 PR。那比打赏有用得多。

---

## 关于「我是来学的」

如果你是想入行的新人：**这个仓库就是给你看的。**

- `workbench.py` 452 行，是一个完整可读的「网络进件 + SQLite 账本 + 子进程调 AI」样本
- `YZ.swift` 509 行，SwiftUI 四个页面的完整写法，含钥匙串
- `dsh-plugin/index.mjs` 是个真实可用的 AI 工具插件，七个工具怎么写一目了然

不用怕改坏什么。fork 一份，随便玩。

---

## 行为准则

就一条：**对事不对人。** 技术争论欢迎，人身攻击、广告刷屏、歧视性言论直接删。

---

*YZ 源码开放许可证 · 见 [LICENSE](LICENSE)*
