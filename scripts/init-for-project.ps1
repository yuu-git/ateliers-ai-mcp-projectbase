#######################################
# ateliers-ai-mcp-projectbase 初回セットアップスクリプト (PowerShell版)
# 
# 使用方法:
#   irm https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/scripts/init-for-project.ps1 | iex
#######################################

param(
    [switch]$Help
)

if ($Help) {
    Write-Host @"
ateliers-ai-mcp-projectbase セットアップスクリプト

使用方法:
  ワンライナー:
    irm https://raw.githubusercontent.com/yuu-git/ateliers-ai-mcp-projectbase/master/scripts/init-for-project.ps1 | iex
  
  ローカル実行:
    .\scripts\init-for-project.ps1

このスクリプトは以下を自動実行します:
  - サブモジュールの追加と初期化
  - masterブランチへの切り替え
  - 更新スクリプトのコピー
  - GitHub Actions の設定（オプション）
  - ワークフロー運用ドキュメントのコピー（オプション）
"@
    exit 0
}

# 設定
$REPO_URL = "https://github.com/yuu-git/ateliers-ai-mcp-projectbase.git"
$SUBMODULE_PATH = ".submodules/ateliers-ai-mcp-projectbase"
$SCRIPTS_DIR = "scripts"

# エラー発生時に停止
$ErrorActionPreference = "Stop"

# ヘッダー表示
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  ateliers-ai-mcp-projectbase セットアップ" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Gitリポジトリチェック
if (-not (Test-Path ".git")) {
    Write-Host "⚠️  警告: このディレクトリはGitリポジトリではありません" -ForegroundColor Yellow
    Write-Host "   先に 'git init' を実行してください"
    exit 1
}

# サブモジュール追加
Write-Host "📦 サブモジュールを追加中..." -ForegroundColor Blue
if (Test-Path $SUBMODULE_PATH) {
    Write-Host "   既に存在します。スキップします。"
} else {
    try {
        git submodule add $REPO_URL $SUBMODULE_PATH 2>&1 | Where-Object { $_ -notmatch "Cloning into" } | Write-Host
    } catch {
        Write-Host "   エラー: サブモジュールの追加に失敗しました" -ForegroundColor Red
        exit 1
    }
}

# サブモジュール初期化・更新
Write-Host "🔄 サブモジュールを初期化中..." -ForegroundColor Blue
git submodule update --init --recursive

# masterブランチに切り替え
Write-Host "🌿 masterブランチに切り替え中..." -ForegroundColor Blue
Push-Location $SUBMODULE_PATH
try {
    git checkout master
    git pull origin master
} finally {
    Pop-Location
}

# scriptsディレクトリ作成
if (-not (Test-Path $SCRIPTS_DIR)) {
    New-Item -ItemType Directory -Path $SCRIPTS_DIR | Out-Null
}

# 更新スクリプトをコピー
Write-Host "📋 更新スクリプトをコピー中..." -ForegroundColor Blue
Copy-Item "$SUBMODULE_PATH/scripts/update-ateliers-ai-mcp-projectbase.ps1" "$SCRIPTS_DIR/" -Force
Copy-Item "$SUBMODULE_PATH/scripts/update-ateliers-ai-mcp-projectbase.sh" "$SCRIPTS_DIR/" -Force

# GitHub Actionsワークフローをコピー（オプション）
Write-Host ""
$response = Read-Host "GitHub Actions による自動更新を設定しますか? (y/N)"
if ($response -match "^[Yy]$") {
    if (-not (Test-Path ".github/workflows")) {
        New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
    }
    Copy-Item "$SUBMODULE_PATH/.github/workflows/update-ateliers-ai-mcp-projectbase.yml" ".github/workflows/" -Force
    Write-Host "✅ GitHub Actions ワークフローを追加しました" -ForegroundColor Green
    Write-Host "   定期的に自動更新されます（毎日9時）"
    
    # ワークフロー運用ドキュメントもコピー
    Write-Host ""
    $docResponse = Read-Host "ワークフロー運用ドキュメントもコピーしますか? (y/N)"
    if ($docResponse -match "^[Yy]$") {
        if (-not (Test-Path ".github/docs/workflows")) {
            New-Item -ItemType Directory -Path ".github/docs/workflows" -Force | Out-Null
        }
        Copy-Item "$SUBMODULE_PATH/.github/docs/workflows/update-ateliers-ai-mcp-projectbase.md" ".github/docs/workflows/" -Force
        Write-Host "✅ ワークフロー運用ドキュメントを追加しました" -ForegroundColor Green
        Write-Host "   場所: .github/docs/workflows/update-ateliers-ai-mcp-projectbase.md"
    }
}

# .gitignoreの確認
Write-Host ""
Write-Host "📝 .gitignore を確認中..." -ForegroundColor Blue
if (Test-Path ".gitignore") {
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -notmatch "\.project-knowledge/") {
        Add-Content ".gitignore" "`n# Project Knowledge (if using copy script)`n.project-knowledge/"
        Write-Host "   .gitignore に .project-knowledge/ を追加しました"
    }
} else {
    Set-Content ".gitignore" "# Project Knowledge (if using copy script)`n.project-knowledge/"
    Write-Host "   .gitignore を作成しました"
}

# 完了メッセージ
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ セットアップ完了！" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "【セットアップ内容】"
Write-Host "  ✓ サブモジュール: $SUBMODULE_PATH"
Write-Host "  ✓ 更新スクリプト: $SCRIPTS_DIR/update-ateliers-ai-mcp-projectbase.ps1"
if ($response -match "^[Yy]$") {
    Write-Host "  ✓ GitHub Actions: .github/workflows/update-ateliers-ai-mcp-projectbase.yml"
    if ($docResponse -match "^[Yy]$") {
        Write-Host "  ✓ 運用ドキュメント: .github/docs/workflows/update-ateliers-ai-mcp-projectbase.md"
    }
}
Write-Host ""
Write-Host "【AI ツールでの使用方法】"
Write-Host ""
Write-Host "  Cursor / Cline:"
Write-Host "    @Docs $SUBMODULE_PATH/llms.txt"
Write-Host ""
Write-Host "  GitHub Copilot:"
Write-Host "    $SUBMODULE_PATH 内のファイルを開く"
Write-Host ""
Write-Host "【今後の更新方法】"
Write-Host ""
Write-Host "  手動更新 (PowerShell):"
Write-Host "    .\$SCRIPTS_DIR\update-ateliers-ai-mcp-projectbase.ps1"
Write-Host ""
Write-Host "  手動更新 (bash):"
Write-Host "    ./$SCRIPTS_DIR/update-ateliers-ai-mcp-projectbase.sh"
Write-Host ""
if ($response -match "^[Yy]$") {
    Write-Host "  自動更新:"
    Write-Host "    毎日9時に自動実行されます"
    Write-Host "    手動実行: GitHub > Actions > Update Project Knowledge > Run workflow"
    Write-Host ""
}
Write-Host "詳細: https://github.com/yuu-git/ateliers-ai-mcp-projectbase"
Write-Host ""
