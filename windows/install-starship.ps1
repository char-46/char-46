# ============================================================
#  install-starship.ps1 - 安装 starship 并接入 pwsh + cmd
#
#  * 安装 starship (scoop, 备选 winget)
#  * 安装 clink   (cmd 增强外壳, starship 的 cmd 后端)
#  * 部署 starship.toml 到 ~/.config
#  * 生成 %LocalAppData%\clink\starship.lua (cmd 提示符)
#  * 在 pwsh 5.1/7 的 profile 中加入初始化 (幂等)
#
#  用法: pwsh -File windows/install-starship.ps1 [-RepoRoot <repo>]
# ============================================================
param(
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

function Ensure-Pkg([string]$Name, [scriptblock]$ScoopInstall, [string]$WingetId) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        & $ScoopInstall
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id $WingetId -e --accept-package-agreements --accept-source-agreements
    } else {
        throw "无法安装 $Name : 找不到 scoop 或 winget"
    }
}

Write-Host '==> 安装 starship / clink'
Ensure-Pkg 'starship' { scoop install starship } 'Starship.Starship'
Ensure-Pkg 'clink'   { scoop install clink   } 'chrisant996.Clink'

# ---- 部署 starship.toml ----
Write-Host '==> 部署 starship.toml'
New-Item -ItemType Directory -Force "$HOME\.config" | Out-Null
$src = Join-Path $RepoRoot 'starship.toml'
if (Test-Path $src) {
    Copy-Item $src "$HOME\.config\starship.toml" -Force
} else {
    # 回退: 从仓库 raw 地址下载 (国内网络可能需要代理)
    curl.exe -fsSL "https://raw.githubusercontent.com/char-46/char-46/master/starship.toml" -o "$HOME\.config\starship.toml"
}
Write-Host "  ~/.config/starship.toml"

# ---- pwsh profile (5.1 与 7 都加, 幂等) ----
Write-Host '==> 配置 pwsh profile'
$initLine = 'Invoke-Expression (&starship init powershell)'
$profiles = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"     # pwsh 7
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"  # 5.1
)
foreach ($pf in $profiles) {
    $dir = Split-Path $pf -Parent
    if (-not (Test-Path $dir)) { continue }   # 没用过的 shell 不主动创建
    New-Item -ItemType Directory -Force $dir | Out-Null
    $content = if (Test-Path $pf) { Get-Content $pf -Raw } else { '' }
    if ($content -notmatch [regex]::Escape('starship init powershell')) {
        Add-Content $pf "`n# ---------- starship 提示符 ----------`nif (Get-Command starship -ErrorAction SilentlyContinue) {`n    $initLine`n}"
        Write-Host "  [profile] $pf"
    }
}

# ---- cmd: clink + starship.lua ----
Write-Host '==> 配置 cmd (clink)'
$clinkDir = "$env:LOCALAPPDATA\clink"
New-Item -ItemType Directory -Force $clinkDir | Out-Null
$starship = (Get-Command starship).Source
& $starship init cmd | Out-File "$clinkDir\starship.lua" -Encoding ascii
Write-Host "  $clinkDir\starship.lua"
clink autorun install

Write-Host '完成。cmd 提示符在下次启动 cmd 时生效。'
