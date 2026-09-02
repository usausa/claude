# public partial class Program の宣言

| 項目 | 内容 |
|---|---|
| ID | host-5 |
| 分類 | host |
| 関連 | host-1(Program.cs の構成) / test-6(シナリオ結合テスト) / test-8(テストプロジェクト構成) / structure-4(警告抑止の三層) |

## 目的

トップレベル文の `Program` 型を、統合テストの `WebApplicationFactory<Program>` から**型安全に参照可能にする**。

- トップレベル文からコンパイラが生成する `Program` クラスは internal のため、そのままではテストプロジェクトの型引数に指定できない
- ファイル末尾の partial 宣言1つで public 化でき、テスト側は文字列指定等の迂回なしにエントリポイントを参照できる
- `[ExcludeFromCodeCoverage]` を付与し、起動コード(トップレベル文全体)をカバレッジ集計から除外する

## 標準形

`Program.cs` の末尾(`RunAsync()` の後)に宣言する。

```csharp
// Run
await app.RunAsync();

[ExcludeFromCodeCoverage]
public partial class Program
{
}
```

- `[ExcludeFromCodeCoverage]` は `System.Diagnostics.CodeAnalysis`。partial の片割れに付けた属性は型全体に効き、トップレベル文から生成されるエントリポイントがカバレッジ対象から外れる
- public 化には CA1515(公開型を internal にせよ)が反応するが、アプリケーションプロジェクトでは `GlobalSuppressions.cs` の標準ペアで抑止済み(structure-4)

テスト側は `WebApplicationFactory<Program>` を fixture として受ける(test-6)。

```csharp
public sealed class HealthEndpointTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> factory;

    public HealthEndpointTest(WebApplicationFactory<Program> factory)
    {
        this.factory = factory;
    }

    [Fact]
    public async Task HealthReturnsHealthy()
    {
        // Arrange
        using var client = factory.CreateClient();

        // Act
        var response = await client.GetAsync("/health");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
```

## 配置ルール

| 対象 | 場所 |
|---|---|
| partial 宣言 | `Program.cs` の末尾(別ファイルにしない) |
| 利用側 | 統合テストプロジェクト(test-8 の `<App>.IntegrationTests`) |

## バリエーションと使い分け

internal のまま `InternalsVisibleTo` でテストへ公開する方法もある。

```xml
<ItemGroup>
  <InternalsVisibleTo Include="Template.ApiServer.Host.IntegrationTests" />
</ItemGroup>
```

| 観点 | public partial 宣言 | internal + InternalsVisibleTo |
|---|---|---|
| 記述場所 | `Program.cs` の3行で完結 | csproj(またはアセンブリ属性)に列挙 |
| テストプロジェクト追加時 | 変更不要 | プロジェクト名を追加列挙 |
| 公開範囲 | `Program` 型のみ | アセンブリ内の全 internal 型 |

**標準は public partial 宣言**とする。エントリポイント型の公開に実害はなく、記述が1箇所で完結し、テストプロジェクト名にも依存しない。`InternalsVisibleTo` は `Program` 以外の internal 型(差し替え対象の実装等)をテストから参照する必要が生じた場合に併用する。

## アンチパターン

- **宣言忘れの場当たり回避** — `WebApplicationFactory` の型引数に別の公開型を渡す、文字列でエントリポイントを解決する等の迂回をしない。宣言を足すのが正
- **`[ExcludeFromCodeCoverage]` の付け忘れ** — 起動コードが未カバー行としてカバレッジ集計に現れ続ける
- **partial 宣言へのメンバ追加** — この宣言は公開のためのマーカーであり、ロジックやフィールドを持たせない
- **独立ファイルへの分離** — 宣言だけのファイルを作らない。`Program.cs` 末尾に置くことで存在理由が文脈から読める
