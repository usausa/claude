# PostToolUse フック: 作成/編集されたソースを UTF-8(BOM 無し)+ CRLF に正規化する。
# .editorconfig(charset=utf-8 / end_of_line=crlf)とは別に、編集の都度これを適用する。
# stdin の tool_input.file_path が対象拡張子なら再保存。非ブロッキング(常に exit 0)。
$ErrorActionPreference = 'SilentlyContinue'
try {
    $path = ([Console]::In.ReadToEnd() | ConvertFrom-Json).tool_input.file_path
}
catch { exit 0 }
if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { exit 0 }

$ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
$targets = @('.cs', '.csproj', '.props', '.targets', '.xaml', '.razor', '.axaml', '.slnx')
if ($targets -notcontains $ext) { exit 0 }

try {
    $text = [System.IO.File]::ReadAllText($path)                          # BOM で判定、無ければ UTF-8
    $crlf = ($text -replace "`r`n", "`n") -replace "`r", "`n" -replace "`n", "`r`n"  # 全 EOL を CRLF に
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)                  # BOM 無し(charset=utf-8 に整合)
    [System.IO.File]::WriteAllText($path, $crlf, $utf8NoBom)
}
catch {}
exit 0
