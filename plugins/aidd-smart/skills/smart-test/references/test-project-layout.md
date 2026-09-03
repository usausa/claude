# テストプロジェクト構成

| 項目 | 内容 |
|---|---|
| ID | test-8 |
| 分類 | test |
| 関連 | test-2(テスト基盤) / test-3(配置・命名) / test-6(シナリオ結合テスト) / test-7(bunit) / solution-1(プロジェクト分割) / structure-1(リポジトリ骨格) / host-5(public partial Program) |

## 目的

テストプロジェクトの分割単位を固定する。**一般方針は `<App>.UnitTests`(単体)+ `<App>.IntegrationTests`(結合)の2プロジェクト構成**とする(任意で E2E / UITests を追加)。

- 単体と結合で実行特性(速度・環境要件・並列性)が異なるため、プロジェクト境界で分ける
- 結合テストのみが実行環境を要求するため、CI ではステージを分けて実行できる
- 4分割(単体 / シナリオ / テスト部品ライブラリ / データ投入 CLI)は**大規模向けの発展形**であり、一般方針とはしない

## 標準形

solution-1 の3点構成(Core + ホスト + テスト)のテスト部分を2プロジェクトにする。

```
<ルート>
├─ CodeCoverage.runsettings      … テスト共通設定(test-2)
├─ App.Core/
├─ App.Host/                     … Program.cs 末尾に public partial class Program(host-5)
├─ App.UnitTests/                … 単体テスト
│   ├─ Domain/                   … 対象構造をミラー(test-3)
│   ├─ Services/
│   └─ Mocks/                    … 共有モック(test-4)
└─ App.IntegrationTests/         … WebApplicationFactory ベースの結合テスト
    ├─ Scenario/                 … シナリオテスト(test-6)
    ├─ data/
    └─ Infrastructure/
```

| プロジェクト | 対象 | 参照 | 特徴 |
|---|---|---|---|
| App.UnitTests | Domain / Service / Component 等の単体(bunit のコンポーネントテストを含む。test-7) | Core(+ Host の単体対象) | 実環境なしで常時全実行。高速・並列 |
| App.IntegrationTests | ホストを起動した一気通貫の検証 | Host(`WebApplicationFactory`) | `[IntegrationFact]` で環境依存をスキップ制御(test-6) |

- 両プロジェクトとも csproj は test-2 の標準形(xunit.v3 + Microsoft.Testing.Platform、`OutputType=Exe`)
- RootNamespace・フォルダミラー・命名は test-3 に従う
- Assembly.cs / GlobalUsing.cs / GlobalSuppressions.cs の定型セットを持つ(structure-5)
- ソリューションフォルダは `/Tests/` にまとめる(structure-1 の .slnx 例)

## 配置ルール

| 対象 | 場所 |
|---|---|
| 単体テスト | `<App>.UnitTests`(対象プロジェクトが複数でも単体テストは1プロジェクトに集約) |
| 結合テスト | `<App>.IntegrationTests` |
| E2E / UI テスト | 任意で `<App>.E2ETests` / `<App>.UITests` を追加 |
| runsettings | ルート1ファイルを全テストプロジェクトで共有(test-2) |

## バリエーションと使い分け

- **結合対象を持たないプロジェクト**(ライブラリ、ホストレスのクライアント等): `<App>.UnitTests` のみで開始し、結合対象が生じた時点で `IntegrationTests` を追加する
- **E2E / UITests**: ブラウザ・実機を要するテスト(Playwright / Appium 等)は実行特性がさらに異なるため、必要なプロジェクトでのみ任意追加する。一般方針の必須要素にはしない
- **大規模向けの4分割(発展形)**: テスト規模・チーム規模が大きい場合の構成。一般方針からの移行先であり、初期構成では採らない

```
App.UnitTests            … 単体
App.ScenarioTests        … シナリオ結合(test-6 の体系を独立プロジェクト化)
App.Testing              … テスト部品ライブラリ(Mocks / Factory / 拡張を単体・シナリオで共有)
App.DataSetup            … データ投入 CLI(シナリオ用 DB の初期化・投入)
```

判断基準: 共有モック・ヘルパが UnitTests / IntegrationTests 双方から必要になり重複し始めたら `Testing` ライブラリを、シナリオデータの準備がテストコードから分離した運用(手動実行・環境構築)を要し始めたら `DataSetup` CLI を切り出す。

## アンチパターン

- **単体と結合の混在プロジェクト** — 環境依存テストが混ざると「全部実行すると赤い」状態が常態化し、テスト実行の習慣が崩れる。境界はプロジェクトで切る
- **対象プロジェクト毎のテストプロジェクト乱立**(`App.Core.Tests` + `App.Host.Tests` + …) — 小中規模では管理コストだけが増える。単体は `<App>.UnitTests` の1プロジェクトに集約し、内部はフォルダミラー(test-3)で整理する
- **`<App>.Tests` という単一プロジェクトへの全部入れ** — 一般方針は UnitTests + IntegrationTests の分離。既存の `Tests` 単一構成は移行元として扱う
- **初期構成での4分割採用** — 部品ライブラリ・データ投入 CLI は必要になってから切り出す。空のプロジェクト骨格を先に作らない
