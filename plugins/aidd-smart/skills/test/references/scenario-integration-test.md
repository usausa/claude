# シナリオ結合テスト

| 項目 | 内容 |
|---|---|
| ID | test-6 |
| 分類 | test |
| 関連 | test-8(テストプロジェクト構成) / test-2(テスト基盤) / test-4(モック方針) / host-5(public partial Program) |

## 目的

`WebApplicationFactory` でホストをインプロセス起動し、**業務シナリオ単位の一気通貫テスト**を行う。あわせてリクエスト/レスポンスの JSON を記録し、テスト実行結果をエビデンスとして残す。

- テストクラスとテストデータをシナリオ番号で1対1対応させ、シナリオの追加・削除を機械的にする
- 時刻・外部サービスは DI 差し替えで固定し、シナリオを決定的(再実行可能)にする
- 実行環境が必要なテストは `[IntegrationFact]` でスキップ制御し、環境がないマシンでもソリューション全体のテストが赤くならないようにする

## 標準形

### 構成

```
App.IntegrationTests/
├─ Scenario/
│   ├─ 01LoginTest.cs            … [Scenario("01Login")]
│   └─ 02OrderTest.cs            … [Scenario("02Order")]
├─ data/
│   ├─ 01Login/                  … シナリオと1対1対応
│   │   ├─ request.json
│   │   └─ response.json
│   └─ 02Order/
└─ Infrastructure/               … TestWebApplicationFactory / 属性 / ヘルパ
```

テストクラス `Scenario/NNXxxTest.cs` とデータフォルダ `data/NNXxx/` を属性で対応付ける。

```csharp
[Scenario("01Login")]
public sealed class LoginTest : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory factory;

    public LoginTest(TestWebApplicationFactory factory)
    {
        this.factory = factory;
    }

    [IntegrationFact]
    public async Task LoginSucceededReturnsToken()
    {
        // Arrange
        using var client = factory.CreateClient();
        var request = await factory.ReadDataAsync(this, "request.json");

        // Act
        var response = await client.PostAsync("/api/auth/login", request);

        // Assert
        // レスポンス JSON はエビデンスとして記録した上で期待値と比較する
        await factory.WriteEvidenceAsync(this, response);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

### ホスト参照と extern alias

ホストプロジェクトの参照には alias を付け、テスト側(RootNamespace は対象と同一。test-3)との型・名前空間衝突を避ける。エントリポイントはホスト側の `public partial class Program` を型引数に取る(host-5)。

```xml
<ItemGroup>
  <ProjectReference Include="..\App.Host\App.Host.csproj" Aliases="Host" />
</ItemGroup>
```

```csharp
extern alias Host;

using HostProgram = Host::Program;

public sealed class TestWebApplicationFactory : WebApplicationFactory<HostProgram>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(static services =>
        {
            // 時刻を固定しシナリオを決定的にする
            services.RemoveService<TimeProvider>();
            services.AddSingleton<TimeProvider>(new StaticTimeProvider(new DateTimeOffset(2026, 1, 15, 9, 0, 0, TimeSpan.FromHours(9))));

            // 外部サービスをモックへ差し替える
            services.RemoveService<INotificationService>();
            services.AddSingleton<INotificationService, MockNotificationService>();
        });
    }
}
```

### サービス差し替えヘルパ(RemoveService)

```csharp
public static class ServiceCollectionExtensions
{
    public static IServiceCollection RemoveService<TService>(this IServiceCollection services)
    {
        var descriptor = services.FirstOrDefault(static x => x.ServiceType == typeof(TService));
        if (descriptor is not null)
        {
            services.Remove(descriptor);
        }

        return services;
    }
}
```

### 時刻固定(StaticTimeProvider)

アプリ側が `TimeProvider` を注入で受けていることが前提(直接 `DateTime.Now` を読まない)。

```csharp
public sealed class StaticTimeProvider : TimeProvider
{
    private readonly DateTimeOffset now;

    public StaticTimeProvider(DateTimeOffset now)
    {
        this.now = now;
    }

    public override DateTimeOffset GetUtcNow() => now.ToUniversalTime();
}
```

### スキップ制御([IntegrationFact])

実 DB 等の環境を要するテストは、環境変数の有無でスキップする専用属性を使う。

```csharp
public sealed class IntegrationFactAttribute : FactAttribute
{
    public IntegrationFactAttribute()
    {
        if (Environment.GetEnvironmentVariable("TEMPLATE_INTEGRATION_TEST") is null)
        {
            Skip = "Integration test environment is not available.";
        }
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| シナリオテスト | `Scenario/NNXxxTest.cs`(番号順) |
| テストデータ | `data/NNXxx/`(シナリオと1対1、`CopyToOutputDirectory` で出力へコピー) |
| エビデンス | テスト出力フォルダ配下にシナリオ毎の JSON を記録 |
| 基盤部品 | `TestWebApplicationFactory` / 属性 / 拡張は `Infrastructure/` |

## バリエーションと使い分け

- **単発のエンドポイント検証**: シナリオ体系に乗せるほどでないヘルスチェック等は、素の `WebApplicationFactory<Program>` + `[Fact]` でよい(host-5 の例)
- **大規模構成(test-8 の発展形)**: シナリオテストを独立プロジェクトに分離し、テスト部品ライブラリ・データ投入 CLI と組み合わせる。本トピックの構造(Scenario/data 対応、差し替えヘルパ)はそのまま持ち上がる

## アンチパターン

- **`DateTime.Now` 直読みのままのシナリオ** — 日付跨ぎで結果が変わる不安定テストになる。アプリは `TimeProvider` を注入で受け、テストは `StaticTimeProvider` で固定する
- **`[Fact]` のままの環境依存テスト** — 環境がないマシンで赤くなり、テスト結果の信頼が失われる。`[IntegrationFact]` でスキップとして可視化する
- **テストコード内へのデータ埋め込み** — 長大な JSON をリテラルで持たない。`data/NNXxx/` に外部化し、シナリオとの対応を属性で保つ
- **差し替え漏れによる外部サービス実呼び出し** — 通知・決済等の副作用があるサービスは必ず `RemoveService` + モック登録で遮断する
- **エビデンス記録の手動運用** — レスポンス JSON の保存をテストコードの共通ヘルパに組み込み、手作業のキャプチャに依存しない
