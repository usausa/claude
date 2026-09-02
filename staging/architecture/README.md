# template-architecture

既存プロジェクト群から蒸留した .NET アプリケーションのアーキテクチャ規約集。
トピックカタログと決定事項の経緯は [TOPICS.md](TOPICS.md) にある(分類 = フォルダ、トピック = 1ファイル)。
ルート直下の `.editorconfig` / `Directory.Build.props` / `Analyzers.ruleset` は正典として管理する実物。
**本リポジトリは凍結**: 内容は usausa/template-spec(2 段プラグイン構成: aidd-dotnet / aidd-smart)へ統合され、以後の改稿はそちらで行う。テンプレ群(template-*)が参照する正典実物(Analyzers.ruleset / .editorconfig)の新しい置き場も統合先となる。

## 索引

### structure — プロジェクト構造

| ID | ドキュメント | 内容 |
|---|---|---|
| structure-1 | [repository-layout](docs/structure/repository-layout.md) | リポジトリ骨格 |
| structure-2 | [directory-build-props](docs/structure/directory-build-props.md) | Directory.Build.props 標準 |
| structure-3 | [analyzers-ruleset](docs/structure/analyzers-ruleset.md) | Analyzers.ruleset(共通化) |
| structure-4 | [warning-suppression](docs/structure/warning-suppression.md) | 警告抑止の三層 |
| structure-5 | [standard-files](docs/structure/standard-files.md) | 定型ファイル |
| structure-6 | [coding-style](docs/structure/coding-style.md) | コーディングスタイル(.editorconfig) |
| structure-7 | [member-order](docs/structure/member-order.md) | メンバ記述順序 |

### solution — ソリューション・プロジェクト分割

| ID | ドキュメント | 内容 |
|---|---|---|
| solution-1 | [project-layout](docs/solution/project-layout.md) | プロジェクト分割の基本形 |
| solution-2 | [aspire-apphost](docs/solution/aspire-apphost.md) | Aspire AppHost(ServiceDefaults なし) |
| solution-3 | [foundation-project](docs/solution/foundation-project.md) | 基盤層プロジェクトの分離 |
| solution-4 | [infrastructure-projects](docs/solution/infrastructure-projects.md) | Infrastructure の二段構え |

### namespace — 名前空間辞書

| ID | ドキュメント | 内容 |
|---|---|---|
| namespace-1 | [server-namespaces](docs/namespace/server-namespaces.md) | サーバ側の標準語彙 |
| namespace-2 | [application-namespace](docs/namespace/application-namespace.md) | Application 名前空間 |
| namespace-3 | [components-and-infrastructure](docs/namespace/components-and-infrastructure.md) | Components / Infrastructure |
| namespace-4 | [domain](docs/namespace/domain.md) | Domain の作法 |
| namespace-5 | [model-suffixes](docs/namespace/model-suffixes.md) | モデルのサフィックス規約 |
| namespace-6 | [usecase](docs/namespace/usecase.md) | Usecase 層 |
| namespace-7 | [client-namespaces](docs/namespace/client-namespaces.md) | クライアント側の標準語彙 |

### host — 起動処理(サーバ系)

| ID | ドキュメント | 内容 |
|---|---|---|
| host-1 | [program-structure](docs/host/program-structure.md) | Program.cs の構成 |
| host-2 | [startup-boilerplate](docs/host/startup-boilerplate.md) | 起動の定型行 |
| host-3 | [startup-logging](docs/host/startup-logging.md) | 起動ログの儀式 |
| host-4 | [di-registration](docs/host/di-registration.md) | DI 登録スタイル |
| host-5 | [partial-program](docs/host/partial-program.md) | public partial class Program |

### deploy — サービス化・発行

| ID | ドキュメント | 内容 |
|---|---|---|
| deploy-1 | [service-hosting](docs/deploy/service-hosting.md) | Windows / systemd 両対応 |
| deploy-2 | [systemd-unit](docs/deploy/systemd-unit.md) | systemd unit の定石 |
| deploy-3 | [publish-script](docs/deploy/publish-script.md) | 発行スクリプト |

### log — ログ

| ID | ドキュメント | 内容 |
|---|---|---|
| log-1 | [log-class](docs/log/log-class.md) | Log.cs 定型(LoggerMessage) |
| log-2 | [serilog-configuration](docs/log/serilog-configuration.md) | Serilog の構成方法 |
| log-3 | [output-template](docs/log/output-template.md) | outputTemplate の標準形 |
| log-4 | [enricher-and-sinks](docs/log/enricher-and-sinks.md) | Enricher / シンク構成 |
| log-5 | [log-toggles](docs/log/log-toggles.md) | ログ4系統の個別トグル |

### config — 設定クラス

| ID | ドキュメント | 内容 |
|---|---|---|
| config-1 | [setting-and-options](docs/config/setting-and-options.md) | 命名と2系統(Setting / Options) |
| config-2 | [binding-patterns](docs/config/binding-patterns.md) | バインドの定型2パターン |
| config-3 | [nested-settings](docs/config/nested-settings.md) | ネスト設定(~Entry) |
| config-4 | [settings-placement](docs/config/settings-placement.md) | 配置場所 |

### data — データアクセス

| ID | ドキュメント | 内容 |
|---|---|---|
| data-1 | [smart-data-accessor](docs/data/smart-data-accessor.md) | Smart.Data.Accessor |
| data-2 | [two-way-sql](docs/data/two-way-sql.md) | 2-way SQL 外部ファイル |
| data-3 | [connection-dialect-trace](docs/data/connection-dialect-trace.md) | 接続・方言・トレース |

### web — Web API

| ID | ドキュメント | 内容 |
|---|---|---|
| web-1 | [minimal-api](docs/web/minimal-api.md) | Minimal API(優先方式) |
| web-2 | [controller-areas](docs/web/controller-areas.md) | Controller + Areas(代替方式) |
| web-3 | [api-contract](docs/web/api-contract.md) | API 契約の作法 |
| web-4 | [grpc](docs/web/grpc.md) | gRPC |
| web-5 | [auth-state](docs/web/auth-state.md) | アプリ固有の認証状態管理 |
| web-6 | [error-handling-openapi](docs/web/error-handling-openapi.md) | エラー応答・OpenAPI |

### blazor — Blazor

| ID | ドキュメント | 内容 |
|---|---|---|
| blazor-1 | [view-helper-and-extensions](docs/blazor/view-helper-and-extensions.md) | ViewHelper / ViewExtensions |
| blazor-2 | [framework-extensions](docs/blazor/framework-extensions.md) | フレームワーク拡張群 |
| blazor-3 | [app-component-base](docs/blazor/app-component-base.md) | AppComponentBase |
| blazor-4 | [code-behind](docs/blazor/code-behind.md) | code-behind 分離 |
| blazor-5 | [state-management](docs/blazor/state-management.md) | State 管理 |
| blazor-6 | [layout-and-shell](docs/blazor/layout-and-shell.md) | レイアウト・シェル |
| blazor-7 | [cookie-authentication](docs/blazor/cookie-authentication.md) | Cookie 認証一式 |
| blazor-8 | [validation](docs/blazor/validation.md) | バリデーション(FluentValidation) |
| blazor-9 | [ui-library](docs/blazor/ui-library.md) | UI ライブラリ(規定しない) |

### mvvm — XAML 系クライアント共通

| ID | ドキュメント | 内容 |
|---|---|---|
| mvvm-1 | [smart-mvvm](docs/mvvm/smart-mvvm.md) | Smart.Mvvm 基盤 |
| mvvm-2 | [smart-navigation](docs/mvvm/smart-navigation.md) | Smart.Navigation(画面遷移の標準) |
| mvvm-3 | [smart-resolver](docs/mvvm/smart-resolver.md) | DI コンテナ差し替え |
| mvvm-4 | [client-startup-hub](docs/mvvm/client-startup-hub.md) | クライアント起動ハブ |
| mvvm-5 | [modules-structure](docs/mvvm/modules-structure.md) | Modules 構成(vertical slice) |

### wpf — WPF 固有

| ID | ドキュメント | 内容 |
|---|---|---|
| wpf-1 | [window-manager](docs/wpf/window-manager.md) | WindowManager(用途限定) |
| wpf-2 | [window-placement](docs/wpf/window-placement.md) | ウィンドウ配置永続化 |
| wpf-3 | [exception-handling](docs/wpf/exception-handling.md) | 例外ハンドリング |

### avalonia — Avalonia 固有

| ID | ドキュメント | 内容 |
|---|---|---|
| avalonia-1 | [startup-and-lifetime](docs/avalonia/startup-and-lifetime.md) | 起動とライフタイム分岐 |
| avalonia-2 | [embedded-input-abstraction](docs/avalonia/embedded-input-abstraction.md) | 組込みの入力抽象化 |
| avalonia-3 | [embedded-execution-model](docs/avalonia/embedded-execution-model.md) | 組込みの実行形態 |

### maui — MAUI 固有

| ID | ドキュメント | 内容 |
|---|---|---|
| maui-1 | [mauiprogram-chain](docs/maui/mauiprogram-chain.md) | MauiProgram 宣言的チェーン |
| maui-2 | [application-initializer](docs/maui/application-initializer.md) | ApplicationInitializer |
| maui-3 | [custom-shell](docs/maui/custom-shell.md) | 自前 Shell |
| maui-4 | [platform-wrappers](docs/maui/platform-wrappers.md) | プラットフォーム機能ラッパ |
| maui-5 | [blazor-hybrid](docs/maui/blazor-hybrid.md) | Blazor Hybrid への置換 |

### worker — バッチ・ジョブ・CLI

| ID | ドキュメント | 内容 |
|---|---|---|
| worker-1 | [batch-skeleton](docs/worker/batch-skeleton.md) | Batch の共通骨格 |
| worker-2 | [command-dispatch](docs/worker/command-dispatch.md) | コマンドディスパッチ |
| worker-3 | [cli-tool](docs/worker/cli-tool.md) | CLI ツール |

### network — ソケット・プロトコル処理

| ID | ドキュメント | 内容 |
|---|---|---|
| network-1 | [tcp-server-kestrel](docs/network/tcp-server-kestrel.md) | TCP サーバ基盤(Kestrel) |
| network-2 | [receive-loop](docs/network/receive-loop.md) | 受信ループの定型 |
| network-3 | [allocation-free](docs/network/allocation-free.md) | アロケーションフリー処理 |

### test — テスト

| ID | ドキュメント | 内容 |
|---|---|---|
| test-1 | [aaa-pattern](docs/test/aaa-pattern.md) | AAA パターン |
| test-2 | [test-platform](docs/test/test-platform.md) | テスト基盤(xunit.v3 + MTP) |
| test-3 | [layout-and-naming](docs/test/layout-and-naming.md) | 配置・命名 |
| test-4 | [mocking](docs/test/mocking.md) | モック方針 |
| test-5 | [helper-section](docs/test/helper-section.md) | Helper セクション方式 |
| test-6 | [scenario-integration-test](docs/test/scenario-integration-test.md) | シナリオ結合テスト |
| test-7 | [bunit](docs/test/bunit.md) | bunit |
| test-8 | [test-project-layout](docs/test/test-project-layout.md) | テストプロジェクト構成 |

### telemetry — テレメトリ・ヘルスチェック

| ID | ドキュメント | 内容 |
|---|---|---|
| telemetry-1 | [opentelemetry](docs/telemetry/opentelemetry.md) | OpenTelemetry |
| telemetry-2 | [health-checks](docs/telemetry/health-checks.md) | HealthChecks |
| telemetry-3 | [endpoint-protection](docs/telemetry/endpoint-protection.md) | 公開エンドポイントの保護 |

### generator — ソースジェネレータ

| ID | ドキュメント | 内容 |
|---|---|---|
| generator-1 | [project-packaging](docs/generator/project-packaging.md) | プロジェクト構成と配布 |
| generator-2 | [implementation](docs/generator/implementation.md) | 実装作法 |
| generator-3 | [testing](docs/generator/testing.md) | テスト方式 |
| generator-4 | [aop-di-registration](docs/generator/aop-di-registration.md) | 応用: AOP + DI 自動登録 |

### guideline — 横断ガイドライン

| ID | ドキュメント | 内容 |
|---|---|---|
| guideline-1 | [error-handling](docs/guideline/error-handling.md) | エラー処理方針 |
| guideline-2 | [async-guideline](docs/guideline/async-guideline.md) | 非同期作法 |
| guideline-3 | [http-client](docs/guideline/http-client.md) | HTTP クライアント |
