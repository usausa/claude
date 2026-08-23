---
paths:
  - "**/*.razor"
  - "**/*.razor.cs"
  - "**/Components/**"
---

# Blazor (UI / コンポーネント)

> ASP.NET Core Web の **Blazor UI** 固有 (Server / WASM 共通。Server 固有の点はその旨明記)。Web 全般は [`web.md`](web.md)、API は [`api.md`](api.md) を参照。ホスティング構成・認証基盤・エラーページの配線は起動の組み立て側が担保する。

## コンポーネントの形

- **razor と code-behind を常時分離**する: `Page.razor` + `sealed partial class`。ロジックは code-behind に置き、実処理は Service / Application へ委譲する (薄いコンポーネント)。
- 依存は **`[Inject] required` プロパティ**で受ける。定義順は field → `[Inject]` → パラメータ → メソッド。
- 状態は必要なスコープで持つ。長寿命の状態は Service / State へ寄せる。
- Rx 購読等の破棄は共通基底の `Disposables` に登録し、破棄漏れを防ぐ (基底の実装は組み立て側)。
- 配置は `Components/` (`Layout/`・`Pages/`・`App.razor`・`Routes.razor`・`_Imports.razor`)。

## フォーム検証

- フォームの入力型と検証は**ページ内で完結**させる (検証クラスを別ファイルに増やさない)。検証ライブラリはプロジェクトで選定し `/adr` に残す。
- 桁・書式は Domain の定数 (`Length` / `Pattern`) を参照し、**二重定義しない** ([domain.md](domain.md))。

## ダイアログ

- ダイアログ呼び出しは**拡張メソッド `ShowXxx()`** でパラメータ組立を隠蔽し、`ValueTask<bool>` (確定 / キャンセル) を返す形に統一する (呼び出し側は 1 行)。

## UI / UX

- レイアウトは `Layout/` で共通化。レスポンシブを前提にする。
- スタイルは分離 (CSS 分離 / 共通スタイル)。色・サイズを各所に散在させない。
- アクセシビリティ (aria 属性、フォーカス制御、コントラスト) を考慮。
- ローディング / エラー / 空状態の表示を用意する。
- ビジー管理: ビジー状態を上位から配布し (CascadingParameter 等)、スコープは `using` できる形で開始・終了を対にする。Busy 中は実行ガードで多重実行を拒否する。
- エラー境界: コンポーネント内で例外を握らない。ErrorBoundary + エラーページ (組み立て側の配線) に任せ、業務エラーの表示だけを扱う。

## セキュリティの具体 ([security.md](security.md) の実装 / UI 側)

- 認可はページ単位に `[Authorize(Roles = ...)]` (ロール名は定数クラス参照で typo を防ぐ)。認証状態は `AuthenticationStateProvider` / `<AuthorizeView>` で扱う。
- 双方向 (interactive) 更新は antiforgery を有効に (`UseAntiforgery`。Server)。
- Server はレンダーモードに応じ、サーバ回路に機微データを載せすぎない。WASM はクライアント側に秘匿値を置かない。
- ユーザー入力の表示はフレームワークのエスケープに任せ、`MarkupString` の直挿しを避ける。

## その他

- 画面状態 (ページ番号・検索条件) の保持方式はホスティング形態 (Server / WASM) で異なるため、共通ルールにしない (プロジェクトで方式を決める)。
