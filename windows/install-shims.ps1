# ============================================================
#  install-shims.ps1 - 生成命令 shim
#  pip  -> uv pip <subcommand> --system
#  npm  -> pnpm
#  npx  -> pnpm dlx   (即 pnpx)
#  python/python3 -> uv 管理的 CPython
#
#  用法: pwsh -File windows/install-shims.ps1 [-ShimDir D:\PATH] [-PythonVersion 3.14]
# ============================================================
param(
    [string]$ShimDir = 'D:\PATH',
    [string]$PythonVersion = '3.14'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    throw 'uv 未安装。请先: winget install astral-sh.uv 或 cargo install uv'
}

# 解析 uv 管理的 python 解释器绝对路径
$pyExe = (uv python find $PythonVersion 2>$null | Select-Object -First 1).Trim()
if (-not $pyExe -or -not (Test-Path $pyExe)) {
    Write-Host "未找到 uv 管理的 Python $PythonVersion，正在安装..."
    uv python install $PythonVersion
    $pyExe = (uv python find $PythonVersion | Select-Object -First 1).Trim()
}

New-Item -ItemType Directory -Force $ShimDir | Out-Null
if (-not ($ShimDir -in ($env:Path -split ';'))) {
    Write-Warning "$ShimDir 不在 PATH 中，正在添加到用户 PATH"
    $p = [Environment]::GetEnvironmentVariable('Path', 'User')
    [Environment]::SetEnvironmentVariable('Path', "$ShimDir;$p", 'User')
}

function Write-Shim([string]$Name, [string[]]$Lines) {
    # 统一写 CRLF，避免 cmd 解析问题
    $ext = if ($Name -like '*.ps1') { 'ps1' } else { 'cmd' }
    [IO.File]::WriteAllText((Join-Path $ShimDir $Name), ($Lines -join "`r`n") + "`r`n")
    Write-Host "  [shim] $ShimDir\$Name"
}

Write-Host "生成 shim 到 $ShimDir :"

# ---- python / python3 -> uv 管理的 CPython ----
foreach ($n in 'python', 'python3') {
    Write-Shim "$n.cmd" @(
        '@echo off',
        ":: $n -> uv 管理的 CPython $PythonVersion (install-shims.ps1 生成)",
        "`"$pyExe`" %*"
    )
    Write-Shim "$n.ps1" @(
        "# $n -> uv 管理的 CPython $PythonVersion (install-shims.ps1 生成)",
        "& `"$pyExe`" @args",
        'exit $LASTEXITCODE'
    )
}

# ---- pip -> uv pip <subcommand> --system ----
Write-Shim 'pip.cmd' @(
    '@echo off',
    ':: pip -> uv pip <subcommand> --system (install-shims.ps1 生成)',
    'uv pip %* --system'
)
Write-Shim 'pip.ps1' @(
    '# pip -> uv pip <subcommand> --system (install-shims.ps1 生成)',
    'uv pip @args --system',
    'exit $LASTEXITCODE'
)

# ---- npm -> pnpm ----
Write-Shim 'npm.cmd' @(
    '@echo off',
    ':: npm -> pnpm (install-shims.ps1 生成)',
    'pnpm %*'
)
Write-Shim 'npm.ps1' @(
    '# npm -> pnpm (install-shims.ps1 生成)',
    'pnpm @args',
    'exit $LASTEXITCODE'
)

# ---- npx -> pnpm dlx (即 pnpx) ----
Write-Shim 'npx.cmd' @(
    '@echo off',
    ':: npx -> pnpm dlx (install-shims.ps1 生成)',
    'pnpm dlx %*'
)
Write-Shim 'npx.ps1' @(
    '# npx -> pnpm dlx (install-shims.ps1 生成)',
    'pnpm dlx @args',
    'exit $LASTEXITCODE'
)

Write-Host "完成。python -> $pyExe"
