param(
    [string]$Out = "",
    [int]$Delay = 5
)
# 用法：
#   .\tools\shot.ps1
#   .\tools\shot.ps1 -Out docs\task01-env\06-vscode.png
#   .\tools\shot.ps1 -Out docs\task01-env\06-vscode.png -Delay 8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Join-Path "docs\task01-env" ("shot-" + (Get-Date -Format "yyMMdd-HHmmss") + ".png")
}
$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

Write-Host ("== {0} 秒后自动截屏，现在请把 VS Code 切到前台并最大化 ==" -f $Delay) -ForegroundColor Cyan
Write-Host "   截图前请确认：左侧文件树可见、编辑区有代码、底部状态栏可见" -ForegroundColor DarkGray
Start-Sleep -Seconds $Delay

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$info = Get-Item $Out
$kb = [math]::Round($info.Length / 1KB, 1)
Write-Host ""
Write-Host ("已保存: " + $info.FullName) -ForegroundColor Green
Write-Host ("大小: " + $kb + " KB   分辨率: " + $bounds.Width + "x" + $bounds.Height)

if ($kb -lt 150) {
    Write-Host ""
    Write-Host "提示: 这张只有 $kb KB，画面可能过于空旷，常见原因是：" -ForegroundColor Yellow
    Write-Host "   1) VS Code 的终端面板被最大化（只剩终端）→ 按 Ctrl+J，或菜单 视图 > 外观 > 最大化面板 取消" -ForegroundColor Yellow
    Write-Host "   2) VS Code 没有最大化，四周是桌面背景 → 点窗口右上角最大化" -ForegroundColor Yellow
    Write-Host "   3) 截到了锁屏或黑屏 → 退回 Win+Shift+S 手动截" -ForegroundColor Yellow
    Write-Host "   请打开图片确认，不合格就重拍（同一文件名会覆盖）" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "请打开图片核对：标题栏 / 左侧文件树 / 编辑区代码 / 状态栏 Python .venv (3.12.10) / 任务栏时间" -ForegroundColor DarkGray
}
