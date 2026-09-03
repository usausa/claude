# 警告抑止の三層

| 項目 | 内容 |
|---|---|
| ID | structure-4 |
| 分類 | structure |
| 関連 | structure-1(AGENTS.md 規約) / structure-3(Analyzers.ruleset) / structure-5(定型ファイル) / guideline-1(エラー処理) / guideline-2(非同期作法) / log-1(Log.cs) |

## 目的

警告の抑止を**「どの範囲に効かせるか」で三層に分離し、それぞれの置き場を固定する**。

| 層 | 手段 | 範囲 | 用途 |
|---|---|---|---|
| ① | Analyzers.ruleset(structure-3) | ソリューション全体 | 全プロジェクトで採用しないルール |
| ② | GlobalSuppressions.cs | アセンブリ(プロジェクト)単位 | 層の特性上そのプロジェクトでは意味をなさないルール |
| ③ | `#pragma warning disable` / `[SuppressMessage]` | クラス・メソッド・行 | 意図を持った局所的な例外 |

②が ruleset と分かれているのは、**規則の妥当性がアセンブリの層によって変わるため**である。同じ規則でも「ライブラリでは抑止しない」という判断をプロジェクト粒度で下せる。

## 標準形

### ② GlobalSuppressions.cs(アセンブリ単位の恒久抑止)

ホストプロジェクトの標準ペアは **CA1515 + CA2007**。

```csharp
[assembly: SuppressMessage("Maintainability", "CA1515:Consider making public types internal", Justification = "Ignore")]
[assembly: SuppressMessage("Reliability", "CA2007:Do not directly await a Task", Justification = "Ignore")]
```

- **CA1515(トップレベル型を internal にせよ)** — 型の公開範囲は用途で判断するため、実行可能プロジェクトでも一律の internal 化は行わない
- **CA2007(ConfigureAwait 必須)** — SynchronizationContext を持たない Web ホスト・アプリ層では `ConfigureAwait(false)` は意味をなさないため抑止する。**複数アプリから再利用する共通サービス用 DLL では意味をなすため抑止しない**(`ConfigureAwait(false)` を書く。guideline-2)。この層依存性のため ruleset には含めず、プロジェクト単位で無効化する

アプリ内ライブラリ(Core)では CA2007 のみとなる(CA1515 は実行可能プロジェクト向けの規則のため対象外)。

```csharp
[assembly: SuppressMessage("Reliability", "CA2007:Do not directly await a Task", Justification = "Ignore")]
```

アセンブリ全体への恒久抑止は、判断理由が層特性そのものであるため Justification は定型の `"Ignore"` でよい。

### ③ 局所抑止

範囲を最小にし、対象のクラス・メソッド単位で `disable` / `restore` で囲む。

```csharp
#pragma warning disable CA1031
// 監視ループは何があっても継続する(異常はログのみ)
try
{
    await ProcessAsync(entry);
}
catch (Exception ex)
{
    log.ErrorProcessFailed(ex);
}
#pragma warning restore CA1031
```

`[SuppressMessage]` を使う場合、Justification には**理由を日本語で書く**。

```csharp
[SuppressMessage("Performance", "CA1819:Properties should not return arrays", Justification = "設定バインド用クラスのため配列プロパティを許容する")]
public string[] Urls { get; set; } = default!;
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| ルール強度の定義 | ルートの Analyzers.ruleset(structure-3) |
| アセンブリ単位の恒久抑止 | 各プロジェクト直下の GlobalSuppressions.cs(structure-5) |
| 局所抑止 | 対象コードの直近。ファイル全体には広げない |

判断フローは次のとおり。

1. 全アセンブリで採用しない → ruleset で無効化(①)
2. このアセンブリでは層の特性上意味をなさない → GlobalSuppressions.cs(②)
3. この箇所だけ意図的に外す → `#pragma` / `[SuppressMessage]` を最小範囲で(③)

なお、抑止の追加自体が要相談事項である(AGENTS.md の規約 → structure-1)。

## バリエーションと使い分け

プロジェクトの事情に応じて②へ追加してよい代表例。

- **CA1848(LoggerMessage の使用)** — `[LoggerMessage]` 定型(log-1)を使わない小規模プロジェクトのみ
- **CA1819(配列プロパティ)/ CA1861(定数配列引数)** — 設定クラス・宣言的定義が中心のプロジェクト
- **SonarAnalyzer 併用時の S 系(S125 / S1135 等)** — コメントアウトコード・TODO の扱いを別途運用する場合
- **CA1707(識別子のアンダースコア)** — 原則不要。テスト命名(test-3)はアンダースコアを含まない3部構成のため、テストプロジェクトでも抑止せずに済む

## アンチパターン

- **層依存規則を ruleset に入れる** — CA2007 を ruleset で無効化すると、本来 `ConfigureAwait(false)` を書くべき汎用ライブラリまで検査から外れる
- **番号なしの `#pragma warning disable` でファイル全体を覆う** — 全警告が消える。許されるのは GlobalUsing.cs 等の宣言専用の定型ファイル(structure-5)のみ
- **`restore` の書き忘れ** — 抑止範囲がファイル末尾まで漏れる。囲む形を崩さない
- **csproj の NoWarn への追記による抑止** — 抑止の存在がコードから見えなくなる。アセンブリ単位の抑止は GlobalSuppressions.cs に置き、grep で追える状態を保つ
- **局所抑止の理由省略** — ③では「なぜ例外か」を Justification か前置コメントで日本語で残す
