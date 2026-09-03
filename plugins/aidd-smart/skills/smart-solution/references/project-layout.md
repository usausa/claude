# プロジェクト分割の基本形

| 項目 | 内容 |
|---|---|
| ID | solution-1 |
| 分類 | solution |
| 関連 | solution-2(Aspire AppHost) / solution-3(基盤層プロジェクト) / solution-4(Infrastructure の二段構え) / structure-1(リポジトリ骨格) / namespace-1(サーバ側の標準語彙) / namespace-7(クライアント側の標準語彙) / test-3(テストの配置・命名) / test-8(テストプロジェクト構成) |

## 目的

ソリューションのプロジェクト数を**最小**に保ち、レイヤはプロジェクトではなくフォルダ=名前空間で表現する。

- プロジェクト分割の目的は「参照方向の強制」に限定する。業務ロジック(Core)がホスト(ASP.NET Core 等)に依存しない、という一点をコンパイラに保証させる
- レイヤ毎のプロジェクト分割(Domain / Application / Infrastructure を別 DLL にする等)は行わない。境界の表現はフォルダと名前空間で足りる(namespace-1)
- プロジェクトが増えるほど参照・ビルド・定型ファイル(structure-5)の管理コストが増える。増やすのは共有の必要が実際に生じたときのみ(solution-3, solution-4)

## 標準形

### サーバ系: 3点構成

`X.Core`(業務ロジック) + ホスト(実行プロジェクト) + `X.Tests`(テスト)の3点で構成する。

```
Template.slnx
├─ Aspire/
│   └─ Template.AppHost/       … 開発オーケストレーション(Web 標準構成、solution-2)
├─ Backend/
│   ├─ Template.Core/          … 業務ロジック(RootNamespace=Template)
│   ├─ Template.Server/        … 実行ホスト(Program.cs / Endpoints / Settings / Application / Infrastructure)
│   └─ Template.Server.Tests/  … テスト(RootNamespace=Template.Server)
└─ Solution Items/
    .editorconfig / .gitattributes / .gitignore / Analyzers.ruleset /
    Directory.Build.props / Directory.Build.targets / README.md 等
```

- ソリューションファイルは `.slnx` 形式とし、規約ファイル群は Solution Items フォルダに登録する(structure-1)
- ホストは実行形態が伝わる名前(`X.Server` / `X.Host` 等)、テストは `<対象>.Tests` とする
- 小規模構成ではソリューションフォルダ(Aspire / Backend)を省略してフラットに並べてよい

### RootNamespace の短縮規約

`X.Core` はプロジェクト名(=アセンブリ名)に `.Core` を残したまま、**RootNamespace からは `Core` を除いて短縮する**。

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <RootNamespace>Template</RootNamespace>
  <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
</PropertyGroup>
```

| プロジェクト | RootNamespace | 備考 |
|---|---|---|
| `Template.Core` | `Template` | `.Core` を除いて短縮 |
| `App.Product.Core` | `App.Product` | 接頭辞が複数階層でも同様 |
| `Template.Server`(ホスト) | `Template.Server`(既定のまま) | ホストは短縮しない |
| `Template.Server.Tests` | `Template.Server` | 対象と同じ RootNamespace(test-3) |

- 利用側から見た名前空間は `Template.Services` / `Template.Domain` のようになり、「Core」という実装都合の語がコードに現れない
- テストプロジェクトも**対象と同じ RootNamespace** にし、フォルダ構造は対象をミラーする(test-3)

### クライアント系: 1ソリューション=1プロジェクト

WPF / Avalonia / MAUI 等のクライアントは**1ソリューション=1プロジェクト**とし、レイヤはフォルダ=名前空間で分割する(namespace-7)。

```
Template.Client.slnx
└─ Template.Client/
    ├─ Modules/        … 機能単位に View + ViewModel を同居(mvvm-5)
    ├─ State/
    ├─ Services/       … I/O 境界
    ├─ Usecase/
    ├─ Components/     … プラットフォーム機能ラッパ
    ├─ Behaviors/
    ├─ Messaging/
    ├─ Helpers/
    └─ Shell/
```

- 実行形態が1つで参照方向を強制する利得が無く、分割はコストのみになるため
- テストを持つ場合のみ `X.Tests` を追加する

## 配置ルール

| プロジェクト | 収容物 |
|---|---|
| `X.Core` | 業務ロジック。`Services` / `Usecase` / `Domain` / `Models` / `Accessors`(namespace-1)。フレームワーク(ASP.NET Core 等)に依存しない |
| ホスト(`X.Server` / `X.Host` 等) | 起動処理(host-1)・`Endpoints`(web-1)・`Settings`・`Application`・`Infrastructure` |
| `X.Tests` | テスト。対象構造をミラーし、RootNamespace は対象と同一(test-3) |
| `X.AppHost` | Web 標準構成の開発オーケストレーション(solution-2) |

## バリエーションと使い分け

- **複数ホスト構成**(API + バッチ等): `X.Core` を共有したままホストを並べる。ホスト間で共有する業務非依存部品は基盤層プロジェクトへ分離する(solution-3)
- **製品をまたぐ汎用部品**: アプリ非依存の基盤は独立プロジェクトにする(solution-4)
- **テストの分割**: 単体と結合を分ける場合は `X.UnitTests` + `X.IntegrationTests` とする(test-8)。3点構成の `X.Tests` は単一プロジェクトで足りる規模向け
- **非 Web のサーバ**(バッチ・常駐サービスのみ): AppHost を持たない3点構成とする

## アンチパターン

- **レイヤ毎のプロジェクト分割** — `X.Domain` / `X.Application` / `X.Infrastructure` のような多層 DLL 分割。参照管理と定型ファイルが層の数だけ増え、境界の表現は名前空間で足りる
- **クライアントの複数プロジェクト化** — 実行形態が1つのクライアントでレイヤを DLL に分ける
- **RootNamespace を既定のまま使う** — `Template.Core.Services` のように実装都合の `Core` が名前空間へ漏れる
- **Core からホストへの参照** — 業務ロジックにフレームワーク依存が生える。参照方向は常にホスト → Core
- **予防的な共有プロジェクト** — 共有先がまだ無いのに基盤層や汎用ライブラリを先回りで作る(適用基準は solution-3, solution-4)
