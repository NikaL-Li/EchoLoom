# FeatureRecords 交接包

记录列表与会话详情。文件直接并入 P1 的 App target（`ios/Yizhen/Features/FeatureRecords/`），使用 P1 `Shared` 中的内部类型。

## 交付内容

- `RecordsView`：记录 Tab 内容；列表、统计卡、空态；不写存储、不建导航。P1 `RootView` 实际是「首页 / 记录 / 我的」三 Tab，`RecordsView` 放 `.records` Tab，不需要返回按钮。
- `SessionView`：会话详情；句子卡、大字态、要点卡；只读。
- `YZFeatureSessionStore`：P1 `YZSessionStoring` 的本地 JSON 实现（最多 20 条、原子写、读失败归空）。

## P1 实际 API 对齐

- `YZSessionStoring` 是 P1 的同步协议：`load() -> [YZSession]` / `save([YZSession])`。
- 会话模型使用 P1 `YZSession`（`scene` / `subScene` / `startedAt` / `endedAt` / `turns`）。
- 句子使用 P1 `YZTurn`（`role` / `text` / `date`）。
- 视觉全部使用 P1 `YZTheme` 与 `YZCard` / `YZPrimaryButton` / `YZPillButton`。
- 所有类型保持 module internal（与 P1 一致）；没有 `public`，不需要额外 target。

## 合并

1. 复制整个 `FeatureRecords/` 到 `ios/Yizhen/Features/FeatureRecords/`。
2. `RootView` 的 `.records` Tab 使用：
   `RecordsView(sessions: appState.sessions, todaySessionCount: appState.todaySessionCount, totalSessionCount: max(YZFeatureSessionStore.savedTotalCount, appState.sessions.count), onSelectSession: { appState.openSession($0) }, onRequestStartConversation: { appState.startTalk() })`
3. `.session(id)` 路由使用：
   `if let session = appState.session(with: id) { SessionView(session: session) { appState.closeRoute() } }`
   建议该路由直接渲染 `SessionView`，不要再套带「返回」的 `RoutePageView`，避免两个返回按钮。
4. 若需要本地 JSON 持久化：在 `YizhenApp` 创建 `YZAppState(sessionStore: YZFeatureSessionStore(), phraseStore: ...)`；这一步属于 P1/P4 接线。

## 口径

- 记录页「今天」直接接收 `appState.todaySessionCount`，与首页完全同源（P1 使用 `Calendar.current.isDateInToday(endedAt)`）。
- 近 7 天、本月用同一 `endedAt` 口径计算；不自行扫文件。
- 累计通过 UserDefaults `yz.sessions.totalSavedCount` 维护：JSON 只留 20 条，但累计次数可以超过 20。
- 会话行时间为 `startedAt`，句子数为 `turns.count`。

## 边界

- **两个 Feature 目录本身**只包含记录/详情页面与 Store，不修改 P1 页面结构。
- 合并工程为完成字号/高对比/首页色，已额外修改 P1 的 `Theme`、`Components`、`HomeView`、`EmergencySignView`、`PlaceholderView`、`RootView`、`YizhenApp`、`project.yml`；以 `ios/` 工程为准。
- 不申请麦克风，不接入要点生成；`YZDefaultSessionSummaryProvider` 固定返回「要点生成暂不可用」，P3 到位后替换该内部实现。
- 未实现删除（P1 `YZSessionStoring` 没有 delete；AppState 也未提供删除入口）。
- 当前 Windows 无法编译；需在 macOS + Xcode 16 合并后验证。