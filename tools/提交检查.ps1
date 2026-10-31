param(
    [int]$Task = 1,
    [switch]$Open
)
# 交作业前自检：跑一遍看还差什么
#   .\tools\提交检查.ps1            # 检查任务一
#   .\tools\提交检查.ps1 -Task 2     # 检查任务二
#   .\tools\提交检查.ps1 -Open       # 全部通过后自动打开提交页面

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$dirs = @{ 1 = "task01-env"; 2 = "task02-api"; 3 = "task03-llm"; 4 = "task04-agent" }
$titles = @{
    1 = "任务一：Python 与开发环境"
    2 = "任务二：后端与数据基础"
    3 = "任务三：LLM API 与提示词工程"
    4 = "任务四：工具调用与检索"
}
$names = @{
    1 = "异步脚本项目（能并发请求多个接口并汇总）"
    2 = "FastAPI + Docker 服务（含一次流式响应）"
    3 = "结构化输出问答服务 + 提示词实验记录"
    4 = "工具调用助手 + RAG 项目"
}
if (-not $dirs.ContainsKey($Task)) { throw "Task 只支持 1-4" }

$sub = Join-Path "docs" $dirs[$Task]
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    $git = $gitCmd.Source
} elseif (Test-Path "C:\Program Files\Git\cmd\git.exe") {
    $git = "C:\Program Files\Git\cmd\git.exe"
} else {
    $git = $null
}
$check = @()

# 1. 截图数量
$pngs = @(Get-ChildItem $sub -Filter *.png -ErrorAction SilentlyContinue)
$check += [pscustomobject]@{
    Item = "学习记录截图（$sub）"
    Need = "≥ 4 张，能看出操作过程与结果"
    Have = "$($pngs.Count) 张"
    Ok   = ($pngs.Count -ge 4)
}

# 2. 笔记
$note = Join-Path $sub "笔记.md"
$check += [pscustomobject]@{
    Item = "过程笔记"
    Need = "$note"
    Have = if (Test-Path $note) { "存在" } else { "缺失" }
    Ok   = (Test-Path $note)
}

# 3. 项目代码（用文件数量粗判）
$codeFiles = @(Get-ChildItem -Recurse -Include *.py,*.js,*.ts,*.go,*.java -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notlike "*\.venv\*" })
$check += [pscustomobject]@{
    Item = "项目代码"
    Need = "有可运行的源码文件"
    Have = "$($codeFiles.Count) 个源码文件"
    Ok   = ($codeFiles.Count -ge 1)
}

# 4. README（进阶项：他人 10 分钟复现）
$readme = @("README.md", "readme.md", "README.MD") | ForEach-Object { Join-Path $root $_ } |
    Where-Object { Test-Path $_ } | Select-Object -First 1
$check += [pscustomobject]@{
    Item = "README（运行方式与依赖版本）"
    Need = "根目录 README.md"
    Have = if ($readme) { "存在" } else { "缺失（进阶项，但强烈建议）" }
    Ok   = [bool]$readme
}

# 5. 工作区是否干净（有未提交内容会漏交）
$status = & $git status --porcelain 2>$null
$dirty = @($status | Where-Object { $_ -ne "" })
$check += [pscustomobject]@{
    Item = "Git 工作区"
    Need = "无未提交改动"
    Have = if ($dirty.Count -eq 0) { "干净" } else { "$($dirty.Count) 项未提交" }
    Ok   = ($dirty.Count -eq 0)
}

# 6. 远程仓库（任务要求提交仓库地址）
$remote = & $git remote -v 2>$null
$hasRemote = @($remote | Where-Object { $_ -ne "" }).Count -gt 0
if ($hasRemote) {
    $ahead = & $git status -sb 2>$null | Select-Object -First 1
    $notPushed = ($ahead -match "ahead")
} else { $notPushed = $false }
$check += [pscustomobject]@{
    Item = "远程仓库（要交仓库地址）"
    Need = "已配置 origin 且已推送"
    Have = if (-not $hasRemote) { "未配置 origin" } elseif ($notPushed) { "有提交未推送" } else { "已配置并同步" }
    Ok   = ($hasRemote -and -not $notPushed)
}

# 7. 最新提交
$last = & $git log -1 --format="%h %ad %s" --date=format:"%m-%d %H:%M" 2>$null
$check += [pscustomobject]@{
    Item = "最新提交"
    Need = "有提交记录"
    Have = if ($last) { $last } else { "无" }
    Ok   = [bool]$last
}

# ---- 输出 ----
Write-Host ""
Write-Host ("=== " + $titles[$Task] + " 提交自检 ===") -ForegroundColor Cyan
Write-Host ("目录：" + $root) -ForegroundColor DarkGray
Write-Host ""
foreach ($c in $check) {
    $mark = if ($c.Ok) { "[OK]  " } else { "[缺]  " }
    $color = if ($c.Ok) { "Green" } else { "Red" }
    Write-Host ($mark + $c.Item + "：" + $c.Have) -ForegroundColor $color
    if (-not $c.Ok) { Write-Host ("        要求：" + $c.Need) -ForegroundColor DarkGray }
}

$fail = @($check | Where-Object { -not $_.Ok })
Write-Host ""
if ($fail.Count -eq 0) {
    Write-Host "全部通过，可以提交了。" -ForegroundColor Green
    Write-Host "  1) 确认代码已推送： git push" -ForegroundColor Gray
    Write-Host "  2) 把 docs\$($dirs[$Task]) 里的截图 + 笔记 整理成一个 PDF" -ForegroundColor Gray
    Write-Host "  3) 上传到 https://homework.redrock.team （PDF + 仓库地址）" -ForegroundColor Gray
    Write-Host "  4) 本任务要求交付：" + $names[$Task] -ForegroundColor Gray
    if ($Open) { Start-Process "https://homework.redrock.team" }
} else {
    Write-Host ("还差 " + $fail.Count + " 项，先补齐再提交：") -ForegroundColor Yellow
    $fail | ForEach-Object { Write-Host ("  - " + $_.Item + "（" + $_.Need + "）") -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "截图可以用： .\tools\shot.ps1 -Out docs\$($dirs[$Task])\0X-说明.png -Delay 8" -ForegroundColor DarkGray
}
Write-Host ""
