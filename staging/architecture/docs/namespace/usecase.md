# Usecase 層

| 項目 | 内容 |
|---|---|
| ID | namespace-6 |
| 分類 | namespace |
| 関連 | namespace-1(総覧) / namespace-5(モデルサフィックス) / namespace-7(クライアント側) / host-4(DI 登録) / guideline-1(結果による通知) |

## 目的

一連の業務フローを組み立てる層を `Usecase` として独立させる。

- **`Services` と同階層の独立名前空間とする(決定)**。Service のサブ名前空間や画面側には埋めない
- 複数 Service の束ね・外部 SDK 操作の唯一の入口をここに定める
- 呼び出し側(ViewModel / Endpoint)は Usecase を1つ呼ぶだけになり、フローの重複と散在が消える

## 標準形

### 責務

| 項目 | 内容 |
|---|---|
| 役割 | 一連の業務フローの組み立て。複数 Service の束ね、外部 SDK 操作の唯一の入口 |
| 状態 | **ステートレス**。状態は `State` / `Contexts` に置き、Usecase は保持しない(DI は Singleton 登録 → host-4) |
| 参照可 | Service / State / Dialog / Components 等の下位・横断部品 |
| 参照不可 | ViewModel・View・Endpoint(上位)。Usecase 同士の相互参照もしない |
| 戻り値 | **SDK 型を漏らさず record に詰め替える** |

### Service との違い

| | Service | Usecase |
|---|---|---|
| 粒度 | DB・通信のプリミティブ操作(1操作=1メソッド) | 一連の業務フロー |
| 参照 | Accessor・HttpClient 等の I/O 部品のみ。上位を参照しない | Service / State / Dialog を参照可 |
| 判断 | 業務判断・分岐を持たない | 分岐・組み合わせ・進行を担う |

Service は I/O のプリミティブに徹する。

```csharp
namespace Template.Services;

public sealed class UserService
{
    private readonly UserAccessor userAccessor;

    public UserService(UserAccessor userAccessor)
    {
        this.userAccessor = userAccessor;
    }

    public ValueTask<UserEntity?> QueryUserAsync(int id) =>
        userAccessor.QueryUserAsync(id);
}
```

Usecase はフローを組み立てる(クライアント例。State を読み、複数 Service を束ね、Dialog で通知する)。

```csharp
namespace Template.MobileApp.Usecase;

public sealed class OrderUsecase
{
    private readonly IDialog dialog;

    private readonly UserService userService;

    private readonly OrderService orderService;

    private readonly Session session;

    public OrderUsecase(
        IDialog dialog,
        UserService userService,
        OrderService orderService,
        Session session)
    {
        this.dialog = dialog;
        this.userService = userService;
        this.orderService = orderService;
        this.session = session;
    }

    public async ValueTask<bool> SubmitOrderAsync(OrderInput input)
    {
        var user = await userService.QueryUserAsync(session.UserId);
        if (user is null)
        {
            await dialog.InformationAsync("User not found.");
            return false;
        }

        var success = await orderService.InsertOrderAsync(user.Id, input);
        if (!success)
        {
            await dialog.InformationAsync("Order failed.");
        }

        return success;
    }
}
```

### 外部 SDK の詰め替え

外部 SDK(認識・クラウドサービス等)の操作は Usecase を唯一の入口とし、**SDK の型を戻り値に漏らさない**。

```csharp
public sealed record RecognitionResult(string Text, float Confidence);

public sealed class RecognitionUsecase
{
    private readonly VisionClient client;    // 外部 SDK

    public RecognitionUsecase(VisionClient client)
    {
        this.client = client;
    }

    public async ValueTask<RecognitionResult?> RecognizeAsync(Stream image)
    {
        var result = await client.AnalyzeAsync(image);    // SDK 型はここで閉じる
        var line = result.Lines.FirstOrDefault();
        return line is null ? null : new RecognitionResult(line.Text, line.Confidence);
    }
}
```

SDK の差し替え・バージョンアップの影響が Usecase 内で止まる。異常系は例外ではなく結果で返す(guideline-1)。

## 配置ルール

| 対象 | 場所 |
|---|---|
| Usecase クラス | `Usecase/`(`Services` と同階層) |
| 戻り値 record | Usecase と同ファイルまたは `Usecase/` 内 |
| フローが跨いで使う状態 | `State` / `Contexts`(namespace-1)。Usecase には持たせない |

## バリエーションと使い分け

- 画面が Service を1つ呼ぶだけの場合は Usecase を挟まなくてよい。フロー(分岐・複数 Service・SDK)が現れた時点で切り出す
- サーバ側は Endpoint → Usecase → Service、クライアント側は ViewModel → Usecase → Service。呼び出し方向は同型
- 命名は `<業務>Usecase`。SDK 操作の補助クラス(リトライ・進行制御等)は `Usecase` 名前空間に同居させてよい

## アンチパターン

- Service が別の Service を呼ぶ — 束ねは Usecase の仕事。Service は横並びを知らない
- Usecase が状態(前回結果のキャッシュ等)を持つ — 状態は `State` へ
- SDK の型・例外を呼び出し側へそのまま漏らす — record への詰め替えと結果通知(guideline-1)で閉じる
- ViewModel・Endpoint に複数 Service 呼び出しのフローを直書きする
- 単純な1対1呼び出しまで一律に Usecase で包む — 層が形骸化し委譲だけのクラスが量産される
