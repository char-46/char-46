# ============================================================
#  bootstrap.ps1 - Windows 一键配置入口
#  https://github.com/char-46/char-46
#
#  前置: scoop / uv / pnpm / fnm 至少 scoop+uv 已安装
#  (scoop: https://scoop.sh ; uv: winget install astral-sh.uv)
#
#  用法: pwsh -File windows/bootstrap.ps1 [-ShimDir D:\PATH] [-PythonVersion 3.14]
# ============================================================
param(
    [string]$ShimDir = 'D:\PATH',
    [string]$PythonVersion = '3.14',
    [switch]$NoStarship
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent

# ---------- 0. 依赖检查 ----------
foreach ($t in 'scoop', 'uv') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
        throw "缺少 $t 。scoop: iwr -useb get.scoop.sh | iex ; uv: winget install astral-sh.uv"
    }
}
foreach ($t in 'pnpm', 'fnm') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
        Write-Warning "建议安装 $t (node 生态): cargo install fnm ; irm https://get.pnpm.io/install.ps1 | iex"
    }
}

# ---------- 1. UV_PYTHON 用户环境变量 ----------
Write-Host '==> 设置 UV_PYTHON 用户环境变量'
[Environment]::SetEnvironmentVariable('UV_PYTHON', $PythonVersion, 'User')

# ---------- 2. shim 生成 ----------
Write-Host '==> 生成命令 shim (pip/npm/npx/python)'
& (Join-Path $PSScriptRoot 'install-shims.ps1') -ShimDir $ShimDir -PythonVersion $PythonVersion

# ---------- 3. starship ----------
if (-not $NoStarship) {
    Write-Host '==> 安装 starship (pwsh + cmd)'
    & (Join-Path $PSScriptRoot 'install-starship.ps1') -RepoRoot $RepoRoot
}

# ---------- 4. cmdrc.cmd + AutoRun ----------
Write-Host '==> 部署 cmdrc.cmd 并注册 cmd AutoRun'
if (-not (Test-Path $ShimDir)) { New-Item -ItemType Directory -Force $ShimDir | Out-Null }
# 复制模板并统一 CRLF
$cmdrc = Get-Content (Join-Path $PSScriptRoot 'cmdrc.cmd') -Raw
[IO.File]::WriteAllText((Join-Path $ShimDir 'cmdrc.cmd'), ($cmdrc -replace "`r?`n", "`r`n"))

$cpKey = 'HKCU:\Software\Microsoft\Command Processor'
$ar = (Get-ItemProperty $cpKey -Name AutoRun -ErrorAction SilentlyContinue).AutoRun
if (-not $ar) { $ar = '' }
if ($ar -notlike '*cmdrc.cmd*') {
    $new = ($ar.Trim() + " & `"$ShimDir\cmdrc.cmd`"").Trim(' &')
    Set-ItemProperty $cpKey -Name AutoRun -Value $new
    Write-Host "  AutoRun = $new"
} else {
    Write-Host '  AutoRun 已包含 cmdrc.cmd'
}

# ---------- 5. pwsh profile 函数别名 (幂等) ----------
Write-Host '==> 配置 pwsh profile (npm/npx/pip 函数)'
$profiles = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)
$block = @"

# ---------- char-46: 包管理器别名 ----------
# npm -> pnpm ; npx -> pnpm dlx ; pip -> uv pip --system
function npm { pnpm `@args }
function npx { pnpm dlx `@args }
function pip { uv pip `@args --system }
"@
foreach ($pf in $profiles) {
    if (-not (Test-Path (Split-Path $pf -Parent))) { continue }
    $content = if (Test-Path $pf) { Get-Content $pf -Raw } else { '' }
    if ($content -notmatch 'function npm \{ pnpm') {
        Add-Content $pf $block
        Write-Host "  [profile] $pf"
    }
}

Write-Host @'

完成! 新开 pwsh / cmd 即生效:
  python  -> uv 管理的 CPython
  pip     -> uv pip <subcommand> --system
  npm     -> pnpm
  npx     -> pnpm dlx
'@
