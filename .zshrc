eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$(brew --prefix python)/libexec/bin:$PATH"
export PATH="$HOME/@kadota/tools-dev/flutter/bin:$PATH"
export LC_TIME=C
date() { if (( $# )); then command date "$@"; else command date +"%Y-%m-%d %H:%M:%S %Z"; fi }
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export VSCODE_SHELL_INTEGRATION_DEBUG=0
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"

# Claude Code: VSCode 内蔵ターミナルでは fullscreen レンダラを無効化（描画が重いため）
if [[ "$TERM_PROGRAM" == "vscode" ]]; then
  export CLAUDE_CODE_NO_FLICKER=0
  export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1
fi

# Ghostty CLI: Ghostty 以外のターミナルからも ghostty コマンドを使えるようにする
if [[ ":$PATH:" != *":/Applications/Ghostty.app/Contents/MacOS:"* ]]; then
  export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"
fi

# zoxide: ディレクトリ移動履歴を学習する cd 代替（z <キーワード> / zi で fzf 選択）
eval "$(zoxide init zsh)"

# --- 補完・入力支援 ---
# zsh-completions: 追加の補完定義（compinit より前に fpath へ追加する必要がある）
fpath=(/opt/homebrew/share/zsh-completions $fpath)

# zsh 標準の補完システムを有効化（Tab で候補一覧。brew の site-functions も読み込まれる）
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select                          # Tab 連打で候補をカーソル選択
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'      # 大文字小文字を区別しない
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # 候補に色付け

# fzf: Ctrl+R で履歴あいまい検索 / Ctrl+T でファイル検索 / Alt+C でディレクトリ移動
source <(fzf --zsh)

# zsh-autosuggestions: 履歴から入力候補を薄い文字で表示（→ キーで確定）
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting: コマンドの色付け（必ず最後に読み込む）
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-abbr: 略語展開（abbr add gc="git commit" → gc + Space で展開）。syntax-highlighting より後に読み込む
source ~/.zsh/plugins/zsh-abbr/zsh-abbr.zsh
