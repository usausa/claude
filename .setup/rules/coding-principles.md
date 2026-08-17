---
paths:
  - "**/*.cs"
---

# コーディング原則 (.NET 共通)

> .NET 共通の不変原則 (全形態で同一)。書式は `.editorconfig` + analyzer が正。
> プロジェクト固有で編集する方針 (analyzer で機械化できないもの) は [`conventions.md`](conventions.md) に置く。

## 命名
- 省略形は避ける (`usr`→`user`)。同じ概念に同じ名前を一貫して使う。DB 命名は [`data.md`](data.md)。

## 設計の指針
- DRY / SOLID / YAGNI。早期リターンでネストを浅く。
- 上位層 (UI / エンドポイント) は薄く保ち、ロジックは下位層 (Service / Domain) へ委譲する。
- 汎用処理はヘルパー / ユーティリティへ。ただしアプリ・ドメイン固有の共通処理は Domain へ。

## ビルド / 品質
- ビルド警告ゼロが完了条件。合わないルールは `Analyzers.ruleset` で緩める。
- 局所抑制は `#pragma warning disable/restore` (範囲を最小に)、恒久は `GlobalSuppressions.cs`。適用前に人へ確認。

## テストを仕様として書く
- 受け入れ条件はテスト名に意味を込める。手書きの現状仕様は作らず、テストが実行可能な仕様になる。
