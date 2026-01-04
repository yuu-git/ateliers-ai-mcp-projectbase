# MCP ロギング 実践ガイド

このドキュメントは、MCPロギングの**実践的な使用ガイド**を提供します。
Logging Policyを補完し、開発、デバッグ、運用中に**ログが実際にどのように使用されるか**を説明します。

このガイドは、MVPフェーズ後の**ドキュメント駆動開発**をサポートするために書かれています。

---

## 1. ログ保持期間 具体的な実装

### 1.1 目的

MCPログは無期限に保持されません。
保持期間が存在する理由：

- ディスク容量の枯渇を防ぐ
- ログを関連性が高く読みやすい状態に保つ
- 運用メンテナンス作業を回避する

保持期間処理は**MCP起動時に一度だけ**実行されます。

---

### 1.2 ディレクトリレイアウトの前提

```
logs/
├─ app/     # Information / 通常実行ログ
├─ error/   # Error / クリティカルログ
├─ trace/   # LLM / 詳細トレースログ（オプション）
```

---

### 1.3 保持ポリシー（有効期間）

| カテゴリ | ログレベル | 保持期間 |
|---------|-----------|---------|
| trace   | Trace     | 1～3日   |
| app     | Info      | 14日    |
| error   | Error+    | 90日    |

---

### 1.4 実際のクリーンアップロジック（参考）

```csharp
private void CleanDirectory(string subDir, TimeSpan retention)
{
    var dir = Path.Combine(_baseLogDirectory, subDir);
    if (!Directory.Exists(dir))
        return;

    var now = DateTimeOffset.UtcNow;

    foreach (var file in Directory.EnumerateFiles(dir))
    {
        var lastWriteUtc = File.GetLastWriteTimeUtc(file);
        var lastWrite = new DateTimeOffset(lastWriteUtc, TimeSpan.Zero);

        if (now - lastWrite > retention)
        {
            try
            {
                File.Delete(file);
            }
            catch
            {
                // 削除失敗は無視
            }
        }
    }
}
```

**設計メモ**

- タイムゾーンの安全性のため `LastWriteTimeUtc` を使用
- 削除失敗は無視
- クリーンアップ自体はログに記録しない（ログの増幅を避けるため）

---

## 2. ログの使用方法（運用視点）

このセクションでは、状況に応じて**最初にどのログを確認すべきか**を説明します。

---

## 3. 通常のMCP実行確認

### 状況
- MCPが正常に実行された
- 動作を確認したい

### 確認するログ
`logs/app/mcp-YYYY-MM-DD.log`

### 確認内容
```
[INFO] MCP.Start
[INFO] MCP.Success
```

### 解釈
- 実行は正常に完了
- さらなる調査は不要

---

## 4. MCP実行が失敗した場合

### 状況
- ツールが失敗を返した
- CLI / 呼び出し元がエラーを報告

### 確認するログ（順序が重要）
1. `logs/error/`
2. 対応する `logs/app/`

### 確認内容
```
[ERROR] MCP.Failed
Exception: ...
CorrelationId=xxxx
```

その後、同じ `CorrelationId` を app ログで検索します。

### 解釈
- エラーログが**なぜ**失敗したかを説明
- appログが失敗前に**何が起きていたか**を説明

---

## 5. 外部サービス / API の問題

### 状況
- Notion / GitHub / 外部APIが失敗
- 認証またはネットワーク問題が疑われる

### 確認するログ
`logs/error/`

以下を含むエントリ：
- ToolName
- エンドポイント情報
- HTTPステータス

### 典型的なパターン
```
[ERROR] External service call failed
status=401
```

### 解釈
- 設定または認証情報の問題の可能性が高い
- MCP自体のロジックバグではない

---

## 6. LLM / AI 動作の調査

### 状況
- 予期しないLLM出力
- プロンプトまたは推論の検査が必要

### 確認するログ
`logs/trace/`（有効な場合のみ）

### 注意事項
- トレースログはデフォルトで無効
- 研究、チューニング、デバッグを目的としている
- 通常の運用には不要

---

## 7. CorrelationId の使用方法

すべてのMCP実行には `CorrelationId` があります。

### 目的
以下をまたいでログを関連付ける：
- ツール実行
- API呼び出し
- LLMインタラクション
- ファイル操作

### 使用方法
1. エラーログで `CorrelationId` を見つける
2. appログで同じIDを検索
3. 実行タイムラインを再構築

---

## 8. ロギング vs 例外 ? 設計ルール

MCPは以下の原則に従います：

> **例外は実行を停止する。**  
> **ログは何が起きたかを説明する。**

### 実践的な意味
- 例外は汎用的な場合がある
- ログには常にコンテキストが含まれる
- **例外メッセージだけに頼らない。**
- **常にログを最初に確認する。**

---

## 9. ログが使用されない用途

以下はMCP Coreロギングのスコープ外です：

- ビジネス分析
- メトリクス集計
- 監査証跡
- 長期保存

---

## 10. まとめ

- **ログは主要な可観測性メカニズムである**
- **保持期間は自動的かつ保守的である**
- **運用フローは常にログから始まる**
- **例外構造はロギングの二次的なものである**

この設計は、明確性、安全性、進化性を意図的に優先しています。
