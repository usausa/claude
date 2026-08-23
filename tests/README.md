# tests (テストの配置先)

> 現時点でテストは未配置。ここは将来の配置先。テストは実装と同じ変更で書く (テスト=実行可能な仕様)。
> **採用形態に応じて使う**(不要なものは削ってよい)。

## 想定構成 (Web の場合)

```
tests/
  <App>.UnitTests/          xUnit 単体テスト
  <App>.IntegrationTests/   WebApplicationFactory ベースの結合テスト (実際の DI / パイプラインで検証)
  <App>.E2ETests/           E2E テスト (Playwright)。任意
```

## 想定構成 (MAUI の場合)

```
tests/
  <App>.UnitTests/   xUnit 単体テスト (ViewModel / Usecase / Service / Domain)
  <App>.UITests/     UI (E2E) テスト (Appium / .NET MAUI UITest)。任意
```

## 想定構成 (Desktop の場合)

```
tests/
  <App>.UnitTests/   xUnit 単体テスト (ViewModel / Usecase / Service / Domain)
  <App>.UITests/     UI (E2E) テスト (FlaUI 等)。任意
```

## 想定構成 (Worker の場合)

```
tests/
  <App>.UnitTests/          xUnit 単体テスト (Usecase / Service / Domain。Worker は薄いので下位層で担保)
  <App>.IntegrationTests/   Generic Host ベースの結合テスト。任意
```

## メモ
- 受け入れ条件 (spec の Given/When/Then) をテスト名に込める。英語 PascalCase の 3 部構成 `対象_条件_期待`。例: `UploadFile_SizeOverLimit_Returns400`。
- 結合は Web=`Microsoft.AspNetCore.Mvc.Testing` の `WebApplicationFactory<Program>`。UI / E2E (Playwright / Appium / FlaUI) は端末・ブラウザ依存なので、ロジックは下位層に寄せてユニットテスト可能にする。
- Blazor の E2E (Playwright) の手順・固有の注意点は `blazor-e2e` rule (`.claude/rules/blazor-e2e.md`) に従う (E2E テストのファイルを触ると自動適用)。
- テストプロジェクトも root の `Directory.Build.props` を継承する。
