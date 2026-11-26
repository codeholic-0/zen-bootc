#!/usr/bin/env bash
# Image smoke checks for zen-bootc.
#
# Runs INSIDE the built image; the script itself is fed on stdin so it is not
# baked into the image (the image stays a normal bootc image):
#
#   podman run --rm -i "$IMAGE:latest" /bin/bash -s < .github/scripts/smoke.sh
#
# Failures are labelled (ok / FAIL) and the failing command is traced, so the
# Actions log says which invariant broke instead of just "exit code 1".

set -Eeuo pipefail

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

# Fedora major version is baked as ENV FEDORA_VER in the Containerfile.
VER=${FEDORA_VER:?FEDORA_VER not set in image}

# Package, debloat, service, flathub, symlink and lint invariants are asserted
# at build time by build_scripts/base/90-validation.sh; this script covers the
# runtime-facing image contract only.

# --- Image invariants ---
check "os-release NAME"              grep -q '^NAME="ZenC OS"' /etc/os-release
check "os-release VERSION_ID ${VER}" grep -q "^VERSION_ID=${VER}$" /etc/os-release
check "PRETTY_NAME ZenC OS ${VER}"   grep -qx "PRETTY_NAME=\"ZenC OS ${VER} (KDE Plasma Desktop)\"" /usr/lib/os-release

check "zen-ctl syntax"               bash -n /usr/bin/zen-ctl
check "zen-ctl executable"           test -x /usr/bin/zen-ctl
check "zen-ctl help"                 zen-ctl help
check "zen-ctl cron"                 test -f /etc/cron.d/zen-ctl
check "zen-ctl cron wiring"          grep -q 'root /usr/bin/zen-ctl check' /etc/cron.d/zen-ctl

check "bootc on PATH"                command -v bootc
check "jq on PATH"                   command -v jq

# Fastfetch branding
check "fastfetch config"             test -s /etc/fastfetch/config.jsonc
check "fastfetch logo"               test -s /usr/share/zen-bootc/branding/zenc.txt
check "fastfetch logo wired"         test -f "$(jq -r '.logo.source' /etc/fastfetch/config.jsonc)"
check "fastfetch renders"            fastfetch --pipe false

# Client-side signature verification
check "policy sigstoreSigned"        grep -q sigstoreSigned /etc/containers/policy.json
check "cosign public key"            test -f /usr/share/containers/cosign.pub
check "docker group"                 grep -q '^g docker' /usr/lib/sysusers.d/zen-bootc.conf

# --- Toolchain (baked into the only image) ---
check "gcc on PATH"                  command -v gcc
check "g++ on PATH"                  command -v g++
check "make on PATH"                 command -v make
check "cmake on PATH"                command -v cmake
check "gdb on PATH"                  command -v gdb
check "python3 on PATH"              command -v python3
check "codium on PATH"               command -v codium
check "vscodium repo"                grep -q vscodium /etc/yum.repos.d/vscodium.repo
check "autoconf on PATH"             command -v autoconf
check "shellcheck on PATH"           command -v shellcheck
check "gh on PATH"                   command -v gh
check "nvim on PATH"                 command -v nvim
check "yq on PATH"                   command -v yq
check "sqlite3 on PATH"              command -v sqlite3
check "iverilog on PATH"             command -v iverilog
check "verilator on PATH"            command -v verilator
check "gtkwave on PATH"              command -v gtkwave

echo "smoke: all checks passed"
