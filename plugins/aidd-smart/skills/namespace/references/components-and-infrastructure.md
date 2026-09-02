# Components と Infrastructure

| 項目 | 内容 |
|---|---|
| ID | namespace-3 |
| 分類 | namespace |
| 関連 | namespace-1(総覧) / namespace-2(Application との使い分け) / namespace-7(クライアント側 Components) / config-1(Options 命名) / config-4(Options の配置) / blazor-2(フレームワーク拡張群) / solution-4(基盤部品のプロジェクト分離) |

## 目的

`Components` と `Infrastructure` の役割を確定し、UI コンポーネントとインフラ部品で置き場が衝突しないようにする。

- **`Components` は Blazor 標準ルール(UI コンポーネントの置き場)を優先する(決定)**
- **インフラ部品(Storage・Security 等)は `Infrastructure` に配置する(決定)**。かつて `Components` に置いていた用法は移行元として扱う
- クライアント側(MAUI 等)の `Components` はプラットフォーム機能ラッパとしてそのまま維持する(決定 → namespace-7)

## 標準形

### Components(Blazor の UI コンポーネント)

Blazor プロジェクトテンプレートの標準構成に従い、UI コンポーネントを置く。

```
Components/
├─ App.razor           # ルートコンポーネント
├─ Routes.razor
├─ Layout/             # MainLayout / NavMenu
├─ Pages/              # ルーティング対象ページ
└─ Shared/             # 再利用コンポーネント・共通ダイアログ
```

`JSRuntimeExtensions` / `NavigationManagerExtensions` 等のフレームワーク拡張は UI コンポーネントではないため `Infrastructure` に集約する(blazor-2)。

### Infrastructure(インフラ部品の4点セット)

インフラ部品は機能単位のサブ名前空間に切り、**`I<Name>` + `<Name>` + `<Name>Options` + `<Name>Exception` の4点セット**を基本形とする。

```
Infrastructure/
├─ Storage/
│  ├─ IStorage.cs             # 抽象(機能名)
│  ├─ FileStorage.cs          # 実装(方式名を冠する)
│  ├─ FileStorageOptions.cs   # 実装付属の設定(config-1)
│  └─ StorageException.cs     # 機能専用の例外
└─ Security/
   ├─ IPasswordProvider.cs
   ├─ DefaultPasswordProvider.cs
   └─ DefaultPasswordProviderOptions.cs
```

- 抽象は機能名(`IStorage`)、実装は方式名を冠する(`FileStorage`)。`*Options` は実装に付属するため実装名を冠する(`FileStorageOptions`)
- 例外は機能単位(`StorageException`)。実装を差し替えても利用側の catch は変わらない
- 4点すべてが必須ではない。設定が不要なら `*Options` を、専用例外が不要なら `*Exception` を省く(`Security` の例は例外なしの3点)

```csharp
namespace Template.Infrastructure.Storage;

public interface IStorage
{
    ValueTask<Stream> ReadAsync(string path, CancellationToken cancellationToken = default);

    ValueTask WriteAsync(string path, Stream stream, CancellationToken cancellationToken = default);
}
```

```csharp
namespace Template.Infrastructure.Storage;

public sealed class FileStorageOptions
{
    public string Root { get; set; } = default!;
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| Blazor の UI コンポーネント | `Components/`(App.razor / Layout / Pages / Shared) |
| インフラ部品(Storage・Security 等) | `Infrastructure/<機能>/` の4点セット |
| Blazor フレームワーク拡張(JSRuntime / NavigationManager 等の拡張メソッド) | `Infrastructure/`(blazor-2) |
| アプリ固有の共通部品 | `Application/`(namespace-2) |
| クライアントのプラットフォーム機能ラッパ | クライアント側の `Components/`(namespace-7) |

## バリエーションと使い分け

- `Application` との境界は「このアプリの知識を含むか」(namespace-2)。`Infrastructure` の部品は他アプリへコピーしてそのまま使える粒度に保つ
- アプリ非依存の部品が育ったら別プロジェクトへ昇格させる(solution-4)。その際は BCL ミラーの名前空間(`<Lib>.IO` / `<Lib>.Threading` 等)を採る
- UI を持たないプロジェクト(Web API・バッチ等)に `Components` は作らない。インフラ部品はすべて `Infrastructure`
- 差し替えが不要で単一実装しかない部品は抽象(`I<Name>`)を省略してよい。差し替え・モック化の必要が生じた時点で抽象を導入する

## アンチパターン

- インフラ部品を `Components` に置く(旧用法)— Blazor の UI 置き場と衝突する。`Infrastructure` へ移す
- 4点セットを1ファイルに同居させる — 1クラス=1ファイルで分割する
- 汎用例外(`Exception` / `InvalidOperationException`)をインフラ部品からそのまま投げる — 機能例外(`<Name>Exception`)に包む
- `*Options` を `Settings/` に置く — コンポーネント付属設定は実装と同居させる(config-4)
- `Infrastructure` に業務知識を持ち込む — URL・キー名・業務ポリシーが現れたらそれは `Application` の部品(namespace-2)
