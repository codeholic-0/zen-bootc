FROM quay.io/fedora-ostree-desktops/kinoite:45
ENV FEDORA_VER="45"

# System-wide metadata
# OCI labels self-document the image on GHCR/tooling.
LABEL org.opencontainers.image.title="zen-bootc" \
      org.opencontainers.image.description="ZenC OS Stable Version" \
      org.opencontainers.image.vendor="codeholic-0" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/codeholic-0/zen-bootc" \
      org.opencontainers.image.url="https://github.com/codeholic-0/zen-bootc"


# dnf plugins, rpmfusion & copr repos
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y install dnf-plugins-core dnf5-plugins

RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VER.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VER.noarch.rpm" \
    && dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo \
    && dnf copr enable imput/helium -y \
    && dnf config-manager setopt 'rpmfusion-free.enabled=1' 'rpmfusion-free-updates.enabled=1' \
        'rpmfusion-nonfree.enabled=1' 'rpmfusion-nonfree-updates.enabled=1' \
    && dnf config-manager setopt fedora-cisco-openh264.enabled=1 \
    && dnf install -y --refresh rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted \
    && dnf makecache

# Bridged repos for the ISO depsolver 
# BIB's depsolver only reads /etc/yum.repos.d; base puts repo defs in
# /usr/share/dnf5/repos.d — without this bridge anaconda-iso builds fail.
RUN cp /usr/share/dnf5/repos.d/*.repo /etc/yum.repos.d/


# KDE Debloat
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y remove \
    akonadi-server \
    akonadi-server-mysql \
    fedora-bookmarks \
    fedora-chromium-config \
    fedora-chromium-config-kde \
    firefox \
    kcharselect \
    khelpcenter \
    plasma-discover \
    plasma-welcome \
    plasma-welcome-fedora \
    xwaylandvideobridge \
    kwrite \
    krfb \
    && dnf -y autoremove

# Codecs & multimedia framework 
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y swap ffmpeg-free ffmpeg --allowerasing \
    && dnf -y install @multimedia

# Plymouth boot splash 
# kargs side lives in plymouth.toml (rhgb quiet).
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y install \
        plymouth \
        plymouth-system-theme \
        plymouth-theme-breeze

RUN plymouth-set-default-theme breeze

# Media & personal apps
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y install \
        mediawriter \
        gthumb \
        yt-dlp \
        vlc \
        zenity \
        kate \
        guvcview

# Containers 
# Flatpak Setup
RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y install \
        docker-ce \
        docker-compose-plugin \
        docker-buildx-plugin \
        podman \
        podman-compose \
        flatpak \
        fedora-flathub-remote \
        fedora-workstation-repositories \
        fedora-third-party

RUN flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak remote-modify --system --enable flathub


# Shell Utils & Tooling
# distrobox is the explicit dev userland (image carries no dev toolchain).

RUN --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    dnf -y install \
    udisks2-btrfs libblockdev-btrfs cryfs \
    earlyoom cronie cronie-anacron crontabs lm_sensors \
    zsh git distrobox\
    btop fastfetch plocate bat eza fd-find fzf ripgrep zoxide dos2unix smem scrub

# Custom Fetch Logo
COPY files/etc/fastfetch/config.jsonc /etc/fastfetch/config.jsonc
COPY files/usr/share/zen-bootc/branding/zenc.txt /usr/share/zen-bootc/branding/zenc.txt

# Enable Services 
RUN systemctl enable NetworkManager.service plasmalogin.service docker.service earlyoom.service crond.service -f

# Branding: ZenC OS 
# /etc/os-release ships as ../usr/lib/os-release symlink (asserted below).
COPY files/usr/lib/os-release /usr/lib/os-release
RUN [ "$(readlink /etc/os-release)" = "../usr/lib/os-release" ]

# Client-side signature verification
# /etc/containers/ is the bootc-supported location (/usr/etc fails lint).
# signedIdentity=matchRepository is required for cosign (signs the repo, not
# the tag). registries.d enables .sig attachment downloads for ghcr.io.
RUN mkdir -p /etc/containers/registries.d /usr/share/containers
COPY policy.json /etc/containers/policy.json
COPY cosign.pub /usr/share/containers/cosign.pub
COPY registries.d/zen-bootc.yaml /etc/containers/registries.d/zen-bootc.yaml

# Composefs: systemd-remount-fs skip drop-in 
COPY files/usr/lib/systemd/system/systemd-remount-fs.service.d/10-composefs-skip.conf \
     /usr/lib/systemd/system/systemd-remount-fs.service.d/10-composefs-skip.conf

# sysusers: declare docker group (docker-ce creates it via scriptlet) 
COPY files/usr/lib/sysusers.d/zen-bootc.conf /usr/lib/sysusers.d/zen-bootc.conf

# zen-ctl: upgrade check/status/apply CLI + weekly cron
COPY files/usr/bin/zen-ctl /usr/bin/zen-ctl
COPY files/etc/cron.d/zen-ctl /etc/cron.d/zen-ctl
RUN chmod 0755 /usr/bin/zen-ctl && chmod 0644 /etc/cron.d/zen-ctl

# Build-hygiene cleanup 
# No dnf clean all (cache mounts): purge runtime-only state. /var/cache/* is
# build residue — regenerates on demand at runtime (also satisfies lint
# var-tmpfiles). /run must exclude /run/systemd* — buildah bind-mounts DNS
# files there ("Device or resource busy").
RUN rm -rf \
        /var/log/dnf5.log* \
        /var/lib/dnf \
        /var/lib/flatpak/repo/tmp \
        /var/cache/* \
    && find /run -mindepth 1 ! -path '/run/systemd*' ! -name '.containerenv' -exec rm -rf {} +

# Bootc conformance lint 
RUN bootc container lint
