# aidd-flow 初期化: プロジェクト宣言 aidd.md (SDD レベル) を .claude/rules/ へ生成する。
# 使い方 (通常は /aidd-flow:init skill から実行される):
#   pwsh <plugin>/scripts/init.ps1 [-Sdd lite|full]
#
#  - aidd.md は managed (init が生成・更新)。-Sdd 未指定なら既存の SDD レベルを維持する (初回既定は full)。
#  - docs 骨格 (adr / work / spec / reference) は各フロー skill が必要時に生成する。
param(
    [ValidateSet('', 'lite', 'full')]
    [string]$Sdd = '',
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$destRules = Join-Path $Destination '.claude/rules'
New-Item -ItemType Directory -Force -Path $destRules | Out-Null

$aidd = Join-Path $destRules 'aidd.md'
$level = $Sdd
if (-not $level) {
    if ((Test-Path $aidd) -and ((Get-Content -Raw $aidd) -match 'SDD レベル:\s*(\S+)')) { $level = $Matches[1] }
    else { $level = 'full' }
}
@"
<!-- managed by aidd-flow plugin: init が生成・更新する (SDD レベルの変更は init -Sdd で行う) -->
- SDD レベル: $level (フロー skill /spec /plan /done 等はこの宣言を読んで分岐する)
"@ | Set-Content -Path $aidd
Write-Host "[aidd-flow init] プロジェクト宣言を生成: aidd.md (SDD レベル = $level)"
Write-Host "docs 骨格 (adr / work / spec / reference) は各フロー skill が必要時に生成する。回し方は spec skill の references/workflow.md。"
