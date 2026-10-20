#!/usr/bin/env bash
# ============================================================
#  Debian 系列 (Debian / Ubuntu 及衍生) 配置脚本
#  用法: sudo bash debian/install.sh
# ============================================================
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo '错误: 未找到 apt-get, 这不是 Debian 系发行版?' >&2
    exit 1
fi

echo '==> apt-get 安装基础工具'
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl wget ca-certificates unzip

# ---- 共享配置 (uv/fnm/pnpm/starship/shims) ----
# shellcheck source=../common.sh
. "$(cd "$(dirname "$0")" && pwd)/../common.sh"
common_setup
