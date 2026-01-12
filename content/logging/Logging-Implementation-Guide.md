@
---
---

# MCP ���M���O �����K�C�h

���̃h�L�������g�́AMCP�T�[�r�X��������**���M���O���j**��񋟂��܂��B
�J���҂��T�[�r�X�N���X�Ƀ��O��ǉ�����ۂ̋�̓I�Ȏw�j�������܂��B

---

## 1. ��{����

### 1.1 ���O���x���̎g������

| ���x�� | �p�r | �� |
|--------|------|-----|
| **Trace** | LLM����̏ڍ׃g���[�X | �v�����v�g�A���X�|���X�A���_�ߒ� |
| **Debug** | �J���E�f�o�b�O��� | ������ԁA�ϐ��l�A�t���[�m�F |
| **Info** | �ʏ�̎��s�t���[ | �����J�n�A�����A��v�ȏ�ԕω� |
| **Warn** | �x���i�p���\�j | �ݒ�s���A�t�H�[���o�b�N���s�A�񐄏��@�\�g�p |
| **Error** | �G���[�i�p���\�j | ���쎸�s�������ʃI�u�W�F�N�g�Œʒm�\ |
| **Critical** | �v���I�G���[�i�p���s�j | ��O��throw���钼�O |

---

## 2. ��O�����ƃ��M���O�̃p�^�[��

### 2.1 ��{�p�^�[���F��O���ɍ쐬���Ă��烍�O

```csharp
// ? ������
if (options == null)
{
    McpLogger?.Critical($"{LogPrefix} ���������s");
    throw new ArgumentNullException(nameof(options));
}

// ? �ǂ���
if (options == null)
{
    var ex = new ArgumentNullException(nameof(options));
    McpLogger?.Critical($"{LogPrefix} ���������s", ex);
    throw ex;
}
```

**���R�F**
- ��O�I�u�W�F�N�g�����O�Ɋ܂߂邱�ƂŁA�X�^�b�N�g���[�X�Ȃǂ̏ڍ׏�񂪋L�^�����
- ���O�Ɨ�O�̏�񂪈�v����

---

### 2.2 Critical vs Error �̎g������

#### Critical: �p���s�\�� throw ����ꍇ

```csharp
if (!File.Exists(fullPath))
{
    var ex = new FileNotFoundException($"File not found: {filePath}");
    McpLogger?.Critical($"{LogPrefix} �t�@�C����������܂���: fullPath={fullPath}", ex);
    throw ex;
}
```

#### Error: �p���\�ȏꍇ�i���ʃI�u�W�F�N�g�Œʒm�j

```csharp
if (!Repository.IsValid(repoPath))
{
    var ex = new InvalidOperationException($"Not a valid git repository: {repoPath}");
    McpLogger?.Error($"{LogPrefix} ���|�W�g���������ł�: {repoPath}", ex);
    return new GitPullResult
    {
        Success = false,
        Message = ex.Message
    };
}
```

**�g�������̊�F**
- ��O�� throw ���� �� **Critical**
- ���ʃI�u�W�F�N�g��Ԃ� �� **Error**
- �����𑱍s�ł��� �� **Warn**

---

## 3. �T�[�r�X�N���X�ł̃��M���O�����p�^�[��

### 3.1 LogPrefix �̒�`

�e�T�[�r�X�N���X�̐擪�Œ�`���܂��B

```csharp
public class GitHubService : McpServiceBase, IGitHubService
{
    private const string LogPrefix = $"{nameof(GitHubService)}:";
    
    // ...
}
```

---

### 3.2 �R���X�g���N�^

```csharp
public GitHubService(IMcpLogger mcpLogger, IGitHubSettings gitHubSettings, ...)
    : base(mcpLogger)
{
    McpLogger?.Info($"{LogPrefix} �����������J�n");
    
    if (gitHubSettings == null)
    {
        var ex = new ArgumentNullException(nameof(gitHubSettings));
        McpLogger?.Critical($"{LogPrefix} ���������s", ex);
        throw ex;
    }
    
    _gitHubSettings = gitHubSettings;
    
    McpLogger?.Info($"{LogPrefix} ����������");
}
```

---

### 3.3 ���J���\�b�h

#### �ȒP�Ȏ擾���\�b�h

```csharp
public IEnumerable<string> GetRepositoryKeys()
{
    McpLogger?.Debug($"{LogPrefix} GetRepositoryKeys �J�n");
    var keys = _gitHubSettings.GitHubRepositories.Keys;
    McpLogger?.Debug($"{LogPrefix} GetRepositoryKeys ����: {keys.Count()}��");
    return keys;
}
```

#### ���G�ȏ������\�b�h

```csharp
public async Task<string> GetFileContentAsync(string repositoryKey, string filePath)
{
    McpLogger?.Info($"{LogPrefix} GetFileContentAsync �J�n: repositoryKey={repositoryKey}, filePath={filePath}");
    
    if (!_gitHubSettings.GitHubRepositories.TryGetValue(repositoryKey, out var repoSettings))
    {
        var ex = new ArgumentException($"Repository '{repositoryKey}' not found in configuration.");
        McpLogger?.Critical($"{LogPrefix} ���|�W�g�����ݒ�Ɍ�����܂���: repositoryKey={repositoryKey}", ex);
        throw ex;
    }
    
    McpLogger?.Debug($"{LogPrefix} ���[�J���D�惂�[�h: localPath={repoSettings.LocalPath}");
    
    // ... ���� ...
    
    McpLogger?.Info($"{LogPrefix} GetFileContentAsync ����: �T�C�Y={content.Length}����");
    return content;
}
```

---

### 3.4 �v���C�x�[�g���\�b�h

�d�v�ȏ����̂݃��O��ǉ����܂��B

```csharp
private async Task<string> GetGitHubFileAsync(string owner, string repo, string path, string branch)
{
    var cacheKey = $"github:{owner}/{repo}:{branch}:{path}";
    McpLogger?.Debug($"{LogPrefix} GetGitHubFileAsync �J�n: owner={owner}, repo={repo}, path={path}");
    
    if (_cache.TryGetValue(cacheKey, out string? cachedContent))
    {
        McpLogger?.Debug($"{LogPrefix} �L���b�V���q�b�g: cacheKey={cacheKey}");
        return cachedContent;
    }
    
    McpLogger?.Debug($"{LogPrefix} �L���b�V���~�X�AGitHub����擾");
    
    // ... API�Ăяo�� ...
    
    McpLogger?.Debug($"{LogPrefix} GetGitHubFileAsync ����: �T�C�Y={content.Length}����");
    return content;
}
```

---

## 4. ���O�Ɋ܂߂�ׂ����

### 4.1 �K�{���

- **���\�b�h��**: �ǂ̏���������ł���悤��
- **��v�p�����[�^**: �����Ώۂ̎��ʏ��
- **��������**: �����A�T�C�Y�A����/���s

### 4.2 �������

```csharp
McpLogger?.Info($"{LogPrefix} ListFilesAsync �J�n: " +
    $"repositoryKey={repositoryKey}, " +
    $"directory={directory}, " +
    $"extension={extension}");
```

### 4.3 �@�����̎�舵��

#### ? ������ׂ����

- �A�N�Z�X�g�[�N��
- �p�X���[�h
- ���S�ȃ����[�gURL�i���[�U�[���E���|�W�g�������܂ށj

#### ? �}�X�N���ċL�^

```csharp
var remoteUrl = repo.Network.Remotes["origin"]?.Url;
McpLogger?.Debug($"{LogPrefix} �����[�gURL: {MaskRemoteUrl(remoteUrl)}");

// "https://github.com/user/repo" �� "github.com/..."
```

---

## 5. ����ȃP�[�X�̃��M���O

### 5.1 �t�H�[���o�b�N����

```csharp
try
{
    // ���[�J������擾�����݂�
    return await GetLocalFileAsync(filePath);
}
catch (Exception ex)
{
    McpLogger?.Warn($"{LogPrefix} ���[�J���A�N�Z�X���s�AGitHub�Ƀt�H�[���o�b�N: {ex.Message}");
    return await GetGitHubFileAsync(filePath);
}
```

### 5.2 �L���b�V������

```csharp
if (_cache.TryGetValue(cacheKey, out var cached))
{
    McpLogger?.Debug($"{LogPrefix} �L���b�V���q�b�g: cacheKey={cacheKey}");
    return cached;
}

McpLogger?.Debug($"{LogPrefix} �L���b�V���~�X�A�V�K�擾");
// ... �擾���� ...
_cache.Set(cacheKey, value, _cacheExpiration);
McpLogger?.Debug($"{LogPrefix} �L���b�V���ɕۑ�: cacheKey={cacheKey}");
```

### 5.3 �O���v���Z�X���s

```csharp
var args = $"-y -i \"{inputFile}\" \"{outputFile}\"";
McpLogger?.Info($"{LogPrefix} FFmpeg ���s�J�n: �p�����[�^ {args}");

var process = Process.Start(psi);
await process.WaitForExitAsync(ct);

if (process.ExitCode != 0)
{
    var error = await process.StandardError.ReadToEndAsync(ct);
    var ex = new InvalidOperationException($"FFmpeg���s���s: ExitCode={process.ExitCode}, �G���[={error}");
    McpLogger?.Critical($"{LogPrefix} FFmpeg ���s���s", ex);
    throw ex;
}

McpLogger?.Info($"{LogPrefix} FFmpeg ���s����");
```

---

## 6. ���O��ǉ����ׂ��^�C�~���O

### 6.1 �K�����O��ǉ�����ӏ�

- [ ] �R���X�g���N�^�i�������J�n�E�����j
- [ ] ���J���\�b�h�̊J�n�E����
- [ ] ��O�� throw ���钼�O
- [ ] �O���T�[�r�X�Ăяo���iAPI�A�f�[�^�x�[�X�A�t�@�C���V�X�e���j
- [ ] �t�H�[���o�b�N����
- [ ] �L���b�V������

### 6.2 �󋵂ɉ����Ēǉ�����ӏ�

- [ ] �d�v�ȏ�������
- [ ] �p�t�H�[�}���X�v�����K�v�ȏ���
- [ ] �f�o�b�O������ȕ��G�ȏ���

### 6.3 ���O��ǉ����Ȃ��ӏ�

- [ ] �P���ȃv���p�e�B�A�N�Z�X
- [ ] �����I�ȃw���p�[���\�b�h�i�Ăяo�����Ń��O�L�^�ς݁j
- [ ] ���p�x�ŌĂ΂��y�ʂȏ���

---

## 7. ���O�̗��x�K�C�h���C��

### 7.1 Info ���x��

```csharp
// ? �K�؁F��v�ȏ����t���[�̊J�n�E����
McpLogger?.Info($"{LogPrefix} GetFileContentAsync �J�n: repositoryKey={repositoryKey}");
McpLogger?.Info($"{LogPrefix} GetFileContentAsync ����: �T�C�Y={content.Length}����");

// ? �ߏ�F���ׂĂ̓�������
McpLogger?.Info($"{LogPrefix} �p�X��������");
McpLogger?.Info($"{LogPrefix} �t�@�C�����݊m�F��");
```

### 7.2 Debug ���x��

```csharp
// ? �K�؁F������ԁA�t���[�m�F
McpLogger?.Debug($"{LogPrefix} �L���b�V���`�F�b�N: cacheKey={cacheKey}");
McpLogger?.Debug($"{LogPrefix} ���|�W�g�����J���܂�: localPath={localPath}");

// ? �ߏ�F���ׂĂ̕ϐ��l
McpLogger?.Debug($"{LogPrefix} i={i}, j={j}, k={k}");
```

---

## 8. �`�F�b�N���X�g�F���O�������r���[

�V�����T�[�r�X�N���X������������A�ȉ����m�F���Ă��������B

- [ ] LogPrefix �萔���`���Ă���
- [ ] �R���X�g���N�^�ŏ������J�n�E���������O�L�^
- [ ] ���J���\�b�h�ŏ����J�n�E���������O�L�^
- [ ] ��O�� throw ����O�� Critical ���O���L�^
- [ ] ��O�I�u�W�F�N�g�����O�Ɋ܂߂Ă���
- [ ] �@�������}�X�N���Ă���
- [ ] ���O���x���iCritical/Error/Warn�j��K�؂Ɏg�������Ă���
- [ ] ��v�p�����[�^�ƌ��ʂ����O�Ɋ܂߂Ă���
- [ ] �O���T�[�r�X�Ăяo�������O�L�^���Ă���
- [ ] �t�H�[���o�b�N���������O�L�^���Ă���

---

## 9. �܂Ƃ�

### ���O�����̉�����

1. **��O���ɍ쐬���A���O�Ɋ܂߂Ă��� throw**
2. **Critical vs Error �𐳂����g��������**
3. **��v�ȏ����t���[�͕K�����O�L�^**
4. **�@�����͕K���}�X�N**
5. **�ߏ�ȃ��O�͔�����i�p�t�H�[�}���X�Ɖǐ��̂��߁j**

���̃K�C�h���C���ɏ]�����ƂŁA����I�ŕێ炵�₷�����O�����������ł��܂��B
