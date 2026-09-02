# Directory.Build.props 標準

| 項目 | 内容 |
|---|---|
| ID | structure-2 |
| 分類 | structure |
| 関連 | structure-1(リポジトリ骨格) / structure-3(Analyzers.ruleset) / structure-5(GlobalUsing.cs) / structure-6(.editorconfig) / deploy-3(発行スクリプト) |

## 目的

言語バージョン・null 許容・アナライザ強度・バージョン番号を**ルートの Directory.Build.props で一括管理し、csproj には TargetFramework とパッケージ参照だけを残す**。

- 全プロジェクトが自動的に同じ品質ゲートの下でビルドされ、設定漏れが構造的に起きない
- 新規プロジェクトの追加時に csproj へ書くことがほとんどない
- バージョン更新・アナライザ更新が1ファイルの変更で完結する

## 標準形

```xml
<Project>

  <PropertyGroup>
    <LangVersion>preview</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <Deterministic>true</Deterministic>
    <MSBuildWarningsAsMessages>SA0001</MSBuildWarningsAsMessages>
    <WarningsAsErrors>nullable</WarningsAsErrors>
    <NoWarn>EnableGenerateDocumentationFile</NoWarn>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <PropertyGroup>
    <AnalysisMode>All</AnalysisMode>
    <AnalysisLevel>latest</AnalysisLevel>
  </PropertyGroup>

  <PropertyGroup Condition="'$(Configuration)' == 'Release'">
    <ContinuousIntegrationBuild>true</ContinuousIntegrationBuild>
  </PropertyGroup>

  <PropertyGroup>
    <Version>0.0.1</Version>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.556">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Usa.Smart.Analyzers.JapaneseComment" Version="1.6.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

  <ItemGroup Condition="'$(Configuration)' == 'Release'">
    <PackageReference Include="Microsoft.SourceLink.GitHub" Version="10.0.301">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
  </ItemGroup>

</Project>
```

### 各プロパティの意図

| プロパティ | 意図 |
|---|---|
| `LangVersion=preview` | 最新の言語機能を常時使用する |
| `Nullable=enable` + `WarningsAsErrors=nullable` | null 許容注釈を有効化し、null 警告だけはエラーへ昇格して混入を許さない |
| `ImplicitUsings=enable` | SDK 既定の暗黙 using を使用する。追加分は GlobalUsing.cs(structure-5) |
| `Deterministic=true` | 同一ソースから同一バイナリを生成する再現可能ビルド |
| `MSBuildWarningsAsMessages=SA0001` + `NoWarn=EnableGenerateDocumentationFile` | XML ドキュメント出力は行わない方針のため、SA0001(XML コメント解析無効)をメッセージへ降格し、GenerateDocumentationFile 有効化を促す警告を抑止する |
| `EnforceCodeStyleInBuild=true` | .editorconfig(structure-6)のスタイル違反をビルド時に検証する |
| `AnalysisMode=All` + `AnalysisLevel=latest` | CA 系ルールを最新セット・全ルール有効で適用する。採用しないルールの減算は ruleset(structure-3) |
| Release 限定 `ContinuousIntegrationBuild` + SourceLink | 配布ビルドのみパス正規化とソース参照情報を付与し、日常の Debug ビルドを軽く保つ |
| `Version` | 全アセンブリのバージョンをここで一括管理する |

### 共通アナライザ

| パッケージ | 用途 |
|---|---|
| StyleCop.Analyzers | スタイル検査。強度は Analyzers.ruleset で調整する(structure-3) |
| Usa.Smart.Analyzers.JapaneseComment | 日本語コメントの表記検査 |

## 配置ルール

| 対象 | 場所 |
|---|---|
| Directory.Build.props / Directory.Build.targets | ルート直下。Solution Items に登録(structure-1) |
| プロジェクト固有設定 | 各 csproj(TargetFramework、パッケージ参照、`CodeAnalysisRuleSet`、発行設定のみ) |

`Directory.Build.targets` は**空のまま置く拡張点**とする。props はプロジェクト定義より先、targets は後に評価されるため、プロジェクト側の設定を踏まえた後処理が必要になった場合の挿入口として予約しておく。

```xml
<Project>
</Project>
```

## バリエーションと使い分け

- **発行設定(deploy-3)**: 単一ファイル発行などの発行系プロパティは全プロジェクト共通ではないため、props ではなく対象 csproj 側で条件付き定義する
- **テスト基盤(test-2)**: テストランナー系のパッケージ・プロパティはテストプロジェクトの csproj 側に置く。props に置くのは全プロジェクト共通の要素のみ

## アンチパターン

- **csproj への LangVersion / Nullable の個別指定** — props の一括管理と二重になり、乖離の温床になる
- **Version のプロジェクト個別管理** — アセンブリ間でバージョンがずれる
- **アナライザパッケージのプロジェクト単位追加** — 検査強度がプロジェクトによって変わる。共通アナライザは props に集約する
- **Debug ビルドへの SourceLink / ContinuousIntegrationBuild 適用** — ローカルビルドを重くするだけで利点がない
- **Directory.Build.targets への既定値記述** — 既定値の定義は props の役割。targets に書くと csproj 側の指定を意図せず上書きする
