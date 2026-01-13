#!/bin/bash

#######################################
# ateliers-ai-mcp-projectbase 初回セットアップスクリプト
# 
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/scripts/init-for-project.sh | bash
#######################################

set -e

# 設定
REPO_URL="https://github.com/yuu-git/ateliers-ai-mcp-projectbase.git"
SUBMODULE_PATH=".submodules/ateliers-ai-mcp-projectbase"
SCRIPTS_DIR="scripts"

# カラー出力
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  ateliers-ai-mcp-projectbase セットアップ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Gitリポジトリチェック
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}⚠️  警告: このディレクトリはGitリポジトリではありません${NC}"
    echo "   先に 'git init' を実行してください"
    exit 1
fi

# サブモジュール追加
echo -e "${BLUE}📦 サブモジュールを追加中...${NC}"
if [ -d "$SUBMODULE_PATH" ]; then
    echo "   既に存在します。スキップします。"
else
    git submodule add "$REPO_URL" "$SUBMODULE_PATH" 2>&1 | grep -v "Cloning into"
fi

# サブモジュール初期化・更新
echo -e "${BLUE}🔄 サブモジュールを初期化中...${NC}"
git submodule update --init --recursive

# masterブランチに切り替え
echo -e "${BLUE}🌿 masterブランチに切り替え中...${NC}"
cd "$SUBMODULE_PATH"
git checkout master
git pull origin master
cd ../..

# scriptsディレクトリ作成
mkdir -p "$SCRIPTS_DIR"

# 更新スクリプトをコピー
echo -e "${BLUE}📋 更新スクリプトをコピー中...${NC}"
cp "$SUBMODULE_PATH/scripts/update-ateliers-ai-mcp-projectbase.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/update-ateliers-ai-mcp-projectbase.sh"

# GitHub Actionsワークフローをコピー（オプション）
echo ""
echo -e "${YELLOW}GitHub Actions による自動更新を設定しますか? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    mkdir -p .github/workflows
    cp "$SUBMODULE_PATH/.github/workflows/update-ateliers-ai-mcp-projectbase.yml" .github/workflows/
    echo -e "${GREEN}✅ GitHub Actions ワークフローを追加しました${NC}"
    echo "   定期的に自動更新されます（毎日9時）"
    
    # ワークフロー運用ドキュメントもコピー
    echo ""
    echo -e "${YELLOW}ワークフロー運用ドキュメントもコピーしますか? (y/N)${NC}"
    read -r doc_response
    if [[ "$doc_response" =~ ^[Yy]$ ]]; then
        mkdir -p .github/docs/workflows
        cp "$SUBMODULE_PATH/.github/docs/workflows/update-ateliers-ai-mcp-projectbase.md" .github/docs/workflows/
        echo -e "${GREEN}✅ ワークフロー運用ドキュメントを追加しました${NC}"
        echo "   場所: .github/docs/workflows/update-ateliers-ai-mcp-projectbase.md"
    fi
fi

# .gitignoreの確認
echo ""
echo -e "${BLUE}📝 .gitignore を確認中...${NC}"
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.project-knowledge/" .gitignore; then
        echo "# Project Knowledge (if using copy script)" >> .gitignore
        echo ".project-knowledge/" >> .gitignore
        echo "   .gitignore に .project-knowledge/ を追加しました"
    fi
else
    echo "# Project Knowledge (if using copy script)" > .gitignore
    echo ".project-knowledge/" >> .gitignore
    echo "   .gitignore を作成しました"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ セットアップ完了！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "【セットアップ内容】"
echo "  ✓ サブモジュール: $SUBMODULE_PATH"
echo "  ✓ 更新スクリプト: $SCRIPTS_DIR/update-ateliers-ai-mcp-projectbase.sh"
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "  ✓ GitHub Actions: .github/workflows/update-ateliers-ai-mcp-projectbase.yml"
    if [[ "$doc_response" =~ ^[Yy]$ ]]; then
        echo "  ✓ 運用ドキュメント: .github/docs/workflows/update-ateliers-ai-mcp-projectbase.md"
    fi
fi
echo ""
echo "【AI ツールでの使用方法】"
echo ""
echo "  Cursor / Cline:"
echo "    @Docs $SUBMODULE_PATH/llms.txt"
echo ""
echo "  GitHub Copilot:"
echo "    $SUBMODULE_PATH 内のファイルを開く"
echo ""
echo "【今後の更新方法】"
echo ""
echo "  手動更新 (PowerShell):"
echo "    .\\$SCRIPTS_DIR\\update-ateliers-ai-mcp-projectbase.ps1"
echo ""
echo "  手動更新 (bash):"
echo "    ./$SCRIPTS_DIR/update-ateliers-ai-mcp-projectbase.sh"
echo ""
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "  自動更新:"
    echo "    毎日9時に自動実行されます"
    echo "    手動実行: GitHub > Actions > Update Project Knowledge > Run workflow"
    echo ""
fi
echo "詳細: https://github.com/yuu-git/ateliers-ai-mcp-projectbase"
echo ""
