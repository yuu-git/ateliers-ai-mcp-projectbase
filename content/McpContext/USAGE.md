@
---
---

# MCP ���s�R���e�L�X�g�g�p���@

## �T�v

MCP ���s�R���e�L�X�g�́A�c�[���̎��s��ǐՂ��邽�߂̎d�g�݂ł��B
�e�c�[���̎��s�ɂ͈�ӂ̑���ID�iCorrelationId�j�����蓖�Ă��A�c�[�����Ƌ��ɊǗ�����܂��B

## ��{�I�Ȏg����

### 1. DI �R���e�i�ւ̓o�^

```csharp
using Ateliers.Ai.Mcp.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

var services = new ServiceCollection();

// MCP ���s�R���e�L�X�g��o�^
services.AddMcpExecutionContext();

var serviceProvider = services.BuildServiceProvider();
```

### 2. �R���X�g���N�^�C���W�F�N�V����

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
        // �c�[���X�R�[�v���J�n
        using var scope = _context.BeginTool("my.tool");
        
        // ����ID�ƃc�[�����������ݒ肳���
        Console.WriteLine($"CorrelationId: {_context.CorrelationId}");
        Console.WriteLine($"ToolName: {_context.ToolName}");
        
        // �c�[������
        await ProcessAsync();
    }
    
    private async Task ProcessAsync()
    {
        // ���̃��\�b�h���ł������R���e�L�X�g�����p�\
        Console.WriteLine($"Still in context: {_context.CorrelationId}");
        await Task.Delay(100);
    }
}
```

## �X�R�[�v�̊Ǘ�

### �c�[���X�R�[�v

```csharp
public async Task ExecuteToolAsync()
{
    // using �X�e�[�g�����g�ŃX�R�[�v���Ǘ�
    using var scope = _context.BeginTool("notion.sync");
    
    // �X�R�[�v���̏���
    await SyncNotionAsync();
    
    // �X�R�[�v�I�����Ɏ����I�ɃN���[���A�b�v
}
```

### �l�X�g�����X�R�[�v

```csharp
public async Task ParentToolAsync()
{
    using var parentScope = _context.BeginTool("parent.tool");
    Console.WriteLine($"Parent CorrelationId: {_context.CorrelationId}");
    Console.WriteLine($"Parent ToolName: {_context.ToolName}");
    
    // �q�c�[�����Ăяo��
    await ChildToolAsync();
    
    // �e�X�R�[�v�ɖ߂�
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

## ����ID�̊��p

### ���O�Ƃ̓���

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
        
        // ���O�Ɏ����I�ɑ���ID�ƃc�[�������t�^�����
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

### HTTP���N�G�X�g�w�b�_�[�ւ̒ǉ�

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
        
        // ����ID���w�b�_�[�ɒǉ��i���U�g���[�V���O�j
        if (!string.IsNullOrEmpty(_context.CorrelationId))
        {
            request.Headers.Add("X-Correlation-Id", _context.CorrelationId);
        }
        
        var response = await _httpClient.SendAsync(request);
        return await response.Content.ReadAsStringAsync();
    }
}
```

## �����c�[���̎��s

### �������s

```csharp
public async Task ExecuteMultipleToolsAsync()
{
    // �c�[��1
    using (var scope1 = _context.BeginTool("tool1"))
    {
        _logger.Info("Executing tool1");
        await Task.Delay(100);
    }
    
    // �c�[��2
    using (var scope2 = _context.BeginTool("tool2"))
    {
        _logger.Info("Executing tool2");
        await Task.Delay(100);
    }
    
    // �e�c�[���͓Ɨ���������ID������
}
```

### ������s

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
    // �e�^�X�N�œƗ������R���e�L�X�g������
    using var scope = _context.BeginTool(toolName);
    _logger.Info($"Executing {toolName}");
    await Task.Delay(100);
}
```

## ���s�R���e�L�X�g�̎擾

### �ÓI�A�N�Z�X

```csharp
using Ateliers.Ai.Mcp.Context;

public class MyService
{
    public void DoSomething()
    {
        // �ÓI�v���p�e�B���猻�݂̃R���e�L�X�g���擾
        var current = McpExecutionContext.Current;
        if (current != null)
        {
            Console.WriteLine($"CorrelationId: {current.CorrelationId}");
            Console.WriteLine($"ToolName: {current.ToolName}");
        }
    }
}
```

### DI �o�R�ł̃A�N�Z�X�i�����j

```csharp
public class MyService
{
    private readonly IMcpExecutionContext _context;

    // �R���X�g���N�^�C���W�F�N�V�������g�p�i�����j
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

## �e�X�g�ł̎g�p��

### ��{�I�ȃe�X�g

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
            
            // �e�X�R�[�v�ɖ߂�
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
        
        // �ÓI�v���p�e�B����A�N�Z�X
        var current = McpExecutionContext.Current;
        
        // Assert
        Assert.NotNull(current);
        Assert.Equal(context.CorrelationId, current.CorrelationId);
        Assert.Equal("test.tool", current.ToolName);
    }
}
```

### �����e�X�g

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

## �x�X�g�v���N�e�B�X

1. **�K�� using �X�e�[�g�����g���g�p����**: �X�R�[�v�̓K�؂ȊǗ�
2. **DI �ŃR���e�L�X�g�𒍓�����**: �ÓI�A�N�Z�X��������
3. **�X�R�[�v�͒Z���ۂ�**: �c�[���̎��s�P�ʂŃX�R�[�v���쐬
4. **����ID�����O�Ɋ��p����**: �g���[�T�r���e�B�̌���
5. **�l�X�g�����X�R�[�v�����p����**: ���G�ȏ����̊K�w�Ǘ�

## ���x�Ȏg�p��

### �J�X�^���v���p�e�B�̒ǉ�

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

// DI �o�^
services.AddScoped<IMcpExecutionContext>(provider =>
    new ExtendedMcpExecutionContext(
        Guid.NewGuid().ToString(),
        null,
        userId: "user123",
        sessionId: "session456"));
```

### �~�h���E�F�A�Ƃ̓����iASP.NET Core�j

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

        // HTTP�w�b�_�[���瑊��ID���擾�i���݂���ꍇ�j
        var correlationId = context.Request.Headers["X-Correlation-Id"].FirstOrDefault()
            ?? Guid.NewGuid().ToString();

        using var scope = mcpContext.BeginTool(context.Request.Path);
        
        // ���X�|���X�w�b�_�[�ɑ���ID��ǉ�
        context.Response.Headers.Append("X-Correlation-Id", correlationId);

        await _next(context);
    }
}

// Startup.cs
app.UseMiddleware<McpContextMiddleware>();
```

## �g���u���V���[�e�B���O

### �R���e�L�X�g�� null �̏ꍇ

```csharp
// AddMcpExecutionContext ���o�^����Ă��邩�m�F
services.AddMcpExecutionContext();

// �X�R�[�v���쐬����Ă��邩�m�F
using var scope = context.BeginTool("tool.name");
```

### ����ID����v���Ȃ��ꍇ

```csharp
// �񓯊������� ExecutionContext �������p����Ȃ��ꍇ
// ConfigureAwait(false) ���g�p���Ă��Ȃ����m�F
await Task.Delay(100); // OK
await Task.Delay(100).ConfigureAwait(false); // NG: �R���e�L�X�g��������
```

### �l�X�g�����X�R�[�v�����܂����삵�Ȃ��ꍇ

```csharp
// using �X�e�[�g�����g�𐳂����g�p���Ă��邩�m�F
using (var scope1 = context.BeginTool("tool1"))
{
    using (var scope2 = context.BeginTool("tool2"))
    {
        // OK
    }
}

// �ȉ��� NG: scope ���K�؂ɕ����Ȃ�
var scope1 = context.BeginTool("tool1");
var scope2 = context.BeginTool("tool2");
```

## �Q�l�����N

- [MCP Logging USAGE](../logging/USAGE.md)
- [Ateliers.Core ExecutionContext](../../../Ateliers.Core/Context/)
