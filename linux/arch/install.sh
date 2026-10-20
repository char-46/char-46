#!/usr/bin/env bash
# ============================================================
#  Arch 系列 (Arch / Manjaro / EndeavourOS) 配置脚本
#  包管理器: pacman
#  用法: sudo bash arch/install.sh
# ============================================================
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
    echo '错误: 未找到 pacman, 这不是 Arch 系发行版?' >&2
    exit 1
fi

echo '==> pacman 安装基础工具'
pacman -Sy --needed --noconfirm base-devel git curl wget unzip

# ---- 共享配置 (uv/fnm/pnpm/starship/shims) ----
# shellcheck source=../common.sh
. "$(cd "$(dirname "$0")" && pwd)/../common.sh"
common_setup
