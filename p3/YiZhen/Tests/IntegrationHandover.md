# P1 / P2 联调交接

本期为设计稿对齐后的静态界面版。P1（`YZTheme`、`YZModels`、`YZAppState`）与 P2（`SceneNavBar`、`SayList`）仍以同契约占位实现。

## 契约变更

### `YZAppState`

新增（只增不改）：

- `selectedPhaseID: YZPhase.ID?`：当前场景的二级项；`currentPhaseID` 保留为兼容别名并同步。
- `selectPhase(_:)`：校验、幂等，切换后刷新句表。
- `phases(for sceneID:)`：按场景派生二级集合。
- `navStyle(of sceneID:)`：返回 `.step`（就医）或 `.tab`（其余）。
- `defaultPhaseID(for sceneID:)`：场景默认二级（就医为 `medical.question`）。

不变式：`selectedPhaseID` 为 nil 或属于当前场景二级集合；切场景时按「场景 → 二级 → 句表」同步重置。

### `SceneNavContext`

新增带默认值字段，旧构造点可编译：

- `navStyle: YZNavStyle = .step`
- `onSelectPhase: ((YZPhase.ID) -> Void)? = nil`（nil = 只读）

约束：`phases` 语义为「当前场景的二级集合」，不是全局流程；P2 组件不得自带背景、毛玻璃、水平外边距与选中态。

### `SayListContext`

新增带默认值字段：

- `phaseName: String = ""`
- `emptyText: String = "这个场景还没有句子"`

`onUse` 本期仅提示「播报功能筹备中」，不播报、不写消息、不改计数。

### `YZPhase`

字段结构不变；语义由「全局流程环节」变为「当前场景的二级子项」；数量不再固定 5（就医 5、点餐/出行/办事 4、紧急 3）。

### `YZMessage`

只新增派生：`statusKind`（plain/ok/fail）与格式化 `cardLabel(sceneID:date:)`；存储字段不变。

## 替换点

| 组件 | 本期实现 | 替换位置 |
| --- | --- | --- |
| 主题 | `YZPlaceholderThemeProvider` | `RootView` 的 `dependencies.themeProvider` |
| 状态 | 本地 `YZAppState` | `RootView` 的 `@State appState` |
| 场景/二级内容 | `PlaceholderSceneNavBar`（`SceneChipRow` + `PhaseStepNav/Tab`） | `StaticDialogPage` 第一个泛型实参 |
| 常用语句表 | `SayListView` | `StaticDialogPage` 第二个泛型实参 |
| 动作 | 占位 Handler + Toast | `DialogDependencies.placeholder(...)` |

替换只改装配层，`Features/Dialog` 视图不改。P2 若仍按旧契约构造，退化为只读 step 形态。

## 约束

1. `Info.plist` 无任何权限键；本期不接麦克风、播报、剪贴板、拨号、网络、持久化。
2. 设计稿唯一有效令牌为 738–760 行；旧色值不得重新引入。
3. `YZValidation`、`YZMotionTokens`、`PressableStyles`、`ToastCenter`、Handler 文案与 key 为零改动红线。