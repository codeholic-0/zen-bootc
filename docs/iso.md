# Installer ISO

Manual-dispatch CI builds a bootable network-installer ISO for the single
`zen-bootc:latest` image and publishes it to SourceForge. Config:
[`disk_config/iso-kde.toml`](../disk_config/iso-kde.toml).

## CI

```bash
gh workflow run iso-publish.yaml --ref main
```

One dispatch builds one ISO for `:latest` — no variant selection or extra inputs.
The Actions UI exposes the same plain "Run workflow" button.

- Press only when the latest image run is green and signed: the workflow
  cosign-verifies `:latest` before building and refuses to publish an installer
  for an unsigned image.
- Output (run summary has the URL):
  `https://sourceforge.net/projects/zen-bootc/files/<YYYY-MM-DD>/zen-bootc-<YYYYMMDD>-<sha7>.iso/download`
- Each ISO ships its own `<name>.iso.sha256` beside it (verify with
  `sha256sum -c <name>.iso.sha256`).
- Secrets: `SF_SSH_PRIVATE_KEY`, `SF_USERNAME`.
- Known constraints: runner pinned to `ubuntu-24.04` (26.04 AppArmor breaks
  osbuild mounts); BIB pinned by digest; frs accepts rsync/sftp only.

## Local build

BIB is pinned to the same digest as CI. `bootc-image-builder:latest` is not a
drop-in replacement here: newer BIB derives installer repos from `ID=zenc`,
which fails with `requested repository not found: for distribution "zenc-45"`.

```bash
sudo podman pull ghcr.io/codeholic-0/zen-bootc:latest
mkdir -p output
sudo podman run --rm -it --privileged \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(pwd)/disk_config/iso-kde.toml:/config.toml:ro" \
  quay.io/centos-bootc/bootc-image-builder@sha256:dab86ee6b46dcade411b37f4e70b07d93b6a06da0dbfec6fe89247a220e0d9f8 \
  --rootfs ext4 --type anaconda-iso \
  ghcr.io/codeholic-0/zen-bootc:latest
```

Output: `output/bootiso/install.iso`. BIB doesn't auto-pull — the target tag
must be in storage first. The installer content is whatever image you pass, but
the kickstart `%post` always pins the installed system to `:latest` (network
required), so build from `:latest` unless you deliberately want otherwise.

## Install

Boot → interactive Anaconda (locale, keyboard, timezone, partitioning, user).
`%post`: `bootc switch` to `ghcr.io/codeholic-0/zen-bootc:latest` (network
required). Flathub is baked into the image; optional user-local tooling is
installed with `zctl zdev`.
