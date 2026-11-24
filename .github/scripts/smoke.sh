#!/usr/bin/env bash
# Image smoke checks for zen-bootc.
#
# Runs INSIDE the built image; the script itself is fed on stdin so it is not
# baked into the image (the image stays a normal bootc image):
#
#   podman run --rm -i "$IMAGE:$TAG" /bin/bash -s -- "$ROLE" \
#     < .github/scripts/smoke.sh
#
# $1 = flavor role (testing|final|dev). "dev" adds the toolchain checks.
#
# Failures are labelled (ok / FAIL) and the failing command is traced, so the
# Actions log says which invariant broke instead of just "exit code 1".

set -Eeuo pipefail

ROLE=${1:-}

trap 'rc=$?; printf "smoke: FAILED (line %s, rc %s): %s\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2' ERR

check() {
    local desc=$1; shift
    local out
    if out=$("$@" 2>&1); then
        printf '  ok: %s\n' "$desc"
    else
        printf '  FAIL: %s\n' "$desc" >&2
        [ -n "$out" ] && printf '%s\n' "$out" >&2
        exit 1
    fi
}

# --- Base image invariants (testing, final, dev) ---
# PRETTY_NAME differs by flavor ("ZenC OS 45" vs "ZenC OS 45 (KDE Plasma
# Desktop)"), so match the prefix; VERSION_ID is identical on both.
check "os-release NAME"         grep -q '^NAME="ZenC OS"' /etc/os-release
check "os-release VERSION_ID"   grep -q '^VERSION_ID=45$' /etc/os-release
check "PRETTY_NAME ZenC OS 45"  grep -q '^PRETTY_NAME="ZenC OS 45' /usr/lib/os-release
check "os-release symlink"      test "$(readlink /etc/os-release)" = "../usr/lib/os-release"

check "zen-ctl syntax"          bash -n /usr/bin/zen-ctl
check "zen-ctl executable"      test -x /usr/bin/zen-ctl
check "zen-ctl help"            zen-ctl help
check "zen-ctl cron"            test -f /etc/cron.d/zen-ctl

check "bootc on PATH"           command -v bootc
check "jq on PATH"              command -v jq

check "policy sigstoreSigned"   grep -q sigstoreSigned /etc/containers/policy.json
check "cosign public key"       test -f /usr/share/containers/cosign.pub
check "docker group"            grep -q '^g docker' /usr/lib/sysusers.d/zen-bootc.conf

# --- Dev flavor: toolchain + VSCodium layer ---
if [ "$ROLE" = dev ]; then
    check "gcc on PATH"         command -v gcc
    check "make on PATH"        command -v make
    check "cmake on PATH"       command -v cmake
    check "python3 on PATH"     command -v python3
    check "codium on PATH"      command -v codium
    check "vscodium repo"       grep -q vscodium /etc/yum.repos.d/vscodium.repo
fi

echo "smoke: all checks passed"
