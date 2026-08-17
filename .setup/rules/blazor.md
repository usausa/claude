---
paths:
  - "**/*.razor"
  - "**/*.razor.cs"
  - "**/Components/**"
---

# Blazor Server (UI / コンポーネント)

> ASP.NET Core Web の **Blazor Server UI** 固有。Web 全般は [`web.md`](web.md)、API は [`api.md`](api.md) を参照。

## セットアップ
- `AddRazorComponents().AddInteractiveServerComponents()` / `MapRazorComponents<App>().AddInteractiveServerRenderMode()`。
- 配置は `Components/` (`Layout/`・`Pages/`・`App.razor`・`Routes.razor`・`_Imports.razor`)。

## コンポーネント設計
- コンポーネントにロジックを書かず **Service / Application へ委譲**する (薄いコンポーネント)。
- 状態は必要なスコープで持つ。長寿命の状態は Service / State へ寄せる。
- 複雑なコンポーネントはコードビハインド (部分クラス) で整理し、ロジックは下位層へ。

## UI / UX
- レイアウトは `Layout/` で共通化。レスポンシブを前提にする。
- スタイルは分離 (CSS 分離 / 共通スタイル)。色・サイズを各所に散在させない。
- アクセシビリティ (aria 属性、フォーカス制御、コントラスト) を考慮。
- ローディング / エラー / 空状態の表示を用意する。

## セキュリティの具体 ([security.md](security.md) の実装 / UI 側)
- 認証状態は `AuthenticationStateProvider` / `<AuthorizeView>` で扱う。
- 双方向 (interactive) 更新は antiforgery を有効に (`UseAntiforgery`)。
- レンダーモードに応じ、サーバ回路に機微データを載せすぎない。
- ユーザー入力の表示はフレームワークのエスケープに任せ、`MarkupString` の直挿しを避ける。
