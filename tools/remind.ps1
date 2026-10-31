param(
    [string]$Date = "",
    [int]$Timeout = 300
)
# 每日学习提醒：读取 tools\计划数据.json，弹出今天该做什么 + 距最近截止天数
# 手动运行： .\tools\remind.ps1
# 查看指定日期： .\tools\remind.ps1 -Date 2026-11-22

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $PSScriptRoot "计划数据.json"
if (-not (Test-Path $jsonPath)) { throw "找不到 计划数据.json：$jsonPath" }

$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($Date)) { $Date = (Get-Date).ToString("yyyy-MM-dd") }
$today = [datetime]::ParseExact($Date, "yyyy-MM-dd", $null)

# 最近一个未过期的截止
$nextDl = $null
foreach ($dl in $data.deadlines) {
    $d = [datetime]::ParseExact($dl.date, "yyyy-MM-dd", $null)
    if ($d -ge $today) { $nextDl = $dl; break }
}
$left = if ($nextDl) { ([datetime]::ParseExact($nextDl.date, "yyyy-MM-dd", $null) - $today).Days } else { -1 }

$lines = New-Object System.Collections.Generic.List[string]
[void]$lines.Add("$($data.title)")
[void]$lines.Add("")

if ($nextDl) {
    $tag = if ($left -eq 0) { "【今天截止！】" } elseif ($left -le 5) { "【临近！】" } else { "" }
    [void]$lines.Add("$tag 距「$($nextDl.title)」提交还有 $left 天（$($nextDl.date)）")
    [void]$lines.Add("  要交：$($nextDl.detail)")
} else {
    [void]$lines.Add("阶段已结束，所有截止已过。")
}

$day = $data.days.$Date
if ($day) {
    $h = $today.DayOfWeek
    $hours = if ($today.ToString("yyyy-MM-dd") -eq "2027-01-25") { 0.5 } elseif ($h -in "Saturday", "Sunday") { 1.5 } else { 2.5 }
    [void]$lines.Add("")
    [void]$lines.Add("第 $($day.week) 周 · $($day.task)（约 $hours 小时）")
    [void]$lines.Add("核心：$($day.core)")
    [void]$lines.Add("加餐：$($day.extra)")
    [void]$lines.Add("产出：$($day.out)")
} elseif ($today -lt [datetime]::ParseExact($data.start, "yyyy-MM-dd", $null)) {
    [void]$lines.Add("")
    [void]$lines.Add("还没开课（11/02 正式开始）。今天可以先预热：把环境跑通、写第一个 hello.py。")
} else {
    [void]$lines.Add("")
    [void]$lines.Add("今天不在计划范围内，做补课或复盘。")
}

if ($today.DayOfWeek -eq "Sunday") {
    [void]$lines.Add("")
    [void]$lines.Add("今天是周日：花 20 分钟更新进度，并跑 .\tools\提交检查.ps1 看看是否该交作业。")
}

[void]$lines.Add("")
[void]$lines.Add("计划文件：tools\计划数据.json")

$text = $lines -join "`r`n"
$shell = New-Object -ComObject WScript.Shell
[void]$shell.Popup($text, $Timeout, "Agent 学习提醒 · $Date", 64)
