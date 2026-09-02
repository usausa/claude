---
paths:
  - "**/*.cs"
---

# プロジェクト方針 (編集可)

> このプロジェクト固有のコーディング / 設計方針。**チームで編集して育てる**ドキュメント。
> `.editorconfig` や analyzer で機械化できない「意味のルール」を置く。`paths` により対象ファイルを触ると自動適用される。
> .NET 共通の不変原則は [`coding-principles.md`](coding-principles.md)。

## コーディング
- 定型 API の静的呼び出しは **BCL 型**で書く: `String.IsNullOrEmpty(x)` (`string.IsNullOrEmpty` としない)。
- 空文字などの**値**はキーワードで書く: `string.Empty` (`String.Empty` としない)。
- エラー・警告メッセージは**コード付きカタログ**に集約する (例: `AE-0201` = エラー / `AW-0901` = 警告)。文言の散在と重複を防ぎ、問い合わせ時にコードで特定できる。

## 追記のしかた
- ここにプロジェクト固有の方針を追記していく ([`../../docs/review-checklist.md`](../../docs/review-checklist.md) の観点が本ファイルを参照するため、追記だけでレビュー対象になる)。
- 機械強制できるものは可能なら `.editorconfig` / `Analyzers.ruleset` へ寄せ、ここには「機械化できない意味ルール」を残す。

## 外部 skill / MCP との優先順位
- 外部スキル (例: maui-skills, dotnet/skills) や MCP (Microsoft Learn / NuGet 等) の助言は**参考・補完**。
- **この `.claude/rules/*` が常に優先**する。
- 外部の一般ベストプラクティスを採り入れるときは、本テンプレの方針と整合するか確認し、必要ならここへ明文化する。
