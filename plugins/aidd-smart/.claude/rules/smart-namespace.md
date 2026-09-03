---
paths:
  - "src/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# 名前空間辞書 (Smart スタック標準)

> どの名前空間に何を置くか。詳細・コード例は `smart-namespace` skill の references を必要時に読む。

- サーバ側の標準語彙: `Accessors` (複数形) / `Models.{Entity,View,Parameter}` / `Services` / **`Usecase` (Services と同階層の独立名前空間)** / `Domain.{Code,Enums,Logic}` / `Settings` / `Application` (アプリ固有の共通部品) / `Infrastructure` (アプリ非依存の基盤部品) / `Providers` / `Contexts` / `Workers` / `Endpoints`。
- クライアント側の標準語彙: `Modules/<機能>` (vertical slice) / `State` / `Services` / `Usecase` / `Components` (プラットフォーム機能ラッパ) / `Behaviors` / `Messaging` / `Shell` / `Devices.Input`。
- `Components` はサーバ側では Blazor 標準 (UI コンポーネント置き場) を優先し、インフラ部品 (`I<Name>` + `<Name>` + `<Name>Options` + `<Name>Exception` の 4 点セット) は `Infrastructure` へ。
- モデルサフィックス: `*Entity` (テーブル) / `*View` (SQL 結果) / `*Parameter` (SQL 引数) / `*Request`・`*Response` (API 境界) / `*Setting` / `*Options` / `*Entry` (ネスト設定)。
- Domain: `Code` = DB コード値 (static class + const・判定同居・enum にしない) / `Enums` = アプリ内論理値 / `Logic` = 純粋関数 / `Length`・`Pattern` 等の横断定数ホルダ。Domain は Models 型に依存しない。
