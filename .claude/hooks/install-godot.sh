#!/bin/bash
# Installs a headless-capable Godot 4 binary and the alexmeckes godot-mcp
# server in Claude Code cloud sessions (both MCP servers are in .mcp.json).
set -euo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

GODOT_VERSION="4.5.1-stable"
if ! godot --headless --version 2>/dev/null | grep -q "^${GODOT_VERSION%-stable}"; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --max-time 300 -o "$tmp/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
  unzip -q "$tmp/godot.zip" -d "$tmp"
  install -m 755 "$tmp/Godot_v${GODOT_VERSION}_linux.x86_64" /usr/local/bin/godot
fi

# Warm the npx cache so the Coding-Solo server starts quickly.
timeout 120 npx -y @coding-solo/godot-mcp@0.1.1 --version </dev/null >/dev/null 2>&1 || true

# alexmeckes/godot-mcp is not on npm; install a pinned commit from source.
ALEX_MCP_COMMIT="6a10531695da7cf3be4f06962bf3c0c584ecdff4"
ALEX_MCP_DIR="$HOME/.local/share/godot-mcp-alexmeckes"
if [ "$(git -C "$ALEX_MCP_DIR" rev-parse HEAD 2>/dev/null)" != "$ALEX_MCP_COMMIT" ] || [ ! -d "$ALEX_MCP_DIR/node_modules" ]; then
  rm -rf "$ALEX_MCP_DIR"
  timeout 120 git clone -q https://github.com/alexmeckes/godot-mcp "$ALEX_MCP_DIR"
  git -C "$ALEX_MCP_DIR" checkout -q "$ALEX_MCP_COMMIT"
  (cd "$ALEX_MCP_DIR" && timeout 300 npm ci --omit=dev --ignore-scripts --no-audit --no-fund >/dev/null)
fi
