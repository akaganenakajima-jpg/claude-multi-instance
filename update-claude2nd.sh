#!/usr/bin/env bash
# Claude 2nd ショートカットを最新バージョンに自動更新（Linux / macOS）

set -euo pipefail

OS="$(uname -s)"

find_claude_exe() {
  local candidates=()
  if [[ "$OS" == "Darwin" ]]; then
    candidates=(
      "/Applications/Claude.app/Contents/MacOS/Claude"
      "$HOME/Applications/Claude.app/Contents/MacOS/Claude"
    )
  else
    candidates=(
      "/usr/bin/claude"
      "/usr/local/bin/claude"
      "/opt/Claude/claude"
      "/opt/claude/claude"
      "$HOME/.local/bin/claude"
      "$HOME/Applications/claude"
    )
    if [[ -d "$HOME/Applications" ]] || [[ -d "/opt" ]]; then
      while IFS= read -r f; do
        [[ -n "$f" ]] && candidates+=("$f")
      done < <(find "$HOME/Applications" /opt -maxdepth 3 -iname "claude*.AppImage" 2>/dev/null || true)
    fi
  fi
  for exe in "${candidates[@]}"; do
    [[ -x "$exe" ]] && echo "$exe" && return 0
  done
  command -v claude &>/dev/null && command -v claude && return 0
  return 1
}

CLAUDE_EXE=""
if ! CLAUDE_EXE="$(find_claude_exe)"; then
  echo "ERROR: Claude の実行ファイルが見つかりません。" >&2
  exit 1
fi

if [[ "$OS" == "Darwin" ]]; then
  USER_DATA_DIR="$HOME/Library/Application Support/Claude2"
  LAUNCHER="$HOME/Desktop/Claude 2nd.command"

  cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
"$CLAUDE_EXE" --user-data-dir="$USER_DATA_DIR"
EOF
  chmod +x "$LAUNCHER"

  # AppleScript アプリも更新
  APPLET="$HOME/Applications/Claude 2nd.app"
  if command -v osacompile &>/dev/null; then
    osacompile -o "$APPLET" - <<APPLESCRIPT
do shell script "\"$CLAUDE_EXE\" --user-data-dir=\"$USER_DATA_DIR\" &> /dev/null &"
APPLESCRIPT
  fi
  echo "更新完了: $CLAUDE_EXE"

else
  USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Claude2"
  DESKTOP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/applications/claude-2nd.desktop"

  if [[ ! -f "$DESKTOP_FILE" ]]; then
    echo "ERROR: $DESKTOP_FILE が存在しません。先に setup-claude2nd.sh を実行してください。" >&2
    exit 1
  fi

  # Exec 行だけ更新
  sed -i "s|^Exec=.*|Exec=\"$CLAUDE_EXE\" --user-data-dir=\"$USER_DATA_DIR\"|" "$DESKTOP_FILE"
  update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true

  # デスクトップのコピーも更新
  DESKTOP="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
  [[ -f "$DESKTOP/claude-2nd.desktop" ]] && \
    cp "$DESKTOP_FILE" "$DESKTOP/claude-2nd.desktop"

  echo "更新完了: $CLAUDE_EXE"
fi
