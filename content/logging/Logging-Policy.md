# MCP Logging Policy

## 1. 目的（Purpose）

本ドキュメントは、Ateliers.Ai.Mcp エコシステムにおける  
**ログ出力・保存・保持・削除に関する共通方針**を定義する。

MCP は以下の特徴を持つ：

- ローカル実行される CLI / exe プロセス
- 外部 API / LLM / ファイルシステムとの連携
- 将来的に Docker / サーバー環境へ移行する可能性

そのため、本ログ設計は  
**「開発時のデバッグ」ではなく「実行状態の観測（Observability）」**を主目的とする。

---

## 2. ログの基本方針（Principles）

- ログは **プロセス単位**で出力される
- ログは **失敗時に原因を追跡できる最小限**に留める
- ログ保存は **無制限に行わない**
- 実装は **差し替え可能（抽象化）**であること

---

## 3. ログレベル定義（Log Levels）

| Level | 用途 |
|------|------|
| Trace | LLM の思考過程、詳細デバッグ（通常 OFF） |
| Debug | 開発時の詳細情報 |
| Information | 通常実行ログ（開始・終了・結果） |
| Warning | 想定外だが処理継続可能な事象 |
| Error | 処理失敗・例外 |
| Critical | プロセス継続不能な致命的エラー |

---

## 4. ログの種類（Categories）

### 4.1 実行ログ（Process Log）

**目的**  
MCP プロセスが「何をしたか」を把握する。

**例**
```
[INFO] MCP.Start tool=notion.sync
[INFO] MCP.Success elapsed=1432ms
```
- 常に有効
- 日次ローテーション対象

---

### 4.2 技術ログ（Technical Log）

**目的**  
失敗原因・例外内容を特定する。

**例**
```
[ERROR] HttpRequest failed
endpoint=https://api.notion.com

status=401
```
- Error / Warning レベル中心
- 長期保持対象

---

### 4.3 思考ログ（Trace / AI）

**目的**  
LLM の挙動検証・研究用途。

- デフォルト無効
- 別ファイル・別ディレクトリに出力
- 本番運用では保存しないことを原則とする

---

## 5. 保存先（Storage Locations）

### 5.1 ローカル環境（推奨）
```
logs/
├─ app/
│ └─ mcp-YYYY-MM-DD.log
├─ error/
│ └─ mcp-error-YYYY-MM.log
├─ trace/
│ └─ llm-YYYY-MM-DD.log
└─ archive/
```
- 実行ファイル配下、または `%LOCALAPPDATA%/ateliers/mcp/logs`
- 権限問題を避けるため Program Files 直下は避ける

---

### 5.2 将来（コンテナ / サーバー）

- 標準出力（stdout）への出力を基本とする
- ファイル保存は環境設定により切り替え可能とする

---

## 6. ログ保持期間（Retention Policy）

| レベル | 保持期間 |
|------|------|
| Trace | 1〜3日 |
| Debug | 3〜7日 |
| Information | 14日 |
| Warning | 30日 |
| Error / Critical | 90日 |

---

## 7. ローテーション・削除ルール

- ログは **日次ローテーション**
- 起動時または定期処理により古いログを自動削除
- 手動削除を前提としない

---

## 8. 実装指針（Implementation Notes）

- `ILogger<T>` を直接使用せず、MCP 独自の Logger インターフェースを介す
- ログ出力先・レベルは設定ファイルで切り替え可能にする
- 外部ライブラリ（Serilog 等）への依存は Core では持たない

---

## 9. 非対象（Out of Scope）

- DB へのログ保存
- 分散トレーシング
- APM / メトリクス収集

（必要になった段階で別ドキュメントとして定義する）

---