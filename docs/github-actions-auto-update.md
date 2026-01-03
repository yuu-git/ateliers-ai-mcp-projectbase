# GitHub Actions 自動更新ワークフロー

このドキュメントでは、ateliers-ai-mcp-projectbase の自動更新を行う GitHub Actions ワークフローについて説明します。

## 概要

- **ワークフロー名**: Update Project Knowledge
- **ファイル**: `.github/workflows/update-project-knowledge.yml`
- **実行頻度**: 毎日 9:00 (JST)
- **目的**: サブモジュールとして参照している各プロジェクトで、最新のプロジェクトナレッジを自動的に同期

## 実行タイミング

### 自動実行（スケジュール）

```yaml
schedule:
  - cron: '0 0 * * *'  # UTC 0:00 = JST 9:00 (毎日)
```

- **頻度**: 毎日 9:00 (JST)
- **理由**: MCPプロジェクト群は現在活発に開発中で、毎日コミットが発生しているため

### 手動実行

GitHub リポジトリから手動実行も可能：

1. GitHub リポジトリの「Actions」タブを開く
2. 「Update Project Knowledge」ワークフローを選択
3. 「Run workflow」ボタンをクリック

## ワークフローの動作

### 1. リポジトリのチェックアウト

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    submodules: true
```

- サブモジュールを含めてリポジトリをチェックアウト
- `GITHUB_TOKEN` を使用して認証

### 2. 現在のサブモジュールコミット取得

```yaml
- name: Get current submodule commit
  id: current_commit
  run: |
    cd .submodules/ateliers-ai-mcp-projectbase
    CURRENT_SHA=$(git rev-parse HEAD)
    CURRENT_SHORT_SHA=$(git rev-parse --short HEAD)
    echo "sha=$CURRENT_SHA" >> $GITHUB_OUTPUT
    echo "short_sha=$CURRENT_SHORT_SHA" >> $GITHUB_OUTPUT
```

- 更新前のコミットハッシュ（フル/ショート）を取得
- 後の比較用に保存

### 3. サブモジュールの更新

```yaml
- name: Update submodule to latest
  run: |
    git submodule update --remote --merge .submodules/ateliers-ai-mcp-projectbase
```

- リモートの最新版にサブモジュールを更新
- `--merge` オプションで変更をマージ

### 4. 更新後のコミット取得

```yaml
- name: Get updated submodule commit
  id: updated_commit
  run: |
    cd .submodules/ateliers-ai-mcp-projectbase
    UPDATED_SHA=$(git rev-parse HEAD)
    UPDATED_SHORT_SHA=$(git rev-parse --short HEAD)
```

- 更新後のコミットハッシュを取得

### 5. 変更チェック

```yaml
- name: Check for changes
  id: check_changes
  run: |
    if [ "${{ steps.current_commit.outputs.sha }}" == "${{ steps.updated_commit.outputs.sha }}" ]; then
      echo "has_changes=false" >> $GITHUB_OUTPUT
    else
      echo "has_changes=true" >> $GITHUB_OUTPUT
    fi
```

- 更新前後のコミットハッシュを比較
- 変更があるかどうかを判定

### 6. 変更履歴の取得

```yaml
- name: Get change log
  if: steps.check_changes.outputs.has_changes == 'true'
  id: changelog
  run: |
    cd .submodules/ateliers-ai-mcp-projectbase
    CHANGELOG=$(git log --oneline ${{ steps.current_commit.outputs.sha }}..${{ steps.updated_commit.outputs.sha }})
    echo "log<<EOF" >> $GITHUB_OUTPUT
    echo "$CHANGELOG" >> $GITHUB_OUTPUT
    echo "EOF" >> $GITHUB_OUTPUT
    
    COMMIT_COUNT=$(git rev-list --count ${{ steps.current_commit.outputs.sha }}..${{ steps.updated_commit.outputs.sha }})
    echo "count=$COMMIT_COUNT" >> $GITHUB_OUTPUT
```

- 変更がある場合のみ実行
- コミットログとコミット数を取得

### 7. コミットとプッシュ

```yaml
- name: Commit and push if changed
  if: steps.check_changes.outputs.has_changes == 'true'
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .submodules/ateliers-ai-mcp-projectbase
    git commit -m "chore: update project knowledge submodule" \
               -m "Updated from abc1234 to def5678 (5 commits)"
    git push
```

- 変更がある場合のみコミット・プッシュ
- コミットメッセージに更新情報を含める
  - タイトル: `chore: update project knowledge submodule`
  - 本文: 更新前後のコミットハッシュとコミット数

### 8. サマリーの作成

```yaml
- name: Create summary
  run: |
    if [ "${{ steps.check_changes.outputs.has_changes }}" == "true" ]; then
      echo "## ✅ Project Knowledge サブモジュールを更新しました" >> $GITHUB_STEP_SUMMARY
      # ... 詳細な情報を追加
    else
      echo "## ℹ️ Project Knowledge は既に最新版です" >> $GITHUB_STEP_SUMMARY
    fi
```

- GitHub Actions のサマリー機能を使用
- 更新情報、変更履歴、確認コマンドを表示

## サマリー出力例

### 更新があった場合

```markdown
## ✅ Project Knowledge サブモジュールを更新しました

### 📊 更新情報

- **更新前**: `abc1234`
- **更新後**: `def5678`
- **コミット数**: 5 commits

### 📝 変更履歴

```
def5678 Add architecture overview
cde4567 Update design principles
bcd3456 Add naming conventions
abc2345 Initial directory structure
```

### 🔍 詳細確認

```bash
# サブモジュールディレクトリに移動
cd .submodules/ateliers-ai-mcp-projectbase

# 変更履歴を確認
git log --oneline -10

# 特定のコミットの詳細を確認
git show <commit-hash>
```
```

### 更新がなかった場合

```markdown
## ℹ️ Project Knowledge は既に最新版です

現在のコミット: `abc1234`
```

## カスタマイズ

### 実行頻度の変更

開発が落ち着いてきたら、実行頻度を調整できます：

```yaml
# 毎週月曜日 9:00
schedule:
  - cron: '0 0 * * 1'

# 毎日 9:00（現在の設定）
schedule:
  - cron: '0 0 * * *'

# 週2回（月曜日と木曜日 9:00）
schedule:
  - cron: '0 0 * * 1,4'
```

### サブモジュールパスの変更

デフォルトでは `.submodules/ateliers-ai-mcp-projectbase` を参照していますが、別のパスを使用する場合は変更が必要です。

## トラブルシューティング

### ワークフローが実行されない

- **原因**: スケジュール実行はデフォルトブランチでのみ動作
- **解決**: `.github/workflows/update-project-knowledge.yml` が `main` または `master` ブランチにあることを確認

### プッシュに失敗する

- **原因**: 権限不足
- **解決**: リポジトリの設定で「Settings > Actions > General > Workflow permissions」を確認
  - 「Read and write permissions」を有効化

### サブモジュールが更新されない

- **原因**: サブモジュールが正しく初期化されていない
- **解決**: 手動で確認
  ```bash
  git submodule status
  git submodule update --init --recursive
  ```

## 必要な権限

このワークフローには以下の権限が必要です：

```yaml
permissions:
  contents: write
```

- **contents: write**: リポジトリへのコミット・プッシュに必要

## セキュリティ

- `GITHUB_TOKEN` は GitHub Actions によって自動的に提供される
- スコープは実行中のリポジトリに限定される
- 追加のシークレット設定は不要

## 関連ドキュメント

- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
- [Git Submodules](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%81%95%E3%81%BE%E3%81%96%E3%81%BE%E3%81%AA%E3%83%84%E3%83%BC%E3%83%AB-%E3%82%B5%E3%83%96%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB)
- [README.md](../README.md) - インストールと使用方法

## 更新履歴

- **2026-01-04**: 初版作成
  - 毎日実行に変更（活発な開発期間に対応）
  - 詳細な変更履歴表示機能を追加
  - コミットメッセージに更新情報を含めるように改善
