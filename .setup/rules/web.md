---
paths:
  - "src/**"
---

# アーキテクチャ (Web 全般)

> **ASP.NET Core (Web) の全般** (API / Blazor 共通)。API 固有は [`api.md`](api.md)、Blazor UI は [`blazor.md`](blazor.md)。.NET 共通の規範 (async / errors / logging / data / security / http-client) は対象ファイルを読むと自動適用される。プロジェクト方針は [`conventions.md`](conventions.md)。

## レイヤ (依存は上→下のみ)

```
Program.cs → Application (組み立て/DI/ルート定数)
                 │
     ┌───────────┼───────────┐
     ▼           ▼           ▼
 Endpoints    Components   (ミドルウェア)
 (minimal API)  (Blazor)
     └─────┬─────┘
           ▼
        Services → (DB / 外部通信)      Models=POCO, Domain=純粋ロジック
```

| レイヤ | 責務 |
|---|---|
| Program.cs | 合成起点。builder 構成・Serilog・DI 登録・パイプライン・Map。**薄く保つ** |
| Application | 起動の組み立てを Program から切り出す拡張群、ルート定数 (`ApiRoutes`)、共通ヘルパー |
| Endpoints | minimal API (採用時。詳細は [`api.md`](api.md)) |
| Components | Blazor UI (採用時。詳細は [`blazor.md`](blazor.md)) |
| Services | DB/ファイル/外部通信のプリミティブ。DI 登録。設定は注入で受ける (注入形は要件で選定) |
| Models / Domain | POCO / 純粋ロジック |

- Endpoints / Components は**採用するものだけ置く** (API のみ・Blazor のみの構成も可)。

## ログの具体 ([logging.md](logging.md) の実装)
- Serilog: `AddSerilog(o => o.ReadFrom.Configuration(builder.Configuration))`。出力の書き方は [logging.md](logging.md) (LoggerMessage 全面採用・配置は適宜分割)。

## データの具体 ([data.md](data.md) の実装)
- ORM / データアクセス方式は用途で選定 ([data.md](data.md))。接続文字列は `appsettings` / 環境変数 (`GetConnectionString()`)。

## セキュリティの具体 ([security.md](security.md) の実装 / サーバ側)
- 認証・認可は ASP.NET Core Authentication/Authorization。エンドポイントに `RequireAuthorization()`。
- HTTPS 必須 (`UseHttpsRedirection` / HSTS)。CORS は許可元を明示的に絞る。
- 秘匿値の保護は DataProtection / ユーザーシークレット / Key Vault。
- 非 GET の状態変更は antiforgery/CSRF 対策 (Blazor 側は [`blazor.md`](blazor.md))。
