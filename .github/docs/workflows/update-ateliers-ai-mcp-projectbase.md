# Update Project Knowledge Workflow

**ワークフローファイル**: [`.github/workflows/update-ateliers-ai-mcp-projectbase.yml`](../../workflows/update-ateliers-ai-mcp-projectbase.yml)

## 📋 概要

`ateliers-ai-mcp-projectbase` をサブモジュールとして利用しているプロジェクトで、サブモジュールを自動的に最新版に更新するためのワークフローです。

**目的**:
- サブモジュールの自動更新
- 変更履歴の記録
- コミット＆プッシュの自動化

**適用対象**:
- このワークフローファイルを `.github/workflows/` にコピーしたプロジェクト
- `.submodules/ateliers-ai-mcp-projectbase` にサブモジュールが配置されているプロジェクト

## ⏰ トリガー

### 定期実行

```yaml
schedule:
  - cron: '0 0 * * *'  # UTC 0:00 = JST 9:00 (毎日)
```

**実行時刻**: 毎日 JST 9:00（UTC 0:00）

### 手動実行

```yaml
workflow_dispatch:
```

GitHub の Actions タブから手動で実行可能。

**手順**:
1. GitHub リポジトリの「Actions」タブを開く
2. 「Update Project Knowledge」を選択
3. 「Run workflow」をクリック

## 🔧 処理フロー

### 1. リポジトリのチェックアウト

```yaml
- name: Checkout repository
  uses: actions/checkout@v4
  with:
    token: ${{ secrets.GITHUB_TOKEN }}
    submodules: true
```

- メインリポジトリとサブモジュールを取得
- `GITHUB_TOKEN` を使用（自動生成）

### 2. 現在のサブモジュールコミットを取得

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

**出力**:
- `current_commit.sha`: 完全な SHA-1 ハッシュ
- `current_commit.short_sha`: 短縮 SHA-1 ハッシュ

### 3. サブモジュールを最新版に更新

```yaml
- name: Update submodule to latest
  run: |
    git submodule update --remote .submodules/ateliers-ai-mcp-projectbase
```

- サブモジュールの master ブランチの最新コミットを取得

### 4. 更新後のサブモジュールコミットを取得

```yaml
- name: Get updated submodule commit
  id: updated_commit
  run: |
    cd .submodules/ateliers-ai-mcp-projectbase
    UPDATED_SHA=$(git rev-parse HEAD)
    UPDATED_SHORT_SHA=$(git rev-parse --short HEAD)
    echo "sha=$UPDATED_SHA" >> $GITHUB_OUTPUT
    echo "short_sha=$UPDATED_SHORT_SHA" >> $GITHUB_OUTPUT
```

**出力**:
- `updated_commit.sha`: 更新後の完全な SHA-1 ハッシュ
- `updated_commit.short_sha`: 更新後の短縮 SHA-1 ハッシュ

### 5. 変更を検出

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

**出力**:
- `check_changes.has_changes`: `true` または `false`

**条件分岐**:
- 変更がない場合: コミット・デプロイをスキップ
- 変更がある場合: 次のステップを実行

### 6. 変更履歴を取得（変更がある場合のみ）

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

**出力**:
- `changelog.log`: 変更履歴（git log --oneline の出力）
- `changelog.count`: コミット数

### 7. コミット＆プッシュ（変更がある場合のみ）

```yaml
- name: Commit and push if changed
  if: steps.check_changes.outputs.has_changes == 'true'
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .submodules/ateliers-ai-mcp-projectbase
    git commit -m "chore: update ateliers-ai-mcp-projectbase submodule" \
               -m "Updated from ... to ... (X commits)"
    git push
```

**コミットメッセージ形式**:
```
chore: update ateliers-ai-mcp-projectbase submodule

Updated from abc1234 to def5678 (3 commits)
```

### 8. サマリーを生成

```yaml
- name: Create summary
  run: |
    # GitHub Actions の Summary 機能を使用して結果を表示
```

**サマリー内容**:
- 更新前後のコミットハッシュ
- 変更されたコミット数
- 変更履歴（git log）
- 詳細確認コマンド

## 🔐 必要な設定

### Secrets

| Secret | 説明 | 権限 |
|--------|------|------|
| `GITHUB_TOKEN` | GitHub Actions が自動生成 | `contents: write` |

**設定不要**: `GITHUB_TOKEN` は自動的に利用可能です。

### Permissions

```yaml
permissions:
  contents: write
```

**必要な権限**:
- `contents: write`: サブモジュール更新のコミット＆プッシュに必要

## 📊 実行結果の確認

### GitHub Actions タブ

1. リポジトリの「Actions」タブを開く
2. 「Update Project Knowledge」ワークフローを選択
3. 実行履歴を確認

### サマリー例（変更あり）

```
## ✅ Project Knowledge サブモジュールを更新しました

### 📊 更新情報

- **更新前**: `abc1234`
- **更新後**: `def5678`
- **コミット数**: 3 commits

### 📝 変更履歴

```
abc1234 feat: add architecture guidelines
bcd2345 docs: update design principles
cde3456 fix: correct llms.txt path
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

### サマリー例（変更なし）

```
## ℹ️ Project Knowledge は既に最新版です

現在のコミット: `abc1234`
```

## 🛠️ トラブルシューティング

### ワークフローが実行されない

**原因1**: cron 設定のタイムゾーン間違い

**確認**:
- GitHub Actions の cron は UTC
- JST 9:00 = UTC 0:00 = `'0 0 * * *'`

**原因2**: ワークフローが無効化されている

**解決策**:
1. Actions タブで該当ワークフローを確認
2. 無効化されている場合は有効化

### サブモジュールが更新されない

**原因**: サブモジュールが detached HEAD 状態

**解決策**:
```bash
cd .submodules/ateliers-ai-mcp-projectbase
git checkout master
git pull origin master
cd ../..
git add .submodules/ateliers-ai-mcp-projectbase
git commit -m "chore: fix submodule state"
git push
```

### コミットに失敗する

**原因1**: 権限不足

**確認**:
```yaml
permissions:
  contents: write  # この設定があるか確認
```

**原因2**: Git 設定の問題

**解決策**: ワークフロー内で Git 設定が正しく行われているか確認
```yaml
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
```

### プッシュに失敗する

**原因**: ブランチ保護ルールに抵触

**解決策**:
1. リポジトリ設定の「Branches」を確認
2. `github-actions[bot]` からのプッシュを許可

## 🔮 今後の改善案

1. **通知機能**: Slack や Discord への更新通知
2. **条件付き更新**: 特定のファイルが変更された場合のみ更新
3. **ロールバック機能**: 問題発生時の自動ロールバック
4. **複数ブランチ対応**: develop ブランチなどの対応

---

*Last Updated: 2026-01-13*  
*Workflow Version: 1.0*
