# アーキテクチャ規約の地図

このプロジェクトの設計原則。**AI もこれに従って生成・レビューする**。迷ったらここ。
原則から外す判断は決定なので `/adr` で残す。

## 📁 分類

| 種別 | ファイル | 内容 |
|---|---|---|
| **XAML 系共通 (MAUI / Desktop)** | [`mvvm.md`](mvvm.md) | MVVM レイヤ・原則、UI/UX 共通、異常系 (戻り値) |
| **アーキ固有 (MAUI)** | [`maui.md`](maui.md) | MAUI 固有: UI/UX、ログ / データ / セキュリティの具体 |
| **アーキ固有 (Desktop)** | [`desktop.md`](desktop.md) | Windows デスクトップ環境固有 (WPF / WinUI 共通): DPAPI、配置、AppData |
| **アーキ固有 (Desktop)** | [`wpf.md`](wpf.md) | WPF 固有 (将来 `winui.md` を並置予定) |
| **アーキ固有 (Web)** | [`web.md`](web.md) | Web 全般: レイヤ、ログ / データ / サーバ側セキュリティ |
| **アーキ固有 (Web)** | [`api.md`](api.md) | Web API 固有: minimal API、API 命名、ProblemDetails、OpenAPI |
| **アーキ固有 (Web)** | [`blazor.md`](blazor.md) | Blazor Server コンポーネント、UI/UX、UI 側セキュリティ |
| **アーキ固有 (Worker)** | [`worker.md`](worker.md) | Worker Service: 実行モデル、graceful shutdown、ホスティング |
| **プロジェクト方針 (編集可)** | [`conventions.md`](conventions.md) | analyzer で機械化できない、このPJ固有のコーディング / 設計方針 |
| **.NET 共通** | [`common/`](common/) | coding-principles / async / errors / logging / data / security / http-client(全形態共通) |

- **命名原則**: 系名 (web / desktop / mvvm) = 系の全般、技術名 (api / blazor / wpf / winui) = 技術固有。
- **form 固有 doc は採用形態のものだけ残す**: `setup.ps1 -Form maui|web|desktop|worker` が非採用の doc を削除する。この表の未採用行も削ってよい。系内の doc は全部残る (未使用の技術 doc は削ってよい)。
- **`common/`** = .NET 共通(全形態で同一内容)。
- **`conventions.md`** = このプロジェクトで編集して育てる方針(機械強制でなくレビューで担保)。
