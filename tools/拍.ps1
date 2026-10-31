param(
    [string]$Name = "",
    [int]$Delay = 3,
    [switch]$NoCountdown
)
# 一条命令 = 一张清晰截图，直接存进 docs\task01-env\
#   .\tools\拍.ps1 03-vscode-overview
#   .\tools\拍.ps1 04-some-name -Delay 6

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrWhiteSpace($Name)) {
    $Name = "shot-" + (Get-Date -Format "yyMMdd-HHmmss")
}
if ($Name -notmatch "\.png$") { $Name = $Name + ".png" }
$dir = Join-Path $root "docs\task01-env"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$out = [System.IO.Path]::GetFullPath((Join-Path $dir $Name))

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
if (-not ("CapHelper" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class CapHelper {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("shcore.dll")] public static extern int SetProcessDpiAwareness(int value);
    public static void MakeDpiAware() {
        try { SetProcessDpiAwareness(2); } catch { try { SetProcessDPIAware(); } catch { } }
    }
}
"@
# 按屏幕真实分辨率采集（2560x1600），而不是缩放后的 1707x1067
}

[CapHelper]::MakeDpiAware()

# 静默等待：不打印任何文字（文字会进截图），只用一声提示音
if ($Delay -gt 0) {
    try { [console]::Beep(1200, 120) } catch { }
    Start-Sleep -Seconds $Delay
}

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

# 检查最底部是否有状态栏（纯色 = 状态栏没进画面）
$vals = New-Object System.Collections.Generic.List[double]
for ($x = 2; $x -lt $bmp.Width - 2; $x += 50) {
    for ($y = $bmp.Height - 30; $y -lt $bmp.Height - 4; $y += 8) {
        $c = $bmp.GetPixel($x, $y)
        $vals.Add(([double]$c.R + [double]$c.G + [double]$c.B) / 3.0)
    }
}
$bmp.Dispose()
$avg = ($vals | Measure-Object -Average).Average
$sum = 0.0
foreach ($v in $vals) { $sum += ($v - $avg) * ($v - $avg) }
$sd = [math]::Sqrt($sum / $vals.Count)

$info = Get-Item $out
Write-Host ""
Write-Host ("已保存: " + $info.FullName) -ForegroundColor Green
Write-Host ("大小: " + [math]::Round($info.Length / 1KB, 1) + " KB   分辨率: " + $bounds.Width + "x" + $bounds.Height)

if ($sd -lt 4) {
    if ($Name -like "*overview*") {
        Write-Host "不合格提示: 这是整体图，但底部没有状态栏。" -ForegroundColor Red
        Write-Host "   1) 双击「终端」标签还原面板，让编辑区出现代码" -ForegroundColor Yellow
        Write-Host "   2) 菜单 视图 > 外观 > 状态栏，确认已勾选" -ForegroundColor Yellow
        Write-Host "   3) 重跑本命令覆盖同一文件名即可" -ForegroundColor Yellow
    } else {
        Write-Host "（底部纯色属正常：终端占满全屏时看不到状态栏）" -ForegroundColor DarkGray
    }
} else {
    Write-Host "底部检测到状态栏，整体图合格。" -ForegroundColor Green
}
