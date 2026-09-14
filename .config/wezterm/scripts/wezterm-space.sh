#!/bin/sh
# 指定したワークスペース名で、独立した WezTerm GUI プロセスを起動する。
# macOS の Space ごとに別ワークスペースのウィンドウを常駐させたいとき用。
# Raycast / Karabiner / Alfred などから呼ぶことを想定。
#
#   usage: wezterm-space.sh <workspace-name>
set -eu

if [ $# -lt 1 ]; then
  echo "usage: $(basename "$0") <workspace-name>" >&2
  exit 1
fi

WEZTERM=${WEZTERM_BIN:-/Applications/WezTerm.app/Contents/MacOS/wezterm}

nohup "$WEZTERM" start --always-new-process --workspace "$1" >/dev/null 2>&1 &
