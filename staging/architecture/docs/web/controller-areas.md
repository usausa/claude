# Controller + Areas(代替方式)

| 項目 | 内容 |
|---|---|
| ID | web-2 |
| 分類 | web |
| 関連 | web-1(Minimal API) / web-3(API 契約) / web-5(認証状態管理) / web-6(エラー応答・OpenAPI) / namespace-5(モデルサフィックス) |

## 目的

API 方式は Minimal API を優先する(決定 → web-1)。本トピックは **Controller を使う場合の作法**を定義し、方式の使い分け基準を明確にする。

- Controller を採用する場合も、属性の重複記述を排除し「極薄 Controller」に統一する
- Area 単位で Controller / Models を近接配置し、機能のまとまりを物理配置に写す

## 使い分け基準

| 条件 | 方式 |
|---|---|
| 新規のスタンドアロン Web API | **Minimal API(web-1)を使用する。迷ったらこちら** |
| 既存の Controller 資産があるプロジェクトの拡張 | Controller 方式を継続する(方式混在によるコストの方が高い) |
| Blazor Server / MVC アプリに少数の内部 API を同居させる | Controller 方式も許容(既に MVC パイプラインが有効なため) |
| Area 単位に多数の画面向け API を整理する大規模 API | Controller + Areas 方式を検討する(`[area]/[controller]/[action]` の規約ルーティングが効く) |
| ModelBinder / ActionFilter 等 MVC 固有の拡張点に依存する資産がある | Controller 方式(Minimal API 側は EndpointFilter で代替できるなら web-1) |

1 プロジェクト内で両方式を混在させる場合は、境界(例: 公開 API は Minimal API、画面向け内部 API は Controller)を決めてから始める。

## 標準形

### Base Controller への属性集約

`[ApiController]` / `[Area]` / `[Route]` は Area 毎の基底クラスに 1 回だけ書き、個々の Controller には書かない。

```csharp
namespace Template.Server.Api;

[Area("api")]
[Microsoft.AspNetCore.Mvc.Route("[area]/[controller]/[action]")]
[ApiController]
public abstract class BaseApiController : ControllerBase
{
}
```

### 極薄 Controller

Controller は「mapper.Map + Service 呼び出し + ActionResult 変換」のみとし、業務ロジックを持たない。

```csharp
namespace Template.Server.Api.Controllers;

using Template.Server.Api.Models;

public sealed class TestController : BaseApiController
{
    [HttpGet]
    public IActionResult Time()
    {
        return Ok(new TestTimeResponse { DateTime = DateTime.Now });
    }
}
```

Service を伴う場合もパターンは同じにする。

```csharp
public sealed class DataController : BaseApiController
{
    private readonly DataService dataService;

    private readonly IMapper mapper;

    public DataController(DataService dataService, IMapper mapper)
    {
        this.dataService = dataService;
        this.mapper = mapper;
    }

    [HttpGet("{id:long}")]
    public async ValueTask<IActionResult> Get(long id)
    {
        var entity = await dataService.QueryAsync(id);
        return entity is not null
            ? Ok(mapper.Map<DataResponse>(entity))
            : NotFound();
    }
}
```

### Request / Response の配置

DTO は Area 毎の `Models/` に置く。命名は web-3 に従い `*Request` / `*Response` とする。

```
Areas/
└─ Api/
   ├─ BaseApiController.cs
   ├─ Controllers/
   │  ├─ DataController.cs
   │  └─ TestController.cs
   └─ Models/
      ├─ DataResponse.cs
      └─ TestTimeResponse.cs
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| Area 基底 Controller | `Areas/<Area>/Base<Area>Controller.cs`(小規模なら `Api/` 直下) |
| Controller | `Areas/<Area>/Controllers/` |
| Request / Response DTO | `Areas/<Area>/Models/` |
| ModelBinder / Filter 等 MVC 拡張 | `Infrastructure/` または `Components/`(namespace-3) |

## バリエーションと使い分け

- **Blazor Server 同居型**: Blazor Server に少数の内部 API を持たせる場合は `Api/` フォルダ(`BaseApiController` + `Controllers/` + `Models/`)の最小構成でよい。Areas のフォルダ規約は Area が複数になってから導入する
- **JSON オプション**: Controller 方式では `AddControllers().AddJsonOptions(...)` で web-3 の命名規約(camelCase)を適用する。`ConfigureHttpJsonOptions` は Minimal API 側にしか効かない点に注意
- **認証状態の注入**: Controller 方式ではアクション引数への ModelBinder 注入が使える(web-5)

## アンチパターン

- **新規 API での Controller 採用** — 適用条件に該当しない新規プロジェクトで Controller を選ばない。Minimal API が標準(決定)
- **属性の繰り返し** — `[ApiController]` / `[Route]` を各 Controller に書かない。基底クラスに集約する
- **Fat Controller** — Controller 内の条件分岐・複数 Service の束ね・トランザクション制御は Service / Usecase へ移す
- **DTO の共用逃げ** — Entity や View モデルをそのまま API 応答に使わない。Area の `Models/` に `*Response` を定義する(web-3)
- **無方針な方式混在** — 同じリソースの API が Minimal API と Controller に泣き別れる状態を作らない
