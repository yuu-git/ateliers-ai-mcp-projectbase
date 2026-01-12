---
---

# MCP 実行コンテキスト使用方法

## 概要

MCP 実行コンテキストは、ツールの実行を追跡するための仕組みです。
各ツールの実行には一意の相関ID（CorrelationId）が割り当てられ、ツール名と共に管理されます。

## 基本的な使い方

### 1. DI コンテナへの登録

```csharp
using Ateliers.Ai.Mcp.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();

// MCP 実行コンテキストを登録
services.AddMcpExecutionContext();

var serviceProvider = services.BuildServiceProvider();
```

### 2. コンストラクタインジェクション

```csharp
using Ateliers.Ai.Mcp;
using Ateliers.Ai.Mcp.Context;

public class MyMcpTool
{
    private readonly IMcpExecutionContext _context;

    public MyMcpTool(IMcpExecutionContext context)
    {
        _context = context;
    }

    public async Task ExecuteAsync()
    {
        // ツールスコープを開始
        using var scope = _context.BeginTool("my.tool");
        
        // 相関IDとツール名が自動設定される
        Console.WriteLine($"CorrelationId: {_context.CorrelationId}");
        Console.WriteLine($"ToolName: {_context.ToolName}");
        
        // ツール処理
        await ProcessAsync();
    }
    
    private async Task ProcessAsync()
    {
        // このメソッド内でも同じコンテキストが利用可能
        Console.WriteLine($"Still in context: {_context.CorrelationId}");
        await Task.Delay(100);
    }
}
```

## スコープの管理

### ツールスコープ

```csharp
public async Task ExecuteToolAsync()
{
    // using ステートメントでスコープを管理
    using var scope = _context.BeginTool("notion.sync");
    
    // スコープ内の処理
    await SyncNotionAsync();
    
    // スコープ終了時に自動的にクリーンアップ
}
```

### ネストしたスコープ

```csharp
public async Task ParentToolAsync()
{
    using var parentScope = _context.BeginTool("parent.tool");
    Console.WriteLine($"Parent CorrelationId: {_context.CorrelationId}");
    Console.WriteLine($"Parent ToolName: {_context.ToolName}");
    
    // 子ツールを呼び出し
    await ChildToolAsync();
    
    // 親スコープに戻る
    Console.WriteLine($"Back to parent: {_context.CorrelationId}");
}

private async Task ChildToolAsync()
{
    using var childScope = _context.BeginTool("child.tool");
    Console.WriteLine($"Child CorrelationId: {_context.CorrelationId}");
    Console.WriteLine($"Child ToolName: {_context.ToolName}");
    
    await Task.Delay(100);
}
```

## 相関IDの活用

### ログとの統合

```csharp
public class NotionSyncTool
{
    private readonly IMcpExecutionContext _context;
    private readonly IMcpLogger _logger;

    public NotionSyncTool(IMcpExecutionContext context, IMcpLogger logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task ExecuteAsync()
    {
        using var scope = _context.BeginTool("notion.sync");
        
        // ログに自動的に相関IDとツール名が付与される
        _logger.Info("MCP.Start");  // [CID:abc-123] [Tool:notion.sync] MCP.Start
        
        try
        {
            await SyncAsync();
            _logger.Info("MCP.Success");
        }
        catch (Exception ex)
        {
            _logger.Error("MCP.Failed", ex);
            throw;
        }
    }
}
```

### HTTPリクエストヘッダーへの追加

```csharp
public class ApiClient
{
    private readonly IMcpExecutionContext _context;
    private readonly HttpClient _httpClient;

    public ApiClient(IMcpExecutionContext context, HttpClient httpClient)
    {
        _context = context;
        _httpClient = httpClient;
    }

    public async Task<string> GetDataAsync(string url)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, url);
        
        // 相関IDをヘッダーに追加（分散トレーシング）
        if (!string.IsNullOrEmpty(_context.CorrelationId))
        {
            request.Headers.Add("X-Correlation-Id", _context.CorrelationId);
        }
        
        var response = await _httpClient.SendAsync(request);
        return await response.Content.ReadAsStringAsync();
    }
}
```

## 複数ツールの実行

### 順次実行

```csharp
public async Task ExecuteMultipleToolsAsync()
{
    // ツール1
    using (var scope1 = _context.BeginTool("tool1"))
    {
        _logger.Info("Executing tool1");
        await Task.Delay(100);
    }
    
    // ツール2
    using (var scope2 = _context.BeginTool("tool2"))
    {
        _logger.Info("Executing tool2");
        await Task.Delay(100);
    }
    
    // 各ツールは独立した相関IDを持つ
}
```

### 並列実行

```csharp
public async Task ExecuteToolsInParallelAsync()
{
    var tasks = new[]
    {
        ExecuteToolAsync("tool1"),
        ExecuteToolAsync("tool2"),
        ExecuteToolAsync("tool3")
    };
    
    await Task.WhenAll(tasks);
}

private async Task ExecuteToolAsync(string toolName)
{
    // 各タスクで独立したコンテキストを持つ
    using var scope = _context.BeginTool(toolName);
    _logger.Info($"Executing {toolName}");
    await Task.Delay(100);
}
```

## 実行コンテキストの取得

### 静的アクセス

```csharp
using Ateliers.Ai.Mcp.Context;

public class MyService
{
    public void DoSomething()
    {
        // 静的プロパティから現在のコンテキストを取得
        var current = McpExecutionContext.Current;
        if (current != null)
        {
            Console.WriteLine($"CorrelationId: {current.CorrelationId}");
            Console.WriteLine($"ToolName: {current.ToolName}");
        }
    }
}
```

### DI 経由でのアクセス（推奨）

```csharp
public class MyService
{
    private readonly IMcpExecutionContext _context;

    // コンストラクタインジェクションを使用（推奨）
    public MyService(IMcpExecutionContext context)
    {
        _context = context;
    }

    public void DoSomething()
    {
        Console.WriteLine($"CorrelationId: {_context.CorrelationId}");
        Console.WriteLine($"ToolName: {_context.ToolName}");
    }
}
```

## テストでの使用例

### 基本的なテスト

```csharp
using Ateliers.Ai.Mcp;
using Ateliers.Ai.Mcp.Context;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

public class McpExecutionContextTests
{
    [Fact]
    public void Test_ContextScope()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddMcpExecutionContext();
        var provider = services.BuildServiceProvider();
        var context = provider.GetRequiredService<IMcpExecutionContext>();
        
        // Act
        string? correlationId = null;
        string? toolName = null;
        
        using (var scope = context.BeginTool("test.tool"))
        {
            correlationId = context.CorrelationId;
            toolName = context.ToolName;
        }
        
        // Assert
        Assert.NotNull(correlationId);
        Assert.Equal("test.tool", toolName);
    }

    [Fact]
    public void Test_NestedScopes()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddMcpExecutionContext();
        var provider = services.BuildServiceProvider();
        var context = provider.GetRequiredService<IMcpExecutionContext>();
        
        // Act & Assert
        using (var parentScope = context.BeginTool("parent.tool"))
        {
            var parentCorrelationId = context.CorrelationId;
            var parentToolName = context.ToolName;
            
            Assert.Equal("parent.tool", parentToolName);
            
            using (var childScope = context.BeginTool("child.tool"))
            {
                var childCorrelationId = context.CorrelationId;
                var childToolName = context.ToolName;
                
                Assert.Equal("child.tool", childToolName);
                Assert.NotEqual(parentCorrelationId, childCorrelationId);
            }
            
            // 親スコープに戻る
            Assert.Equal(parentCorrelationId, context.CorrelationId);
            Assert.Equal("parent.tool", context.ToolName);
        }
    }

    [Fact]
    public async Task Test_StaticAccess()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddMcpExecutionContext();
        var provider = services.BuildServiceProvider();
        var context = provider.GetRequiredService<IMcpExecutionContext>();
        
        // Act
        using var scope = context.BeginTool("test.tool");
        
        // 静的プロパティからアクセス
        var current = McpExecutionContext.Current;
        
        // Assert
        Assert.NotNull(current);
        Assert.Equal(context.CorrelationId, current.CorrelationId);
        Assert.Equal("test.tool", current.ToolName);
    }
}
```

### 統合テスト

```csharp
public class NotionSyncToolIntegrationTests
{
    [Fact]
    public async Task Test_ToolExecutionWithContext()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddMcpExecutionContext();
        
        InMemoryMcpLogger memoryLogger = null!;
        services.AddMcpLogging(logging =>
        {
            logging.AddInMemory(out memoryLogger);
        });
        
        var provider = services.BuildServiceProvider();
        var tool = new NotionSyncTool(
            provider.GetRequiredService<IMcpExecutionContext>(),
            provider.GetRequiredService<IMcpLogger>());
        
        // Act
        await tool.ExecuteAsync();
        
        // Assert
        Assert.All(memoryLogger.Entries, entry =>
        {
            Assert.NotNull(entry.CorrelationId);
            Assert.Equal("notion.sync", entry.ToolName);
            Assert.Equal("MCP", entry.Category);
        });
    }
}
```

## ベストプラクティス

1. **必ず using ステートメントを使用する**: スコープの適切な管理
2. **DI でコンテキストを注入する**: 静的アクセスよりも推奨
3. **スコープは短く保つ**: ツールの実行単位でスコープを作成
4. **相関IDをログに活用する**: トレーサビリティの向上
5. **ネストしたスコープを活用する**: 複雑な処理の階層管理

## 高度な使用例

### カスタムプロパティの追加

```csharp
public class ExtendedMcpExecutionContext : McpExecutionContext
{
    public string? UserId { get; init; }
    public string? SessionId { get; init; }

    public ExtendedMcpExecutionContext(
        string correlationId,
        string? toolName,
        string? userId = null,
        string? sessionId = null)
        : base(correlationId, toolName)
    {
        UserId = userId;
        SessionId = sessionId;
    }
}

// DI 登録
services.AddScoped<IMcpExecutionContext>(provider =>
    new ExtendedMcpExecutionContext(
        Guid.NewGuid().ToString(),
        null,
        userId: "user123",
        sessionId: "session456"));
```

### ミドルウェアとの統合（ASP.NET Core）

```csharp
public class McpContextMiddleware
{
    private readonly RequestDelegate _next;

    public McpContextMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var mcpContext = context.RequestServices
            .GetRequiredService<IMcpExecutionContext>();

        // HTTPヘッダーから相関IDを取得（存在する場合）
        var correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString();

        using var scope = mcpContext.BeginTool(context.Request.Path);
        
        // レスポンスヘッダーに相関IDを追加
        context.Response.Headers.Append("X-Correlation-Id", correlationId);

        await _next(context);
    }
}

// Startup.cs
app.UseMiddleware<McpContextMiddleware>();
```

## トラブルシューティング

### コンテキストが null の場合

```csharp
// AddMcpExecutionContext が登録されているか確認
services.AddMcpExecutionContext();

// スコープが作成されているか確認
using var scope = context.BeginTool("tool.name");
```

### 相関IDが一致しない場合

```csharp
// 非同期処理で ExecutionContext が引き継がれない場合
// ConfigureAwait(false) を使用していないか確認
await Task.Delay(100); // OK
await Task.Delay(100).ConfigureAwait(false); // NG: コンテキストが失われる
```

### ネストしたスコープがうまく動作しない場合

```csharp
// using ステートメントを正しく使用しているか確認
using (var scope1 = context.BeginTool("tool1"))
{
    using (var scope2 = context.BeginTool("tool2"))
    {
        // OK
    }
}

// 以下は NG: scope が適切に閉じられない
var scope1 = context.BeginTool("tool1");
var scope2 = context.BeginTool("tool2");
```

## 参考リンク

- [MCP Logging USAGE](../logging/USAGE.md)
- [Ateliers.Core ExecutionContext](../../../Ateliers.Core/Context/)
