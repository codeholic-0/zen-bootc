#!/bin/bash
# zdev installer — fetches the latest zdev into ~/.local/bin.
#
# Usage (documented one-liner, works on any flavor):
#   curl -fsSL https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/zdev-install.sh | bash
#
# Trust posture: latest main over TLS — the same class as the upstream
# installers zdev itself drives (brew/sdkman/nvm). The OS image keeps
# its full cosign/policy chain; this is user tooling in $HOME.
set -eu

URL="https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/zdev"
TARGET="$HOME/.local/bin/zdev"

mkdir -p "$(dirname "$TARGET")"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$URL" -o "$tmp"
bash -n "$tmp"
grep -q '^# zdev' "$tmp"   # never install a 404 page / wrong file
mv "$tmp" "$TARGET" && chmod 0755 "$TARGET"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) echo "zdev: note: $HOME/.local/bin is not in PATH" >&2 ;;
esac
echo "zdev installed at $TARGET"
echo "  zdev            list tools + install state"
echo "  zdev update     self-update from the repo"
