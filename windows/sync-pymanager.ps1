# ============================================================
#  sync-pymanager.ps1 - 把 uv 管理的 Python 注册给 pymanager
#  (PEP 514 注册表, HKCU\Software\Python\Astral\<tag>)
#
#  架构: pymanager 只做 py launcher (替代旧版 py.exe);
#        Python 版本的安装/升级/卸载全部由 uv 管理。
#  uv python install/update 之后重跑本脚本即可刷新注册。
#
#  用法: pwsh -File windows/sync-pymanager.ps1 [-Versions 3.14,3.15]
# ============================================================
param(
    [string[]]$Versions = @('3.14', '3.15')
)

$ErrorActionPreference = 'Stop'
$companyKey = 'HKCU:\Software\Python\Astral'

if (-not (Get-Command py -ErrorAction SilentlyContinue)) {
    Write-Warning 'pymanager 未安装 (winget install Python.PythonInstallManager)，跳过注册'
    return
}

# 清掉旧注册，避免 uv 升级后残留死路径
if (Test-Path $companyKey) {
    Get-ChildItem $companyKey | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Force $companyKey | Out-Null
Set-ItemProperty $companyKey -Name '(Default)' -Value 'Astral'

foreach ($v in $Versions) {
    $exe = (uv python find $v 2>$null | Select-Object -First 1)
    if (-not $exe -or -not (Test-Path $exe)) {
        Write-Warning "uv 未安装 Python $v，跳过 (uv python install $v)"
        continue
    }
    $exe = (Resolve-Path $exe).Path
    $dir = Split-Path $exe
    $full = & $exe -c 'import platform; print(platform.python_version())'

    $tagKey = "$companyKey\$v"
    New-Item -ItemType Directory -Force $tagKey | Out-Null
    Set-ItemProperty $tagKey -Name '(Default)' -Value "CPython $full"
    Set-ItemProperty $tagKey -Name 'DisplayName' -Value "CPython $full (Astral, uv-managed)"
    Set-ItemProperty $tagKey -Name 'SupportUrl' -Value 'https://docs.astral.sh/uv/'
    Set-ItemProperty $tagKey -Name 'Version' -Value $full
    Set-ItemProperty $tagKey -Name 'SysVersion' -Value $v
    $ipKey = "$tagKey\InstallPath"
    New-Item -ItemType Directory -Force $ipKey | Out-Null
    Set-ItemProperty $ipKey -Name '(Default)' -Value $dir
    Set-ItemProperty $ipKey -Name 'ExecutablePath' -Value $exe
    Write-Host "  [reg] Astral\$v -> $full ($dir)"
}

# 默认运行时指向最高版本
$default = ($Versions | Sort-Object { [version]$_ } -Descending | Select-Object -First 1)
$cfgDir = "$env:APPDATA\Python"
New-Item -ItemType Directory -Force $cfgDir | Out-Null
$cfg = @{
    default_tag       = "Astral\$default"
    automatic_install = $false
    include_unmanaged = $true
} | ConvertTo-Json
Set-Content "$cfgDir\pymanager.json" $cfg -Encoding UTF8
Write-Host "  [cfg] default_tag = Astral\$default"

Write-Host '完成。py list / py -V 应能看到 uv 管理的解释器。'
