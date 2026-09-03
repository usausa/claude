# aidd-dotnet 初期化: アーキ規範 rules (managed) とプロジェクト宣言を .claude/rules/ へ展開する。
# 使い方 (通常は /aidd-dotnet:init skill から実行される):
#   pwsh <plugin>/scripts/init.ps1 [-Sdd lite|full]
#
#  - 展開されるのは .claude/rules/ のみ (既存プロジェクトへの追加を想定)。
#  - managed rules は**常に上書き** (プラグイン update 後の再実行で更新)。
#  - aidd.md (プロジェクト宣言) は -Sdd 未指定なら既存の SDD レベルを維持する (初回既定は full)。
#  - docs 骨格 (adr / work / spec / reference / pm) は各フロー skill が必要時に生成する。
param(
    [ValidateSet('', 'lite', 'full')]
    [string]$Sdd = '',
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$plugin = Split-Path -Parent $PSScriptRoot
$destRules = Join-Path $Destination '.claude/rules'
New-Item -ItemType Directory -Force -Path $destRules | Out-Null

# --- 1. アーキ規範 rules の展開 (プラグインの .claude/rules -> プロジェクト。managed = 常に上書き) ---
$ruleFiles = @(Get-ChildItem -Path (Join-Path $plugin '.claude/rules') -File -Filter '*.md')
$ruleFiles | ForEach-Object { Copy-Item -Force $_.FullName (Join-Path $destRules $_.Name) }
Write-Host "[init] アーキ規範 rules を展開 (managed・上書き更新): $($ruleFiles.Count) 本"

# --- 2. プロジェクト宣言 aidd.md (SDD レベルの確定。未指定時は既存値を維持) ---
$aidd = Join-Path $destRules 'aidd.md'
$level = $Sdd
if (-not $level) {
    if ((Test-Path $aidd) -and ((Get-Content -Raw $aidd) -match 'SDD レベル:\s*(\S+)')) { $level = $Matches[1] }
    else { $level = 'full' }
}
@"
# aidd プロジェクト宣言
<!-- managed by aidd-dotnet plugin: init が生成・更新する (SDD レベルの変更は init -Sdd で行う) -->
- SDD レベル: $level (フロー skill /spec /plan /done 等はこの宣言を読んで分岐する)
- 規範の序列: conventions.md (プロジェクト固有) > smart-* > dotnet-* > 外部 skill / MCP
"@ | Set-Content -Path $aidd
Write-Host "[init] プロジェクト宣言を展開: aidd.md (SDD レベル = $level)"

Write-Host ""
Write-Host "docs 骨格 (adr / work / spec / reference / pm) は各フロー skill が必要時に生成する。"
Write-Host "回し方 (人向け) は spec skill の references/workflow.md を参照。"
