#!/usr/bin/bash
set -Eeuo pipefail

log_group() {
    echo "::group:: === ${1} ==="
}

log_group_end() {
    echo "::endgroup::"
}

require_root() {
    (( EUID == 0 )) || {
        echo "This script must run as root" >&2
        exit 1
    }
}

require_command() {
    command -v "$1" >/dev/null || {
        echo "Required command not found: $1" >&2
        exit 1
    }
}

dnf_install() {
    dnf -y install "$@"
}

dnf_remove() {
    dnf -y remove "$@"
}