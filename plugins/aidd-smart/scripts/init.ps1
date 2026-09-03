# aidd-smart 初期化: Smart スタック規範 rules (managed) を .claude/rules/ へ上書き展開する。
# 使い方 (通常は /aidd-smart:init skill から実行される):
#   pwsh <plugin>/scripts/init.ps1
#
#  - managed rules は**常に上書き** (プラグイン update 後の再実行で更新)。
#  - プロジェクト固有の上書きは .claude/rules/conventions.md が正。
param(
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$plugin = Split-Path -Parent $PSScriptRoot
$rulesDir = Join-Path $plugin '.claude/rules'
$destRules = Join-Path $Destination '.claude/rules'
New-Item -ItemType Directory -Force -Path $destRules | Out-Null
$ruleFiles = @(Get-ChildItem -Path $rulesDir -File -Filter '*.md')
$ruleFiles | ForEach-Object { Copy-Item -Force $_.FullName (Join-Path $destRules $_.Name) }
Write-Host "[aidd-smart init] Smart スタック規範 rules を展開 (managed・上書き更新): $($ruleFiles.Count) 本"
Write-Host "第 1 段の rules が未展開の場合は /aidd-dotnet:init を先に実行する。"
