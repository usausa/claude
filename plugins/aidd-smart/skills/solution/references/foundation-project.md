# 基盤層プロジェクトの分離

| 項目 | 内容 |
|---|---|
| ID | solution-3 |
| 分類 | solution |
| 関連 | solution-1(プロジェクト分割の基本形) / solution-2(Aspire AppHost) / solution-4(Infrastructure の二段構え) / namespace-2(Application 名前空間) / namespace-3(Infrastructure 名前空間) / host-1(ApplicationExtensions) |

## 目的

複数のホスト(実行プロジェクト)を持つ構成で、**「アプリ固有だが業務非依存」の部品**を基盤層プロジェクト(共有 DLL)に分離し、ホスト間の重複を排除する。

- 対象は Filter / ModelBinder / Json Converter / Validation 属性 / Swagger 拡張 / Telemetry / Worker 基盤など、「このアプリの規約を体現するが、業務(ドメイン)を知らない」部品
- 分離は**ホストが複数になったときに初めて行う**。単一プロジェクト構成では分離せず、ホスト内の `Application` / `Infrastructure` 名前空間で足りる(namespace-2, namespace-3)

## 標準形

### 適用基準

| 構成 | 業務非依存部品の置き場 |
|---|---|
| ホストが1つ | ホスト内の `Application/` / `Infrastructure/` 名前空間(namespace-2, namespace-3)。プロジェクトは作らない |
| ホストが複数(API + バッチ + 管理 UI 等) | 基盤層プロジェクトに分離して共有 |
| 製品をまたいで再利用できる(アプリ非依存) | 独立プロジェクト・BCL ミラー名前空間(solution-4) |

### 構成

ホスト2つ(Web API + バッチ)の例。基盤層プロジェクトは役割が伝わる名前とする(以下 `Template.Foundation` と表記)。

```
Template.slnx
├─ Template.Core/                  … 業務ロジック(namespace-1)
├─ Template.Foundation/            … 基盤層: アプリ固有・業務非依存の共有部品
├─ Template.Foundation.AspNetCore/ … ASP.NET Core 標準機能の差し替え実装(隔離)
├─ Template.ApiServer/             … ホスト1: Web API
└─ Template.BatchServer/           … ホスト2: バッチ
```

参照方向は次のとおり。基盤層は業務(Core)に依存せず、Core はフレームワークに依存しない。両者を参照して結線するのはホストのみ。

```
ホスト(ApiServer / BatchServer)
  ├─→ Template.Core                  … 業務ロジック(基盤層に依存しない)
  ├─→ Template.Foundation            … 基盤層(Core に依存しない)
  └─→ Template.Foundation.AspNetCore … 差し替えを使うホストのみ参照
```

### 収容する部品

| 部品 | 例 |
|---|---|
| Filter / ModelBinder | 認証状態のアクション引数注入(web-5)、共通例外フィルタ |
| Json Converter | 日時・独自スカラー型のコンバータ(web-3) |
| Validation 属性 | カスタム検証属性群(web-3) |
| Swagger / OpenAPI 拡張 | スキーマフィルタ、既定ドキュメント設定 |
| Telemetry | `ApplicationInstrument` / 計測拡張(telemetry-1) |
| Worker 基盤 | `IAction` / `ActionWorker` の骨格(worker-1) |
| ServiceDefaults 相当 | テレメトリ・ヘルスチェック等の既定登録(solution-2) |

### ホスト側拡張との関係

起動構成(`ConfigureXxx()`)は各ホストの `ApplicationExtensions.cs` に残す(host-1)。基盤層は**部品と、その既定をまとめて登録する拡張メソッド**を提供し、ホストの `ConfigureXxx()` がそれを呼ぶ。

```csharp
// 基盤層: 既定登録の拡張メソッド(ServiceDefaults 相当、solution-2)
public static class ApplicationDefaultsExtensions
{
    public static IHostApplicationBuilder AddApplicationDefaults(this IHostApplicationBuilder builder)
    {
        builder.AddApplicationInstrumentation();
        builder.Services.AddHealthChecks();

        return builder;
    }
}
```

```csharp
// ホスト側: ApplicationExtensions.cs(host-1)から呼ぶ
public static IHostApplicationBuilder ConfigureTelemetry(this IHostApplicationBuilder builder)
{
    builder.AddApplicationDefaults();

    return builder;
}
```

### ASP.NET Core 標準機能の差し替えの隔離

標準機能の**差し替え実装**(既定 ModelBinder の置き換え、フレームワーク内部の規約に沿った実装差し替え等)は、通常の基盤部品と同居させず、さらに別プロジェクトに隔離する。

- フレームワークのバージョン追従で壊れやすいコードを1プロジェクトに閉じ込め、更新時の影響範囲と再検証の単位を明確にする
- 公開 API のみに依存する通常の基盤部品と安定度が異なるため、参照の有無でホスト毎に選択可能にする

## 配置ルール

| 対象 | 場所 |
|---|---|
| 複数ホストで共有する業務非依存部品 | 基盤層プロジェクト |
| ASP.NET Core 標準機能の差し替え実装 | 基盤層からさらに分離した専用プロジェクト |
| ServiceDefaults 相当の既定登録 | 基盤層プロジェクト(solution-2) |
| ホスト固有の起動構成(`ConfigureXxx()`) | 各ホストの `ApplicationExtensions.cs`(host-1) |
| 単一ホスト構成の同種部品 | ホスト内 `Application/` / `Infrastructure/`(namespace-2, namespace-3) |

## バリエーションと使い分け

- **段階的な昇格**: 最初からは作らない。単一ホストの間は `Application/` / `Infrastructure/` 名前空間に置き、2つ目のホストが現れた時点で基盤層プロジェクトへ引き上げる。名前空間分類を保っていれば移動はフォルダ単位で済む
- **solution-4 との関係**: 基盤層は**同一アプリ内・複数ホスト間**の共有であり、アプリの規約(設定クラス・ログ・命名)に依存してよい。**製品をまたぐ**共有はアプリ非依存の独立プロジェクト(solution-4)であり、基盤層とは分ける
- **バッチが多数ある構成**: Worker 基盤(worker-1)を基盤層に置き、各バッチホストは `IAction` 実装の追加だけになる

## アンチパターン

- **単一ホストでの先回り分離** — 共有先が無いのに基盤層プロジェクトを作る。名前空間で分けておけば必要になった時点で移動できる
- **基盤層への業務ロジック混入** — 基盤層から `Template.Core` への参照が生えたら誤り。業務を知る部品はホストか Core へ置く
- **`Common` / `Shared` という雑多プロジェクト** — 「アプリ固有かつ業務非依存」という判定基準を名前が失い、何でも入る置き場になる
- **差し替え実装と通常部品の同居** — フレームワーク更新の影響が基盤層全体へ波及し、差し替えを使わないホストまで巻き込む
- **ホスト間のコピペ共有** — プロジェクト分離を避けて同一部品を複製する。修正が全ホストに伝播しない
