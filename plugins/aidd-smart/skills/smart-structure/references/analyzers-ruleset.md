# Analyzers.ruleset

| 項目 | 内容 |
|---|---|
| ID | structure-3 |
| 分類 | structure |
| 関連 | structure-2(AnalysisMode) / structure-4(警告抑止の三層) / structure-6(コーディングスタイル) / structure-7(メンバ順序) |

## 目的

アナライザルールの強度を**「全ルール警告」を土台に、採用しないルールだけを減算する方式**で定義する。

- `AnalysisMode=All`(structure-2)と組み合わせ、「既定は ON、例外だけ明示的に OFF」の原則を1ファイルで表現する
- 新しく追加されたルールは自動的に警告として現れ、採用可否の判断が漏れない
- **共通 ruleset への一本化を基本とし、層に依存する規則(CA2007 等)は ruleset に含めない**。プロジェクト単位の無効化は GlobalSuppressions.cs で行う(structure-4)

## 標準形

```xml
<?xml version="1.0" encoding="utf-8"?>
<RuleSet Name="Analyzers Rules" Description="Analyzers Rules" ToolsVersion="17.0">
  <IncludeAll Action="Warning" />
  <Rules AnalyzerId="StyleCop.Analyzers" RuleNamespace="StyleCop.Analyzers">
    <Rule Id="SA1005" Action="Hidden" />
    <Rule Id="SA1101" Action="Hidden" />
    <Rule Id="SA1116" Action="Hidden" />
    <Rule Id="SA1117" Action="Hidden" />
    <Rule Id="SA1121" Action="Hidden" />
    <Rule Id="SA1201" Action="Hidden" />
    <Rule Id="SA1202" Action="Hidden" />
    <Rule Id="SA1203" Action="Hidden" />
    <Rule Id="SA1204" Action="Hidden" />
    <Rule Id="SA1214" Action="Hidden" />
    <Rule Id="SA1402" Action="Hidden" />
    <Rule Id="SA1413" Action="Hidden" />
    <Rule Id="SA1512" Action="Hidden" />
    <Rule Id="SA1513" Action="Hidden" />
    <Rule Id="SA1515" Action="Hidden" />
    <Rule Id="SA1516" Action="Hidden" />
    <Rule Id="SA1600" Action="Hidden" />
    <Rule Id="SA1601" Action="Hidden" />
    <Rule Id="SA1602" Action="Hidden" />
    <Rule Id="SA1633" Action="Hidden" />
    <Rule Id="SA1649" Action="Hidden" />
  </Rules>
  <Rules AnalyzerId="Microsoft.CodeQuality.Analyzers" RuleNamespace="Microsoft.CodeQuality.Analyzers">
    <Rule Id="CA1000" Action="Hidden" />
    <Rule Id="CA1002" Action="Hidden" />
    <Rule Id="CA1028" Action="Hidden" />
    <Rule Id="CA1034" Action="Hidden" />
    <Rule Id="CA1054" Action="Hidden" />
    <Rule Id="CA1056" Action="Hidden" />
    <Rule Id="CA1062" Action="Hidden" />
    <Rule Id="CA1716" Action="Hidden" />
    <Rule Id="CA1724" Action="Hidden" />
    <Rule Id="CA1873" Action="Hidden" />
  </Rules>
</RuleSet>
```

各 csproj からは相対パスで参照する。

```xml
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <CodeAnalysisRuleSet>..\Analyzers.ruleset</CodeAnalysisRuleSet>
</PropertyGroup>
```

### 無効化ルールの意図(StyleCop)

| ルール | 内容 | 無効化の意図 |
|---|---|---|
| SA1101 | `this.` プレフィックス必須 | `this.` は付けない流儀のため(structure-6) |
| SA1201 / SA1202 / SA1203 / SA1204 / SA1214 | メンバ順序の機械強制 | 順序は structure-7 のガイドラインに委ね、機械強制しない |
| SA1512 / SA1513 / SA1515 / SA1516 | コメント・ブレース前後の空行強制 | 区切りコメント(structure-6)を軸にした独自の空行運用と衝突する |
| SA1600 / SA1601 / SA1602 / SA1633 / SA1649 | ドキュメントコメント・ファイルヘッダ必須、ファイル名と型名の一致 | XML ドキュメントコメントを必須としない。関連型の同居によるファイル名不一致も許容する |
| SA1005 | コメントは空白で開始 | コメントアウトされたコードや `//----` 帯(structure-6)と衝突する |
| SA1116 / SA1117 | 引数の改行レイアウト | 引数の折り返し位置は可読性で判断し、機械強制しない |
| SA1121 | 組込み型エイリアスの強制 | 静的メンバ参照は `Int32.MaxValue` / `String.IsNullOrEmpty` と CLR 型名で書く流儀のため(structure-6) |
| SA1402 | 1ファイル1型 | 小さな関連型(Options・EventArgs 等)の同居を許容する |
| SA1413 | 複数行初期化子の末尾カンマ必須 | 末尾カンマは付けない方針のため |

### 無効化ルールの意図(CA)

| ルール | 内容 | 無効化の意図 |
|---|---|---|
| CA1000 | ジェネリック型の static メンバ回避 | ファクトリ等での利用を許容する |
| CA1002 | `List<T>` の公開回避 | アプリ内部の API では `List<T>` を戻り値に使う(data-1) |
| CA1028 | enum 基底型は Int32 に限定 | DB・プロトコルに合わせた基底型を許容する |
| CA1034 | ネスト型の公開回避 | ネスト設定(config-3)やフォーム定義等で使用する |
| CA1054 / CA1056 | URL は string でなく Uri 型 | 設定バインドやエンドポイント指定は string で扱う |
| CA1062 | public メソッド引数の null 検証 | Nullable 参照型(structure-2)で静的に担保し、実行時検証は書かない |
| CA1716 | 予約語と衝突する識別子回避 | `Error` / `Stop` 等の自然な名前を優先する |
| CA1724 | 型名と名前空間名の衝突回避 | `Telemetry` 等、文脈で判別できる一致を許容する |
| CA1873 | ログ引数の評価コスト警告 | ログは `[LoggerMessage]` 定型(log-1)でレベルガードされるため個別警告は不要 |

## 配置ルール

| 対象 | 場所 |
|---|---|
| Analyzers.ruleset | ルート直下に1ファイル。Solution Items に登録(structure-1) |
| 参照 | 各 csproj の `CodeAnalysisRuleSet`(相対パス) |
| アセンブリ単位の抑止 | ruleset ではなく GlobalSuppressions.cs(structure-4) |

## バリエーションと使い分け

- **クライアント系プロジェクトでの追加無効化**: 次のルールを追加してよい
  - CA1416(プラットフォーム互換性検証)— 対象プラットフォームが固定のクライアントでは冗長
  - CA1303(リテラル文字列のリソース化)/ CA1305(IFormatProvider の明示)— ローカライズしない前提の UI 文字列・表示書式では冗長
- **大規模構成での2分割**: アプリ用と基盤ライブラリ用に ruleset を分け、基盤側のみ厳しくする構成もとれる。ただし基本は共通1ファイルとし、分割は強度差の必要が明確な場合に限る

## アンチパターン

- **層依存の規則(CA2007 等)を ruleset に入れる** — Web ホストと汎用ライブラリで妥当性が逆転する規則はソリューション共通にできない。GlobalSuppressions.cs でプロジェクト単位に扱う(structure-4)
- **加算方式(IncludeAll なしの個別 ON)** — 新規ルールが自動適用されず、品質ゲートが経年劣化する
- **ruleset のプロジェクト毎コピー** — 内容が乖離し、共通化の意味がなくなる
- **エディタ操作による安易な Severity 変更** — ruleset の変更はソリューション全体に効く。1箇所の都合なら局所抑止(structure-4)を使う
