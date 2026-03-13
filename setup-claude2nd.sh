#!/usr/bin/env bash
# Claude Code 2つ目のインスタンス 初回セットアップ（Linux / macOS）

set -euo pipefail

OS="$(uname -s)"

# ── Claude 実行ファイルを探す ──────────────────────────────────────────
find_claude_exe() {
  # 一般的なインストール先を順番に確認
  local candidates=()

  if [[ "$OS" == "Darwin" ]]; then
    candidates=(
      "/Applications/Claude.app/Contents/MacOS/Claude"
      "$HOME/Applications/Claude.app/Contents/MacOS/Claude"
    )
  else
    # Linux
    candidates=(
      "/usr/bin/claude"
      "/usr/local/bin/claude"
      "/opt/Claude/claude"
      "/opt/claude/claude"
      "$HOME/.local/bin/claude"
      # AppImage (パターンマッチ)
      "$HOME/Applications/claude"
    )
    # AppImage を追加検索
    if [[ -d "$HOME/Applications" ]] || [[ -d "/opt" ]]; then
      while IFS= read -r f; do
        [[ -n "$f" ]] && candidates+=("$f")
      done < <(find "$HOME/Applications" /opt -maxdepth 3 -iname "claude*.AppImage" 2>/dev/null || true)
    fi
  fi

  for exe in "${candidates[@]}"; do
    if [[ -x "$exe" ]]; then
      echo "$exe"
      return 0
    fi
  done

  # PATH 上の claude コマンドを確認
  if command -v claude &>/dev/null; then
    command -v claude
    return 0
  fi

  return 1
}

CLAUDE_EXE=""
if ! CLAUDE_EXE="$(find_claude_exe)"; then
  echo "ERROR: Claude の実行ファイルが見つかりません。先に Claude をインストールしてください。" >&2
  exit 1
fi
echo "Claude 実行ファイル: $CLAUDE_EXE"

# ── プロファイルディレクトリ ───────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  USER_DATA_DIR="$HOME/Library/Application Support/Claude2"
else
  USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Claude2"
fi

# ── ショートカット / ランチャーを作成 ────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  # macOS: シェルスクリプトラッパー + エイリアス案内
  LAUNCHER="$HOME/Desktop/Claude 2nd.command"
  cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# Claude Code 2nd Instance
"$CLAUDE_EXE" --user-data-dir="$USER_DATA_DIR"
EOF
  chmod +x "$LAUNCHER"
  echo "  -> ランチャー作成完了: $LAUNCHER"

  # Dock 用の AppleScript アプリとして保存（オプション）
  APPLET="$HOME/Applications/Claude 2nd.app"
  if command -v osacompile &>/dev/null; then
    osacompile -o "$APPLET" - <<APPLESCRIPT
do shell script "\"$CLAUDE_EXE\" --user-data-dir=\"$USER_DATA_DIR\" &> /dev/null &"
APPLESCRIPT
    echo "  -> AppleScript アプリ作成完了: $APPLET"
    echo "     Dock に追加するには Finder でドラッグしてください。"
  fi

else
  # Linux: .desktop ファイル
  DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  mkdir -p "$DESKTOP_DIR"
  DESKTOP_FILE="$DESKTOP_DIR/claude-2nd.desktop"

  # アイコンを1つ目インスタンスから流用
  ICON=""
  for p in /usr/share/icons/hicolor/256x256/apps/claude.png \
            /usr/share/pixmaps/claude.png \
            /opt/Claude/resources/app/icon.png; do
    if [[ -f "$p" ]]; then ICON="$p"; break; fi
  done

  cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Claude 2nd
Comment=Claude Code 2nd Instance
Exec="$CLAUDE_EXE" --user-data-dir="$USER_DATA_DIR"
Terminal=false
Type=Application
Categories=Development;
EOF
  [[ -n "$ICON" ]] && echo "Icon=$ICON" >> "$DESKTOP_FILE"

  chmod +x "$DESKTOP_FILE"
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
  echo "  -> デスクトップエントリ作成完了: $DESKTOP_FILE"

  # デスクトップにもコピー
  DESKTOP="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
  if [[ -d "$DESKTOP" ]]; then
    cp "$DESKTOP_FILE" "$DESKTOP/claude-2nd.desktop"
    chmod +x "$DESKTOP/claude-2nd.desktop"
    echo "  -> デスクトップにもコピー: $DESKTOP/claude-2nd.desktop"
  fi

  # 自動更新スクリプトをインストール
  BIN_DIR="$HOME/.local/bin"
  mkdir -p "$BIN_DIR"
  cp "$(dirname "$0")/update-claude2nd.sh" "$BIN_DIR/update-claude2nd.sh"
  chmod +x "$BIN_DIR/update-claude2nd.sh"

  # systemd ユーザーサービスで自動更新（オプション）
  SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
  if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null 2>&1; then
    mkdir -p "$SYSTEMD_USER_DIR"
    cat > "$SYSTEMD_USER_DIR/update-claude2nd.service" <<EOF
[Unit]
Description=Update Claude 2nd shortcut after Claude update

[Service]
Type=oneshot
ExecStart=$BIN_DIR/update-claude2nd.sh
EOF
    cat > "$SYSTEMD_USER_DIR/update-claude2nd.path" <<EOF
[Unit]
Description=Watch for Claude updates to refresh 2nd instance shortcut

[Path]
PathChanged=$(dirname "$CLAUDE_EXE")

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now update-claude2nd.path 2>/dev/null && \
      echo "  -> systemd path ユニット登録完了（Claude 更新時に自動修復）" || \
      echo "  -> systemd 登録をスキップ（手動で update-claude2nd.sh を実行してください）"
  fi
fi

echo ""
echo "セットアップ完了！"
if [[ "$OS" == "Darwin" ]]; then
  echo "デスクトップの「Claude 2nd.command」をダブルクリックして起動してください。"
  echo "または $APPLET を Dock に追加してください。"
else
  echo "デスクトップの「Claude 2nd」アイコンをダブルクリックして起動してください。"
fi
echo "初回は Google アカウントへのログインが必要です。"
