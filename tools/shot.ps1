param(
    [string]$Out = "",
    [int]$Delay = 5,
    [switch]$Force
)
# 用法：
#   .\tools\shot.ps1
#   .\tools\shot.ps1 -Out docs\task01-env\06-vscode.png -Delay 8
#   .\tools\shot.ps1 -Out xxx.png -Force      # 跳过"前台必须是 VS Code"的检查

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class Win32Focus {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    public static string Title() {
        var sb = new StringBuilder(512);
        GetWindowText(GetForegroundWindow(), sb, 512);
        return sb.ToString();
    }
}
"@

if ([string]::IsNullOrWhiteSpace($Out)) {
    $Out = Join-Path "docs\task01-env" ("shot-" + (Get-Date -Format "yyMMdd-HHmmss") + ".png")
}
$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

Write-Host ("== {0} 秒后自动截屏，现在请把 VS Code 切到前台并最大化 ==" -f $Delay) -ForegroundColor Cyan
Write-Host "   确认画面包含：左侧文件树、编辑区代码、底部终端、右下角解释器版本" -ForegroundColor DarkGray
Start-Sleep -Seconds $Delay

# 检查前台窗口，避免截到聊天/浏览器窗口后覆盖掉原来合格的图
$title = [Win32Focus]::Title()
if (-not $Force -and $title -notlike "*Visual Studio Code*") {
    Write-Host ""
    Write-Host ("中止：当前前台窗口是「" + $title + "」，不是 VS Code。") -ForegroundColor Red
    Write-Host "   没有写入任何文件，原来那张图没被覆盖。请切到 VS Code 后重跑。" -ForegroundColor Yellow
    exit 1
}

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
Write-Host ("大小: " + $kb + " KB   分辨率: " + $bounds.Width + "x" + $bounds.Height + "   窗口: " + $title)

if ($kb -lt 40) {
    Write-Host ""
    Write-Host "提示: 只有 $kb KB，可能截到了黑屏/锁屏（深色主题正常是 60–200 KB）" -ForegroundColor Yellow
    Write-Host "   请打开图片确认；有问题就退回 Win+Shift+S 手动截" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "大小正常。请打开图片逐项核对：标题栏 / 文件树 / 代码 / 终端输出 / 状态栏 .venv 版本 / 任务栏时间" -ForegroundColor DarkGray
}
