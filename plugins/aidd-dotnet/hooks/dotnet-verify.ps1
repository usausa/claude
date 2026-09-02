# PostToolUse フック(Edit|Write 後)
# 変更が C# 系ファイルなら、変更ファイルの属するプロジェクトを dotnet format で軽量検証し、
# .editorconfig との差分があれば Claude にフィードバックする(編集→検査→修正の逆フィードバック)。
# 非ブロッキング(常に exit 0)。重い「警告ゼロ」検査はフルビルドで /done・CI に寄せる。
#
# stdin: JSON(tool_input.file_path 等)。UTF-8(BOMなし)前提。

$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try { $payload = $raw | ConvertFrom-Json } catch { exit 0 }

$path = $payload.tool_input.file_path
if (-not $path) { exit 0 }
if ($path -notmatch '\.(cs|csproj|xaml)$') { exit 0 }   # C# 系以外はスキップ

# 変更ファイルに最も近い .csproj を親方向に探索
$dir = Split-Path -Parent $path
$proj = $null
while ($dir -and (Test-Path $dir)) {
    $proj = Get-ChildItem -Path $dir -Filter *.csproj -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proj) { break }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $proj) { exit 0 }

# 書式のみ軽量検証(フルビルドより速い)。差分があれば要修正として返す。
$out = & dotnet format $proj.FullName --verify-no-changes --no-restore 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Output "[dotnet-verify] $($proj.Name): .editorconfig と差分あり。修正してください。"
    Write-Output ($out | Out-String)
}
# 「警告ゼロ」を毎回強制したい場合は上を `dotnet build $proj.FullName --no-restore` に置換
exit 0
