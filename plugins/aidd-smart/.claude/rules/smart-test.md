---
paths:
  - "tests/**"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# テスト (Smart スタック標準)

> `dotnet-testing` rule を具体化する。詳細・コード例は `smart-test` skill の references を必要時に読む。

- 基盤は **xunit.v3 + Microsoft.Testing.Platform** (`OutputType=Exe` + `UseMicrosoftTestingPlatformRunner`) + ルート 1 つの `CodeCoverage.runsettings` (cobertura・`.g.cs` 除外)。
- 構成は `<App>.UnitTests` + `<App>.IntegrationTests` (+ 任意 E2E/UITests)。RootNamespace は対象と同一・フォルダは対象をミラー・クラス名は `<対象>Test`。**テスト名は「対象メソッド + シナリオ + 期待結果」の 3 部構成をアンダースコアなしの PascalCase で連結** (例: `DailyAuthorizeFailedReturns403`)。
- 本文は AAA (`// Arrange` `// Act` `// Assert` は固定文言の区切り行。補足は別コメント・例外系は `// Act & Assert`)。クラス冒頭に `//---- Helper ----` セクション (`CreateParameter` + `CreateXxx()` ファクトリ) を置き本体を 3〜10 行に保つ。
- モック方針: 汎用 = **NSubstitute** / 振る舞い持ち = 手書き `MockXxx` / DB = **Usa.Smart.Mock.Data** (`MockDbConnection`) / ロガー = `DebugLoggerFactory` / 時刻 = `TimeProvider` 注入。共有モックの名前空間は `Mocks`。
- 結合は `WebApplicationFactory` (+ 必要なら extern alias)。時刻固定 `StaticTimeProvider`・サービス差し替え `RemoveService`・環境依存は `[IntegrationFact]` でスキップ制御。Blazor コンポーネントは bunit (`BunitContext` + `Render<T>` + `WaitForAssertion`)。
