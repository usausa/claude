---
name: blazor-e2e
description: Blazor E2E テスト (Playwright) の手順と規約
paths:
  - "tests/**/*E2ETests*/**"
  - "**/playwright.config.*"
---

# Blazor E2E テスト (Playwright)

> 配置は `tests/README.md`、UI 原則は `blazor` skill に従う。E2E はクリティカルパス (ログイン・主要フロー) に絞り、ロジックの網羅は下位層のユニットテストへ寄せる (`csharp-layered-feature` 参照)。

## 手順

1. **配置**: `tests/<App>.E2ETests/` (xUnit)。`Microsoft.Playwright` を参照する (xUnit 統合の `Microsoft.Playwright.Xunit` = `PageTest` 基底を使ってもよい)。root の `Directory.Build.props` を継承する。
2. **ブラウザ導入 (初回のみ)**: ビルド後に `pwsh tests/<App>.E2ETests/bin/Debug/<tfm>/playwright.ps1 install chromium`。未導入だと `dotnet test` (= `/verify`) が失敗する。
3. **アプリ起動 fixture**: 実ブラウザから叩くため in-memory の `TestServer` は使えない。実 Kestrel を立てる。
   - .NET 10+: `WebApplicationFactory<Program>` の Kestrel モード (`UseKestrel()`)。
   - それ以前: fixture で空きポートの Kestrel を起動し BaseAddress をテストへ渡す (または起動済みアプリの URL を環境変数で受ける)。
4. **テスト作成**: spec の受け入れ条件 (Given/When/Then) をテスト名に込める (英語 PascalCase 3 部構成。例: `Login_FailedFiveTimes_LocksAccount`)。fixture (ホスト・ブラウザ) はクラス / コレクションで共有し、テスト間で状態は共有しない。
5. **仕上げ**: `/verify` (E2E 含め全テスト緑) → 通常フロー (`/review` → `/done`)。

## Blazor (interactive server) 固有の要点

- **hydration 待ち**: プリレンダリング直後は描画済みでもイベント未接続で、早すぎる操作は無視される。「接続後にだけ現れる / 変わる状態」を `Expect()` で待ってから操作する。安定しない場合はテスト対象ページの prerender 無効化も検討。
- **セレクタ**: `GetByTestId` (`data-testid`) / `GetByRole` を優先し、CSS 構造・自動生成クラス名に依存しない。コンポーネント側にも `data-testid` を付けておく。
- **回路切断の検知**: SignalR 回路が落ちると `#blazor-error-ui` が表示される。不可解な失敗はまずこの有無を確認する。
- **画面遷移**: 初回のみ `GotoAsync`。以降のアプリ内遷移はフルページロードにならないため、`Expect(Page).ToHaveURLAsync()` 等で遷移完了を待つ。

## アンチパターン

- `Thread.Sleep` / 固定待ち (→ auto-wait と `Expect()` のリトライに任せる)
- 画面ロジックを E2E で網羅 (→ ロジックは Service / Application へ委譲し、ユニットテストで担保)
- CSS クラス・DOM 構造依存のセレクタ (→ `data-testid` / role)
- テスト間の実行順・状態への依存 (→ テストごとに独立したデータ / コンテキスト)

## 参考 (深掘り用)

- [Aaronontheweb/dotnet-skills: playwright-blazor](https://github.com/Aaronontheweb/dotnet-skills/blob/master/skills/playwright-blazor/SKILL.md) (MIT) — 認証 (cookie 注入・OAuth モック)・SignalR リアルタイム更新・スクリーンショット・CI の詳細パターン。必要時に参照。
