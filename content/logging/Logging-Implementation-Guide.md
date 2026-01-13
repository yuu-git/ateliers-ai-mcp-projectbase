---
title: MCP ロギング 実装ガイド
sidebar_label: ロギング実装ガイド
tags: [Ateliers.Ai.Mcp, Logging, ロギング, ガイド]
description: Ateliers.Ai.Mcp サービス実装におけるロギングの実装ガイドライン
---

# MCP ロギング 実装ガイド

このドキュメントは、MCPサービス実装時の**ロギング方針**を提供します。
開発者がサービスクラスにログを追加する際の具体的な指針を示します。

---

## 1. 基本原則

### 1.1 ログレベルの使い分け

| レベル | 用途 | 例 |
|--------|------|-----|
| **Trace** | LLM動作の詳細トレース | プロンプト、レスポンス、推論過程 |
| **Debug** | 開発・デバッグ情報 | 内部状態、変数値、フロー確認 |
| **Info** | 通常の実行フロー | 処理開始、完了、主要な状態変化 |
| **Warn** | 警告（継続可能） | 設定不足、フォールバック実行、非推奨機能使用 |
| **Error** | エラー（継続可能） | 操作失敗だが結果オブジェクトで通知可能 |
| **Critical** | 致命的エラー（継続不可） | 例外をthrowする直前 |

---

## 2. 例外処理とロギングのパターン

### 2.1 基本パターン：例外を先に作成してからログ

```csharp
// ? 悪い例
if (options == null)
{
    McpLogger?.Critical($"{LogPrefix} 初期化失敗");
    throw new ArgumentNullException(nameof(options));
}

// ? 良い例
if (options == null)
{
    var ex = new ArgumentNullException(nameof(options));
    McpLogger?.Critical($"{LogPrefix} 初期化失敗", ex);
    throw ex;
}
```

**理由：**
- 例外オブジェクトをログに含めることで、スタックトレースなどの詳細情報が記録される
- ログと例外の情報が一致する

---

### 2.2 Critical vs Error の使い分け

#### Critical: 継続不可能で throw する場合

```csharp
if (!File.Exists(fullPath))
{
    var ex = new FileNotFoundException($"File not found: {filePath}");
    McpLogger?.Critical($"{LogPrefix} ファイルが見つかりません: fullPath={fullPath}", ex);
    throw ex;
}
```

#### Error: 継続可能な場合（結果オブジェクトで通知）

```csharp
if (!Repository.IsValid(repoPath))
{
    var ex = new InvalidOperationException($"Not a valid git repository: {repoPath}");
    McpLogger?.Error($"{LogPrefix} リポジトリが無効です: {repoPath}", ex);
    return new GitPullResult
    {
        Success = false,
        Message = ex.Message
    };
}
```

**使い分けの基準：**
- 例外を throw する → **Critical**
- 結果オブジェクトを返す → **Error**
- 処理を続行できる → **Warn**

---

## 3. サービスクラスでのロギング実装パターン

### 3.1 LogPrefix の定義

各サービスクラスの先頭で定義します。

```csharp
public class GitHubService : McpServiceBase, IGitHubService
{
    private const string LogPrefix = $"{nameof(GitHubService)}:";
    
    // ...
}
```

---

### 3.2 コンストラクタ

```csharp
public GitHubService(IMcpLogger mcpLogger, IGitHubSettings gitHubSettings, ...)
    : base(mcpLogger)
{
    McpLogger?.Info($"{LogPrefix} 初期化処理開始");
    
    if (gitHubSettings == null)
    {
        var ex = new ArgumentNullException(nameof(gitHubSettings));
        McpLogger?.Critical($"{LogPrefix} 初期化失敗", ex);
        throw ex;
    }
    
    _gitHubSettings = gitHubSettings;
    
    McpLogger?.Info($"{LogPrefix} 初期化完了");
}
```

---

### 3.3 公開メソッド

#### 簡単な取得メソッド

```csharp
public IEnumerable<string> GetRepositoryKeys()
{
    McpLogger?.Debug($"{LogPrefix} GetRepositoryKeys 開始");
    var keys = _gitHubSettings.GitHubRepositories.Keys;
    McpLogger?.Debug($"{LogPrefix} GetRepositoryKeys 完了: {keys.Count()}件");
    return keys;
}
```

#### 複雑な処理メソッド

```csharp
public async Task<string> GetFileContentAsync(string repositoryKey, string filePath)
{
    McpLogger?.Info($"{LogPrefix} GetFileContentAsync 開始: repositoryKey={repositoryKey}, filePath={filePath}");
    
    if (!_gitHubSettings.GitHubRepositories.TryGetValue(repositoryKey, out var repoSettings))
    {
        var ex = new ArgumentException($"Repository '{repositoryKey}' not found in configuration.");
        McpLogger?.Critical($"{LogPrefix} リポジトリが設定に見つかりません: repositoryKey={repositoryKey}", ex);
        throw ex;
    }
    
    McpLogger?.Debug($"{LogPrefix} ローカル優先モード: localPath={repoSettings.LocalPath}");
    
    // ... 処理 ...
    
    McpLogger?.Info($"{LogPrefix} GetFileContentAsync 完了: サイズ={content.Length}文字");
    return content;
}
```

---

### 3.4 プライベートメソッド

重要な処理のみログを追加します。

```csharp
private async Task<string> GetGitHubFileAsync(string owner, string repo, string path, string branch)
{
    var cacheKey = $"github:{owner}/{repo}:{branch}:{path}";
    McpLogger?.Debug($"{LogPrefix} GetGitHubFileAsync 開始: owner={owner}, repo={repo}, path={path}");
    
    if (_cache.TryGetValue(cacheKey, out string? cachedContent))
    {
        McpLogger?.Debug($"{LogPrefix} キャッシュヒット: cacheKey={cacheKey}");
        return cachedContent;
    }
    
    McpLogger?.Debug($"{LogPrefix} キャッシュミス、GitHubから取得");
    
    // ... API呼び出し ...
    
    McpLogger?.Debug($"{LogPrefix} GetGitHubFileAsync 完了: サイズ={content.Length}文字");
    return content;
}
```

---

## 4. ログに含めるべき情報

### 4.1 必須情報

- **メソッド名**: どの処理か特定できるように
- **主要パラメータ**: 処理対象の識別情報
- **処理結果**: 件数、サイズ、成功/失敗

### 4.2 推奨情報

```csharp
McpLogger?.Info($"{LogPrefix} ListFilesAsync 開始: " +
    $"repositoryKey={repositoryKey}, " +
    $"directory={directory}, " +
    $"extension={extension}");
```

### 4.3 機密情報の取り扱い

#### ? 避けるべき情報

- アクセストークン
- パスワード
- 完全なリモートURL（ユーザー名・リポジトリ名を含む）

#### ? マスクして記録

```csharp
var remoteUrl = repo.Network.Remotes["origin"]?.Url;
McpLogger?.Debug($"{LogPrefix} リモートURL: {MaskRemoteUrl(remoteUrl)}");

// "https://github.com/user/repo" → "github.com/..."
```

---

## 5. 特殊なケースのロギング

### 5.1 フォールバック処理

```csharp
try
{
    // ローカルから取得を試みる
    return await GetLocalFileAsync(filePath);
}
catch (Exception ex)
{
    McpLogger?.Warn($"{LogPrefix} ローカルアクセス失敗、GitHubにフォールバック: {ex.Message}");
    return await GetGitHubFileAsync(filePath);
}
```

### 5.2 キャッシュ動作

```csharp
if (_cache.TryGetValue(cacheKey, out var cached))
{
    McpLogger?.Debug($"{LogPrefix} キャッシュヒット: cacheKey={cacheKey}");
    return cached;
}

McpLogger?.Debug($"{LogPrefix} キャッシュミス、新規取得");
// ... 取得処理 ...
_cache.Set(cacheKey, value, _cacheExpiration);
McpLogger?.Debug($"{LogPrefix} キャッシュに保存: cacheKey={cacheKey}");
```

### 5.3 外部プロセス実行

```csharp
var args = $"-y -i \"{inputFile}\" \"{outputFile}\"";
McpLogger?.Info($"{LogPrefix} FFmpeg 実行開始: パラメータ {args}");

var process = Process.Start(psi);
await process.WaitForExitAsync(ct);

if (process.ExitCode != 0)
{
    var error = await process.StandardError.ReadToEndAsync(ct);
    var ex = new InvalidOperationException($"FFmpeg実行失敗: ExitCode={process.ExitCode}, エラー={error}");
    McpLogger?.Critical($"{LogPrefix} FFmpeg 実行失敗", ex);
    throw ex;
}

McpLogger?.Info($"{LogPrefix} FFmpeg 実行完了");
```

---

## 6. ログを追加すべきタイミング

### 6.1 必ずログを追加する箇所

- [ ] コンストラクタ（初期化開始・完了）
- [ ] 公開メソッドの開始・完了
- [ ] 例外を throw する直前
- [ ] 外部サービス呼び出し（API、データベース、ファイルシステム）
- [ ] フォールバック処理
- [ ] キャッシュ動作

### 6.2 状況に応じて追加する箇所

- [ ] 重要な条件分岐
- [ ] パフォーマンス計測が必要な処理
- [ ] デバッグが困難な複雑な処理

### 6.3 ログを追加しない箇所

- [ ] 単純なプロパティアクセス
- [ ] 内部的なヘルパーメソッド（呼び出し元でログ記録済み）
- [ ] 高頻度で呼ばれる軽量な処理

---

## 7. ログの粒度ガイドライン

### 7.1 Info レベル

```csharp
// ? 適切：主要な処理フローの開始・完了
McpLogger?.Info($"{LogPrefix} GetFileContentAsync 開始: repositoryKey={repositoryKey}");
McpLogger?.Info($"{LogPrefix} GetFileContentAsync 完了: サイズ={content.Length}文字");

// ? 過剰：すべての内部処理
McpLogger?.Info($"{LogPrefix} パスを結合中");
McpLogger?.Info($"{LogPrefix} ファイル存在確認中");
```

### 7.2 Debug レベル

```csharp
// ? 適切：内部状態、フロー確認
McpLogger?.Debug($"{LogPrefix} キャッシュチェック: cacheKey={cacheKey}");
McpLogger?.Debug($"{LogPrefix} リポジトリを開きます: localPath={localPath}");

// ? 過剰：すべての変数値
McpLogger?.Debug($"{LogPrefix} i={i}, j={j}, k={k}");
```

---

## 8. チェックリスト：ログ実装レビュー

新しいサービスクラスを実装したら、以下を確認してください。

- [ ] LogPrefix 定数を定義している
- [ ] コンストラクタで初期化開始・完了をログ記録
- [ ] 公開メソッドで処理開始・完了をログ記録
- [ ] 例外を throw する前に Critical ログを記録
- [ ] 例外オブジェクトをログに含めている
- [ ] 機密情報をマスクしている
- [ ] ログレベル（Critical/Error/Warn）を適切に使い分けている
- [ ] 主要パラメータと結果をログに含めている
- [ ] 外部サービス呼び出しをログ記録している
- [ ] フォールバック処理をログ記録している

---

## 9. まとめ

### ログ実装の黄金律

1. **例外を先に作成し、ログに含めてから throw**
2. **Critical vs Error を正しく使い分ける**
3. **主要な処理フローは必ずログ記録**
4. **機密情報は必ずマスク**
5. **過剰なログは避ける（パフォーマンスと可読性のため）**

このガイドラインに従うことで、統一的で保守しやすいログ実装が実現できます。
