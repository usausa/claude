# テスト方式

| 項目 | 内容 |
|---|---|
| ID | generator-3 |
| 分類 | generator |
| 関連 | generator-1(プロジェクト構成と配布) / generator-2(実装作法) / test-2(テスト基盤) / test-1(AAA パターン) |

## 目的

ソースジェネレータのテストは、スナップショット比較ではなく**「ジェネレータをアナライザ参照した実プロジェクトをビルドし、生成コードの振る舞いを検証する」実ビルド方式**とする。

- 検証対象を「生成されたソース文字列」ではなく「生成コードが実際にコンパイルされ、期待どおり動くこと」に置く
- 生成コードのフォーマット変更(空行・インデント)でテストが壊れない。壊れるのは振る舞いが変わったときだけ
- Develop ハーネスにより、コードを書いてビルドするだけで生成結果を即時確認できる開発ループを作る

## 標準形

### Tests プロジェクト — アナライザ参照 + 実ビルド

Generator プロジェクトを `OutputItemType="analyzer"` で参照する(ランタイム参照はしない)。`EmitCompilerGeneratedFiles` で生成ソースをディスクに出力し、目視・デバッグを可能にする。

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <OutputType>Exe</OutputType>
    <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
    <RootNamespace>Template.Library</RootNamespace>
  </PropertyGroup>

  <PropertyGroup>
    <UseMicrosoftTestingPlatformRunner>true</UseMicrosoftTestingPlatformRunner>
    <TestingPlatformDotnetTestSupport>true</TestingPlatformDotnetTestSupport>
    <TestingPlatformShowTestsFailure>true</TestingPlatformShowTestsFailure>
  </PropertyGroup>

  <PropertyGroup>
    <EmitCompilerGeneratedFiles>true</EmitCompilerGeneratedFiles>
  </PropertyGroup>

  <PropertyGroup>
    <TemplateLibraryGeneratorValue>test</TemplateLibraryGeneratorValue>
  </PropertyGroup>

  <Import Project="..\Template.Library.props" />

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="18.8.1" />
    <PackageReference Include="Microsoft.Testing.Extensions.CodeCoverage" Version="18.10.0" />
    <PackageReference Include="xunit.v3.mtp-v2" Version="3.2.2" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\Template.Library.Generator\Template.Library.Generator.csproj" OutputItemType="analyzer" ReferenceOutputAssembly="false" />
    <ProjectReference Include="..\Template.Library\Template.Library.csproj" />
  </ItemGroup>

</Project>
```

- テスト基盤は xunit.v3 + Microsoft.Testing.Platform ランナー(test-2)
- 配布 .props を `Import` し、`CompilerVisibleProperty` 経由のオプション(generator-1)もテスト対象に含める
- 生成ソースは `obj/.../generated/` に出力される(`.g.cs` はカバレッジ除外 = test-2)

### テストコード — 属性を使って書き、生成物の振る舞いを検証

テストプロジェクト内に検出対象(属性付きの partial 定義)を書き、生成された実装を呼んで結果を検証する。

```csharp
namespace Template.Library;

public sealed class CustomMethodTest
{
    [Fact]
    public void MethodGenerated()
    {
        // Act
        var result = Target.Method();

        // Assert
        Assert.Equal("expected", result);
    }
}

internal static partial class Target
{
    [CustomMethod]
    public static partial string Method();
}
```

不正な使い方(Diagnostic を出すべきケース)をテストプロジェクトに書くとビルドが警告/エラーになるため、**正常系は実ビルド、異常系(Diagnostic)は Develop ハーネスでの目視確認**を基本とする。

### Develop ハーネス — 即時確認とデバッグ

コンソールアプリの Develop プロジェクトを置き、生成コードを直接呼び出して動作確認する。

```csharp
namespace Develop;

using Template.Library;

internal static class Program
{
    public static void Main()
    {
        Target.Method();
    }
}

internal static partial class Target
{
    [CustomMethod]
    public static partial void Method();
}
```

```xml
<PropertyGroup>
  <EmitCompilerGeneratedFiles>true</EmitCompilerGeneratedFiles>
</PropertyGroup>

<ItemGroup>
  <ProjectReference Include="..\Template.Library.Generator\Template.Library.Generator.csproj" OutputItemType="analyzer" ReferenceOutputAssembly="false" />
  <ProjectReference Include="..\Template.Library\Template.Library.csproj" />
</ItemGroup>
```

ジェネレータ自体のステップ実行は launchSettings.json の `DebugRoslynComponent`(targetProject に Develop を指定)で行う(generator-1)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| 実ビルドテスト | `<Library>.Tests/`(RootNamespace は本体と同一 = test-3) |
| 動作確認ハーネス | `Develop/`(.slnx で `DefaultStartup` に指定) |
| デバッグプロファイル | Generator プロジェクトの `Properties/launchSettings.json` |

## バリエーションと使い分け

- **生成ソース断面の固定が必要な場合**: 公開ライブラリで生成コードの互換性自体が契約になるケースに限り、スナップショットテスト(Verify 等)を追加してよい。既定では持たない
- **Diagnostic の網羅検証が必要な場合**: `CSharpGeneratorDriver` でコンパイルを組み立てて Diagnostic を Assert する単体テストを追加できる。導入は Diagnostic の種類が増えてから
- **複数 TFM の検証**: 本体がマルチターゲット(generator-1)の場合も、テストは最新 TFM の1本で足りる(生成コードは TFM 非依存に書く)

## アンチパターン

- **スナップショット一辺倒** — 生成文字列の完全一致比較は、無害なフォーマット変更のたびに大量の期待値更新を強いる。振る舞いの検証を主とする
- **Generator への通常参照** — `ReferenceOutputAssembly` を切らずに参照するとジェネレータ DLL がテストのランタイム依存に混入する。`OutputItemType="analyzer"` + `ReferenceOutputAssembly="false"` の組で参照する
- **EmitCompilerGeneratedFiles なしでの開発** — 生成結果を確認する手段がデコンパイルしかなくなる。Develop / Tests では必ず有効化する
- **パッケージ参照でのテスト** — 開発中のジェネレータを NuGet パッケージ経由でテストすると、キャッシュにより変更が反映されず開発ループが壊れる。ProjectReference(analyzer)で参照する
