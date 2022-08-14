#!/usr/bin/env bash
# Regenerates docs/screenshot-light.png and docs/screenshot-dark.png from a debug build in
# demo mode (fixed example addresses, no network changes). Run it after changing the UI.
#
# macOS asks your terminal app for Screen Recording permission the first time.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build
BIN="$(swift build --show-bin-path)/IPv6Switch"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Prints the on-screen window number belonging to a process ID.
cat > "$TMP/window-id.swift" <<'SWIFT'
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
for w in windows where w[kCGWindowOwnerPID as String] as? Int == pid && w[kCGWindowLayer as String] as? Int == 0 {
    print(w[kCGWindowNumber as String]!)
    break
}
SWIFT
swiftc "$TMP/window-id.swift" -o "$TMP/window-id"

mkdir -p docs
for mode in light dark; do
  IPV6SWITCH_DEMO="$mode" "$BIN" &
  pid=$!
  id=""
  for _ in $(seq 50); do
    id="$("$TMP/window-id" "$pid")"
    [[ -n "$id" ]] && break
    sleep 0.2
  done
  if [[ -z "$id" ]]; then
    kill "$pid"
    echo "error: the app window never appeared" >&2
    exit 1
  fi
  sleep 1 # let SwiftUI finish layout and the window become active
  screencapture -x -o -l"$id" "docs/screenshot-$mode.png"
  kill "$pid"
  wait "$pid" 2>/dev/null || true
  echo "Saved docs/screenshot-$mode.png"
done
