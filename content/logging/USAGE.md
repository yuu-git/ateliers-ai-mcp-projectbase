@
---
---

# MCP ���M���O�g�p���@

## ��{�I�Ȏg����

### 1. DI �R���e�i�ւ̓o�^

```csharp
using Ateliers.Ai.Mcp.DependencyInjection;
using Ateliers.Ai.Mcp.Logging.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();

// MCP ���s�R���e�L�X�g��o�^
services.AddMcpExecutionContext();

// MCP ���M���O��o�^
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Information)    // �ŏ����O���x��
        .AddConsole()                             // �R���\�[���o��
        .AddFile();                               // �t�@�C���o�́i�f�t�H���g: ./logs/app/mcp-*.log�j
});

var serviceProvider = services.BuildServiceProvider();
```

### 2. �R���X�g���N�^�C���W�F�N�V����

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
        // �c�[���X�R�[�v���J�n�i����ID�ƃc�[�����������Ǘ��j
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
        // ��������
        await Task.Delay(100);
        _logger.Info("Sync completed");
    }
}
```

## ���O���x��

```csharp
_logger.Trace("�g���[�X���");              // LogLevel.Trace
_logger.Debug("�f�o�b�O���");              // LogLevel.Debug
_logger.Info("��񃁃b�Z�[�W");             // LogLevel.Information
_logger.Warn("�x�����b�Z�[�W");             // LogLevel.Warning
_logger.Error("�G���[���b�Z�[�W", ex);      // LogLevel.Error
_logger.Critical("�d��ȃG���[", ex);       // LogLevel.Critical
```

## ���O�o�̓t�H�[�}�b�g

```
[2025-01-23T10:00:00.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] MCP.Start
[2025-01-23T10:00:01.0000000Z] [Debug] [MCP] [CID:abc-123] [Tool:notion.sync] Tool: notion.sync, CorrelationId: abc-123
[2025-01-23T10:00:02.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] Syncing Notion data...
[2025-01-23T10:00:03.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] Sync completed
[2025-01-23T10:00:04.0000000Z] [Information] [MCP] [CID:abc-123] [Tool:notion.sync] MCP.Success
```

�t�H�[�}�b�g�ڍׁF
- `[Timestamp]`: ISO 8601 �`���̃^�C���X�^���v�iUTC�j
- `[LogLevel]`: ���O���x��
- `[MCP]`: �J�e�S���i�����ݒ�j
- `[CID:xxx]`: ����ID�i�����ݒ�j
- `[Tool:xxx]`: �c�[�����iBeginTool �Őݒ�j
- ���b�Z�[�W�{��

## MCP ���s�R���e�L�X�g�̎g����

### �c�[���X�R�[�v�̍쐬

```csharp
public async Task ExecuteToolAsync(string toolName)
{
    // �c�[���X�R�[�v���J�n�i�V��������ID�ƃc�[�������ݒ肳���j
    using var scope = _context.BeginTool(toolName);
    
    _logger.Info($"MCP.Start tool={toolName}");
    
    // ���̃X�R�[�v���̂��ׂẴ��O�ɓ�������ID�ƃc�[�������t�^�����
    await ProcessToolAsync();
    
    _logger.Info($"MCP.Success tool={toolName}");
}
```

### ����ID�ƃc�[�����̎擾

```csharp
public void LogContextInfo()
{
    var correlationId = _context.CorrelationId;
    var toolName = _context.ToolName;
    
    _logger.Info($"CorrelationId: {correlationId}, ToolName: {toolName}");
}
```

## MCP ���M���O�|���V�[

MCP �ł͈ȉ��̃��M���O�|���V�[�ɏ]���܂��F

1. **�K�{���O**:
   - `MCP.Start`: �c�[�����s�J�n��
   - `MCP.Success`: �c�[�����s������
   - `MCP.Failed`: �c�[�����s���s��

2. **�������O**:
   - �d�v�ȏ����̃X�e�b�v
   - �O���T�[�r�X�ւ̃��N�G�X�g/���X�|���X
   - �f�[�^�̕ϊ�/�ύX

3. **�֎~����**:
   - �l���iPII�j�̃��O�o��
   - �F�؃g�[�N��/�p�X���[�h�̃��O�o��
   - ��ʃf�[�^�̏ڍ׃��O�iDebug ���x���ł�������j

## ���O�̓ǂݎ��

### ����ID�Ń��O��ǂݎ��

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
        // �J�e�S���Ńt�B���^�����O
        var mcpSession = _logReader.ReadByCategory("MCP");
        
        Console.WriteLine($"MCP Logs: {mcpSession.Entries.Count} entries");
        foreach (var entry in mcpSession.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] [{entry.ToolName}] {entry.Message}");
        }
    }

    public void ReadToolLogs(string correlationId, string category = "MCP")
    {
        // ����ID�ƃJ�e�S���̗����Ńt�B���^�����O
        var session = _logReader.ReadByCorrelationIdAndCategory(correlationId, category);
        
        Console.WriteLine($"Tool Logs: {session.CorrelationId} ({session.Entries.Count} entries)");
        foreach (var entry in session.Entries)
        {
            Console.WriteLine($"  [{entry.Timestamp}] {entry.Message}");
        }
    }
}
```

### DI �ւ̓o�^

```csharp
// �t�@�C���x�[�X�̃��O���[�_�[
services.AddSingleton<IMcpLogReader>(provider =>
    new FileMcpLogger(new McpLoggerOptions
    {
        LogDirectory = "./logs/app"
    }));

// �܂��́A�C�����������O���[�_�[�i�e�X�g�p�j
services.AddSingleton<IMcpLogReader>(provider =>
    new InMemoryMcpLogger(new McpLoggerOptions()));
```

## �������K�[�̑g�ݍ��킹

```csharp
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Debug)
        .AddConsole()                                  // �R���\�[���ɏo��
        .AddFile("./logs/mcp")                        // �t�@�C���ɏo��
        .AddInMemory(out var memoryLogger);           // �������ɕێ��i�f�o�b�O/�e�X�g�p�j
});
```

## �e�X�g�ł̎g�p��

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
        Assert.True(memoryLogger.Entries.Count >= 2); // �Œ�� Start �� Success
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

## Production ���ł̐ݒ��

```csharp
services.AddMcpLogging(logging =>
{
    logging
        .SetMinimumLevel(LogLevel.Information)  // Production �ł� Information �ȏ�
        .AddFile("./logs/mcp");                // �t�@�C���̂݁i�R���\�[���͕s�v�j
});

// ���O�ێ��|���V�[�̓K�p�i�N�����Ɏ��s�j
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

## �x�X�g�v���N�e�B�X

1. **�K�� BeginTool ���g�p����**: �c�[�����Ƒ���ID�������ݒ肳��܂�
2. **MCP.Start / MCP.Success / MCP.Failed ���L�^����**: �c�[���̎��s�󋵂�ǐՂł��܂�
3. **�K�؂ȃ��O���x�����g�p����**: 
   - Debug: �J�����̂�
   - Information: �ʏ�̏����t���[
   - Warning: �\�����Ȃ��������\�ȏ�
   - Error: �������s
   - Critical: �T�[�r�X��~���x���̃G���[
4. **��O�͕K�����O�ɋL�^����**: �X�^�b�N�g���[�X���ۑ�����܂�
5. **�l�����L�^���Ȃ�**: GDPR ���̃R���v���C�A���X������
6. **����ID�Ń��O��ǐՂ���**: ���̃f�o�b�O���e�ՂɂȂ�܂�

## �g���u���V���[�e�B���O

### �c�[�������L�^����Ȃ��ꍇ

```csharp
// BeginTool ���Ăяo���Ă��邩�m�F
using var scope = _context.BeginTool("tool.name");
```

### ���O�t�@�C����������Ȃ��ꍇ

```csharp
// �f�t�H���g�̃��O�f�B���N�g�����m�F
var logDir = Path.Combine(AppContext.BaseDirectory, "logs", "app");
Console.WriteLine($"Log directory: {logDir}");

// �܂��́A�����I�Ƀp�X���w��
services.AddMcpLogging(logging =>
{
    logging.AddFile(logDirectory: "C:\\logs\\mcp");
});
```

### ���O���ǂݎ��Ȃ��ꍇ

```csharp
// IMcpLogReader ���o�^����Ă��邩�m�F
services.AddSingleton<IMcpLogReader>(provider =>
    provider.GetRequiredService<IMcpLogger>() as IMcpLogReader
        ?? throw new InvalidOperationException("Logger does not implement IMcpLogReader"));
```

## �Q�l�����N

- [MCP Logging Policy](../../docs/LoggingPolicy.md)
- [Ateliers.Core Logging USAGE](../../../Ateliers.Core/Logging/USAGE.md)
