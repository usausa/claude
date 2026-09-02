# AppComponentBase

| 項目 | 内容 |
|---|---|
| ID | blazor-3 |
| 分類 | blazor |
| 関連 | blazor-4(code-behind 分離) / blazor-5(State 管理) / blazor-6(レイアウト・シェル) / maui-5(Blazor Hybrid) / mvvm-1(BusyState) |

## 目的

全ページ・共通コンポーネントの基底クラス `AppComponentBase` を1つ用意し、**破棄処理と実行ガードの書き方を統一**する。

- 購読解除・タイマー破棄などの後始末を `Disposables` への登録1行に統一する
- Blazor Hybrid では `Execute` / `ExecuteAsync` + `BusyState` ガードを内蔵し、二度押し・多重実行の防止をページに書かせない

## 標準形

### 基本形(`ComponentBase, IDisposable` + 遅延 Disposables)

破棄リストは遅延生成とし、破棄するものがないページにコストを掛けない。

```csharp
namespace Template.Infrastructure.Components;

public abstract class AppComponentBase : ComponentBase, IDisposable
{
    private List<IDisposable>? disposables;

    protected ICollection<IDisposable> Disposables => disposables ??= [];

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (disposing && (disposables is not null))
        {
            foreach (var disposable in disposables)
            {
                disposable.Dispose();
            }

            disposables = null;
        }
    }
}
```

ページ側は `@inherits AppComponentBase` を宣言し、破棄が必要なリソースは `Disposables` に登録するだけでよい。

```razor
@page "/data"
@inherits AppComponentBase
```

```csharp
protected override void OnInitialized()
{
    Disposables.Add(Messenger.Observe<DataChanged>().Subscribe(OnDataChanged));
}
```

### Hybrid 版(Execute / ExecuteAsync + BusyState ガード)

Blazor Hybrid(maui-5)では、基本形に `IBusyState` による実行ガードを加える。実行中の再入(ボタン連打・多重イベント)を基底で防ぐ。破棄リストは Smart 系の `CompositeDisposable` を使い、ファイナライザ付きの Dispose パターンとする。

```csharp
namespace Template.Views;

public abstract class AppComponentBase : ComponentBase, IDisposable
{
    private CompositeDisposable? disposables;

    protected ICollection<IDisposable> Disposables => disposables ??= [];

    [Inject]
    public required IReactiveMessenger Messenger { get; set; }

    [Inject]
    public required IBusyState BusyState { get; set; }

    // Dispose パターン(ファイナライザ + disposables?.Dispose())は省略

    protected void Execute(Action func)
    {
        if (BusyState.IsBusy)
        {
            return;
        }

        using (BusyState.Begin())
        {
            func();
        }
    }

    protected async Task ExecuteAsync(Func<Task> func)
    {
        if (BusyState.IsBusy)
        {
            return;
        }

        using (BusyState.Begin())
        {
            await func().ConfigureAwait(true);
        }
    }

    protected async Task<TResult> ExecuteAsync<TResult>(Func<Task<TResult>> func)
    {
        if (BusyState.IsBusy)
        {
            return default!;
        }

        using (BusyState.Begin())
        {
            return await func().ConfigureAwait(true);
        }
    }

    // パラメータ付きオーバーロード(Execute<TParameter> / ExecuteAsync<TParameter, TResult>)を同型で並べる
}
```

ページのアクションはラムダを包むだけになる。

```csharp
private Task OnClickLoad() =>
    ExecuteAsync(async () =>
    {
        items = await DataService.QueryAsync();
    });
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| AppComponentBase.cs | `Infrastructure/Components/`(namespace-3。Blazor 標準の `Components/` は UI コンポーネント用に空ける)。Hybrid では `Views/` 直下に1ファイル |
| 継承の宣言 | 各ページの `.razor` 先頭で `@inherits AppComponentBase`(`_Imports.razor` での一括指定は行わず、ページ毎に明示する) |

## バリエーションと使い分け

- **基本形(サーバ / WASM)**: Disposables のみ。ブロッキング防止は `ProgressState`(blazor-6)等のレイアウト側機構が担う
- **Hybrid 版(MAUI Blazor)**: `Execute` / `ExecuteAsync` + `BusyState` を内蔵。MVVM 側の `BusyState`(mvvm-1)と同じ部品を共有し、クライアント全体でガードの仕組みを揃える
- **破棄が不要な小さなコンポーネント**: それでも `AppComponentBase` を継承してよい(遅延生成のためコストはない)。素の `ComponentBase` 直継承を混在させない

## アンチパターン

- **ページ毎の IDisposable 手実装** — Dispose パターンの書き方がページごとにぶれる。基底に集約し、ページは `Disposables.Add` のみ
- **購読の解除漏れ** — `Messenger.Observe(...).Subscribe(...)` の戻り値を捨てる。必ず `Disposables` に登録する
- **アクション毎の isBusy フラグ手書き(Hybrid)** — `private bool running` のようなガードフラグをページに書かない。`ExecuteAsync` に包む
- **基底クラスの肥大化** — AppComponentBase に置くのは破棄と実行ガードのような全ページ共通の機構のみ。特定機能のヘルパーはコンポーネントや Infrastructure(blazor-2)へ
