import AppKit
import Combine
import Security
import SwiftUI

struct Ticket: Identifiable, Decodable {
    let id: Int
    let project, repo, status, title: String
    let issue_number: Int
    let source_url, body, draft, error: String?
    let activity: [Activity]?
    var stage: String {
        ["pending": "待诊断", "running": "运行中", "failed": "运行失败", "draft": "待审核", "reviewed": "已审核"][status] ?? status
    }
}
struct Activity: Decodable { let action, at: String }
struct SavedLink: Identifiable, Codable { var id = UUID(); let url, title: String }

enum Runner {
    static let state = URL.applicationSupportDirectory.appending(path: "yizhi", directoryHint: .isDirectory)
    static func run(_ arguments: [String], model: [String: String] = [:], stateFolder: URL = state) throws -> String {
        guard let script = Bundle.main.url(forResource: "workbench", withExtension: "py") else {
            throw NSError(domain: "yizhi", code: 1, userInfo: [NSLocalizedDescriptionKey: "缺少工作台运行组件"])
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["python3", script.path, "--state", stateFolder.path] + arguments
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        for (key, value) in model { environment[key] = value }
        task.environment = environment
        let output = Pipe()
        task.standardOutput = output
        task.standardError = output
        try task.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        let message = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        if task.terminationStatus != 0 {
            throw NSError(domain: "yizhi", code: Int(task.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "操作失败" : message])
        }
        return message
    }
    static func decode<T: Decodable>(_ type: T.Type, _ data: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(data.utf8))
    }
}

enum ModelKey {
    static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.cova.yizhi.model", kSecAttrAccount as String: "gateway"]
    }
    static func read() -> String {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var data: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &data) == errSecSuccess, let bytes = data as? Data else { return "" }
        return String(decoding: bytes, as: UTF8.self)
    }
    static func save(_ key: String) throws {
        let bytes = Data(key.utf8)
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: bytes] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = bytes
            status = SecItemAdd(item as CFDictionary, nil)
        }
        if status != errSecSuccess {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }
}

enum Page: String, CaseIterable, Identifiable {
    case inbox = "问题收件箱", sources = "来源与登录", pipelines = "执行管线", settings = "模型与设置"
    var id: Self { self }
    var icon: String {
        switch self {
        case .inbox: "tray"; case .sources: "globe"; case .pipelines: "point.3.connected.trianglepath.dotted"; case .settings: "slider.horizontal.3"
        }
    }
}

@main struct YZ: App {
    init() {
        NSApplication.shared.applicationIconImage = Bundle.main.url(forResource: "AppIcon", withExtension: "icns").flatMap { NSImage(contentsOf: $0) }
    }
    var body: some Scene {
        WindowGroup("YZ") { Workspace().frame(minWidth: 940, minHeight: 625) }
            .defaultSize(width: 1160, height: 740)
    }
}

struct Workspace: View {
    @State private var page: Page? = .inbox
    @State private var tickets: [Ticket] = []
    @State private var selection: Int?
    @State private var detail: Ticket?
    @State private var repo = "KhronosGroup/glTF-Blender-IO"
    @State private var terms = "export, material"
    @State private var entry = ""
    @State private var note = "准备就绪"
    @State private var busy = false
    @State private var stored: [SavedLink] = []
    @State private var modelKey = ""
    @State private var projectRepository: String?
    @State private var feedStates: [WatchState.Feed] = []
    @State private var watchSummary = "等待 DSH 对话桥上线"
    private let refresh = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @AppStorage("gatewayURL") private var gatewayURL = ""
    @AppStorage("gatewayModel") private var gatewayModel = ""
    let sources: [[String]] = {
        guard let url = Bundle.main.url(forResource: "sources", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([[String]].self, from: data) else { return [] }
        return rows
    }()

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: "viewfinder").foregroundStyle(.mint).font(.title2)
                    Text("YZ").font(.system(size: 26, weight: .semibold, design: .monospaced))
                }.padding(.horizontal, 16).padding(.top, 18)
                List(Page.allCases, selection: $page) { item in
                    Label(item.rawValue, systemImage: item.icon).tag(item)
                }.listStyle(.sidebar)
                Text("本机工作台").font(.caption).foregroundStyle(.secondary).padding(16)
            }.navigationSplitViewColumnWidth(194)
        } detail: {
            VStack(alignment: .leading, spacing: 0) {
                switch page ?? .inbox {
                case .inbox: inbox
                case .sources: directory
                case .pipelines: pipelines
                case .settings: settings
                }
                Divider()
                HStack {
                    if busy { ProgressView().controlSize(.small) }
                    Text(note).lineLimit(2).textSelection(.enabled)
                    Spacer()
                }.font(.caption).foregroundStyle(.secondary).padding(12)
            }
        }
        .tint(.mint)
        .task {
            if let data = UserDefaults.standard.data(forKey: "savedLinks") {
                stored = (try? JSONDecoder().decode([SavedLink].self, from: data)) ?? []
            }
            await reload()
            reloadWatch()
        }
        .onReceive(refresh) { _ in
            guard !busy else { return }
            reloadWatch()
            Task { await reload(); await select(selection) }
        }
        .onChange(of: selection) { _, newValue in
            Task { await select(newValue) }
        }
    }

    func title(_ name: String, _ info: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name).font(.largeTitle.weight(.semibold))
            Text(info).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    var inbox: some View {
        VStack(alignment: .leading, spacing: 16) {
            title("问题收件箱", "扫描公开 GitHub Issue，或保存其他社区的原帖。")
            HStack {
                TextField("owner/repo", text: $repo)
                TextField("关键词，用逗号分隔", text: $terms)
                Button("扫描 GitHub") { scan() }.buttonStyle(.borderedProminent).disabled(busy)
            }
            Text(watchSummary).font(.caption).foregroundStyle(.secondary)
            HStack {
                TextField("粘贴问题链接", text: $entry).onSubmit { importLink() }
                Button("收件") { importLink() }.disabled(busy)
            }
            Divider()
            HSplitView {
                List(selection: $selection) {
                    Section("工单 · \(tickets.count)") {
                        ForEach(tickets) { ticket in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(ticket.title).lineLimit(2).fontWeight(.medium)
                                Text("\(ticket.repo) · #\(ticket.issue_number) · \(ticket.stage)").font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical, 4).tag(ticket.id)
                        }
                    }
                    if !stored.isEmpty {
                        Section("保存的原帖 · \(stored.count)") {
                            ForEach(stored) { item in
                                if let url = URL(string: item.url) {
                                    HStack {
                                        Link(item.title, destination: url).lineLimit(2)
                                        Spacer()
                                        Button { removeLink(item.id) } label: { Image(systemName: "minus.circle") }
                                            .buttonStyle(.plain).help("移除链接")
                                    }
                                }
                            }
                        }
                    }
                }.frame(minWidth: 250, idealWidth: 310)
                if let ticket = detail, ticket.id == selection { ticketView(ticket) }
                else {
                    ContentUnavailableView("选择工单", systemImage: "tray",
                                           description: Text("工单详情会显示原帖、DSH 草稿和审核状态。"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }.padding(22)
    }
    func ticketView(_ ticket: Ticket) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(ticket.stage).font(.caption).foregroundStyle(.secondary)
                Text(ticket.title).font(.title2.bold()).textSelection(.enabled)
                HStack {
                    if let raw = ticket.source_url, let url = URL(string: raw) { Link("打开原帖", destination: url) }
                    Spacer()
                    if ["pending", "failed", "running"].contains(ticket.status) {
                        Button("生成诊断草稿") { draft(ticket.id) }.disabled(busy)
                    }
                    if ticket.status == "draft" {
                        Button("标记已审核") { apply(["review", String(ticket.id)], note: "已记录本地审核") }.disabled(busy)
                    }
                }
                if let error = ticket.error { Text(error).foregroundStyle(.orange) }
                if let body = ticket.body, !body.isEmpty {
                    GroupBox("问题正文") { Text(body).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
                }
                if let draft = ticket.draft {
                    GroupBox("DSH 草稿") {
                        Text(draft).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                    }
                }
                if let events = ticket.activity, !events.isEmpty {
                    GroupBox("活动记录") {
                        VStack(alignment: .leading) {
                            ForEach(events.indices, id: \.self) { index in
                                Text("\(events[index].at) UTC · \(events[index].action)").font(.caption)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding(14)
        }.frame(minWidth: 410)
    }
    var directory: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                title("来源与登录", "使用系统默认浏览器。登录状态由浏览器和平台管理。")
                HStack {
                    Button("扫描公开社区") { apply(["community-scan", "all"]) }.buttonStyle(.borderedProminent).disabled(busy)
                    Text("Blender、UE 与 Godot").foregroundStyle(.secondary)
                }
                if !feedStates.isEmpty {
                    GroupBox("社区值守") {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(feedStates, id: \.source) { state in
                                Text(state.label + " · " + (state.error ?? "读取 " + String(state.read ?? 0) + " 条，匹配 " + String(state.matched ?? 0) + " 条"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }.padding(5)
                    }
                }
                ForEach(Array(Set(sources.map { $0[1] })).sorted(), id: \.self) { group in
                    GroupBox(group) {
                        VStack(spacing: 0) {
                            ForEach(sources.filter { $0[1] == group }, id: \.first) { site in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(site[0]).fontWeight(.medium)
                                        Text(site[4]).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let url = URL(string: site[2]) { Link("打开站点", destination: url) }
                                    if let url = URL(string: site[3]) { Link("登录或后台", destination: url).padding(.leading, 12) }
                                }.padding(10)
                                Divider()
                            }
                        }
                    }
                }
            }.padding(24)
        }
    }
    var pipelines: some View {
        VStack(alignment: .leading, spacing: 18) {
            title("执行管线", "按案件跟踪从进件到交付的步骤。")
            ForEach([
                ("01", "来源与进件", "GitHub、Blender、UE 与 Godot 可扫描，其他来源可保存原帖。"),
                ("02", "DSH 诊断", "配好模型后可运行，结果进入工单。"),
                ("03", "精神 APP · Blender", "应用启动入口已就绪，GLB 工序派单待接。"),
                ("04", "尺度 APP · 视频", "应用启动入口已就绪，分镜和视频派单待接。"),
                ("05", "审核与回复", "本地审核已可用，外部答复从原帖人工发布。")
            ], id: \.0) { step in
                HStack(spacing: 17) {
                    Text(step.0).font(.system(.headline, design: .monospaced)).foregroundStyle(.mint)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(step.1).font(.headline)
                        Text(step.2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if step.0 == "03" { Button("打开精神") { openApp("jingshen") } }
                    if step.0 == "04" { Button("打开尺度") { openApp("chidu") } }
                }.padding(13).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
        }.padding(24)
    }
    var settings: some View {
        VStack(alignment: .leading, spacing: 18) {
            title("模型与设置", "通过本机 DeepSeek Harness 调用兼容 Chat Completions 的模型。")
            GroupBox("模型网关") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("地址，例如 https://gateway.example/v1", text: $gatewayURL)
                    TextField("模型 ID", text: $gatewayModel)
                    SecureField("API Key", text: $modelKey)
                    Button("存入系统钥匙串") {
                        guard !modelKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            note = "请输入要保存的密钥"; return
                        }
                        do {
                            try ModelKey.save(modelKey.trimmingCharacters(in: .whitespacesAndNewlines))
                            modelKey = ""; note = "模型密钥已保存到系统钥匙串"
                        } catch { note = error.localizedDescription }
                    }
                }.padding(8)
            }
            if let projectRepository, let url = URL(string: "https://github.com/" + projectRepository) {
                Link("打开 YZ 项目仓库", destination: url)
            }
            Button("打开 DeepSeek Harness") { openApp("DeepSeek Harness") }
            Text("在 DSH 对话里可以扫描、读取 YZ 工单，并把当前模型写的诊断存为待审草稿。").foregroundStyle(.secondary)
            Button("检查本机 DSH") { apply(["doctor"]) }.disabled(busy)
            Button("在 Finder 打开本机数据") { NSWorkspace.shared.open(Runner.state) }
            Spacer()
        }.padding(24)
    }
    func openApp(_ name: String) {
        let app = URL(fileURLWithPath: "/Applications/\(name).app")
        guard FileManager.default.fileExists(atPath: app.path) else { note = "未找到 \(name).app"; return }
        NSWorkspace.shared.openApplication(at: app, configuration: .init()) { _, error in
            if let error { Task { @MainActor in note = error.localizedDescription } }
        }
    }
    func saveLinks() {
        if let data = try? JSONEncoder().encode(stored) { UserDefaults.standard.set(data, forKey: "savedLinks") }
    }
    func removeLink(_ id: UUID) { stored.removeAll { $0.id == id }; saveLinks() }
    func importLink() {
        let input = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: input), let host = url.host,
              ["https", "http"].contains(url.scheme), url.user == nil, url.password == nil else {
            note = "请输入有效的网页链接"; return
        }
        let parts = url.path.split(separator: "/")
        if host.lowercased() == "github.com", parts.count == 4, parts[2] == "issues", Int(parts[3]) != nil {
            let repository = "\(parts[0])/\(parts[1])"
            let project = repository.lowercased() == "khronosgroup/gltf-blender-io" ? "blender-gltf" : "github"
            apply(["github-read", project, repository, String(parts[3])], note: "GitHub 工单已收件", selectResult: true)
        } else {
            if !stored.contains(where: { $0.url == url.absoluteString }) {
                stored.insert(SavedLink(url: url.absoluteString, title: host + url.path), at: 0)
                saveLinks()
            }
            note = "原帖已保存在本机"
        }
        entry = ""
    }
    func scan() {
        let repository = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        let keywords = terms.replacingOccurrences(of: "，", with: ",").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !repository.isEmpty, !keywords.isEmpty else { note = "填写仓库和至少一个关键词"; return }
        let project = repository.lowercased() == "khronosgroup/gltf-blender-io" ? "blender-gltf" : "github"
        apply(["github-scan", project, repository, "--limit", "15"] + keywords.flatMap { ["--keyword", $0] }, countResult: true)
    }
    func draft(_ id: Int) {
        let key = ModelKey.read()
        guard !key.isEmpty, !gatewayURL.isEmpty, !gatewayModel.isEmpty else {
            page = .settings; note = "请先设置模型地址、模型 ID 和密钥"; return
        }
        apply(["run", String(id)], model: [
            "CG_DSH_MODEL_URL": gatewayURL, "CG_DSH_MODEL_ID": gatewayModel, "CG_DSH_MODEL_KEY": key
        ], note: "DSH 草稿已保存")
    }
    func apply(_ arguments: [String], model: [String: String] = [:], note success: String? = nil,
               selectResult: Bool = false, countResult: Bool = false) {
        guard !busy else { return }
        busy = true; note = "处理中…"
        Task {
            defer { busy = false }
            do {
                let output = try await Task.detached { try Runner.run(arguments, model: model) }.value
                if arguments.first == "community-scan" {
                    feedStates = try Runner.decode([WatchState.Feed].self, output)
                    let added = feedStates.reduce(0) { $0 + ($1.new ?? 0) }
                    let failed = feedStates.filter { $0.error != nil }.count
                    note = "社区扫描完成 · 新增 \(added) 条 · \(failed) 个来源失败"
                } else if countResult {
                    let matches = try Runner.decode([[String: HitValue]].self, output)
                    note = "扫描完成，匹配 \(matches.count) 条公开议题"
                } else { note = success ?? output }
                if selectResult { selection = Int(output) }
                await reload()
                await select(selection)
            } catch {
                let message = error.localizedDescription
                await reload()
                await select(selection)
                note = message
            }
        }
    }
    func reloadWatch() {
        let projectFile = Runner.state.appending(path: "project-repo.json")
        if let data = try? Data(contentsOf: projectFile),
           let project = try? JSONDecoder().decode(ProjectRepository.self, from: data),
           project.repository.range(of: #"^[A-Za-z0-9-]+/[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil {
            projectRepository = project.repository
        }
        let url = Runner.state.appending(path: "github-watch.json")
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(WatchState.self, from: data),
              let last = state.last else { return }
        if let feeds = last.communities { feedStates = feeds }
        let time = ISO8601DateFormatter().date(from: last.at)
        let stamp = time?.formatted(date: .omitted, time: .shortened) ?? last.at
        if let problem = last.error { watchSummary = "GitHub 值守 · " + stamp + " · " + problem }
        else { watchSummary = "GitHub 值守 · " + stamp + " · 匹配 " + String(last.matched ?? 0) + " 条" }
    }
    func reload() async {
        do {
            let output = try await Task.detached { try Runner.run(["list"]) }.value
            tickets = try output.split(separator: "\n").map { try Runner.decode(Ticket.self, String($0)) }
        } catch { note = error.localizedDescription }
    }
    func select(_ id: Int?) async {
        guard let id else { detail = nil; return }
        do {
            let output = try await Task.detached { try Runner.run(["show", String(id)]) }.value
            let result = try Runner.decode(Ticket.self, output)
            if selection == id { detail = result }
        } catch { if selection == id { note = error.localizedDescription } }
    }
}

struct HitValue: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if (try? value.decode(Int.self)) != nil { return }
        _ = try value.decode([String].self)
    }
}

struct WatchState: Decodable {
    let last: Last?
    struct Last: Decodable {
        let at: String; let matched: Int?; let error: String?
        let communities: [Feed]?
    }
    struct Feed: Decodable {
        let source, label: String
        let read, matched, new: Int?
        let error: String?
    }
}

struct ProjectRepository: Decodable { let repository: String }
