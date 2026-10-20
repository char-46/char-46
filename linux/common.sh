#!/usr/bin/env bash
# ============================================================
#  common.sh - Linux 各发行版共享的配置逻辑
#  被 el/install.sh / debian/install.sh / arch/install.sh source
#
#  职责:
#    ~/.local/bin  -> python/python3 (uv 管理的 CPython 软链)
#                  -> pip     (uv pip "$@" --system)
#                  -> npm     (pnpm)
#                  -> npx     (pnpm dlx, 即 pnpx)
#    uv / fnm / pnpm / starship 安装 (已装则跳过)
# ============================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/char-46/char-46/master}"
PYVER="${PYVER:-3.14}"

append_if_not_exists() {
    local content="$1" target="$2"
    [ -f "$target" ] || touch "$target"
    if grep -Fxq "$content" "$target" 2>/dev/null; then
        echo "  [skip] '$content' 已存在于 $target"
    else
        echo "$content" >> "$target"
        echo "  [add ] $target <- $content"
    fi
}

ensure_local_bin() {
    mkdir -p "$HOME/.local/bin"
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) append_if_not_exists 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" ;;
    esac
    export PATH="$HOME/.local/bin:$PATH"
}

install_uv() {
    command -v uv >/dev/null 2>&1 && { echo '  [skip] uv'; return; }
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
}

# python REPL 指向 uv 管理的 CPython; pip -> uv pip --system
setup_python() {
    uv python install "$PYVER"
    local py
    py="$(uv python find "$PYVER")"
    ln -sf "$py" "$HOME/.local/bin/python"
    ln -sf "$py" "$HOME/.local/bin/python3"
    printf '#!/bin/sh\n# pip -> uv pip <subcommand> --system\nexec uv pip "$@" --system\n' > "$HOME/.local/bin/pip"
    chmod +x "$HOME/.local/bin/pip"
    echo "  [link] python/python3 -> $py"
}

install_fnm() {
    command -v fnm >/dev/null 2>&1 && { echo '  [skip] fnm'; return; }
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    append_if_not_exists 'eval "$(fnm env --use-on-cd bash)"' "$HOME/.bashrc"
}

install_pnpm() {
    command -v pnpm >/dev/null 2>&1 && { echo '  [skip] pnpm'; return; }
    curl -fsSL https://get.pnpm.io/install.sh | sh -s - --base-dir "$HOME/.local/share/pnpm"
    append_if_not_exists 'export PNPM_HOME="$HOME/.local/share/pnpm"' "$HOME/.bashrc"
    append_if_not_exists 'export PATH="$PNPM_HOME:$PATH"' "$HOME/.bashrc"
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
}

# npm -> pnpm ; npx -> pnpm dlx
setup_js_shims() {
    printf '#!/bin/sh\n# npm -> pnpm\nexec pnpm "$@"\n'         > "$HOME/.local/bin/npm"
    printf '#!/bin/sh\n# npx -> pnpm dlx (pnpx)\nexec pnpm dlx "$@"\n' > "$HOME/.local/bin/npx"
    chmod +x "$HOME/.local/bin/npm" "$HOME/.local/bin/npx"
    echo '  [shim] ~/.local/bin/{npm,npx}'
}

install_starship() {
    # arch 系优先用 pacman (发行版仓库维护)
    if command -v pacman >/dev/null 2>&1; then
        pacman -S --needed --noconfirm starship
    elif ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    fi
    mkdir -p "$HOME/.config"
    if [ -f "$REPO_ROOT/starship.toml" ]; then
        cp "$REPO_ROOT/starship.toml" "$HOME/.config/starship.toml"
    else
        curl -fsSL "$REPO_RAW/starship.toml" -o "$HOME/.config/starship.toml"
    fi
    append_if_not_exists 'eval "$(starship init bash)"' "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && append_if_not_exists 'eval "$(starship init zsh)"' "$HOME/.zshrc" || true
    echo '  [cfg ] ~/.config/starship.toml'
}

common_setup() {
    echo '==> ~/.local/bin'
    ensure_local_bin
    echo '==> uv + python shims'
    install_uv
    setup_python
    echo '==> fnm (node)'
    install_fnm
    echo '==> pnpm + npm/npx shims'
    install_pnpm
    setup_js_shims
    echo '==> starship'
    install_starship
    echo '全部完成。重新打开 shell 或 source ~/.bashrc 生效。'
}
