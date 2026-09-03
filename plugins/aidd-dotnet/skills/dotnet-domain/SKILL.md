---
name: dotnet-domain
description: Domain 層の実装規約
paths:
  - "**/Domain/**"
---

# Domain 実装規約

> **Domain = パーシステンスも IO も持たない純粋な業務知識** (定数・区分・判定・計算)。Entity / View / Parameter は Model の話であり Domain ではない (`dotnet-data` skill)。Models は形状のみでロジックを持たず、Domain は **Models 型に依存しない** (接着は ViewModel / Service / Converter 側の責務)。
> DI・IO が要る共通処理は Domain でなく **Usecase 層の部品 (Subcase)** に置く。DI 不要の純粋ロジックは Logic に置く。

## フォルダ構成 (3 分類 + ルート定数)

```
Domain/
  Code/     DB に格納されるコード値 (1 区分 = 1 クラス)
  Enums/    DB に保存しないアプリ内の論理値 (enum + 拡張)
  Logic/    純粋関数のロジック (1 業務概念 = 1 クラス)
  Length.cs / Pattern.cs / MaxCount.cs / SpecialDate.cs   … 横断定数ホルダ (固定名)
```

- 配置は規模でスケールする (プロジェクト内フォルダ → 専用アセンブリ)。構造・命名は全規模で同一。

## Code (DB コード値): 1 区分 = 1 static class

- **1 つの DB 区分 (カラム) = 1 つの `static class`**。const の型は **DB 格納型と同型** (TINYINT=`sbyte`、CHAR=`string`) — enum にしない理由は「DB 値との無変換一致」。`dotnet-data` skill の「列挙値カラムは INTEGER」は新規設計時の方針で、既存 DB のコード値は変換せず同型で持つ。
- **判定ヘルパーを同じクラスに同居**させ、生のコード値比較を Domain の外から排除する (最重要ルール)。

```csharp
public static class ProcessState
{
    public const string Requested = "0";
    public const string ApprovalPending = "1";

    public static bool IsCancelable(string value) => value is Requested or ApprovalPending;
}
```

- クラス命名: 種別は複数形 `~Types` / `~Codes`、状態カラムは単数 `~State` / `~Status` / `~Level`。
- SQL の IN 条件など**別表現への変換 (`As~`) も Code クラスに置き**、条件配列は `private static readonly` で事前計算する (呼び出し毎に new しない)。

## Enums (アプリ内論理値): enum + 同一ファイル拡張

- **DB に保存しない**分岐・画面制御用の値は C# enum (1 概念 = 1 enum)。振る舞いが要るときは**同一ファイル内の `XxxExtensions`** に `this` 拡張で添える。

## Logic (純粋関数): 1 業務概念 = 1 クラス

- **1 つの業務概念 (承認・期限計算・判別・生データ解析など) = 1 つの `static class`**。**1 メソッド = 1 判定 or 1 計算**とし、式形式 + switch 式中心で書く。
- 入力はプリミティブ (値・`ReadOnlySpan<byte>` 等) で受け、Models 型を引数にしない。不変 lookup は `static readonly` で事前計算する。
- メソッド命名の語彙: `Is~` / `Can~` (判定)、`Calc~` (計算)、`Convert~` (コード↔表示・型)、`Extract~` (生データ→値)、`Normalize~` (正規化)、`As~` (別表現へ)、`Of~` / `From~` (別値→コード値)。

## ルート定数ホルダ (桁・書式の唯一の正)

- `Length` (桁数 const int。導出定数可) / `Pattern` (書式の正規表現) / `MaxCount` / `SpecialDate` (番兵値) を固定名で置く。
- **検証属性・バリデータ・UI の MaxLength はここだけを参照**する (桁・書式を二重定義しない)。

## ValueObject (例外的少数)

- まず Code + Logic で表す。**複合値に解釈ルールがあるときだけ** `readonly struct` にする (`IEquatable` + 演算子 + `Parse` + `None` 等の static readonly インスタンス)。

## 共通の約束

- 全て **static + 純粋関数**: IO・DI・非同期・インスタンス状態を持たない。値を受け取り値を返す。
- **単体テストの主対象**: テストプロジェクトは `Domain/` のフォルダ構造をミラーする。純粋関数は総当たり検証を使ってよい。
- 汎用ユーティリティ (LINQ / Span / null 安全の拡張) は業務知識ではないので Domain 名前空間の**外**に置く。
