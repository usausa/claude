---
name: smart-blazor
description: Smart スタックの Blazor 標準 (code-behind 分離・AppComponentBase・シェル・Cookie 認証・検証)
paths:
  - "**/*.razor"
  - "**/*.razor.cs"
  - "**/Components/**"
---

# Blazor (Smart スタック標準)

> `aidd-dotnet` の dotnet-blazor を具体化する。詳細・コード例は references/ を必要時に読む。

- **`.razor` + `.razor.cs` の分離を必須**とし `@code` ブロックは使わない。DI は `[Inject] public required T X { get; set; }`。ページ状態は **private フィールドで保持** (Scoped State コンテナは標準にしない)。
- 基底は `AppComponentBase` (遅延 Disposables。Hybrid 版は `Execute/ExecuteAsync` + `BusyState` ガード内蔵)。
- 値→表示の変換は `ViewHelper` (静的純関数。`@using static` で裸呼び) と `ViewExtensions` (書式化の拡張メソッド) の 2 ファイルに固定。フレームワーク型への拡張 (`JSRuntimeExtensions` / `NavigationManagerExtensions` / `SnackbarExtensions` 等) は `Infrastructure` へ。
- シェル: 機能インターフェイス (`IMenuSectionManager` 等) を `CascadingValue` で配布、`ErrorBoundary` + `ErrorDispatcher` + `Error403/404/500`、横断プログレスは `ProgressState` + `ProgressStateScope`。
- Blazor Server の自前認証は **JWT 入り Cookie + 自前 `AuthenticationStateProvider`** 一式 (`CookieAuthenticationStateProvider` = `ILoginProvider` 転送登録・`LoginManager`・`TokenHelper`・スライド更新)。
- フォーム検証は **FluentValidation**: `static readonly` の `InlineValidator<Form>` + ページにネストした `Form` + `FluentValidationValidator` コンポーネント。桁は `Length` 定数参照。
- UI ライブラリはプロジェクト固有の選定 (依存は razor / code-behind / ViewHelper / Infrastructure 拡張 / テーマ定義に閉じ込め、Service / Usecase へ漏らさない)。

## references (詳細)

code-behind / app-component-base / state-management / view-helper-and-extensions / framework-extensions / layout-and-shell / cookie-authentication / validation / ui-library
