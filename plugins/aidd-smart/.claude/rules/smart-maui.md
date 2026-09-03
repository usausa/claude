---
paths:
  - "src/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# MAUI (Smart スタック標準)

> `dotnet-maui` rule を具体化する。詳細・コード例は `smart-maui` skill の references を必要時に読む。

- `CreateMauiApp()` は `ConfigureXxx()` / `UseXxx()` の**チェーン 1 本** + 実体は private static 拡張メソッド。DI は `ConfigureContainer(SmartServiceProviderFactory)` に一元化し、登録順は Components → Messenger → Navigator → State → Service → Usecase → Startup。画面登録は `[ViewSource]` / `[PopupSource]` partial。
- 起動後処理は **`IMauiInitializeService` 実装 (`ApplicationInitializer`)** に隔離 (ResolveProvider 設定 → 設定既定値 → Navigator 購読 → DB Rebuild → ApiContext)。`App` は Window 生成 + 権限要求 + 初期遷移のみ。`CrashReport.Start()` で前回クラッシュを次回起動時に表示。
- 業務端末型 UI は**自前 Shell**: `Shell/` に `IShellControl` / `ShellEvent` (Back / Function1-4) / `ShellProperty` (attached) / `ShellUpdateBehavior` / `DiagnosticPanel`。画面は XAML 属性で宣言し、キーは `Navigator.NotifyAsync(ShellEvent)` → 基底 VM の virtual メソッドで応答。
- デバイス機能は `Components/` に **インターフェース + partial** (`.android.cs` / `.ios.cs`) で分割 (`#if` を本体に散らさない)。View↔VM 命令は `Messaging/` のバインド可能コントローラ。
- Web UI で作る場合は **Blazor Hybrid へ置換** (Smart.Navigation は使わず `Views/` + `AppComponentBase` + メッセージ駆動遷移 `PageNavigator`、ネイティブ橋渡しは `Interop/`)。
