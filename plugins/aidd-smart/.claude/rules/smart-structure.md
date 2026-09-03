---
paths:
  - "**/*.csproj"
  - "**/Directory.Build.props"
  - "**/*.ruleset"
  - "**/.editorconfig"
  - "**/GlobalUsing.cs"
  - "**/GlobalSuppressions.cs"
  - "**/Assembly*.cs"
---

<!-- managed by aidd-smart plugin: 手編集しない (init 再実行で上書き更新される)。プロジェクト固有の上書きは conventions.md へ -->

# プロジェクト構造 (Smart スタック標準)

> `dotnet-coding-principles` rule を具体化する。詳細・コード例は references/ の各ドキュメントを必要時に読む。

- リポジトリ骨格は `.slnx` + Solution Items (.editorconfig / Analyzers.ruleset / Directory.Build.props 等を登録)。正典実物はプラグインの `templates/` にある。
- Directory.Build.props 標準: `LangVersion=preview` / `Nullable=enable` / `WarningsAsErrors=nullable` / `AnalysisMode=All` + `AnalysisLevel=latest` / StyleCop.Analyzers + JapaneseComment / Release のみ SourceLink + `ContinuousIntegrationBuild` / `Version` 一括管理。
- **警告抑止は三層**: ruleset = 全アセンブリ共通の強度 (層依存規則は含めない) / `GlobalSuppressions.cs` = プロジェクト単位の恒久抑止 (標準ペア CA1515 + CA2007。クライアント系は CA1305/CA1416/CA1721 等を追加) / `#pragma` = 局所 (`[SuppressMessage]` の Justification は日本語)。
- 定型ファイル: 各プロジェクトに `GlobalUsing.cs` (System → サードパーティ → 自プロジェクトの順) / `Assembly.cs` (`[assembly: CLSCompliant(false)]` + プラットフォーム属性) / `GlobalSuppressions.cs`。
- メンバ記述順序: 定数 → フィールド → イベント → プロパティ → コンストラクタ → ライフサイクル → メソッド群 (処理の種類単位グルーピング優先・`//----` 帯区切り) → ネスト型。機械強制しない。

> コード例付きの詳細は `smart-structure` skill の references を必要時に読む。
