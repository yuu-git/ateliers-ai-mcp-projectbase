---
title: VOICEVOX Core バージョン管理ガイド
category: プロジェクトナレッジ
description: VOICEVOX Core の依存関係バージョン管理、互換性確認、アップデート手順について解説します。
tags: [VOICEVOX, バージョン管理, 互換性, メンテナンス, ONNX Runtime]
---
# VOICEVOX Core バージョン管理ガイド

このドキュメントでは、VOICEVOX Core と関連する依存関係のバージョン管理方法について説明します。

## 概要

VOICEVOX Core を使用する際、以下のコンポーネントのバージョンを管理する必要があります：

1. **VOICEVOX Core**: 音声合成エンジン本体
2. **ONNX Runtime**: 推論エンジン（`voicevox_onnxruntime-*` という名前で配布）
3. **Open JTalk 辞書**: 日本語解析辞書

これらのバージョンには互換性の制約があり、正しい組み合わせで使用する必要があります。

## コンポーネント詳細

### 1. VOICEVOX Core

**役割**: 音声合成のコアライブラリ

**リリース情報**:
- GitHub: https://github.com/VOICEVOX/voicevox_core/releases
- リリース頻度: 不定期（機能追加・バグ修正時）
- 現在の最新: 0.16.3（2024年12月時点）

**命名規則**:
```
voicevox_core-{platform}-{arch}-{device}-{version}.zip

例:
voicevox_core-windows-x64-cpu-0.16.3.zip
voicevox_core-windows-x64-gpu-0.16.3.zip
```

### 2. ONNX Runtime

**役割**: ニューラルネットワークモデルの推論エンジン

**特徴**:
- VOICEVOX プロジェクト専用にビルドされたバージョン（`voicevox_onnxruntime-*`）
- 通常の ONNX Runtime とは異なり、VOICEVOX Core と一緒に配布
- バージョンは VOICEVOX Core のリリースに紐づく

**命名規則**:
```
voicevox_onnxruntime-{platform}-{arch}-{device}-{version}.zip

例:
voicevox_onnxruntime-windows-x64-cpu-1.17.3.zip
voicevox_onnxruntime-windows-x64-gpu-1.17.3.zip
```

### 3. Open JTalk 辞書

**役割**: 日本語テキストの音素解析

**特徴**:
- バージョン 1.11 が長期間使用されている
- 頻繁に更新されない安定コンポーネント
- SourceForge または VOICEVOX Core リリースから取得可能

**命名規則**:
```
open_jtalk_dic_utf_8-{version}.tar.gz

例:
open_jtalk_dic_utf_8-1.11.tar.gz
```

## バージョン互換性マトリクス

### 確認済みの互換性

| VOICEVOX Core | ONNX Runtime | Open JTalk Dict | リリース日 | 備考 |
|--------------|--------------|-----------------|-----------|------|
| 0.16.3       | 1.17.3       | 1.11            | 2024-12   | 最新（安定） |
| 0.16.2       | 1.17.3       | 1.11            | 2024-11   | 安定 |
| 0.16.1       | 1.17.3       | 1.11            | 2024-10   | 安定 |
| 0.16.0       | 1.17.3       | 1.11            | 2024-09   | 安定 |
| 0.15.x       | 1.16.x       | 1.11            | 2024-06   | 旧バージョン |
| 0.14.x       | 1.15.x       | 1.11            | 2023-12   | 旧バージョン |

### バージョン組み合わせルール

1. **VOICEVOX Core と ONNX Runtime は同じリリースから取得**
   - 例: Core 0.16.3 → ONNX Runtime 1.17.3
   - 異なるバージョンの組み合わせは動作保証なし

2. **Open JTalk 辞書は 1.11 が標準**
   - 当面は 1.11 を使用
   - 将来的に 1.12 がリリースされる可能性あり

3. **GPU 版と CPU 版は排他的**
   - 同時に両方インストールしない
   - GPU 版は CUDA 対応 NVIDIA GPU が必要

## バージョン確認方法

### 1. GitHub Releases から確認（推奨）

最新バージョンと推奨する組み合わせを確認：

```
https://github.com/VOICEVOX/voicevox_core/releases/latest
```

**確認手順**:
1. Releases ページを開く
2. 最新リリースのタイトルでバージョンを確認（例: `0.16.3`）
3. **Assets** セクションで配布ファイルを確認：
   ```
   voicevox_core-windows-x64-cpu-0.16.3.zip
   voicevox_onnxruntime-windows-x64-cpu-1.17.3.zip  ← ONNX Runtime のバージョン
   open_jtalk_dic_utf_8-1.11.zip
   ```

### 2. README のサンプルコードから確認

各リリースの README に記載されているサンプルコマンドを確認：

```powershell
# README に記載されているコマンド例
download-windows-x64.exe --c-api-version 0.16.3 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

### 3. VoicevoxCoreSharp のサンプルから確認

VoicevoxCoreSharp リポジトリのサンプルコードも参考になります：

```
https://github.com/VOICEVOX/VoicevoxCoreSharp/tree/main/example/csharp
```

### 4. インストール済みバージョンの確認

既にインストールしている場合、以下の方法で確認：

```powershell
# ディレクトリ名からバージョンを確認
dir voicevox_core

# 出力例:
# voicevox_core/
# ├── voicevox_core.dll  ← Core のバイナリ
# ├── onnxruntime.dll    ← ONNX Runtime のバイナリ
# ├── open_jtalk_dic_utf_8-1.11/  ← 辞書
# └── model/
```

バイナリファイルのプロパティからバージョン情報を確認することもできます。

## バージョンアップデート手順

### ケース1: VOICEVOX Core を最新にアップデート

**手順**:

1. **最新バージョンを確認**
   ```
   https://github.com/VOICEVOX/voicevox_core/releases/latest
   ```

2. **バックアップを作成**
   ```powershell
   # 既存のインストールをバックアップ
   Rename-Item -Path "voicevox_core" -NewName "voicevox_core_backup_$(Get-Date -Format 'yyyyMMdd')"
   ```

3. **新しいバージョンをダウンロード**
   ```powershell
   # Downloader を取得
   $version = "0.16.3"  # 最新バージョンに変更
   Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/$version/download-windows-x64.exe" -OutFile "download.exe"
   
   # ダウンロード実行
   .\download.exe --c-api-version $version --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
   ```

4. **動作確認**
   ```powershell
   # アプリケーションを起動してテスト
   # 問題なければバックアップを削除
   Remove-Item -Path "voicevox_core_backup_*" -Recurse
   ```

### ケース2: setup.ps1 のデフォルトバージョンを更新

**対象ファイル**: `setup.ps1`

**変更箇所**:
```powershell
param(
    [string]$VoicevoxCoreVersion = "0.16.3",  # ← ここを更新
    [string]$OnnxRuntimeVersion = "voicevox_onnxruntime-1.17.3",  # ← ここも確認
    [string]$CorePath = ".\voicevox_core"
)
```

**更新手順**:
1. GitHub Releases で最新バージョンを確認
2. `setup.ps1` のパラメータを更新
3. テスト環境で動作確認
4. リリースノートに変更を記載

### ケース3: CI/CD パイプラインのバージョンを更新

**対象ファイル**: `.github/workflows/*.yml`

**変更箇所**:
```yaml
- name: Download VOICEVOX Core
  run: |
    Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.3/download-windows-x64.exe" -OutFile "download.exe"
    .\download.exe --c-api-version 0.16.3 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

## トラブルシューティング

### バージョン不一致エラー

**症状**:
```
Error: ONNX Runtime version mismatch
Expected: 1.17.3
Found: 1.16.0
```

**原因**: VOICEVOX Core と ONNX Runtime のバージョンが対応していない

**解決方法**:
1. 両方を同じリリースからダウンロードし直す
2. バージョン互換性マトリクスを確認

### SourceForge DNS エラー

**症状**:
```
Error: error sending request for url (https://jaist.dl.sourceforge.net/project/open-jtalk/...)
dns error: そのようなホストは不明です。 (os error 11001)
```

**原因**: SourceForge のミラーサーバーに接続できない

**解決方法**:

**オプション A: バージョンを最新に変更**
```powershell
# 0.16.0 → 0.16.3 など、最新バージョンを試す
.\download-windows-x64.exe --c-api-version 0.16.3 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

**オプション B: 手動で Open JTalk 辞書をダウンロード**
```powershell
# VOICEVOX Core リリースから直接ダウンロード
Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.3/open_jtalk_dic_utf_8-1.11.zip" -OutFile "dict.zip"
Expand-Archive -Path "dict.zip" -DestinationPath "voicevox_core"
```

**オプション C: プロキシ設定（企業ネットワーク）**
```powershell
$env:HTTP_PROXY = "http://proxy.example.com:8080"
$env:HTTPS_PROXY = "http://proxy.example.com:8080"
.\download-windows-x64.exe --c-api-version 0.16.3 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

### ダウンロードが途中で止まる

**症状**: ダウンロード中にプログレスが進まない

**原因**:
- ネットワークが不安定
- ファイルサイズが大きい（500MB～1GB）
- ファイアウォールやアンチウイルスがブロック

**解決方法**:
1. ネットワーク接続を確認
2. 時間を置いて再試行
3. 手動で ZIP をダウンロードして展開：
   ```powershell
   # Core 本体
   Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.3/voicevox_core-windows-x64-cpu-0.16.3.zip" -OutFile "core.zip"
   
   # ONNX Runtime
   Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.3/voicevox_onnxruntime-windows-x64-cpu-1.17.3.zip" -OutFile "onnx.zip"
   
   # Open JTalk 辞書
   Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/0.16.3/open_jtalk_dic_utf_8-1.11.zip" -OutFile "dict.zip"
   
   # 展開
   Expand-Archive -Path "core.zip" -DestinationPath "voicevox_core"
   Expand-Archive -Path "onnx.zip" -DestinationPath "voicevox_core"
   Expand-Archive -Path "dict.zip" -DestinationPath "voicevox_core"
   ```

### GPU 版が動作しない

**症状**: GPU 版をインストールしたが CPU で動作している

**原因**:
- NVIDIA GPU ドライバーが古い
- CUDA Toolkit がインストールされていない
- GPU に対応していない

**解決方法**:
1. **GPU ドライバーを最新に更新**
   ```
   https://www.nvidia.com/Download/index.aspx
   ```

2. **CUDA Toolkit をインストール（必要に応じて）**
   ```
   https://developer.nvidia.com/cuda-downloads
   ```

3. **CPU 版で代替**（GPU より遅いが動作する）
   ```powershell
   .\download-windows-x64.exe --c-api-version 0.16.3 --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
   # device を指定しない（デフォルトで CPU 版）
   ```

## バージョン管理のベストプラクティス

### 1. バージョンをコード化する

**推奨**: `appsettings.json` や設定ファイルにバージョンを明記

```json
{
  "VoicevoxCore": {
    "Version": "0.16.3",
    "OnnxRuntimeVersion": "1.17.3",
    "OpenJTalkDictVersion": "1.11",
    "CorePath": "./voicevox_core"
  }
}
```

### 2. バージョンチェックを実装

アプリケーション起動時にバージョンを確認：

```csharp
// 例: 起動時チェック
public class VoicevoxVersionValidator
{
    public void ValidateVersions(string corePath)
    {
        // バージョンファイルをチェック
        var versionFile = Path.Combine(corePath, "VERSION");
        if (!File.Exists(versionFile))
        {
            _logger.Warn("VOICEVOX Core のバージョン情報が見つかりません");
            return;
        }
        
        var installedVersion = File.ReadAllText(versionFile).Trim();
        var expectedVersion = "0.16.3";
        
        if (installedVersion != expectedVersion)
        {
            _logger.Warn($"バージョン不一致: 期待={expectedVersion}, 実際={installedVersion}");
        }
    }
}
```

### 3. リリースノートを維持

バージョン変更履歴を記録：

```markdown
## VOICEVOX Core バージョン履歴

| 日付       | App Version | Core Version | ONNX RT | 変更理由 |
|-----------|-------------|--------------|---------|---------|
| 2024-12-10 | 1.1.0      | 0.16.3       | 1.17.3  | 最新版に更新 |
| 2024-09-15 | 1.0.0      | 0.16.0       | 1.17.3  | 初回リリース |
```

### 4. 自動アップデート通知（将来的な改善）

GitHub API を使って最新バージョンをチェック：

```powershell
# 最新バージョンを取得
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/VOICEVOX/voicevox_core/releases/latest"
$latestVersion = $latestRelease.tag_name

Write-Host "最新バージョン: $latestVersion"
Write-Host "現在のバージョン: 0.16.0"

if ($latestVersion -ne "0.16.0") {
    Write-Host "新しいバージョンが利用可能です！" -ForegroundColor Yellow
}
```

## 定期メンテナンス手順

### 月次チェック（推奨）

1. **VOICEVOX Core の最新バージョンを確認**
   - https://github.com/VOICEVOX/voicevox_core/releases

2. **更新が必要か判断**
   - 新機能が必要か
   - バグ修正が含まれているか
   - セキュリティ更新があるか

3. **更新する場合**
   - テスト環境で動作確認
   - バージョン互換性を確認
   - `setup.ps1` を更新
   - CI/CD パイプラインを更新
   - ドキュメントを更新

### リリース前チェック

- [ ] VOICEVOX Core バージョンが最新か確認
- [ ] ONNX Runtime のバージョンが対応しているか確認
- [ ] テスト環境で動作確認済み
- [ ] `setup.ps1` のバージョンが正しいか確認
- [ ] README に推奨バージョンを記載
- [ ] バージョン互換性マトリクスを更新

## 参考リンク

### 公式リソース

- [VOICEVOX Core GitHub](https://github.com/VOICEVOX/voicevox_core)
- [VOICEVOX Core Releases](https://github.com/VOICEVOX/voicevox_core/releases)
- [VoicevoxCoreSharp](https://github.com/VOICEVOX/VoicevoxCoreSharp)
- [VOICEVOX 利用規約](https://voicevox.hiroshiba.jp/term/)

### コミュニティ

- [VOICEVOX Discord](https://discord.gg/WMwWetrzuh)
- [GitHub Discussions](https://github.com/VOICEVOX/voicevox/discussions)

## まとめ

### 重要ポイント

1. **VOICEVOX Core と ONNX Runtime は同じリリースから取得する**
2. **バージョン確認は GitHub Releases ページで行う**
3. **Open JTalk 辞書は 1.11 が標準（当面変更なし）**
4. **定期的に最新バージョンをチェックする**
5. **バージョン不一致エラーは再ダウンロードで解決**

### クイックリファレンス

```powershell
# 最新バージョンを確認
Invoke-RestMethod -Uri "https://api.github.com/repos/VOICEVOX/voicevox_core/releases/latest" | Select-Object tag_name

# 最新版をダウンロード（推奨）
$version = "0.16.3"
Invoke-WebRequest -Uri "https://github.com/VOICEVOX/voicevox_core/releases/download/$version/download-windows-x64.exe" -OutFile "download.exe"
.\download.exe --c-api-version $version --onnxruntime-version voicevox_onnxruntime-1.17.3 -o voicevox_core
```

---

**更新履歴**

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2024-12-XX | 1.0 | 初版作成 |
