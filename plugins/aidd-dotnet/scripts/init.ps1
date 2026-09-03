# aidd-dotnet 初期化: アーキ規範 rules (managed) を .claude/rules/ へ上書き展開する。
# 使い方 (通常は /aidd-dotnet:init skill から実行される):
#   pwsh <plugin>/scripts/init.ps1
#
#  - 展開されるのは .claude/rules/ の dotnet-*.md のみ (既存プロジェクトへの追加を想定)。
#  - managed rules は**常に上書き** (プラグイン update 後の再実行で更新)。
param(
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$plugin = Split-Path -Parent $PSScriptRoot
$destRules = Join-Path $Destination '.claude/rules'
New-Item -ItemType Directory -Force -Path $destRules | Out-Null
$ruleFiles = @(Get-ChildItem -Path (Join-Path $plugin '.claude/rules') -File -Filter '*.md')
$ruleFiles | ForEach-Object { Copy-Item -Force $_.FullName (Join-Path $destRules $_.Name) }
Write-Host "[aidd-dotnet init] アーキ規範 rules を展開 (managed・上書き更新): $($ruleFiles.Count) 本"
Write-Host "基本ワークフロー (spec / plan / 実装) を使う場合は aidd-flow を導入し /aidd-flow:init を実行する。"
