---
name: smart-generator
description: Smart スタックのソースジェネレータ標準 (4 プロジェクト構成・IIncrementalGenerator 作法・実ビルドテスト・AOP)
paths:
  - "**/*Generator*/**"
  - "**/*Generator*.cs"
---

# ソースジェネレータ (Smart スタック標準)

> 詳細・コード例は references/ を必要時に読む。

- 構成は**本体 (属性同居) + Generator (netstandard2.0・`IsRoslynComponent`) + Tests + Develop ハーネス**の 4 プロジェクト。パッケージングは `analyzers/dotnet/cs` + `build/<Id>.props` 同梱、依存 DLL は `GeneratePathProperty`。
- 実装は `IIncrementalGenerator` + `ForAttributeWithMetadataName` の 1 形式、ファイル内は `Initialize / Parser / Generator / Helper` の 4 区画。model は値のみの `internal sealed record` (ISymbol を持たせない)、失敗は Result 型で流し出力段冒頭で `ReportDiagnostic` (`Diagnostics` クラスに ID 体系)。出力は `SourceBuilder`、ファイル名は `名前空間_クラス名.g.cs`。
- テストは**実ビルド方式**: Generator を `OutputItemType="analyzer"` + `ReferenceOutputAssembly="false"` で参照し、生成物の振る舞いを検証 (`EmitCompilerGeneratedFiles` で目視可)。スナップショット比較は既定で持たない。
- 応用 (AOP + DI 自動登録): `[Service(typeof(I))]` → Proxy 生成 + `[ServiceRegistry]` partial に全 `AddSingleton` を生成。横断処理は手書きの `ServiceAspect<T>` (ログ + Activity 一体) へ委譲し、`ServiceAspectOption.Enable` で実体 / Proxy を実行時切替。

## references (詳細)

project-packaging / implementation / testing / aop-di-registration
