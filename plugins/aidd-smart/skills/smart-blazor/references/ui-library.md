# UI ライブラリ

| 項目 | 内容 |
|---|---|
| ID | blazor-9 |
| 分類 | blazor |
| 関連 | blazor-1(ViewHelper / ViewExtensions) / blazor-2(フレームワーク拡張群) / blazor-6(レイアウト・シェル) |

## 目的

**UI ライブラリはプロジェクト固有の選定とし、共通要件では規定しない(決定)。**

- 画面要件・ライセンス・チームの習熟はプロジェクト毎に異なるため、特定ライブラリを標準として固定しない
- 共通要件が定めるのは「UI ライブラリ依存をどこに閉じ込めるか」の構造のみとする

## 標準形

UI ライブラリの選定は自由。ただし依存の置き場は次のとおり固定する。

| UI ライブラリ依存が現れてよい場所 | 例 |
|---|---|
| `.razor` マークアップ | コンポーネントタグ(`<MudButton>` 等) |
| `.razor.cs`(code-behind) | ライブラリのサービス型の `[Inject]`・パラメータ型 |
| `ViewHelper` / `ViewExtensions`(blazor-1) | ライブラリの表示属性型(Variant / Icon 等)を返す変換 |
| フレームワーク拡張群(blazor-2) | `ISnackbar` / `IDialogService` 等への拡張メソッド |
| テーマ・スタイル定義 | `Styles.cs` 等の一元定義クラス + レイアウトの Provider 群(blazor-6) |
| Program.cs の登録 | `AddXxxServices()` と通知等のグローバル設定(1箇所に集約) |

逆に、**`Services` / `Usecase` / `Models` / `Domain` には UI ライブラリの型を持ち込まない**。UI 依存は Components(および Infrastructure の拡張群)より外に漏らさない。

```csharp
// Program.cs — ライブラリのグローバル設定は登録箇所の1箇所に集約する(例は MudBlazor の場合)
builder.Services.AddMudServices(config =>
{
    config.SnackbarConfiguration.PositionClass = Defaults.Classes.Position.BottomRight;
    config.SnackbarConfiguration.VisibleStateDuration = 3000;
});
```

## 配置ルール

| 対象 | 扱い |
|---|---|
| ライブラリの選定 | プロジェクト固有。共通要件では指定しない |
| テーマ定義 | 1クラス(`Styles.cs` 等)に集約し、レイアウトの Provider から参照する |
| 通知・ダイアログの呼び出し規約 | 拡張メソッド(blazor-2)で意図名に固める |
| 本ドキュメント群のコード例 | MudBlazor を使う例があるが**例示であって規定ではない** |

## バリエーションと使い分け

選定時の確認観点(規定ではなくチェックリスト):

- 採用するホスティングモデル / レンダリングモード(Server / WASM / Hybrid)への対応
- ライセンスと商用利用条件、メンテナンスの活発さ
- ダイアログ・通知・テーマ等、シェル機構(blazor-6)との統合のしやすさ
- 素の HTML + CSS(または軽量ライブラリ)で足りる規模なら、ライブラリを入れない選択も含めて判断する

## アンチパターン

- **共通要件としての UI ライブラリ強制** — プロジェクト事情を無視した統一は形骸化する。規定するのは依存の閉じ込め構造のみ
- **複数 UI ライブラリの混在** — 1アプリ内でのライブラリ併用はテーマ・スタイルの整合が取れなくなる。原則1つに絞る
- **Service / Usecase への UI 型漏出** — 戻り値・引数にライブラリの型(Snackbar / DialogResult 等)が現れたら層違反。UI 側で変換する
- **テーマ・スタイル値の散在** — 色・余白等をページ毎に直書きしない。テーマ定義クラスに集約する
