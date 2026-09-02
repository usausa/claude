# リポジトリ骨格

| 項目 | 内容 |
|---|---|
| ID | structure-1 |
| 分類 | structure |
| 関連 | structure-2(Directory.Build.props) / structure-3(Analyzers.ruleset) / structure-6(.editorconfig) / solution-1(プロジェクト分割) / test-8(テストプロジェクト構成) |

## 目的

どのリポジトリでも**ルート直下の構成を同一にし、ビルド設定・品質ゲート・スタイル定義の置き場を固定する**。

- 設定ファイルはソリューション全体で1セットのみ持ち、プロジェクト間の設定差分を構造的に発生させない
- 新しいリポジトリは骨格のコピーから開始でき、「どこに何があるか」を探す必要がない
- AI エージェント向けの規約(AGENTS.md / CLAUDE.md)も骨格の一部として標準化する

## 標準形

ルート直下は次の構成とする。

```
<ルート>
├─ App.slnx                  … ソリューション定義(XML 形式)
├─ Directory.Build.props     … ビルド共通設定(structure-2)
├─ Directory.Build.targets   … 空の拡張点(structure-2)
├─ Analyzers.ruleset         … アナライザルール強度(structure-3)
├─ .editorconfig             … コーディングスタイル(structure-6)
├─ App.sln.DotSettings       … ReSharper / Rider 補完設定
├─ AGENTS.md                 … コーディング規約(エージェント向け)
├─ CLAUDE.md                 … AGENTS.md への参照のみ
├─ .gitignore / .gitattributes / README.md / LICENSE
├─ App.Core/                 … プロジェクト群(solution-1)
├─ App.Host/
├─ App.UnitTests/            … テスト(test-8)
└─ App.IntegrationTests/
```

### .slnx と Solution Items

ソリューションは `.slnx`(XML 形式)とし、ルート直下の設定ファイルを `Solution Items` フォルダに登録して IDE から見える状態にする。

```xml
<Solution>
  <Folder Name="/Backend/">
    <Project Path="App.Core/App.Core.csproj" />
    <Project Path="App.Host/App.Host.csproj" />
  </Folder>
  <Folder Name="/Tests/">
    <Project Path="App.UnitTests/App.UnitTests.csproj" />
    <Project Path="App.IntegrationTests/App.IntegrationTests.csproj" />
  </Folder>
  <Folder Name="/Solution Items/">
    <File Path=".editorconfig" />
    <File Path=".gitattributes" />
    <File Path=".gitignore" />
    <File Path="Analyzers.ruleset" />
    <File Path="Directory.Build.props" />
    <File Path="Directory.Build.targets" />
    <File Path="LICENSE" />
    <File Path="README.md" />
    <File Path="App.sln.DotSettings" />
  </Folder>
</Solution>
```

### AGENTS.md / CLAUDE.md

AGENTS.md は要点4行のみとする。詳細ルールは .editorconfig / ruleset 側が機械可読に定義しているため、文章としての規約は最小限でよい。

```markdown
# Coding Style

- **General:** Follow the rules defined in .editorconfig
- **Instance field:** Do not use `_` prefix for member variables
- **Warnings:** Ensure there are no build warnings
- **Suppress warnings:** If warning suppression is needed, ask before applying the fix
```

CLAUDE.md は AGENTS.md への参照1行のみとし、内容を二重管理しない。

```markdown
@AGENTS.md
```

### .sln.DotSettings

ReSharper / Rider 利用時の追加検査・命名規則を定義する。.editorconfig で表現できない領域(末尾カンマ、using グループ間の空行、`_` なし camelCase フィールド命名の検査等)を補完する位置付けで、`<ソリューション名>.sln.DotSettings` の名前でルートに置く。

## 配置ルール

| ファイル | 役割 | 詳細 |
|---|---|---|
| App.slnx | プロジェクトと Solution Items の登録 | 本トピック |
| Directory.Build.props / .targets | ビルド設定の一括適用 / 拡張点 | structure-2 |
| Analyzers.ruleset | アナライザルールの強度定義 | structure-3 |
| .editorconfig | スタイルとフォーマットの定義 | structure-6 |
| <ソリューション名>.sln.DotSettings | ReSharper / Rider 補完設定 | 本トピック |
| AGENTS.md + CLAUDE.md | エージェント向け規約 | 本トピック |

いずれもルート直下に1セットのみ置き、プロジェクト配下にコピーや上書き版を作らない。

## バリエーションと使い分け

- **XAML 系クライアント(WPF / Avalonia / MAUI)**: XAML フォーマッタ設定 `Settings.XamlStyler` をルートに追加し、Solution Items に登録する
- **Aspire 構成(solution-2)**: AppHost プロジェクトは `/Aspire/` などの専用ソリューションフォルダに分離し、業務プロジェクトと区別する
- **単一プロジェクト構成のクライアント(solution-1)**: プロジェクトが1つでも骨格は同一とする(設定ファイル一式 + .slnx)

## アンチパターン

- **設定ファイルのプロジェクト配下コピー** — プロジェクト間で内容が乖離し、品質ゲートがリポジトリ内で不均一になる
- **Solution Items 未登録** — 設定ファイルの存在が IDE から見えず、編集・レビューの対象から漏れる
- **AGENTS.md の肥大化** — 機械可読な設定(.editorconfig / ruleset)で表現できるルールを文章で重複記述しない。文章規約は要点4行に留める
- **CLAUDE.md への直接記述** — AGENTS.md と内容が分裂する。参照1行に固定する
- **旧 .sln 形式の継続使用** — 差分・マージが困難な独自フォーマットを避け、.slnx に統一する
