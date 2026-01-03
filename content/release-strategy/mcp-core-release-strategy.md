---
title: リリース戦略 (mcp-core)
category: プロジェクトナレッジ
description: Ateliers.Ai.Mcp.Core の NuGet パッケージリリース戦略、バージョニング、ワークフローについて解説します。
tags: [MCP, NuGet, リリース, バージョニング, セマンティックバージョニング]
---
# リリース戦略

このドキュメントでは、Ateliers.Ai.Mcp.Core の NuGet パッケージリリース戦略について説明します。

## バージョン管理の方針

### セマンティックバージョニング

```
MAJOR.MINOR.PATCH[-PRERELEASE]
例: 0.3.0-beta.1
```

- **MAJOR**: 破壊的変更（後方互換性なし）
- **MINOR**: 新機能追加（後方互換性あり）
- **PATCH**: バグ修正（後方互換性あり）
- **PRERELEASE**: プレリリース版のサフィックス

### プレリリース版のサフィックス

| サフィックス | 用途 | 例 |
|------------|------|-----|
| `-alpha.N` | 非常に初期段階、API が不安定 | `0.3.0-alpha.1` |
| `-beta.N` | 機能はほぼ完成、テスト中 | `0.3.0-beta.1` |
| `-rc.N` | リリース候補（Release Candidate） | `0.3.0-rc.1` |
| `-preview.N` | プレビュー版 | `0.3.0-preview.1` |

## リリースワークフロー

### 1. 開発フェーズ（Alpha版）

```xml
<!-- src/Ateliers.Ai.Mcp.Core/Ateliers.Ai.Mcp.Core.csproj -->
<Version>0.3.0-alpha.1</Version>
<AssemblyVersion>0.3.0.0</AssemblyVersion>
<FileVersion>0.3.0.0</FileVersion>
<InformationalVersion>0.3.0-alpha.1</InformationalVersion>
```

```sh
# リリース
git add .
git commit -m "Release 0.3.0-alpha.1"
git push origin master

git tag v0.3.0-alpha.1
git push origin v0.3.0-alpha.1
```

**NuGet での扱い:**
- プレリリース版として表示
- `--prerelease` フラグが必要

### 2. テストフェーズ（Beta版）

```xml
<Version>0.3.0-beta.1</Version>
<InformationalVersion>0.3.0-beta.1</InformationalVersion>
```

```sh
git tag v0.3.0-beta.1
git push origin v0.3.0-beta.1
```

**NuGet での扱い:**
- プレリリース版として表示
- 機能は完成、バグ修正のみ

### 3. リリース候補（RC版）

```xml
<Version>0.3.0-rc.1</Version>
<InformationalVersion>0.3.0-rc.1</InformationalVersion>
```

```sh
git tag v0.3.0-rc.1
git push origin v0.3.0-rc.1
```

**NuGet での扱い:**
- プレリリース版として表示
- 最終テスト段階

### 4. 正式リリース

```xml
<Version>0.3.0</Version>
<AssemblyVersion>0.3.0.0</AssemblyVersion>
<FileVersion>0.3.0.0</FileVersion>
<InformationalVersion>0.3.0</InformationalVersion>
```

```sh
git tag v0.3.0
git push origin v0.3.0
```

**NuGet での扱い:**
- 安定版として表示
- デフォルトでインストール可能

## リリースチェックリスト

### プレリリース版

- [ ] csproj のバージョンを更新（例: `0.3.0-beta.1`）
- [ ] 変更履歴を README に記載
- [ ] ローカルでビルド成功を確認
- [ ] ローカルでテスト成功を確認（`dotnet test`）
- [ ] コミット＆プッシュ
- [ ] タグ作成（例: `v0.3.0-beta.1`）
- [ ] タグプッシュ
- [ ] GitHub Actions で成功を確認
- [ ] NuGet.org でプレリリース版として公開されたことを確認

### 正式リリース

- [ ] csproj のバージョンを更新（例: `0.3.0`）
- [ ] CHANGELOG.md を更新
- [ ] README.md のバージョン情報を更新
- [ ] ローカルでビルド成功を確認
- [ ] ローカルでテスト成功を確認（`dotnet test`）
- [ ] コミット＆プッシュ
- [ ] タグ作成（例: `v0.3.0`）
- [ ] タグプッシュ
- [ ] GitHub Actions で成功を確認
- [ ] NuGet.org で正式版として公開されたことを確認
- [ ] GitHub Release が作成されたことを確認
- [ ] 依存プロジェクトでの動作確認

## NuGet パッケージの状態管理

### Listed（表示）
- 検索結果に表示される
- `dotnet add package` でインストール可能
- 安定版として推奨される

### Unlisted（非表示）
- 検索結果に表示されない
- バージョンを直接指定すればインストール可能
- 開発中やテスト用に使用

### Deprecated（非推奨）
- 警告メッセージが表示される
- 代替バージョンを案内できる
- 誤ってリリースしたバージョンに使用

## GitHub Actions の自動判定

`.github/workflows/ci-cd.yml` では、タグ名に `-` が含まれているかで自動的にプレリリースを判定します：

```yaml
- name: Create GitHub Release
  uses: softprops/action-gh-release@v1
  with:
    files: ./packages/*.*nupkg
    generate_release_notes: true
    draft: false
    prerelease: ${{ contains(github.ref_name, '-') }}
```

- `v0.3.0-beta.1` → Prerelease ?
- `v0.3.0` → Release ?

## トラブルシューティング

### 誤ったバージョンをリリースしてしまった

1. **NuGet.org で Unlist（非表示化）**
   - https://www.nuget.org/packages/Ateliers.Ai.Mcp.Core/manage
   - 該当バージョンを選択して "Unlist"

2. **Deprecated として警告を追加**
   - "Mark as deprecated" で警告メッセージを設定
   - 例: "誤ってリリースされました。バージョン 0.3.0 を使用してください。"

3. **タグを削除**
   ```sh
   # ローカル
   git tag -d v誤ったバージョン
   
   # リモート
   git push origin :refs/tags/v誤ったバージョン
   ```

4. **正しいバージョンをリリース**
   - マイナーバージョンを上げる（例: `0.2.1` → `0.2.2`）
   - 同じバージョン番号は再利用できない

### プレリリース版が安定版として表示される

- すべてのバージョンが Unlisted になっていないか確認
- 最新の安定版を Listed にする

### GitHub Actions が失敗する

- タグとバージョンが一致しているか確認
- csproj のバージョン形式が正しいか確認
- NuGet API キーが有効か確認

## 参考リンク

- [NuGet Package Versioning](https://docs.microsoft.com/en-us/nuget/concepts/package-versioning)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github)
