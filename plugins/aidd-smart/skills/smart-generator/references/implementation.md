# 実装作法

| 項目 | 内容 |
|---|---|
| ID | generator-2 |
| 分類 | generator |
| 関連 | generator-1(プロジェクト構成と配布) / generator-3(テスト方式) / generator-4(AOP + DI 自動登録) / structure-6(コーディングスタイル) |

## 目的

ソースジェネレータは **`IIncrementalGenerator` + `ForAttributeWithMetadataName` の1形式**で実装し、ファイル内を固定の4区画で構造化する。

- インクリメンタルパイプラインにより、無関係な編集で再生成が走らない(IDE のタイピング性能を守る)
- Parser(構文 → model)と Generator(model → ソース)を分離し、model を等値比較可能な record にすることでキャッシュが正しく効く
- 不正な使い方はビルドを黙って通さず、ID 体系を持つ Diagnostic として報告する

## 標準形

### 4区画構成

ジェネレータ本体は `// ---- Initialize / Parser / Generator / Helper ----` の4区画で固定する。

```csharp
namespace Template.Library.Generator;

[Generator]
public sealed class TemplateGenerator : IIncrementalGenerator
{
    private const string AttributeName = "Template.Library.CustomMethodAttribute";

    // ------------------------------------------------------------
    // Initialize
    // ------------------------------------------------------------

    public void Initialize(IncrementalGeneratorInitializationContext context)
    {
        var optionProvider = context.AnalyzerConfigOptionsProvider
            .Select(SelectOption);

        var methodProvider = context.SyntaxProvider
            .ForAttributeWithMetadataName(
                AttributeName,
                static (syntax, _) => IsMethodSyntax(syntax),
                static (context, _) => GetMethodModel(context))
            .Collect();

        context.RegisterImplementationSourceOutput(
            optionProvider.Combine(methodProvider),
            static (context, provider) => Execute(context, provider.Left, provider.Right));
    }

    // ------------------------------------------------------------
    // Parser
    // ------------------------------------------------------------

    // 構文・シンボルの検証と model への変換

    // ------------------------------------------------------------
    // Generator
    // ------------------------------------------------------------

    // model からのソース組み立てと AddSource

    // ------------------------------------------------------------
    // Helper
    // ------------------------------------------------------------

    // ファイル名生成等の小物
}
```

- 属性ターゲットの検出は `ForAttributeWithMetadataName`(メタデータ名の完全修飾文字列)を使う。全構文ノードを舐める `CreateSyntaxProvider` より大幅に速い
- 述語・変換はラムダキャプチャを避けるため `static` ラムダにする(structure-6)
- 実行コードのみに影響する生成は `RegisterImplementationSourceOutput` を使う(IntelliSense に必要な型を生成する場合のみ `RegisterSourceOutput`)

### Parser — 検証と model 化

シンボルを検証し、**成功は model、失敗は DiagnosticInfo** を `Result<T>`(SourceGenerateHelper)に包んで返す。Roslyn のシンボルをパイプラインに流さず、必要な値だけを取り出す。

```csharp
private static bool IsMethodSyntax(SyntaxNode syntax) =>
    syntax is MethodDeclarationSyntax;

private static Result<MethodModel> GetMethodModel(GeneratorAttributeSyntaxContext context)
{
    var syntax = (MethodDeclarationSyntax)context.TargetNode;
    if (context.SemanticModel.GetDeclaredSymbol(syntax) is not IMethodSymbol symbol)
    {
        return Results.Errors<MethodModel>();
    }

    // Validate method definition
    if (!symbol.IsStatic || !symbol.IsPartialDefinition)
    {
        return Results.Error<MethodModel>(new DiagnosticInfo(Diagnostics.InvalidMethodDefinition, syntax.GetLocation(), symbol.Name));
    }

    var containingType = symbol.ContainingType;
    var ns = String.IsNullOrEmpty(containingType.ContainingNamespace.Name)
        ? string.Empty
        : containingType.ContainingNamespace.ToDisplayString();

    return Results.Success(new MethodModel(
        ns,
        containingType.GetClassName(),
        containingType.IsValueType,
        symbol.DeclaredAccessibility,
        symbol.Name));
}
```

### model — internal sealed record

model は値のみを持つ `internal sealed record` とする。record の等値比較がインクリメンタルキャッシュの判定に使われるため、`ISymbol` や `SyntaxNode` を持たせてはならない。

```csharp
namespace Template.Library.Generator.Models;

internal sealed record MethodModel(
    string Namespace,
    string ClassName,
    bool IsValueType,
    Accessibility MethodAccessibility,
    string MethodName);
```

### Diagnostics — ID 体系

診断は `Diagnostics` クラスに `DiagnosticDescriptor` として集約し、プロダクト固有のプレフィックス + 連番(例: `TP0001`)で採番する。

```csharp
namespace Template.Library.Generator;

internal static class Diagnostics
{
    public static DiagnosticDescriptor InvalidMethodDefinition { get; } = new(
        id: "TP0001",
        title: "Invalid method definition",
        messageFormat: "Method must be static partial. method=[{0}]",
        category: "Usage",
        defaultSeverity: DiagnosticSeverity.Warning,
        isEnabledByDefault: true);
}
```

### Generator — SourceBuilder による組み立て

出力は SourceGenerateHelper の `SourceBuilder` で組み立てる。エラーの報告 → クラス単位のグルーピング → `AddSource` の順で処理する。

```csharp
private static void Execute(SourceProductionContext context, OptionModel option, ImmutableArray<Result<MethodModel>> methods)
{
    foreach (var info in methods.SelectError())
    {
        context.ReportDiagnostic(info);
    }

    var builder = new SourceBuilder();
    foreach (var group in methods.SelectValue().GroupBy(static x => new { x.Namespace, x.ClassName }))
    {
        context.CancellationToken.ThrowIfCancellationRequested();

        builder.Clear();
        BuildSource(builder, option, group.ToList());

        var filename = MakeFilename(group.Key.Namespace, group.Key.ClassName);
        var source = builder.ToString();
        context.AddSource(filename, SourceText.From(source, Encoding.UTF8));
    }
}
```

- 生成ソースの冒頭には auto-generated ヘッダと `#nullable enable` を出力する(`builder.AutoGenerated()` / `builder.EnableNullable()`)
- 出力ファイル名は `名前空間_クラス名.g.cs` 形式とする(`.g.cs` はカバレッジ除外の対象 = test-2)

### MSBuild オプションの取得

利用側 csproj のプロパティは `AnalyzerConfigOptionsProvider` から読む。プロパティは配布 .props の `CompilerVisibleProperty` で可視化しておく(generator-1)。

```csharp
private static OptionModel SelectOption(AnalyzerConfigOptionsProvider provider, CancellationToken token)
{
    var value = provider.GlobalOptions.GetValue<string>("TemplateLibraryGeneratorValue");
    return new OptionModel(value);
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| ジェネレータ本体(`<Name>Generator.cs`) | Generator プロジェクト直下 |
| model(`internal sealed record`) | `Models/` |
| `Diagnostics.cs` | Generator プロジェクト直下 |
| 属性(検出対象のマーカー) | 本体ライブラリ側(generator-1) |

## バリエーションと使い分け

- **複数属性の処理**: 属性毎に `ForAttributeWithMetadataName` のプロバイダを作り、`Combine` で合流させる。1ジェネレータ=1関心事を保ち、無関係な生成は別ジェネレータに分ける
- **オプションなし**: `AnalyzerConfigOptionsProvider` の区画を省略し、methodProvider のみで `RegisterImplementationSourceOutput` する
- **partial メソッド実装型 / 新規型生成型**: 呼び出し側の型に実装を注入する場合は partial(`[LoggerMessage]` 型)、独立した型を作る場合は新規ファイル生成型。いずれも 4 区画構成は共通

## アンチパターン

- **ISourceGenerator(旧 API)の使用** — 全編集で再実行され IDE が重くなる。`IIncrementalGenerator` のみを使う
- **model に ISymbol / SyntaxNode を保持** — 等値比較が参照比較になりキャッシュが無効化される。コンパイル全体が GC に残りメモリリークにもなる。値に落としてから流す
- **CreateSyntaxProvider での全ノード走査** — 属性検出は `ForAttributeWithMetadataName` を使う
- **検証なしの生成** — 不正な対象(非 static、引数あり等)を黙って無視すると利用者は原因を追えない。必ず Diagnostic を報告する
- **文字列連結・補間での大規模ソース組み立て** — インデント管理が破綻する。`SourceBuilder` のスコープ API で組み立てる
- **Execute 内での CancellationToken 無視** — 大量生成時にキャンセルへ応答できず IDE をブロックする。ループ毎に `ThrowIfCancellationRequested()` を呼ぶ
