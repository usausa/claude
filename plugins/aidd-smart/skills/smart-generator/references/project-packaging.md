# プロジェクト構成と配布

| 項目 | 内容 |
|---|---|
| ID | generator-1 |
| 分類 | generator |
| 関連 | generator-2(実装作法) / generator-3(テスト方式) / structure-1(リポジトリ骨格) / structure-2(Directory.Build.props) |

## 目的

ソースジェネレータを含むライブラリを、**本体 + Generator + Tests + Develop の4プロジェクト構成**に固定し、1つの NuGet パッケージとして配布できる形にする。

- 属性(マーカー)は本体ライブラリに同居させ、利用側は1パッケージの参照だけで属性もジェネレータも手に入る
- Generator は netstandard2.0 の Roslyn コンポーネントとして分離し、ランタイム参照に混入させない
- 依存 DLL(生成ヘルパ等)やオプション定義(.props)もパッケージに同梱し、利用側の追加設定を不要にする

## 標準形

### プロジェクト構成

```
<ルート>
├─ Template.Library/            … 本体(属性 + ランタイム部品、パッケージング定義)
├─ Template.Library.Generator/  … ジェネレータ(netstandard2.0、IsRoslynComponent)
├─ Template.Library.Tests/      … テスト(実ビルド方式 = generator-3)
├─ Develop/                     … 動作確認ハーネス(コンソール、generator-3)
└─ Template.Library.props       … 利用側へ配布する MSBuild 定義
```

| プロジェクト | 役割 |
|---|---|
| Template.Library | 利用側が参照するパッケージ本体。`[CustomMethod]` 等の属性、ランタイム部品、パッケージング用 Target を持つ |
| Template.Library.Generator | `IIncrementalGenerator` 実装(generator-2)。`IsPackable=false` とし単独では配布しない |
| Template.Library.Tests | ジェネレータをアナライザ参照した実ビルドテスト(generator-3) |
| Develop | 生成結果を即時確認するコンソールアプリ。デバッグ実行のターゲット(generator-3) |

### Generator プロジェクト(.csproj)

netstandard2.0 + `IsRoslynComponent` とし、Roslyn パッケージは `PrivateAssets="all"`。ジェネレータが依存するライブラリ(生成ヘルパ等)は `GeneratePathProperty="true"` で参照し、`GetDependencyTargetPaths` Target でコンパイラから見える位置に供給する。

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <IsRoslynComponent>true</IsRoslynComponent>
    <IsPackable>false</IsPackable>
    <EnforceExtendedAnalyzerRules>true</EnforceExtendedAnalyzerRules>
    <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" Version="5.6.0" PrivateAssets="all" />
    <PackageReference Include="Microsoft.CodeAnalysis.CSharp" Version="5.6.0" PrivateAssets="all" />
    <PackageReference Include="SourceGenerateHelper" Version="1.20.0" GeneratePathProperty="true" PrivateAssets="all" />
  </ItemGroup>

  <PropertyGroup>
    <GetTargetPathDependsOn>$(GetTargetPathDependsOn);GetDependencyTargetPaths</GetTargetPathDependsOn>
  </PropertyGroup>

  <Target Name="GetDependencyTargetPaths">
    <ItemGroup>
      <TargetPathWithTargetPlatformMoniker Include="$(PKGSourceGenerateHelper)\lib\netstandard2.0\SourceGenerateHelper.dll" IncludeRuntimeDependency="false" />
    </ItemGroup>
  </Target>

</Project>
```

### 本体プロジェクトのパッケージング(.csproj)

`TargetsForTfmSpecificContentInPackage` に Pack 用 Target を連結し、**ジェネレータ DLL と依存 DLL を `analyzers/dotnet/cs` へ、.props を `build/` へ**同梱する。

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFrameworks>net10.0;net9.0;net8.0</TargetFrameworks>
    <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
    <NoWarn>$(NoWarn);NU5118;NU5129</NoWarn>
  </PropertyGroup>

  <PropertyGroup>
    <GeneratePackageOnBuild>false</GeneratePackageOnBuild>
    <TargetsForTfmSpecificContentInPackage>$(TargetsForTfmSpecificContentInPackage);PackBuildOutputs</TargetsForTfmSpecificContentInPackage>
  </PropertyGroup>

  <Target Name="PackBuildOutputs" DependsOnTargets="SatelliteDllsProjectOutputGroup;DebugSymbolsProjectOutputGroup">
    <ItemGroup>
      <TfmSpecificPackageFile Include="..\Template.Library.props" PackagePath="build" />
      <TfmSpecificPackageFile Include="..\Template.Library.Generator\bin\$(Configuration)\netstandard2.0\Template.Library.Generator.dll" Pack="true" PackagePath="analyzers/dotnet/cs" Visible="false" />
      <TfmSpecificPackageFile Include="$(PKGSourceGenerateHelper)\lib\netstandard2.0\SourceGenerateHelper.dll" Pack="true" PackagePath="analyzers/dotnet/cs" Visible="false" />
    </ItemGroup>
  </Target>

  <PropertyGroup>
    <PackageId>Template.Library</PackageId>
    <Title>Template.Library</Title>
    <Description>Template source generator.</Description>
    <PackageTags>sourcegenerator</PackageTags>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="SourceGenerateHelper" Version="1.20.0" GeneratePathProperty="true" PrivateAssets="all" />
  </ItemGroup>

</Project>
```

- パッケージ名(`build/<PackageId>.props`)と一致させた .props は、インストール時に利用側プロジェクトへ自動 Import される
- 本体には `ProjectReference` を張らず(ランタイム依存を作らない)、DLL のパス指定で同梱する。ビルド順は .slnx の `BuildDependency` で保証する

```xml
<Project Path="Template.Library/Template.Library.csproj">
  <BuildDependency Project="Template.Library.Generator/Template.Library.Generator.csproj" />
</Project>
```

### 配布する .props — オプションの受け口

利用側の csproj プロパティをジェネレータから読めるようにする(generator-2 の `AnalyzerConfigOptionsProvider` とペア)。

```xml
<Project>

  <ItemGroup>
    <CompilerVisibleProperty Include="TemplateLibraryGeneratorValue" />
  </ItemGroup>

</Project>
```

### デバッグ設定(launchSettings.json)

`DebugRoslynComponent` で Develop プロジェクトを対象にジェネレータ自体をデバッグ実行できるようにする。

```json
{
  "profiles": {
    "Template.Library.Generator": {
      "commandName": "DebugRoslynComponent",
      "targetProject": "..\\Develop\\Develop.csproj"
    }
  }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| 属性(マーカー)定義 | 本体プロジェクト直下(利用側 API と同じ名前空間) |
| ジェネレータ本体 / Models / Diagnostics | Generator プロジェクト(generator-2) |
| 配布用 .props | リポジトリルート(`<PackageId>.props`、Solution Items に登録) |
| リポジトリ骨格(ruleset / Build.props 等) | structure-1 に従いルートに1セット |

## バリエーションと使い分け

- **ランタイム部品なしの純ジェネレータ**: 構成は変えない。本体は属性のみでも「属性 + パッケージング定義の置き場」として維持する(利用側の参照は常に本体1つ)
- **オプション不要のジェネレータ**: .props と `CompilerVisibleProperty` は省略できる。Target 構成はそのまま
- **アナライザ同梱**: 診断専用アナライザを追加する場合も同じ Generator プロジェクトに同居させ、`analyzers/dotnet/cs` へ同梱する

## アンチパターン

- **Generator を net8.0 等でビルド** — Roslyn コンポーネントは netstandard2.0 が必須。ターゲットを上げると Visual Studio / コンパイラプロセスでロードできない
- **本体から Generator への ProjectReference(通常参照)** — Generator DLL がランタイム依存としてパッケージの `lib/` に混入する。参照せず `analyzers/dotnet/cs` へ同梱する
- **依存 DLL の同梱漏れ** — 生成ヘルパを `PrivateAssets="all"` にしただけでは利用側で FileNotFoundException になる。`GeneratePathProperty` + Pack の両方に含める
- **属性を別パッケージに分離** — 利用側が2パッケージの参照とバージョン整合を強いられる。属性は本体に同居させる
- **Develop / Tests の省略** — 生成結果の確認手段がパッケージ利用側にしかなくなり、開発ループが破綻する(generator-3)
