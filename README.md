# ateliers-ai-mcp-projectbase

このリポジトリは、**ateliers-ai-mcp プロジェクト群**のための **プロジェクトナレッジベース** です。  
AI-DDD（AI駆動ドキュメント駆動開発）を実現するための設計ドキュメント、アーキテクチャガイドライン、開発方針などを集約管理します。

## 🎯 目的

- **統一された設計思想**: ateliers-ai-mcp プロジェクト群全体で共通の設計原則とアーキテクチャパターンを維持
- **AI-DDDの実践**: ドキュメント駆動でAIがプロジェクトの意図を正確に理解し、コード生成を支援
- **サブモジュール参照**: 各プロジェクトがサブモジュールとして参照し、常に最新のナレッジにアクセス

## Ateliers.Ai.Mcp.ProjectBase.csproj について

このリポジトリには `Ateliers.Ai.Mcp.ProjectBase.csproj` というC#プロジェクトファイルが含まれていますが
Visual Studio でコンテンツを参照するためのものであり、ビルドや実行は想定していません。

このリポジトリでコードの生成は行わず、あくまでドキュメントとナレッジの集約を目的としています。

## 📦 インストール方法

### 🚀 ワンライナー（推奨）

最も簡単な方法です。1コマンドでセットアップが完了します。

**PowerShell (Windows推奨):**
```powershell
irm https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/scripts/init-for-project.ps1 | iex
```

**Bash (Linux/Mac):**
```bash
curl -fsSL https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/scripts/init-for-project.sh | bash
```

このスクリプトは以下を自動実行します：
- ✅ サブモジュールの追加
- ✅ masterブランチへの切り替え
- ✅ 更新スクリプトのコピー
- ✅ GitHub Actions の設定（オプション）

### 🔧 手動セットアップ

詳細な制御が必要な場合は手動でセットアップできます。

```bash
# 1. サブモジュールとして追加
git submodule add https://github.com/yuu-git/ateliers-ai-mcp-projectbase.git .submodules/ateliers-ai-mcp-projectbase

# 2. サブモジュールを初期化
git submodule update --init --recursive

# 3. masterブランチに切り替え
cd .submodules/ateliers-ai-mcp-projectbase
git checkout master
git pull origin master
cd ../..

# 4. 更新スクリプトをコピー（オプション）
mkdir -p scripts
cp .submodules/ateliers-ai-mcp-projectbase/scripts/update-project-knowledge.sh scripts/
chmod +x scripts/update-project-knowledge.sh
```

## 🔄 更新方法

### 方法1：手動更新スクリプト

必要な時に手動で更新します。

**PowerShell (Windows):**
```powershell
.\scripts\update-project-knowledge.ps1
```

**Bash (Linux/Mac):**
```bash
./scripts/update-project-knowledge.sh
```

### 方法2：GitHub Actions（自動更新）

毎週月曜日9時に自動で更新されます。

```bash
# ワークフローファイルをコピー
mkdir -p .github/workflows
cp .submodules/ateliers-ai-mcp-projectbase/.github/workflows/update-project-knowledge.yml .github/workflows/
```

手動実行も可能：
1. GitHub リポジトリの「Actions」タブを開く
2. 「Update Project Knowledge」を選択
3. 「Run workflow」をクリック

### 方法3：直接コマンド

サブモジュールディレクトリで直接実行します。

```bash
cd .submodules/ateliers-ai-mcp-projectbase
git checkout master
git pull origin master
cd ../..
```

## 🤖 AI ツールでの使用方法

### Cursor / Cline

```
@Docs .submodules/ateliers-ai-mcp-projectbase/llms.txt
```

または、GitHub上のファイルを直接参照：

```
@Docs https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/llms.txt
```

### GitHub Copilot

`.submodules/ateliers-ai-mcp-projectbase` 内のファイルを開くことでコンテキストとして認識されます。

主要ファイル：
- `architecture/overview.md` - 全体アーキテクチャ
- `design-principles/core-concepts.md` - 設計原則
- `project-structure/naming-conventions.md` - 命名規則

### Claude

会話の最初に以下を貼り付けてください：

```
このプロジェクトのナレッジベースに従ってください：
https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/llms.txt
```

## 📚 コンテンツ

### プロジェクトアーキテクチャ

- **全体構成**: ateliers-ai-mcp プロジェクト群の関係性と役割
- **依存関係管理**: NuGetパッケージ依存とバージョン管理戦略
- **レイヤー設計**: Core/Services/Tools/Processes の責務と境界

### 設計原則

- **DDD（ドメイン駆動設計）**: ValueObject、Entity、Aggregateの設計方針
- **クリーンアーキテクチャ**: 依存関係の方向性とレイヤー間通信
- **SOLID原則**: 各プロジェクトで守るべき設計原則

### 開発ガイドライン

- **命名規則**: プロジェクト、名前空間、クラス、メソッドの命名パターン
- **ディレクトリ構造**: 各プロジェクトの標準的なフォルダ構成
- **テスト戦略**: ユニットテスト、統合テストの方針

### リリース戦略

- **バージョニング**: セマンティックバージョニングの運用
- **パッケージング**: NuGetパッケージの作成と配布
- **互換性管理**: 後方互換性の維持方針

## 🏗️ 対象プロジェクト

このナレッジベースは以下のプロジェクトで共有されます：

- **ateliers-ai-mcp-core**: MCPプロトコル実装とコア機能
- **ateliers-ai-mcp-services**: 外部サービス連携（FFmpeg、VOICEVOX等）
- **ateliers-ai-mcp-tools**: 統合ツール（Docusaurus、AteliersDev等）
- **ateliers-ai-mcp-processes**: AI統合プロセス（Claude、Copilot等）
- **ateliers-ai-mcpserver**: MCPサーバー実装
- **ateliers-voice-engines**: 音声エンジン統合

## 📂 ディレクトリ構造

```
ateliers-ai-mcp-projectbase/
├─ content/                              # ドキュメントコンテンツ（Docusaurus連携）
│  └─ project-knowledge/
│     └─ ateliers-ai-mcp/              # Ateliers AI MCP エコシステム
│        ├─ architecture/              # アーキテクチャドキュメント
│        │  ├─ overview.md            # 全体概要
│        │  ├─ project-relationships.md  # プロジェクト間関係
│        │  ├─ dependency-management.md  # 依存関係管理
│        │  └─ layer-design.md        # レイヤー設計
│        │
│        ├─ design-principles/         # 設計原則
│        │  ├─ core-concepts.md       # コア概念
│        │  ├─ ddd-guidelines.md      # DDD設計ガイド
│        │  ├─ clean-architecture.md  # クリーンアーキテクチャ
│        │  └─ solid-principles.md    # SOLID原則
│        │
│        ├─ development-guidelines/    # 開発ガイドライン
│        │  ├─ naming-conventions.md  # 命名規則
│        │  ├─ directory-structure.md # ディレクトリ構造
│        │  ├─ coding-standards.md    # コーディング規約
│        │  └─ testing-strategy.md    # テスト戦略
│        │
│        ├─ release-strategy/          # リリース戦略
│        │  ├─ versioning.md          # バージョニング
│        │  ├─ packaging.md           # パッケージング
│        │  └─ compatibility.md       # 互換性管理
│        │
│        └─ projects/                  # プロジェクト固有知識
│           ├─ core/                   # Core固有ドキュメント
│           ├─ services/               # Services固有ドキュメント
│           ├─ tools/                  # Tools固有ドキュメント
│           └─ processes/              # Processes固有ドキュメント
│
├─ scripts/                              # セットアップ・更新スクリプト
│  ├─ init-for-project.sh               # 初回セットアップ (bash)
│  ├─ init-for-project.ps1              # 初回セットアップ (PowerShell)
│  ├─ update-project-knowledge.sh       # 手動更新 (bash)
│  └─ update-project-knowledge.ps1      # 手動更新 (PowerShell)
│
├─ .github/workflows/                    # GitHub Actions
│  └─ update-project-knowledge.yml      # 自動更新ワークフロー
│
├─ docs/                                 # リポジトリメタドキュメント
│  └─ github-actions-auto-update.md     # ワークフロー説明
│
├─ README.md
├─ llms.txt                              # AI統合用インデックス
└─ LICENSE

```

## 🚀 利用開始

1. **サブモジュールとして追加**: 各プロジェクトで上記のインストール方法を実行
2. **AIツールに参照**: Cursor、Copilot、Claudeなどで `.submodules/ateliers-ai-mcp-projectbase` を参照
3. **定期更新**: GitHub Actionsまたは手動スクリプトで最新化

## 🤝 コントリビューション

プロジェクトナレッジの追加・更新は歓迎します：
- **設計ドキュメント**: 新しいアーキテクチャパターンや設計原則
- **ベストプラクティス**: 開発で得られた知見やノウハウ
- **リファクタリング指針**: コード改善のための方針

## 📄 ライセンス

このリポジトリは [MIT License](https://github.com/yuu-git/ateliers-ai-mcp-projectbase/blob/master/LICENSE) のもとで公開されています。

## 🔗 関連リポジトリ

- [ateliers-knowledge](https://github.com/yuu-git/ateliers-knowledge): AI生成ガイドラインとトレーニングサンプル
- [ateliers-ai-mcp-core](https://github.com/yuu-git/ateliers-ai-mcp-core): MCPコア実装
- [ateliers-ai-mcpserver](https://github.com/yuu-git/ateliers-ai-mcpserver): MCPサーバー実装

