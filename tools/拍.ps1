param(
    [string]$Name = "",
    [int]$Delay = 3,
    [switch]$Quiet
)
# 一条命令 = 一张图，直接存进 docs\task01-env\
#   .\tools\拍.ps1 02-hello-run
#   .\tools\拍.ps1 03-vscode-overview -Delay 6

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
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32Cap {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    public static string Title() {
        var sb = new StringBuilder(512);
        GetWindowText(GetForegroundWindow(), sb, 512);
        return sb.ToString();
    }
}
"@

if (-not $Quiet) {
    Write-Host ("== {0} 秒后截图 -> {1} ==" -f $Delay, $Name) -ForegroundColor Cyan
    Write-Host "   这 3 秒里不要动鼠标键盘，等提示" -ForegroundColor DarkGray
}
Start-Sleep -Seconds $Delay

$title = [Win32Cap]::Title()
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

# 底部是否有状态栏（只作提示，不拦）
$vals = New-Object System.Collections.Generic.List[double]
for ($x = 2; $x -lt $bmp.Width - 2; $x += 40) {
    for ($y = $bmp.Height - 24; $y -lt $bmp.Height - 3; $y += 7) {
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
Write-Host ("大小: " + [math]::Round($info.Length / 1KB, 1) + " KB   当前窗口: " + $title)
if ($sd -lt 4 -and $Name -like "*overview*") {
    Write-Host "注意: 这是整体图，但底部没有状态栏（纯色）——请确认 视图>外观>状态栏 已勾选、窗口已最大化，再重拍一次" -ForegroundColor Yellow
} elseif ($sd -lt 4) {
    Write-Host "（底部是纯色，属正常：终端占满全屏时没有状态栏）" -ForegroundColor DarkGray
} else {
    Write-Host "底部检测到状态栏，整体图合格。" -ForegroundColor DarkGray
}
