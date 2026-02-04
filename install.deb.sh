# 函数名：append_if_not_exists
# 用法：append_if_not_exists "要追加的字符串" "目标文件路径"
# 功能：如果目标文件中不存在该字符串，则将其追加到文件末尾
append_if_not_exists() {
  if [ "$#" -ne 2 ]; then
    echo "错误：需要两个参数。"
    echo "用法: append_if_not_exists \"要追加的字符串\" \"目标文件路径\""
    return 1
  fi

  local content_to_add="$1"
  local target_file="$2"

  # 检查目标文件是否存在
  if [ ! -f "$target_file" ]; then
    echo "警告：目标文件 '$target_file' 不存在，将创建该文件并追加内容。"
  fi

  # 使用 grep 精确匹配整行（-Fxq）
  if grep -Fxq "$content_to_add" "$target_file" 2>/dev/null; then
    echo "内容已存在于 '$target_file' 中，无需重复添加："
    echo "$content_to_add"
  else
    echo "$content_to_add" >> "$target_file"
    echo "已将以下内容追加到 '$target_file'："
    echo "$content_to_add"
  fi
}

# starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
mkdir -p ~/.config
wget 'https://raw.githubusercontent.com/char-46/char-46/refs/heads/master/starship.toml' -O ~/.config/starship.toml
append_if_not_exists 'eval "$(starship init bash)"' ~/.bashrc
append_if_not_exists 'eval "$(starship init zsh)"' ~/.zshrc

# TODO: fnm conda...


