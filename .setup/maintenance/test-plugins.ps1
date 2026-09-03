# プラグイン構造の回帰テスト: 構成・frontmatter・JSON・init の実動スモークを検証する。
# 使い方: pwsh .setup/maintenance/test-plugins.ps1   (ALL PASS が完了条件)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')
$failures = @()

function Assert([bool]$cond, [string]$name) {
    if ($cond) { Write-Host "  PASS: $name" }
    else { Write-Host "  FAIL: $name"; $script:failures += $name }
}

$plugins = Get-ChildItem -Path (Join-Path $root 'plugins') -Directory -ErrorAction SilentlyContinue

foreach ($plugin in $plugins) {
    Write-Host "== plugin: $($plugin.Name) =="

    # --- plugin.json ---
    $pjPath = Join-Path $plugin.FullName '.claude-plugin/plugin.json'
    Assert (Test-Path $pjPath) "plugin.json が存在する"
    $pj = Get-Content -Raw $pjPath | ConvertFrom-Json
    Assert ($pj.name -eq $plugin.Name) "plugin.json の name がディレクトリ名と一致する"
    Assert ([bool]$pj.version -and [bool]$pj.description) "plugin.json に version / description がある"

    # --- 参照 JSON (mcpServers / hooks) ---
    foreach ($field in @('mcpServers', 'hooks')) {
        $val = $pj.$field
        if ($val -is [string]) {
            $refPath = Join-Path $plugin.FullName $val
            Assert (Test-Path $refPath) "$field の参照先 ($val) が存在する"
            $null = Get-Content -Raw $refPath | ConvertFrom-Json
            Assert $true "$field の参照先が JSON として妥当"
        }
    }

    # --- skills ---
    $skillDirs = Get-ChildItem -Path (Join-Path $plugin.FullName 'skills') -Directory -ErrorAction SilentlyContinue
    $badName = @(); $badFm = @(); $emptyPaths = @()
    foreach ($d in $skillDirs) {
        $sk = Join-Path $d.FullName 'SKILL.md'
        if (-not (Test-Path $sk)) { $badFm += $d.Name; continue }
        $text = Get-Content -Raw $sk
        if ($text -notmatch '(?s)^---\r?\n(.*?)\r?\n---') { $badFm += $d.Name; continue }
        $fm = $Matches[1]
        if ($fm -notmatch "(?m)^name:\s*$([regex]::Escape($d.Name))\s*$") { $badName += $d.Name }
        if ($fm -notmatch '(?m)^description:\s*\S') { $badFm += $d.Name }
        if (($fm -match '(?m)^paths:') -and ($fm -notmatch '(?m)^\s+-\s+\S')) { $emptyPaths += $d.Name }
    }
    Assert ($skillDirs.Count -gt 0) "skills が 1 つ以上ある ($($skillDirs.Count) 個)"
    Assert ($badFm.Count -eq 0) "全 skill に SKILL.md と description がある$(if ($badFm) { ' (NG: ' + ($badFm -join ',') + ')' })"
    Assert ($badName.Count -eq 0) "全 skill の name がディレクトリ名と一致する$(if ($badName) { ' (NG: ' + ($badName -join ',') + ')' })"
    Assert ($emptyPaths.Count -eq 0) "paths を持つ skill の paths が空でない$(if ($emptyPaths) { ' (NG: ' + ($emptyPaths -join ',') + ')' })"

    # --- references を持つ skill: 本文からの言及 (列挙節 or リンク) と実ファイルの同期 ---
    $refSkills = @($skillDirs | Where-Object { Test-Path (Join-Path $_.FullName 'references') })
    if ($refSkills.Count -gt 0) {
        $unsynced = @()
        foreach ($d in $refSkills) {
            $text = Get-Content -Raw (Join-Path $d.FullName 'SKILL.md')
            $actual = @(Get-ChildItem -Path (Join-Path $d.FullName 'references') -Filter '*.md' | ForEach-Object { $_.BaseName }) | Sort-Object
            $listed = [Collections.Generic.List[string]]::new()
            $m = [regex]::Match($text, '(?s)## references[^\r\n]*\r?\n\r?\n([^\r\n]+)')
            if ($m.Success) { ($m.Groups[1].Value -split '\s*/\s*') | ForEach-Object { $listed.Add($_.Trim()) } }
            [regex]::Matches($text, 'references/([\w.-]+)\.md') | ForEach-Object { $listed.Add($_.Groups[1].Value) }
            $listed = @($listed | Sort-Object -Unique)
            if (Compare-Object $actual $listed) { $unsynced += $d.Name }
        }
        Assert ($unsynced.Count -eq 0) "references の言及が実ファイルと同期している ($($refSkills.Count) skill)$(if ($unsynced) { ' (NG: ' + ($unsynced -join ',') + ')' })"
    }

    # --- プラグイン内 .claude/rules: managed 規範 rule の形式 ---
    $rulesTplDir = Join-Path $plugin.FullName '.claude/rules'
    if (Test-Path $rulesTplDir) {
        $ruleFiles = @(Get-ChildItem -Path $rulesTplDir -Filter '*.md')
        $badRule = @()
        foreach ($r in $ruleFiles) {
            $text = Get-Content -Raw $r.FullName
            $ok = ($text -match '(?s)^---\r?\npaths:\r?\n([ \t]+-[ \t]+\S[^\r\n]*\r?\n)+---') -and ($text -match 'managed by')
            if (-not $ok) { $badRule += $r.Name }
        }
        Assert ($ruleFiles.Count -gt 0) ".claude/rules に rule がある ($($ruleFiles.Count) 本)"
        Assert ($badRule.Count -eq 0) "全 rule が paths frontmatter + managed ヘッダを持つ$(if ($badRule) { ' (NG: ' + ($badRule -join ',') + ')' })"
    }

    # --- hooks が参照する ps1 の存在 ---
    $hooksJsonPath = Join-Path $plugin.FullName 'hooks/hooks.json'
    if (Test-Path $hooksJsonPath) {
        $hooksText = Get-Content -Raw $hooksJsonPath
        $refs = [regex]::Matches($hooksText, '\$\{CLAUDE_PLUGIN_ROOT\}/([\w./-]+\.ps1)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
        $missing = @($refs | Where-Object { -not (Test-Path (Join-Path $plugin.FullName $_)) })
        Assert ($refs.Count -gt 0 -and $missing.Count -eq 0) "hooks.json が参照する ps1 が存在する ($($refs.Count) 件)"
    }
}

# --- marketplace.json (Phase 4 以降。存在する場合のみ) ---
$mkPath = Join-Path $root '.claude-plugin/marketplace.json'
if (Test-Path $mkPath) {
    Write-Host "== marketplace =="
    $mk = Get-Content -Raw $mkPath | ConvertFrom-Json
    Assert ([bool]$mk.name -and $mk.plugins.Count -gt 0) "marketplace.json に name と plugins がある"
    foreach ($p in $mk.plugins) {
        if ($p.source -is [string] -and $p.source.StartsWith('./')) {
            Assert (Test-Path (Join-Path $root $p.source)) "plugin source ($($p.source)) が存在する"
        }
    }
}

# --- init の実動スモーク (aidd-dotnet) ---
Write-Host "== init smoke =="
$initScript = Join-Path $root 'plugins/aidd-dotnet/scripts/init.ps1'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("aidd-init-test-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    & $initScript -Destination $tmp *> $null

    # dotnet init: rules 展開のみ (既存プロジェクトへの追加型)
    $dotnetRules = @(Get-ChildItem -Path (Join-Path $tmp '.claude/rules') -Filter 'dotnet-*.md')
    Assert ($dotnetRules.Count -eq 20) "dotnet-* rules が 20 本展開される ($($dotnetRules.Count) 本)"
    $aidd = Join-Path $tmp '.claude/rules/aidd.md'
    Assert (-not (Test-Path $aidd)) "dotnet init は aidd.md を生成しない (SDD 宣言は aidd-flow の管轄)"
    $others = @(Get-ChildItem -Path $tmp -Force | Where-Object { $_.Name -ne '.claude' })
    Assert ($others.Count -eq 0) ".claude 以外は何も展開されない (AGENTS / docs / ビルド設定なし)"

    # 再実行: managed 上書き
    $probe = Join-Path $tmp '.claude/rules/dotnet-async.md'
    Set-Content -Path $probe -Value 'stale'
    & $initScript -Destination $tmp *> $null
    Assert ((Get-Content -Raw $probe) -match 'managed by') "managed rule は init 再実行で上書き更新される"

    # flow init: aidd.md 生成 + SDD レベル維持
    $flowInit = Join-Path $root 'plugins/aidd-flow/scripts/init.ps1'
    & $flowInit -Sdd lite -Destination $tmp *> $null
    Assert ((Test-Path $aidd) -and ((Get-Content -Raw $aidd) -match 'SDD レベル: lite')) "flow init が aidd.md を SDD レベル lite で生成する"
    & $flowInit -Destination $tmp *> $null
    Assert ((Get-Content -Raw $aidd) -match 'SDD レベル: lite') "引数なしの再実行で SDD レベルが維持される"

    # smart init: smart rules の展開
    $smartInit = Join-Path $root 'plugins/aidd-smart/scripts/init.ps1'
    & $smartInit -Destination $tmp *> $null
    $smartRules = @(Get-ChildItem -Path (Join-Path $tmp '.claude/rules') -Filter 'smart-*.md')
    Assert ($smartRules.Count -eq 19) "smart-* rules が 19 本展開される ($($smartRules.Count) 本)"
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ""
if ($failures.Count -eq 0) { Write-Host "ALL PASS" }
else { Write-Host "FAILED: $($failures.Count) 件"; exit 1 }
