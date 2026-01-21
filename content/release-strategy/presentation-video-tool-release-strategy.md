---
title: リリース戦略 (Presentation Video Tool)
category: プロジェクトナレッジ
description: プレゼンテーション動画生成ツールのリリース戦略、依存関係の自動セットアップ、配布方法について解説します。
tags: [MCP, プレゼンテーション, VOICEVOX, Marp, FFmpeg, リリース, セットアップ]
---
# プレゼンテーション動画生成ツール リリース戦略

このドキュメントでは、プレゼンテーション動画生成ツール（PresentationVideoTool）のリリース戦略と依存関係の自動セットアップについて説明します。

## 概要

プレゼンテーション動画生成ツールは、以下の外部依存関係を必要とします：

- **Marp CLI**: Markdown からスライド画像を生成
- **VOICEVOX Core**: ナレーション音声を生成
- **FFmpeg**: 画像と音声を動画に合成

これらの依存関係を簡単にセットアップできるよう、自動化スクリプトを提供します。

## 依存関係の詳細

### 1. Marp CLI

**用途**: Markdown からスライド画像（PNG/PDF）を生成

**インストール方法**:
```powershell
npm install -g @marp-team/marp-cli
```

**必要条件**: Node.js がインストールされていること

**公式サイト**: https://github.com/marp-team/marp-cli

### 2. VOICEVOX Core

**用途**: 日本語テキストから音声ファイル（WAV）を生成

**インストール方法**:
```powershell
# Downloader を取得して実行
download-windows-x64.exe --c-api-version 0.16.0 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

**特徴**:
- VOICEVOX Engine と異なり、常駐プロセス不要
- CLI から直接呼び出し可能
- GPU/CPU 両対応

**公式リポジトリ**: https://github.com/VOICEVOX/voicevox_core

**選定理由**:
- ✅ CLI で完結（自動化可能）
- ✅ ライセンス対応（LGPL v3 + 使用許諾）
- ✅ 軽量（Engine より小さい）
- ✅ バージョン指定が容易

**VoicePeak との比較**:
- VoicePeak: 有料製品、個人利用のみ
- VOICEVOX Core: オープンソース、商用利用も可能（条件あり）

### 3. FFmpeg

**用途**: 画像シーケンスと音声ファイルを動画に合成

**インストール方法**:
```powershell
# winget を使用
winget install -e --id Gyan.FFmpeg

# または chocolatey を使用
choco install ffmpeg -y
```

**公式サイト**: https://ffmpeg.org/

## リリース構成

### ディレクトリ構造

```
YourApp-v1.0.0/
├── YourApp.exe                    # メインアプリケーション
├── appsettings.json               # 設定ファイル
├── setup.ps1                      # ワンクリックセットアップスクリプト
├── README.md                      # クイックスタートガイド
├── LICENSE                        # ライセンス情報
└── docs/
    ├── manual-setup.md            # 手動セットアップ手順
    ├── troubleshooting.md         # トラブルシューティング
    └── voicevox-license.txt       # VOICEVOX ライセンス情報
```

### 配布ファイル

1. **アプリケーション本体**
   - Self-contained 形式（.NET Runtime 同梱）
   - または Framework-dependent（.NET 10 必要）

2. **セットアップスクリプト**
   - `setup.ps1`: 依存関係の自動インストール
   - `manual-setup.md`: スクリプトが使えない場合の手順

3. **ドキュメント**
   - README.md: クイックスタート
   - LICENSE: ライセンス情報（VOICEVOX の表記義務を含む）

## 自動セットアップスクリプト

### setup.ps1 の実装

```powershell
# setup.ps1
# プレゼンテーション動画生成ツール セットアップスクリプト

param(
    [string]$VoicevoxCoreVersion = "0.16.0",
    [string]$OnnxRuntimeVersion = "voicevox_onnxruntime-1.17.3",
    [string]$CorePath = ".\voicevox_core"
)

$ErrorActionPreference = "Stop"

Write-Host "=== プレゼンテーション動画生成ツール セットアップ ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Node.js チェック
Write-Host "[1/4] Node.js の確認..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "  ✓ Node.js $nodeVersion が検出されました" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Node.js が見つかりません" -ForegroundColor Red
    Write-Host ""
    Write-Host "Node.js をインストールしてください：" -ForegroundColor Red
    Write-Host "https://nodejs.org/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "インストール後、PowerShell を再起動してこのスクリプトを再度実行してください。" -ForegroundColor Yellow
    exit 1
}

# Step 2: Marp CLI インストール
Write-Host ""
Write-Host "[2/4] Marp CLI のインストール..." -ForegroundColor Yellow
try {
    npm install -g @marp-team/marp-cli
    $marpVersion = marp --version
    Write-Host "  ✓ Marp CLI $marpVersion がインストールされました" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Marp CLI のインストールに失敗しました" -ForegroundColor Red
    Write-Host "  エラー: $_" -ForegroundColor Red
    exit 1
}

# Step 3: FFmpeg インストール
Write-Host ""
Write-Host "[3/4] FFmpeg のインストール..." -ForegroundColor Yellow

$ffmpegInstalled = $false

# FFmpeg が既にインストールされているかチェック
try {
    $ffmpegVersion = ffmpeg -version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ FFmpeg は既にインストールされています" -ForegroundColor Green
        $ffmpegInstalled = $true
    }
} catch {
    # インストールされていない
}

if (-not $ffmpegInstalled) {
    # winget を試す
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "  winget を使用して FFmpeg をインストール中..." -ForegroundColor Cyan
        try {
            winget install -e --id Gyan.FFmpeg --silent
            Write-Host "  ✓ FFmpeg がインストールされました" -ForegroundColor Green
            Write-Host "  ! PowerShell を再起動してください（環境変数を反映するため）" -ForegroundColor Yellow
        } catch {
            Write-Host "  ✗ winget でのインストールに失敗しました" -ForegroundColor Red
        }
    }
    # chocolatey を試す
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "  chocolatey を使用して FFmpeg をインストール中..." -ForegroundColor Cyan
        try {
            choco install ffmpeg -y
            Write-Host "  ✓ FFmpeg がインストールされました" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ chocolatey でのインストールに失敗しました" -ForegroundColor Red
        }
    }
    else {
        Write-Host "  ✗ winget/chocolatey が見つかりません" -ForegroundColor Red
        Write-Host ""
        Write-Host "FFmpeg を手動でインストールしてください：" -ForegroundColor Yellow
        Write-Host "https://ffmpeg.org/download.html" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "または、以下のいずれかのパッケージマネージャーをインストールしてください：" -ForegroundColor Yellow
        Write-Host "- winget (Windows 10 1809+ に標準搭載)" -ForegroundColor Cyan
        Write-Host "- chocolatey (https://chocolatey.org/)" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Step 4: VOICEVOX Core ダウンロード
Write-Host ""
Write-Host "[4/4] VOICEVOX Core のダウンロード..." -ForegroundColor Yellow

$downloaderUrl = "https://github.com/VOICEVOX/voicevox_core/releases/download/$VoicevoxCoreVersion/download-windows-x64.exe"
$downloaderPath = "$PSScriptRoot\download-windows-x64.exe"

try {
    Write-Host "  Downloader をダウンロード中..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloaderUrl -OutFile $downloaderPath
    
    Write-Host "  VOICEVOX Core をダウンロード中（数分かかる場合があります）..." -ForegroundColor Cyan
    & $downloaderPath --c-api-version $VoicevoxCoreVersion --onnxruntime-version $OnnxRuntimeVersion -o $CorePath
    
    # Downloader を削除
    Remove-Item $downloaderPath -Force
    
    Write-Host "  ✓ VOICEVOX Core がダウンロードされました" -ForegroundColor Green
    Write-Host "  場所: $CorePath" -ForegroundColor Cyan
} catch {
    Write-Host "  ✗ VOICEVOX Core のダウンロードに失敗しました" -ForegroundColor Red
    Write-Host "  エラー: $_" -ForegroundColor Red
    exit 1
}

# 完了メッセージ
Write-Host ""
Write-Host "=== セットアップ完了 ===" -ForegroundColor Green
Write-Host ""
Write-Host "次のステップ：" -ForegroundColor Yellow
Write-Host "1. appsettings.json を確認して、必要に応じて設定を変更してください" -ForegroundColor Cyan
Write-Host "2. YourApp.exe を実行してください" -ForegroundColor Cyan
Write-Host ""
Write-Host "注意: FFmpeg をインストールした場合、PowerShell を再起動してください" -ForegroundColor Yellow
Write-Host ""
```

### 実行方法

```powershell
# 管理者権限で PowerShell を起動
# リリースディレクトリに移動
cd C:\path\to\YourApp-v1.0.0

# セットアップを実行
.\setup.ps1

# カスタムパスを指定する場合
.\setup.ps1 -CorePath "C:\CustomPath\voicevox_core"
```

## 手動セットアップ手順

`setup.ps1` が使えない環境向けの手動セットアップ手順。

### 1. Node.js のインストール

1. https://nodejs.org/ から LTS 版をダウンロード
2. インストーラーを実行
3. PowerShell を再起動

### 2. Marp CLI のインストール

```powershell
npm install -g @marp-team/marp-cli
```

### 3. FFmpeg のインストール

**オプション A: winget を使用（推奨）**
```powershell
winget install -e --id Gyan.FFmpeg
```

**オプション B: chocolatey を使用**
```powershell
choco install ffmpeg -y
```

**オプション C: 手動インストール**
1. https://ffmpeg.org/download.html から Windows 版をダウンロード
2. 解凍して適切なディレクトリに配置
3. システム環境変数 `PATH` に FFmpeg の `bin` ディレクトリを追加

### 4. VOICEVOX Core のダウンロード

1. https://github.com/VOICEVOX/voicevox_core/releases から `download-windows-x64.exe` をダウンロード
2. ダウンロードした実行ファイルを実行：

```powershell
.\download-windows-x64.exe --c-api-version 0.16.0 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

### 5. 設定ファイルの確認

`appsettings.json` を開き、VOICEVOX Core のパスが正しいか確認：

```json
{
  "VoicevoxCore": {
    "CorePath": "./voicevox_core",
    "ModelPath": "./voicevox_core/model"
  }
}
```

## CI/CD での自動セットアップ

### GitHub Actions の例

```yaml
name: Setup Dependencies

on:
  push:
    branches: [ master ]

jobs:
  setup:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '20'
    
    - name: Install Marp CLI
      run: npm install -g @marp-team/marp-cli
    
    - name: Install FFmpeg
      run: |
        choco install ffmpeg -y
    
    - name: Download VOICEVOX Core
      run: |
        Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.0/download-windows-x64.exe" -OutFile "download.exe"
        .\download.exe --c-api-version 0.16.0 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
    
    - name: Run Tests
      run: dotnet test
```

## ライセンス表記

### VOICEVOX Core の利用規約

VOICEVOX Core は LGPL v3 ライセンスで提供されており、以下の表記が必要です：

```
本ソフトウェアは、VOICEVOX Core を使用しています。
VOICEVOX Core は LGPL v3 ライセンスの下で配布されています。

VOICEVOX Core:
https://github.com/VOICEVOX/voicevox_core

音声ライブラリ（VOICEVOX）の利用規約：
https://voicevox.hiroshiba.jp/term/
```

### README.md への記載例

```markdown
## 使用しているライブラリ

- **Marp CLI**: MIT License
- **VOICEVOX Core**: LGPL v3 License
- **FFmpeg**: LGPL v2.1 / GPL v2 License

### VOICEVOX について

本ソフトウェアは、音声合成エンジン「VOICEVOX Core」を使用しています。

- プロジェクト: https://github.com/VOICEVOX/voicevox_core
- 利用規約: https://voicevox.hiroshiba.jp/term/

VOICEVOX のキャラクターライセンスは各キャラクターの利用規約に従います。
```

## トラブルシューティング

### Node.js が見つからない

**症状**: `node` コマンドが認識されない

**解決方法**:
1. Node.js をインストール: https://nodejs.org/
2. PowerShell を再起動
3. `node --version` で確認

### Marp CLI が認識されない

**症状**: `marp` コマンドが認識されない

**解決方法**:
1. PowerShell を再起動（グローバルインストールの反映）
2. それでも解決しない場合、npm のグローバルパスを確認：
   ```powershell
   npm config get prefix
   ```
3. 上記パスが環境変数 `PATH` に含まれているか確認

### FFmpeg のインストールが失敗する

**症状**: winget/chocolatey でのインストールが失敗する

**解決方法**:
1. 手動でダウンロード: https://ffmpeg.org/download.html
2. 解凍して `C:\ffmpeg` などに配置
3. システム環境変数 `PATH` に `C:\ffmpeg\bin` を追加

### VOICEVOX Core のダウンロードが遅い

**症状**: ダウンロードに時間がかかる

**原因**: VOICEVOX Core は約 500MB～1GB のサイズがあります

**解決方法**:
- ダウンロードが完了するまで待つ
- ネットワーク環境を確認
- 必要に応じて GPU 版 / CPU 版を選択

### GPU が認識されない

**症状**: VOICEVOX Core が GPU を使用しない

**解決方法**:
1. NVIDIA GPU ドライバーが最新か確認
2. CUDA Toolkit のインストール（必要に応じて）
3. CPU 版でも動作可能（GPU より遅いが問題なし）

## バージョン管理

### 依存関係のバージョン固定

`setup.ps1` ではバージョンをパラメータ化しています：

```powershell
param(
    [string]$VoicevoxCoreVersion = "0.16.0",
    [string]$OnnxRuntimeVersion = "voicevox_onnxruntime-1.17.3"
)
```

新しいバージョンがリリースされた場合：

1. デフォルト値を更新
2. テストを実行
3. README を更新
4. リリースノートに記載

### 互換性マトリクス

| App Version | VOICEVOX Core | Marp CLI | FFmpeg |
|------------|---------------|----------|--------|
| 1.0.0      | 0.16.0        | 3.x      | 6.x    |
| 1.1.0      | 0.16.0        | 3.x      | 6.x    |

## チェックリスト

リリース前のチェックリスト：

- [ ] `setup.ps1` が正常に動作することを確認
- [ ] 手動セットアップ手順をテスト
- [ ] README.md にクイックスタートを記載
- [ ] VOICEVOX のライセンス表記を含める
- [ ] FFmpeg のライセンス表記を含める
- [ ] トラブルシューティングガイドを含める
- [ ] appsettings.json のサンプルを含める
- [ ] 動作確認（Windows 10/11）
- [ ] ウイルススキャン（false positive 対策）

## 参考リンク

- [VOICEVOX Core GitHub](https://github.com/VOICEVOX/voicevox_core)
- [VOICEVOX 利用規約](https://voicevox.hiroshiba.jp/term/)
- [Marp CLI GitHub](https://github.com/marp-team/marp-cli)
- [FFmpeg 公式サイト](https://ffmpeg.org/)
- [Node.js 公式サイト](https://nodejs.org/)

## 更新履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2024-XX-XX | 1.0 | 初版作成 |
