# 配置脚本说明 | Setup Scripts

本仓库同时作为多机配置（dotfiles）使用。

## 目录结构

```
windows/                  Windows (pwsh + cmd)
├── bootstrap.ps1         一键入口: shims + starship + cmdrc/AutoRun + profile
├── install-shims.ps1     生成 pip/npm/npx/python 的 .cmd / .ps1 shim
├── install-starship.ps1  starship + clink 安装与接入 (pwsh & cmd)
└── cmdrc.cmd             cmd AutoRun 模板 (fnm env + doskey 别名)
linux/
├── common.sh             共享逻辑: uv / fnm / pnpm / starship + ~/.local/bin shims
├── el/install.sh         EL 系列: RHEL/CentOS/Rocky/Alma (dnf 优先, EL7 回退 yum)
├── debian/install.sh     Debian 系列: Debian/Ubuntu (apt)
└── arch/install.sh       Arch 系列: Arch/Manjaro (pacman)
starship.toml             提示符配置 (Gruvbox Rainbow 风格)
SETUP.md                  本文件
```

## 使用

### Windows

```powershell
git clone https://github.com/char-46/char-46.git
pwsh -File char-46\windows\bootstrap.ps1 -ShimDir D:\PATH -PythonVersion 3.14
```

### Linux (EL / Debian / Arch)

```bash
sudo bash linux/el/install.sh      # RHEL / CentOS / Rocky / Alma (dnf 或 yum 自动选择)
sudo bash linux/debian/install.sh  # Debian / Ubuntu
sudo bash linux/arch/install.sh    # Arch / Manjaro
```

## 命令别名约定 | Command Shims

| 命令 | 实际执行 | 说明 |
|---|---|---|
| `python` / `python3` | uv 管理的 CPython | 软链/直链到 `uv python find 3.14` |
| `pip <subcmd>` | `uv pip <subcmd> --system` | 配合用户环境变量 `UV_PYTHON=3.14` |
| `npm` | `pnpm` | |
| `npx` | `pnpm dlx`（即 pnpx） | |

Windows 下同时生成 `.cmd`（供 cmd / 脚本调用）与 `.ps1`（供 PowerShell 调用）两份 shim；
pwsh 中另有 profile 函数覆盖，优先级高于 fnm 注入的同名命令。

## 包管理器分工 | Package Manager Policy

每个包只由一个管理器负责，避免重复安装：

| 包管理器 | 负责内容 |
|---|---|
| **winget** | GUI 应用、运行库、驱动、系统组件 |
| **scoop** | Windows 便携 CLI 工具（git / gh / 7zip / ffmpeg / starship / clink …） |
| **cargo (rustup)** | Rust 编写的 CLI（fnm / uv / uesave …） |
| **uv** | Python 解释器与 Python 工具链（`uv python` / `uv tool` / `uvx`） |
| **fnm** | Node.js 运行时版本 |
| **pnpm** | 全局 JS CLI（opencode-ai …），npm/npx 一律转发到 pnpm |
| `D:\PATH` | 无法进包管理器的绿色单文件工具与手工脚本 |
