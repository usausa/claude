---
name: testing
description: テストの書き方
paths:
  - "tests/**"
---

# テストの書き方

> テストプロジェクトの構成は `tests/README.md` (UnitTests + IntegrationTests 構成)。ここは**テストを書くときの書き方**のみ。

- テストフレームワークは **xunit.v3 + Microsoft.Testing.Platform** を標準とする。
- テスト名は**英語 PascalCase の 3 部構成** `対象_条件_期待` で受け入れ条件を表す: `FindOrderBusinessDate_BeforeCloseTime_ReturnsNextBusinessDay`。
- 本文は **AAA パターン**で書き、`// Arrange` `// Act` `// Assert` のコメントで区切る。
- AAA コメントは**固定文言の区切り行**として使う (シナリオ説明を書き足さない。処理内容の補足は対象行の直前に別コメントで書く)。例外検証で Act と Assert が 1 式に融合する場合は `// Act & Assert` の 1 コメントに畳んでよい。
- **ロジックは下位層 (Domain の Logic / Usecase の共通部品 = Subcase) に寄せて**ユニットテスト可能にするのが前提。純粋関数 (Logic) は総当たり検証を使ってよい。

## Mock の用意のしかた

- インターフェースのモックは **NSubstitute** を標準とする (依存を増やせない場合は手書きモック = 未使用メンバは `NotSupportedException`、でもよい)。
- **モックの組み立ては `Mocks` 名前空間の Mock Builder に共通化**し、テスト本文を仕様の記述 (AAA) に集中させる。

## 時刻の扱い

- **時刻に依存するロジックは `TimeProvider` を注入**し、テストでは固定時刻に差し替える (`DateTime.Now` 直参照をしない)。
- 処理日時のような業務時刻は、リクエスト / 処理単位のコンテキストに**確定値として保持して参照する**のが本来の形 (同一処理内で時刻を揺らさない)。`TimeProvider` を直接使うのは「今」を確定する境界に限られる。

## 統合テスト

- 統合テストの方式 (実 DB シナリオテスト等) はプロジェクトで決定し `/adr` に残す (見本は adr-guide の references)。
- E2E テストは `tests/<App>.E2ETests/` に置く (web 形態の手順・Blazor 固有の注意は blazor-e2e rule)。
