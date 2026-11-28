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
check "copr vendor override" grep -q '^distribution = fedora$' /usr/share/dnf/plugins/copr.vendor.conf

check "zctl syntax"               bash -n /usr/bin/zctl
check "zctl executable"           test -x /usr/bin/zctl
check "zctl help"                 zctl help
check "zctl cron"                 test -f /etc/cron.d/zctl
check "zctl cron wiring"          grep -q 'root /usr/bin/zctl check' /etc/cron.d/zctl

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
check "ca-trust regen enabled"       test -e /etc/systemd/system/sysinit.target.wants/bootc-update-ca-trust.service
check "crypto-policy regen enabled"  test -e /etc/systemd/system/sysinit.target.wants/bootc-update-crypto-policies.service
check "docker socket enabled"        test -e /etc/systemd/system/sockets.target.wants/docker.socket
check "podman socket enabled"        test -e /etc/systemd/system/sockets.target.wants/podman.socket

# --- Toolchain (baked into the only image) ---
check "gcc on PATH"                  command -v gcc
check "g++ on PATH"                  command -v g++
check "make on PATH"                 command -v make
check "cmake on PATH"                command -v cmake
check "just on PATH"                 command -v just
check "gdb on PATH"                  command -v gdb
check "python3 on PATH"              command -v python3
check "codium on PATH"               command -v codium
check "vscodium repo"                grep -q vscodium /etc/yum.repos.d/vscodium.repo
check "codium product.json valid"    jq -e . /usr/share/codium/resources/app/product.json
check "codium gallery overridden"    jq -e '.extensionsGallery.serviceUrl == "https://marketplace.visualstudio.com/_apis/public/gallery"' /usr/share/codium/resources/app/product.json
check "autoconf on PATH"             command -v autoconf
check "shellcheck on PATH"           command -v shellcheck
check "xdg-terminal-exec on PATH"    command -v xdg-terminal-exec
check "gh on PATH"                   command -v gh
check "nvim on PATH"                 command -v nvim
check "yq on PATH"                   command -v yq
check "sqlite3 on PATH"              command -v sqlite3
check "iverilog on PATH"             command -v iverilog
check "verilator on PATH"            command -v verilator
check "gtkwave on PATH"              command -v gtkwave

echo "smoke: all checks passed"
