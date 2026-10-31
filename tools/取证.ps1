param(
    [switch]$NoShot
)
# 一条命令搞定"环境证据"：采集 + 自动截图
#   用法（先把终端最大化：双击「终端」标签）
#       .\tools\取证.ps1
#   不加 -NoShot 时，打印完会自动截图存成 docs\task01-env\01-env-all.png

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$env:PYTHONIOENCODING = "utf-8"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$git = if ($gitCmd) { $gitCmd.Source } elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") { "C:\Program Files\Git\cmd\git.exe" } else { $null }

Clear-Host
Write-Host ("=" * 64) -ForegroundColor DarkCyan
Write-Host " 任务一 · 环境证据" -NoNewline -ForegroundColor White
Write-Host ("   " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "  " + $env:COMPUTERNAME) -ForegroundColor Gray
Write-Host (" 目录 " + $root) -ForegroundColor Gray
Write-Host ("=" * 64) -ForegroundColor DarkCyan

function Row($label, $value) {
    Write-Host ("  " + $label.PadRight(14)) -NoNewline -ForegroundColor Yellow
    Write-Host $value
}

Write-Host ""
Write-Host " [1] Python 版本（系统有两个）" -ForegroundColor Cyan
$py0 = (& py -0 2>&1 | Out-String).Trim()
Row "py -0" ($py0 -replace "`r?`n", "  /  ")
Row "where python" ((& where.exe python 2>&1 | Select-Object -First 1))
Row ".venv" (& ".\.venv\Scripts\python.exe" --version 2>&1)

Write-Host ""
Write-Host " [2] Git" -ForegroundColor Cyan
Row "git --version" (& $git --version 2>&1)
Row "user.name" (& $git config user.name)
Row "user.email" (& $git config user.email)
Row "init.branch" (& $git config init.defaultBranch)

Write-Host ""
Write-Host " [3] 提交历史" -ForegroundColor Cyan
(& $git log --oneline 2>&1) | ForEach-Object { Write-Host ("  " + $_) }

Write-Host ""
Write-Host " [4] 工作区 / 忽略规则" -ForegroundColor Cyan
$st = (& $git status --porcelain 2>&1 | Out-String).Trim()
Row "git status" $(if ($st) { $st -replace "`r?`n", " | " } else { "干净（无未提交改动）" })
Row "ignore .venv" (& $git check-ignore -v .venv 2>&1)

Write-Host ""
Write-Host " [5] 程序运行请手动做： .venv\Scripts\python.exe hello.py  然后输入名字" -ForegroundColor Cyan
Write-Host ("=" * 64) -ForegroundColor DarkCyan

if (-not $NoShot) {
    Write-Host ""
    Write-Host " 上面就是证据，2 秒后自动截图…" -ForegroundColor Green
    & (Join-Path $PSScriptRoot "拍.ps1") -Name "01-env-all" -Delay 2 -Quiet
}
