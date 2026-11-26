FROM scratch AS build_ctx
COPY build_scripts /build_scripts

FROM quay.io/fedora-ostree-desktops/kinoite:45

ARG FEDORA_VER=45
ENV FEDORA_VER="${FEDORA_VER}"

# System-wide metadata
# OCI labels self-document the image on GHCR/tooling.
LABEL org.opencontainers.image.title="zen-bootc" \
      org.opencontainers.image.description="ZenC OS" \
      org.opencontainers.image.vendor="codeholic-0" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/codeholic-0/zen-bootc" \
      org.opencontainers.image.url="https://github.com/codeholic-0/zen-bootc"

# Plymouth boot splash 
# kargs side lives in files/usr/lib/bootc/kargs.d/10-plymouth.toml (rhgb quiet).
COPY files/usr/lib/bootc/kargs.d/10-plymouth.toml /usr/lib/bootc/kargs.d/10-plymouth.toml
RUN plymouth-set-default-theme breeze

# VSCodium Repo
COPY files/etc/yum.repos.d/vscodium.repo /etc/yum.repos.d/vscodium.repo

# Custom Fetch Logo
COPY files/etc/fastfetch/config.jsonc /etc/fastfetch/config.jsonc
COPY files/usr/share/zen-bootc/branding/zenc.txt /usr/share/zen-bootc/branding/zenc.txt

# Branding: ZenC OS 
# /etc/os-release ships as ../usr/lib/os-release symlink (asserted below).
COPY files/usr/lib/os-release /usr/lib/os-release

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

# Install & Configure
RUN --mount=type=bind,from=build_ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5,sharing=locked \
    /ctx/build_scripts/shared/build-prep.sh && \
    /ctx/build_scripts/base/00-repos.sh && \
    /ctx/build_scripts/base/10-packages.sh && \
    /ctx/build_scripts/base/20-multimedia.sh && \
    /ctx/build_scripts/base/30-services.sh

# Clean Up
RUN --mount=type=bind,from=build_ctx,source=/,target=/ctx \
    /ctx/build_scripts/shared/cleanup.sh

# Validate
RUN --mount=type=bind,from=build_ctx,source=/,target=/ctx \
    /ctx/build_scripts/base/90-validation.sh