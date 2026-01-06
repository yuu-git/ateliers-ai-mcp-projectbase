# MCP ロギング使用方法

## 基本的な使い方

### 1. DI コンテナへの登録

```csharp
using Ateliers.Ai.Mcp.DependencyInjection;
using Ateliers.Ai.Mcp.Logging.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();

// MCP 実行コンテキストを登録
services.AddMcpExecutionContext();

// MCP ロギングを登録
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Information)    // 最小ログレベル
        .AddConsole()                             // コンソール出力
        .AddFile();                               // ファイル出力（デフォルト: ./logs/app/mcp-*.log）
});

var serviceProvider = services.BuildServiceProvider();
```

### 2. コンストラクタインジェクション

```csharp
using Ateliers.Ai.Mcp;
using Ateliers.Ai.Mcp.Logging;

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
        // ツールスコープを開始（相関IDとツール名を自動管理）
        using var scope = _context.BeginTool("notion.sync");
        
        _logger.Info("MCP.Start");
        _logger.Debug($"Tool: {_context.ToolName}, CorrelationId: {_context.CorrelationId}");
        
        try
        {
            await SyncNotionAsync();
            _logger.Info("MCP.Success");
        }
        catch (Exception ex)
        {
            _logger.Error("MCP.Failed", ex);
            throw;
        }
    }

    private async Task SyncNotionAsync()
    {
        _logger.Info("Syncing Notion data...");
        // 同期処理
        await Task.Delay(100);
        _logger.Info("Sync completed");
    }
}
```

## ログレベル

```csharp
_logger.Trace("トレース情報");              // LogLevel.Trace
_logger.Debug("デバッグ情報");              // LogLevel.Debug
_logger.Info("情報メッセージ");             // LogLevel.Information
_logger.Warn("警告メッセージ");             // LogLevel.Warning
_logger.Error("エラーメッセージ", ex);      // LogLevel.Error
_logger.Critical("重大なエラー", ex);       // LogLevel.Critical
```

## ログ出力フォーマット

```
[2025-01-23T10:00:00.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] MCP.Start
[2025-01-23T10:00:01.0000000Z] [Debug] [MCP] [CID:abc-123] [Tool:notion.sync] Tool: notion.sync, CorrelationId: abc-123
[2025-01-23T10:00:02.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] Syncing Notion data...
[2025-01-23T10:00:03.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] Sync completed
[2025-01-23T10:00:04.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] MCP.Success
```

フォーマット詳細：
- `[Timestamp]`: ISO 8601 形式のタイムスタンプ（UTC）
- `[LogLevel]`: ログレベル
- `[MCP]`: カテゴリ（自動設定）
- `[CID:xxx]`: 相関ID（自動設定）
- `[Tool:xxx]`: ツール名（BeginTool で設定）
- メッセージ本文

## MCP 実行コンテキストの使い方

### ツールスコープの作成

```csharp
public async Task ExecuteToolAsync(string toolName)
{
    // ツールスコープを開始（新しい相関IDとツール名が設定される）
    using var scope = _context.BeginTool(toolName);
    
    _logger.Info($"MCP.Start tool={toolName}");
    
    // このスコープ内のすべてのログに同じ相関IDとツール名が付与される
    await ProcessToolAsync();
    
    _logger.Info($"MCP.Success tool={toolName}");
}
```

### 相関IDとツール名の取得

```csharp
public void LogContextInfo()
{
    var correlationId = _context.CorrelationId;
    var toolName = _context.ToolName;
    
    _logger.Info($"CorrelationId: {correlationId}, ToolName: {toolName}");
}
```

## MCP ロギングポリシー

MCP では以下のロギングポリシーに従います：

1. **必須ログ**:
   - `MCP.Start`: ツール実行開始時
   - `MCP.Success`: ツール実行成功時
   - `MCP.Failed`: ツール実行失敗時

2. **推奨ログ**:
   - 重要な処理のステップ
   - 外部サービスへのリクエスト/レスポンス
   - データの変換/変更

3. **禁止事項**:
   - 個人情報（PII）のログ出力
   - 認証トークン/パスワードのログ出力
   - 大量データの詳細ログ（Debug レベルでも避ける）

## ログの読み取り

### 相関IDでログを読み取る

```csharp
using Ateliers.Ai.Mcp;

public class LogReaderService
{
    private readonly IMcpLogReader _logReader;

    public LogReaderService(IMcpLogReader logReader)
    {
        _logReader = logReader;
    }

    public void ReadSessionLogs(string correlationId)
    {
        var session = _logReader.ReadByCorrelationId(correlationId);
        
        Console.WriteLine($"Session: {session.CorrelationId}");
        foreach (var entry in session.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] [{entry.Level}] {entry.Message}");
        }
    }

    public void ReadLastSession()
    {
        var session = _logReader.ReadLastSession();
        
        Console.WriteLine($"Last Session: {session.CorrelationId}");
        foreach (var entry in session.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] [{entry.Level}] {entry.Message}");
        }
    }

    public void ReadMcpLogs()
    {
        // カテゴリでフィルタリング
        var mcpSession = _logReader.ReadByCategory("MCP");
        
        Console.WriteLine($"MCP Logs: {mcpSession.Entries.Count} entries");
        foreach (var entry in mcpSession.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] [{entry.ToolName}] {entry.Message}");
        }
    }

    public void ReadToolLogs(string correlationId, string category = "MCP")
    {
        // 相関IDとカテゴリの両方でフィルタリング
        var session = _logReader.ReadByCorrelationIdAndCategory(correlationId, category);
        
        Console.WriteLine($"Tool Logs: {session.CorrelationId} ({session.Entries.Count} entries)");
        foreach (var entry in session.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] {entry.Message}");
        }
    }
}
```

### DI への登録

```csharp
// ファイルベースのログリーダー
services.AddSingleton<IMcpLogReader>(provider =>
    new FileMcpLogger(new McpLoggerOptions
    {
        LogDirectory = "./logs/app"
    }));

// または、インメモリログリーダー（テスト用）
services.AddSingleton<IMcpLogReader>(provider =>
    new InMemoryMcpLogger(new McpLoggerOptions()));
```

## 複数ロガーの組み合わせ

```csharp
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Debug)
        .AddConsole()                                  // コンソールに出力
        .AddFile("./logs/mcp")                        // ファイルに出力
        .AddInMemory(out var memoryLogger);           // メモリに保持（デバッグ/テスト用）
});
```

## テストでの使用例

```csharp
using Ateliers.Ai.Mcp;
using Ateliers.Ai.Mcp.Logging;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

public class NotionSyncToolTests
{
    [Fact]
    public async Task Test_ToolExecution()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddMcpExecutionContext();
        
        InMemoryMcpLogger memoryLogger = null!;
        services.AddMcpLogging(logging =>
        {
            logging
                .SetMinimumLevel(LogLevel.Debug)
                .AddInMemory(out memoryLogger);
        });
        
        var provider = services.BuildServiceProvider();
        var tool = new NotionSyncTool(
            provider.GetRequiredService<IMcpExecutionContext>(),
            provider.GetRequiredService<IMcpLogger>());
        
        // Act
        await tool.ExecuteAsync();
        
        // Assert
        Assert.True(memoryLogger.Entries.Count >= 2); // 最低限 Start と Success
        Assert.Contains(memoryLogger.Entries, e => e.Message == "MCP.Start");
        Assert.Contains(memoryLogger.Entries, e => e.Message == "MCP.Success");
        Assert.All(memoryLogger.Entries, e =>
        {
            Assert.Equal("MCP", e.Category);
            Assert.Equal("notion.sync", e.ToolName);
            Assert.NotNull(e.CorrelationId);
        });
    }

    [Fact]
    public void Test_LogReader()
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
        var context = provider.GetRequiredService<IMcpExecutionContext>();
        var logger = provider.GetRequiredService<IMcpLogger>();
        
        // Act
        using (var scope = context.BeginTool("test.tool"))
        {
            logger.Info("Test message");
        }
        
        var correlationId = context.CorrelationId;
        var session = memoryLogger.ReadByCorrelationId(correlationId!);
        
        // Assert
        Assert.Single(session.Entries);
        Assert.Equal("Test message", session.Entries[0].Message);
        Assert.Equal(correlationId, session.Entries[0].CorrelationId);
        Assert.Equal("test.tool", session.Entries[0].ToolName);
    }
}
```

## Production 環境での設定例

```csharp
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Information)  // Production では Information 以上
        .AddFile("./logs/mcp");                // ファイルのみ（コンソールは不要）
});

// ログ保持ポリシーの適用（起動時に実行）
var policy = new LogRetentionPolicy
{
    TraceRetention = TimeSpan.FromDays(1),
    DebugRetention = TimeSpan.FromDays(3),
    InformationRetention = TimeSpan.FromDays(14),
    WarningRetention = TimeSpan.FromDays(30),
    ErrorRetention = TimeSpan.FromDays(90),
    CriticalRetention = TimeSpan.FromDays(90)
};

var cleaner = new LogRetentionCleaner("./logs/mcp", policy);
cleaner.Clean();
```

## ベストプラクティス

1. **必ず BeginTool を使用する**: ツール名と相関IDが自動設定されます
2. **MCP.Start / MCP.Success / MCP.Failed を記録する**: ツールの実行状況を追跡できます
3. **適切なログレベルを使用する**: 
   - Debug: 開発時のみ
   - Information: 通常の処理フロー
   - Warning: 予期しないが処理可能な状況
   - Error: 処理失敗
   - Critical: サービス停止レベルのエラー
4. **例外は必ずログに記録する**: スタックトレースが保存されます
5. **個人情報を記録しない**: GDPR 等のコンプライアンスを遵守
6. **相関IDでログを追跡する**: 問題のデバッグが容易になります

## トラブルシューティング

### ツール名が記録されない場合

```csharp
// BeginTool を呼び出しているか確認
using var scope = _context.BeginTool("tool.name");
```

### ログファイルが見つからない場合

```csharp
// デフォルトのログディレクトリを確認
var logDir = Path.Combine(AppContext.BaseDirectory, "logs", "app");
Console.WriteLine($"Log directory: {logDir}");

// または、明示的にパスを指定
services.AddMcpLogging(logging =>
{
    logging.AddFile(logDirectory: "C:\\logs\\mcp");
});
```

### ログが読み取れない場合

```csharp
// IMcpLogReader が登録されているか確認
services.AddSingleton<IMcpLogReader>(provider =>
    provider.GetRequiredService<IMcpLogger>() as IMcpLogReader
        ?? throw new InvalidOperationException("Logger does not implement IMcpLogReader"));
```

## 参考リンク

- [MCP Logging Policy](../../docs/LoggingPolicy.md)
- [Ateliers.Core Logging USAGE](../../../Ateliers.Core/Logging/USAGE.md)
