# aidd-dotnet 初期化: テンプレ骨格を展開し、SDD レベルを確定する。
# 使い方 (通常は /aidd-dotnet:init skill から実行される):
#   pwsh <plugin>/scripts/init.ps1                 # SDD full (既定)
#   pwsh <plugin>/scripts/init.ps1 -Sdd lite       # lite (SPEC は docs/work/ の一時物)
#   pwsh <plugin>/scripts/init.ps1 -Sdd full-pm    # full + PM
#
#  - アーキ規範はプラグインの skill が paths で自動適用されるため、規範ファイルの配置は行わない。
#  - 既存ファイルは上書きしない (スキップして報告する)。
param(
    [ValidateSet('lite', 'full', 'full-pm')]
    [string]$Sdd = 'full',
    [string]$Destination = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$plugin = Split-Path -Parent $PSScriptRoot
$templates = Join-Path $plugin 'templates'
$isFull = $Sdd -ne 'lite'
$isPm = $Sdd -eq 'full-pm'

# --- 1. 骨格の展開 (templates/root -> Destination。既存はスキップ) ---
$rootDir = Join-Path $templates 'root'
$skipped = @()
Get-ChildItem -Path $rootDir -Recurse -File -Force | ForEach-Object {
    $rel = $_.FullName.Substring($rootDir.Length + 1)
    $dest = Join-Path $Destination $rel
    if (Test-Path $dest) { $script:skipped += $rel; return }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
    Copy-Item $_.FullName $dest
}
Write-Host "[init] 骨格を展開: $Destination"
if ($skipped.Count -gt 0) { Write-Host "[init] 既存のためスキップ: $($skipped -join ' / ')" }

# --- 2. SDD: base (lite) に full 層を加算、または lite のまま確定 ---
$sddDir = Join-Path $templates 'sdd'
$sddFiles = @('AGENTS.md', 'README.md', 'docs/README.md', 'docs/review-checklist.md')

if ($isFull) {
    foreach ($f in $sddFiles) {
        $file = Join-Path $Destination $f
        if (-not (Test-Path $file)) { continue }
        $text = Get-Content -Raw $file
        $blockMatches = [regex]::Matches($text, '<!-- sdd:([a-z-]+):start -->')
        foreach ($m in $blockMatches) {
            $name = $m.Groups[1].Value
            $snippet = (Get-Content -Raw (Join-Path $sddDir "$name-full.md")).TrimEnd("`r", "`n")
            $pattern = "(?s)<!-- sdd:$name`:start -->.*?<!-- sdd:$name`:end -->"
            $text = [regex]::Replace($text, $pattern, $snippet.Replace('$', '$$'))
        }
        Set-Content -NoNewline -Path $file -Value $text
    }

    # full 層のファイルを加算 (spec / work-close / done / workflow / docs/work は上書き、spec-close / trace / docs/spec / traceability は追加)
    $fullDir = Join-Path $sddDir 'full'
    Get-ChildItem -Path $fullDir -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($fullDir.Length + 1)
        $dest = Join-Path $Destination $rel
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -Force $_.FullName $dest
    }
    Write-Host "[sdd=$Sdd] full 層を加算: SPEC 恒久化 (docs/spec)・spec-close・/trace・traceability (プロジェクト側 .claude に配置)。"
}
else {
    foreach ($f in $sddFiles) {
        $file = Join-Path $Destination $f
        if (-not (Test-Path $file)) { continue }
        $text = Get-Content -Raw $file
        $new = $text -replace '(?m)^[ \t]*<!-- sdd:[a-z-]+:(start|end) -->\r?\n?', ''
        if ($new -ne $text) { Set-Content -NoNewline -Path $file -Value $new }
    }
    Write-Host "[sdd=lite] 基層のまま確定: SPEC は docs/work/ の一時物 (完了時に work-close で片付け)。"
}

# --- 3. PM 層 (full-pm のみ): マーカーへ差分を挿入 / 除去、docs/pm を加算 ---
$markers = @{
    'pm:readme-lifespan'    = 'docs/README.md'
    'pm:guide-claude'       = 'README.md'
    'pm:workflow-iteration' = 'docs/guides/workflow.md'
    'pm:agents'             = 'AGENTS.md'
}
$pmDir = Join-Path $templates 'pm'

foreach ($m in $markers.Keys) {
    $file = Join-Path $Destination $markers[$m]
    if (-not (Test-Path $file)) { continue }
    $token = "<!-- $m -->"
    $text = Get-Content -Raw $file
    if ($isPm) {
        $snippet = (Get-Content -Raw (Join-Path $pmDir (($m -replace '^pm:', '') + '.md'))).TrimEnd("`r", "`n")
        $text = $text.Replace($token, $snippet)
    }
    else {
        $text = $text -replace "(\r?\n)?[ \t]*$([regex]::Escape($token))", ''
    }
    Set-Content -NoNewline -Path $file -Value $text
}

if ($isPm) {
    $pmDocsDir = Join-Path $pmDir 'docs-pm'
    Get-ChildItem -Path $pmDocsDir -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($pmDocsDir.Length + 1)
        $dest = Join-Path $Destination "docs/pm/$rel"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -Force $_.FullName $dest
    }
    Write-Host "[pm=on] docs/pm を配置。計画・進捗は /aidd-dotnet:pm-plan・/aidd-dotnet:pm-status。"
}

Write-Host ""
Write-Host "次の手順:"
Write-Host " 1. AGENTS.md の『スタック』節を採用形態に記入。"
Write-Host " 2. LINT/ビルド設定は superset (Settings.XamlStyler は XAML 系用)。実プロジェクトのテンプレで置換してよい。"
Write-Host " 3. 始め方・使い方は README.md (入口。導入後は自プロジェクトの README に置換/削除可)。回し方の正は docs/guides/workflow.md、契約は docs/README.md。"
