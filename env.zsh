# 由 ~/.zshrc 里的 wtool 块 source。
# WTOOL_PROJECT_DIR 由 wtool 块导出 = $HOME/.wtool/links/terminal/fzf
[[ -n "$WTOOL_PROJECT_DIR" ]] || WTOOL_PROJECT_DIR="$HOME/.wtool/links/terminal/fzf"

# fzf 二进制放在 bin/ 下
export PATH="$WTOOL_PROJECT_DIR/bin:$PATH"

# 官方补全/快捷键脚本（fzf.zsh 本来就是要从 ~/.zshrc 里 source 的）
[[ -r "$WTOOL_PROJECT_DIR/fzf.zsh" ]] && source "$WTOOL_PROJECT_DIR/fzf.zsh"
