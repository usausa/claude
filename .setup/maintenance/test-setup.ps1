# setup.ps1 の回帰テスト(テンプレ保守用・原本専用)
# 使い方: pwsh .setup/maintenance/test-setup.ps1
# リポジトリを一時ディレクトリへコピーし、form × SDD レベル(lite|full|full-pm)の各シナリオで
# マーカー解決・ファイル配置/削除・保守痕跡ゼロ・旧名称残存ゼロを検証する。ALL PASS が保守の完了条件。

$ErrorActionPreference = 'Stop'
$src = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$pad = Join-Path ([System.IO.Path]::GetTempPath()) 'template-aidd-tests'
New-Item -ItemType Directory -Force -Path $pad | Out-Null
$fails = @()

function Check($cond, $msg) {
    if ($cond) { Write-Host "  PASS: $msg" } else { Write-Host "  FAIL: $msg" -ForegroundColor Red; $script:fails += $msg }
}
function Fresh($name) {
    $dst = Join-Path $pad $name
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse $src $dst
    Remove-Item -Recurse -Force (Join-Path $dst '.git') -ErrorAction SilentlyContinue
    return $dst
}
function LeftoverCount($dir) {
    # setup 後に残ってはいけない痕跡: 未解決マーカー(sdd ブロック・pm)+ 保守ブロック
    (Get-ChildItem $dir -Recurse -File -Include *.md -Force | Select-String -Pattern '<!-- (sdd|pm|template-dev)' | Measure-Object).Count
}
function OldNameCount($dir) {
    # 旧名称の残存(リファクタで全廃したもの)
    (Get-ChildItem $dir -Recurse -File -Include *.md, *.ps1 -Force |
        Select-String -Pattern 'distill-req|write-adr|spec-sync|cross-review|/requirements|docs/requirements|REQ-|docs/architecture|blazor-playwright' |
        Measure-Object).Count
}
function RulesCheck($dir, $label) {
    # 配置された rules の品質: paths フロントマター + 相対 md リンクの整合
    $rules = Get-ChildItem (Join-Path $dir '.claude/rules') -Filter *.md -ErrorAction SilentlyContinue
    Check ($rules.Count -gt 0) "$label rules 配置あり"
    foreach ($r in $rules) {
        $raw = Get-Content -Raw $r.FullName
        Check ($raw -match '(?s)^---\r?\npaths:') "$label $($r.Name) に paths フロントマター"
        foreach ($m in [regex]::Matches($raw, '\]\((?!https?://)([^)#]+\.md)\)')) {
            $target = Join-Path (Split-Path $r.FullName) $m.Groups[1].Value
            Check (Test-Path $target) "$label $($r.Name) リンク: $($m.Groups[1].Value)"
        }
    }
}

# --- T0: rules カタログの静的検証(原本)---
Write-Host "== T0: .setup/rules カタログ =="
$copyUnion = @('conventions.md', 'coding-principles.md', 'async.md', 'errors.md', 'logging.md', 'security.md', 'data.md', 'http-client.md',
    'mvvm.md', 'maui.md', 'web.md', 'api.md', 'blazor.md', 'blazor-e2e.md', 'desktop.md', 'wpf.md', 'winui.md', 'worker.md')
$catalog = Get-ChildItem (Join-Path $src '.setup/rules') -Filter *.md
Check ($catalog.Count -gt 0) 'T0 カタログあり'
foreach ($f in $catalog) {
    Check ($copyUnion -contains $f.Name) "T0 $($f.Name) がコピー表に載っている"
}

# --- T1: web + full-pm(全部載せ)---
Write-Host "== T1: -Form web -Sdd full-pm =="
$t = Fresh 't1-web-full-pm'
& (Join-Path $t 'setup.ps1') -Form web -Sdd full-pm | Out-Null
Check ((LeftoverCount $t) -eq 0) 'T1 マーカー/保守ブロック残存 0'
Check ((OldNameCount $t) -eq 0) 'T1 旧名称残存 0'
Check (-not (Test-Path "$t\docs\architecture")) 'T1 docs/architecture なし'
Check (Test-Path "$t\.claude\rules\web.md") 'T1 rules: web.md'
Check (Test-Path "$t\.claude\rules\blazor-e2e.md") 'T1 rules: blazor-e2e.md'
Check (Test-Path "$t\.claude\rules\conventions.md") 'T1 rules: 共通 (conventions.md)'
Check (-not (Test-Path "$t\.claude\rules\mvvm.md")) 'T1 rules: mvvm.md なし'
RulesCheck $t 'T1'
Check ((Get-Content -Raw "$t\.claude\commands\spec.md").Contains('docs/spec/')) 'T1 spec command=恒久版'
Check ((Get-Content -Raw "$t\.claude\skills\spec-close\SKILL.md").Contains('蒸留して残す')) 'T1 spec-close=残す版'
Check (Test-Path "$t\.claude\commands\plan.md") 'T1 plan command'
Check (Test-Path "$t\.claude\commands\impl.md") 'T1 impl command'
Check (Test-Path "$t\.claude\commands\reference.md") 'T1 reference command'
Check (Test-Path "$t\.claude\commands\review-cross.md") 'T1 review-cross command'
Check (Test-Path "$t\.claude\commands\trace.md") 'T1 trace command (full)'
Check (Test-Path "$t\.claude\skills\adr-guide\SKILL.md") 'T1 adr-guide skill'
Check (Test-Path "$t\docs\spec\_template.md") 'T1 docs/spec 追加'
Check (Test-Path "$t\docs\traceability\index.md") 'T1 traceability 追加'
Check ((Get-Content -Raw "$t\docs\work\README.md").Contains('PLAN')) 'T1 docs/work 残存 (full 版)'
Check (-not ((Get-Content -Raw "$t\docs\work\README.md").Contains('SPEC-'))) 'T1 docs/work/README に SPEC- なし (full 版)'
Check (-not (Test-Path "$t\work")) 'T1 旧 work/ なし'
Check (Test-Path "$t\.claude\skills\work-init\SKILL.md") 'T1 work-init skill'
Check ((Get-Content -Raw "$t\.claude\skills\work-close\SKILL.md").Contains('spec-close')) 'T1 work-close=full 版 (spec-close 参照)'
Check ((Get-Content -Raw "$t\docs\guides\workflow.md").Contains('/trace')) 'T1 workflow=full 版'
Check ((Get-Content -Raw "$t\.claude\commands\done.md").Contains('/trace')) 'T1 done=full 版'
Check ((Get-Content -Raw "$t\AGENTS.md").Contains('SPEC は蒸留して残す')) 'T1 AGENTS=full 規律'
Check (Test-Path "$t\docs\pm\README.md") 'T1 PM 採用'
Check ((Get-Content -Raw "$t\docs\guides\workflow.md").Contains('イテレーション運用')) 'T1 workflow に PM 挿入'
Check (-not (Test-Path "$t\.setup")) 'T1 .setup 削除 (maintenance 含む)'
Check (-not ((Get-Content -Raw "$t\README.md").Contains('MAINTENANCE'))) 'T1 README に保守節なし'
Check (-not ((Get-Content -Raw "$t\.gitignore").Contains('work/*'))) 'T1 gitignore に work/* なし (git 管理)'

# --- T2: web + lite(基層のまま)---
Write-Host "== T2: -Form web -Sdd lite =="
$t = Fresh 't2-web-lite'
& (Join-Path $t 'setup.ps1') -Form web -Sdd lite | Out-Null
Check ((LeftoverCount $t) -eq 0) 'T2 マーカー/保守ブロック残存 0'
Check ((OldNameCount $t) -eq 0) 'T2 旧名称残存 0'
Check ((Get-Content -Raw "$t\.claude\commands\spec.md").Contains('docs/work')) 'T2 spec command=一時版 (docs/work)'
Check (-not (Test-Path "$t\.claude\skills\spec-close")) 'T2 spec-close なし (lite)'
Check ((Get-Content -Raw "$t\.claude\skills\work-close\SKILL.md").Contains('蒸留漏れ')) 'T2 work-close=lite 版'
Check (Test-Path "$t\.claude\commands\plan.md") 'T2 plan command'
Check (Test-Path "$t\.claude\commands\impl.md") 'T2 impl command'
Check ((Get-Content -Raw "$t\docs\work\README.md").Contains('SPEC-')) 'T2 docs/work/README=lite 版'
Check (-not (Test-Path "$t\docs\spec")) 'T2 docs/spec 無し'
Check (-not (Test-Path "$t\docs\traceability")) 'T2 traceability 無し'
Check (-not (Test-Path "$t\.claude\commands\trace.md")) 'T2 trace command 無し'
Check ((Get-Content -Raw "$t\AGENTS.md").Contains('蒸留漏れ')) 'T2 AGENTS=lite 規律'
Check ((Get-Content -Raw "$t\.claude\commands\done.md").Contains('蒸留漏れ確認')) 'T2 done=lite 版'
Check ((Get-Content -Raw "$t\docs\guides\workflow.md").Contains('SDD lite')) 'T2 workflow=lite 版'
Check (-not (Test-Path "$t\docs\pm")) 'T2 PM 無し'
Check (-not ((Get-Content -Raw "$t\.gitignore").Contains('work/*'))) 'T2 gitignore に work/* なし (git 管理)'

# --- T3: maui + full(既定 = -Sdd 省略)---
Write-Host "== T3: -Form maui (既定 full) =="
$t = Fresh 't3-maui-default'
& (Join-Path $t 'setup.ps1') -Form maui | Out-Null
Check ((LeftoverCount $t) -eq 0) 'T3 マーカー/保守ブロック残存 0'
Check ((OldNameCount $t) -eq 0) 'T3 旧名称残存 0'
Check (Test-Path "$t\.claude\rules\mvvm.md") 'T3 rules: mvvm.md'
Check (Test-Path "$t\.claude\rules\maui.md") 'T3 rules: maui.md'
Check (-not (Test-Path "$t\.claude\rules\web.md")) 'T3 rules: web.md なし'
Check (-not (Test-Path "$t\.claude\rules\blazor-e2e.md")) 'T3 rules: blazor-e2e.md なし'
RulesCheck $t 'T3'
Check (Test-Path "$t\docs\spec\_template.md") 'T3 既定=full (docs/spec あり)'
Check (-not (Test-Path "$t\docs\pm")) 'T3 既定=full (PM なし)'

# --- T4: desktop + lite ---
Write-Host "== T4: -Form desktop -Sdd lite =="
$t = Fresh 't4-desktop-lite'
& (Join-Path $t 'setup.ps1') -Form desktop -Sdd lite | Out-Null
Check ((LeftoverCount $t) -eq 0) 'T4 マーカー/保守ブロック残存 0'
Check ((OldNameCount $t) -eq 0) 'T4 旧名称残存 0'
Check (Test-Path "$t\.claude\rules\mvvm.md") 'T4 rules: mvvm.md'
Check (Test-Path "$t\.claude\rules\wpf.md") 'T4 rules: wpf.md'
Check (Test-Path "$t\.claude\rules\desktop.md") 'T4 rules: desktop.md'
Check (-not (Test-Path "$t\.claude\rules\maui.md")) 'T4 rules: maui.md なし'
Check (-not (Test-Path "$t\docs\spec")) 'T4 docs/spec 無し (lite)'
RulesCheck $t 'T4'

# --- T5: worker + full ---
Write-Host "== T5: -Form worker -Sdd full =="
$t = Fresh 't5-worker-full'
& (Join-Path $t 'setup.ps1') -Form worker -Sdd full | Out-Null
Check ((LeftoverCount $t) -eq 0) 'T5 マーカー/保守ブロック残存 0'
Check ((OldNameCount $t) -eq 0) 'T5 旧名称残存 0'
Check (Test-Path "$t\.claude\rules\worker.md") 'T5 rules: worker.md'
Check (-not (Test-Path "$t\.claude\rules\mvvm.md")) 'T5 rules: mvvm.md なし'
RulesCheck $t 'T5'
Check (Test-Path "$t\docs\spec\_template.md") 'T5 docs/spec 追加 (full)'
Check (-not (Test-Path "$t\docs\pm")) 'T5 PM 無し (full)'

# --- T6: 旧 -PM スイッチは存在しない ---
Write-Host "== T6: -PM => パラメータエラー =="
$t = Fresh 't6-no-pm-switch'
$threw = $false
try { & (Join-Path $t 'setup.ps1') -Form web -PM 2>$null | Out-Null } catch { $threw = $true }
Check $threw 'T6 -PM は受け付けない'

# --- T7: -Sdd の無効値は構文的に弾かれる ---
Write-Host "== T7: -Sdd lite-pm => ValidateSet エラー =="
$t = Fresh 't7-invalid-sdd'
$threw = $false
try { & (Join-Path $t 'setup.ps1') -Form web -Sdd lite-pm 2>$null | Out-Null } catch { $threw = $true }
Check $threw 'T7 無効な -Sdd 値は弾かれる'

Write-Host ""
if ($fails.Count -eq 0) {
    Write-Host "ALL PASS"
    Remove-Item -Recurse -Force $pad -ErrorAction SilentlyContinue   # 成功時は一時ディレクトリを掃除
} else {
    Write-Host "FAILURES: $($fails.Count)" -ForegroundColor Red
    $fails | ForEach-Object { Write-Host " - $_" }
    Write-Host "検証コピーは $pad に残置 (調査用)"
    exit 1
}
