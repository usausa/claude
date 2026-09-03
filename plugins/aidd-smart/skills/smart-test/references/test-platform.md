# テスト基盤(xunit.v3 + Microsoft.Testing.Platform)

| 項目 | 内容 |
|---|---|
| ID | test-2 |
| 分類 | test |
| 関連 | test-8(テストプロジェクト構成) / test-3(配置・命名) / structure-1(リポジトリ骨格) / structure-2(Directory.Build.props) |

## 目的

テスト基盤は **xunit.v3 + Microsoft.Testing.Platform ランナー(`OutputType=Exe`)+ CodeCoverage.runsettings(cobertura、`.g.cs` 除外)を正とする**。

- テストプロジェクトは自己完結の実行可能ファイルになり、`dotnet run` でも `dotnet test` でも同一のランナーで実行できる
- カバレッジ設定はリポジトリルートの `CodeCoverage.runsettings` 1ファイルに集約し、CI とローカルで同じ集計条件を共有する
- ソースジェネレータ生成物(`.g.cs`)と起動コード(`[ExcludeFromCodeCoverage]`、host-5)を除外し、カバレッジを「書いたコード」の指標に保つ

## 標準形

### csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <OutputType>Exe</OutputType>
    <RootNamespace>Template</RootNamespace>
    <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
  </PropertyGroup>

  <PropertyGroup>
    <UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>
    <TestingPlatformDotnetTestSupport>true</TestingPlatformDotnetTestSupport>
    <TestingPlatformShowTestsFailure>true</TestingPlatformShowTestsFailure>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="18.8.1" />
    <PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="18.10.0" />
    <PackageReference Include="xunit.v3.mtp-v2" Version="3.2.2" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\App.Core\App.Core.csproj" />
  </ItemGroup>

</Project>
```

- `OutputType=Exe` + `UseMicrosoftTestingPlatformRunner` が Microsoft.Testing.Platform ランナー方式の核。テストアセンブリ自体が実行可能になる
- `TestingPlatformDotnetTestSupport` により従来の `dotnet test` からも実行できる(CI の移行が不要)
- `RootNamespace` はテスト対象と同一にする(test-3)
- モックが必要なプロジェクトは `NSubstitute` / `Usa.Smart.Mock.Data`(test-4)、Blazor は `bunit`(test-7)を追加する

### CodeCoverage.runsettings

リポジトリルートに置き、Solution Items に登録する(structure-1)。

```xml
<?xml version="1.0" encoding="utf-8"?>
<Configuration>

  <Format>cobertura</Format>

  <IncludeTestAssembly>false</IncludeTestAssembly>
  <DeterministicReport>true</DeterministicReport>

  <CodeCoverage>

    <Attributes>
      <Exclude>
        <Attribute>^System\.Diagnostics\.CodeAnalysis\.ExcludeFromCodeCoverageAttribute$</Attribute>
        <Attribute>^System\.Diagnostics\.ConditionalAttribute$</Attribute>
        <Attribute>^System\.Runtime\.CompilerServices\.CompilerGeneratedAttribute$</Attribute>
      </Exclude>
    </Attributes>

    <Sources>
      <Exclude>
        <Source>.*\\[^\\]*\.g\.cs</Source>
      </Exclude>
    </Sources>

  </CodeCoverage>

</Configuration>
```

### 実行

```sh
# テスト実行(カバレッジ付き)
dotnet test --settings CodeCoverage.runsettings

# ランナー直接実行(Microsoft.Testing.Platform)
dotnet run --project App.UnitTests -- --coverage --coverage-output-format cobertura
```

## 配置ルール

| ファイル | 場所 |
|---|---|
| CodeCoverage.runsettings | リポジトリルートに1ファイル(Solution Items 登録) |
| テストプロジェクト | `<App>.UnitTests` / `<App>.IntegrationTests`(test-8) |
| GlobalUsing.cs | `global using Xunit;` を含む定型セット(structure-5) |

## バリエーションと使い分け

- **GlobalSuppressions.cs**: テストプロジェクトでは CA1515(公開型を internal にせよ)をアセンブリ単位で抑止する(xunit のテストクラスは public が前提。structure-4 の枠組み)
- **カバレッジ除外の追加**: runsettings の `Functions/Exclude` は原則使わない。除外はコード側の `[ExcludeFromCodeCoverage]` で宣言し、除外理由をコードレビューの対象に残す

## アンチパターン

- **xunit v2 + VSTest ランナーの新規採用** — 旧世代構成。新規プロジェクトは xunit.v3 + Microsoft.Testing.Platform で開始する
- **runsettings のプロジェクト毎コピー** — 集計条件がプロジェクト間で乖離する。ルートの1ファイルを全テストプロジェクトで共有する
- **`.g.cs` 除外の欠落** — ソースジェネレータ生成コードが未カバー行として集計され、カバレッジが実態より低く見える
- **テストアセンブリの集計混入** — `IncludeTestAssembly=false` を外さない。テストコード自身のカバレッジは指標として意味を持たない
