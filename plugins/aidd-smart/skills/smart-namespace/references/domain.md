# Domain の作法

| 項目 | 内容 |
|---|---|
| ID | namespace-4 |
| 分類 | namespace |
| 関連 | namespace-1(総覧) / namespace-5(Entity のコード値カラム) / namespace-2(業務定数との線引き) / data-1(アクセサ) / test-1(純粋ロジックのテスト) |

## 目的

業務知識(コード値・純粋ロジック・桁数)を `Domain` に集約し、I/O やフレームワークから切り離す。

- コード値の定義と判定が一箇所になり、マジックナンバーが消える
- 純粋ロジックは引数と戻り値だけで完結し、単体テストが容易になる
- **Domain は他レイヤに依存しない**。参照方向は常に「他レイヤ → Domain」の一方向

## 標準形

### フォルダ構成

```
Domain/
├─ Code/       # DB に格納されるコード値(static class + const。1 区分 = 1 クラス)
│  ├─ AlertLevel.cs
│  └─ UserType.cs
├─ Enums/      # DB に保存しないアプリ内の論理値(enum + 同一ファイル拡張)
├─ Logic/      # I/O 非依存の純粋ロジック(1 業務概念 = 1 クラス)
│  └─ PriceLogic.cs
├─ Length.cs   # 桁数定数の集約
└─ Pattern.cs  # 書式の正規表現(必要に応じ MaxCount / SpecialDate 等の横断定数ホルダを固定名で追加)
```

Domain は **Models 型(Entity / View / Parameter)に依存しない**。入力はプリミティブ(値・`ReadOnlySpan<byte>` 等)で受け、Models との接着は Service / ViewModel / Converter 側の責務とする。DI・I/O が要る共通処理は Domain ではなく Usecase 層の部品に置く(namespace-6)。

### Domain/Code — コード値は enum ではなく static class + const

DB の数値/文字列カラムと直結する値は **enum ではなく `static class` + `const`** で定義し、判定メソッドを同居させる。

```csharp
namespace Template.Domain.Code;

public static class AlertLevel
{
    public const sbyte None = 0;
    public const sbyte Warning = 1;
    public const sbyte Error = 2;

    public static bool IsAlert(sbyte value) => value > None;
}
```

- Entity のプロパティはカラム型そのまま(`sbyte` / `string`)。変換・キャストが発生しない
- 判定ロジックが値定義と同居し、利用側は `AlertLevel.IsAlert(entity.Level)` と書ける

enum を使わない理由:

| 観点 | enum | static class + const |
|---|---|---|
| DB 値との対応 | キャスト・変換が必要 | カラム型と 1:1、変換不要 |
| 未定義値の扱い | 未定義値もキャストで生成でき、正当性検証が別途必要 | 値はただの数値/文字列。定義済み判定もメソッドで表現 |
| 判定ロジック | 拡張メソッドを別クラスに書くことになる | 定数と同じクラスに同居 |
| ビット演算・比較 | キャストの連続になりがち | 素の演算子でそのまま書ける |

文字列コードも同形で定義する。

```csharp
namespace Template.Domain.Code;

public static class UserType
{
    public const string Admin = "A";
    public const string Member = "M";

    public static bool IsAdmin(string value) => value == Admin;
}
```

Code クラスの規約:

- クラス命名は、種別なら複数形(`~Types` / `~Codes`)、状態カラムなら単数(`~State` / `~Status` / `~Level`)
- 判定ヘルパーを値定義と同居させ、**生のコード値比較を Domain の外から排除する**
- SQL の IN 条件など**別表現への変換(`As~`)も Code クラスに置き**、条件配列は `private static readonly` で事前計算する(呼び出し毎に new しない)

### Domain/Enums — アプリ内で閉じる論理値

**DB に保存しない**分岐・画面制御用の値は C# enum(1 概念 = 1 enum)で `Domain/Enums/` に置き、振る舞いが要るときは**同一ファイル内の `XxxExtensions`** に `this` 拡張で添える。

境界を跨ぐ(DB に保存する・API で送る)値になった時点で `Domain/Code` の const へ移す。フレームワークが要求する enum はその利用箇所のレイヤに置いてよい。

### Domain/Logic — 純粋ロジック

I/O 非依存(DB・通信・時刻取得をしない)の業務計算をクラスとして置く。

```csharp
namespace Template.Domain.Logic;

public static class PriceLogic
{
    public static int CalcTotal(int unitPrice, int quantity, decimal taxRate) =>
        (int)Math.Floor(unitPrice * quantity * (1 + taxRate));
}
```

入出力が引数と戻り値だけなので、テストは AAA の数行で書ける(test-1)。現在時刻のような環境依存値は引数で受け、取得は上位に任せる(`Providers` → namespace-1)。

Logic クラスの規約:

- **1 つの業務概念(承認・期限計算・判別・生データ解析など)= 1 つの `static class`**、1 メソッド = 1 判定 or 1 計算とし、式形式 + switch 式中心で書く
- メソッド命名の語彙: `Is~` / `Can~`(判定)、`Calc~`(計算)、`Convert~`(コード↔表示・型)、`Extract~`(生データ→値)、`Normalize~`(正規化)、`As~`(別表現へ)、`Of~` / `From~`(別値→コード値)
- 不変 lookup は `static readonly` で事前計算する
- 判定が複雑化したら `Code` の static メソッドから `Logic` のクラスへ昇格させる

### 横断定数ホルダ — Length / Pattern 等(桁・書式の唯一の正)

入力制限・検証・DB 定義で共有する値を固定名のクラスに集約する。`Length`(桁数 const int。導出定数可)/ `Pattern`(書式の正規表現)を基本とし、必要に応じ `MaxCount` / `SpecialDate`(番兵値)等を追加する。**検証属性・バリデータ・UI の MaxLength はここだけを参照**し、桁・書式を二重定義しない。

```csharp
namespace Template.Domain;

public static class Length
{
    public const int UserId = 8;
    public const int UserName = 40;
    public const int Password = 256;
}
```

### ValueObject(例外的少数)

まず Code + Logic で表す。**複合値に解釈ルールがあるときだけ** `readonly struct` にする(`IEquatable<T>` + 演算子 + `Parse` + `None` 等の static readonly インスタンス)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| コード値定数 | `Domain/Code/`(1 区分 = 1 クラス) |
| アプリ内で閉じる enum | `Domain/Enums/`(enum + 同一ファイル拡張) |
| 純粋ロジック | `Domain/Logic/`(1 業務概念 = 1 クラス) |
| 横断定数ホルダ | `Domain/Length.cs` / `Pattern.cs` 等(固定名) |
| 汎用ユーティリティ(LINQ / Span / null 安全の拡張) | 業務知識ではないため Domain の**外**(Infrastructure 等) |
| Core 分離構成(solution-1) | `Domain` は Core プロジェクト側 |

依存方向: `Domain` は BCL 以外を参照しない。`Models` / `Services` / `Usecase` / `Endpoints` から参照される側であり、逆参照しない。

## バリエーションと使い分け

- 判定が複雑化したら `Code` の static メソッドから `Logic` のクラスへ昇格させる
- 業務定数の線引き: 業務仕様に由来する値(コード値・桁数)は `Domain`、アプリ運用のポリシー値(ページサイズ・件数上限)は `Application` の `LimitPolicy`(namespace-2)
- クライアント側でも同じ作法で `Domain` を持つ(namespace-7)

## アンチパターン

- コード値を enum で定義して DB 値とキャスト変換する — const で 1:1 に保つ
- マジックナンバーの直書き(`if (entity.Level > 0)`)— 必ず `AlertLevel.IsAlert` のような判定メソッドを通す
- `Domain` から Service・Accessor・設定クラスを参照する — 必要な値はすべて引数で受ける
- 桁数リテラルを検証属性・SQL・画面に散らす — `Length` 参照に統一する
- `DateTime.Now` を `Logic` 内で呼ぶ — 時刻は引数で受ける
