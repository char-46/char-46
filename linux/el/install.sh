#!/usr/bin/env bash
# ============================================================
#  EL 系列 (RHEL / CentOS / Rocky / AlmaLinux) 配置脚本
#  自动选择包管理器: dnf (EL8+) 优先, 回退 yum (EL7)
#
#  用法: sudo bash el/install.sh   (普通包可无 sudo, 建议 root)
# ============================================================
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1 && ! command -v yum >/dev/null 2>&1; then
    echo '错误: 未找到 dnf 或 yum, 这不是 EL 系发行版?' >&2
    exit 1
fi

# ---- 选择包管理器: dnf 优先, EL7 回退 yum ----
if command -v dnf >/dev/null 2>&1; then
    PKG=dnf
else
    PKG=yum
fi
echo "==> 使用包管理器: $PKG"

# ---- 基础工具 ----
$PKG install -y epel-release || echo '  [warn] epel-release 安装失败 (可能已内置或不可用)'
# EL9 需要启用 CRB 才有部分依赖 (EL8 是 powertools)
if [ "$PKG" = dnf ]; then
    dnf config-manager --set-enabled crb         2>/dev/null || true
    dnf config-manager --set-enabled powertools  2>/dev/null || true
fi
$PKG install -y git curl wget tar gzip bzip2 unzip openssh-clients ca-certificates findutils

# ---- 共享配置 (uv/fnm/pnpm/starship/shims) ----
# shellcheck source=../common.sh
. "$(cd "$(dirname "$0")" && pwd)/../common.sh"
common_setup
