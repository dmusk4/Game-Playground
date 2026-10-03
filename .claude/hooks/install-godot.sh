#!/bin/bash
# Installs a headless-capable Godot 4 binary in Claude Code cloud sessions so
# the godot MCP server (see .mcp.json) can find it at /usr/local/bin/godot.
set -euo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

GODOT_VERSION="4.5.1-stable"
if command -v godot >/dev/null 2>&1 && godot --headless --version 2>/dev/null | grep -q "^${GODOT_VERSION%-stable}"; then
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/godot.zip" \
  "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
unzip -q "$tmp/godot.zip" -d "$tmp"
install -m 755 "$tmp/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot

# Warm the npx cache so the MCP server starts quickly.
npx -y @coding-solo/godot-mcp@0.1.1 --version </dev/null >/dev/null 2>&1 || true
