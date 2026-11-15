# K9Desktop

K9Desktop is a mail client based on Mozilla Thunderbird LTS, rebranded for AcreetionOS.

## What this repository contains

- The Thunderbird ESR application tree (binaries tracked with Git LFS).
- `scripts/autobuild.sh` — downloads the latest Thunderbird ESR release, rebrands it as K9Desktop, and commits the result.
- `scripts/package.sh` — packages the tree as `.deb`, `.rpm`, and Arch `.pkg.tar.zst`.
- `scripts/validate-packages.sh` — validates produced packages before release.
- `.github/workflows/autobuild.yml` — weekly GitHub Actions pipeline (free tier).

## Automation

The `K9Desktop Autobuild` workflow runs weekly (or on manual dispatch) in an `archlinux:latest` container:

1. Install build dependencies (`git`, `git-lfs`, `dpkg`, `rpm-tools`, etc.).
2. Clone the repository and pull LFS objects.
3. Run `scripts/autobuild.sh` to fetch the latest Thunderbird ESR tarball, rebrand binaries (`thunderbird` → `k9`), sanitize paths, write branded `application.ini`/`platform.ini`, commit, tag, and push.
4. Run `scripts/package.sh` to build deb, rpm, and Arch packages.
5. Run `scripts/validate-packages.sh` to verify metadata and desktop integration.
6. Create or update the GitHub release for that version and upload all artifacts.

## Packaging

Each package installs the application under `/opt/k9-desktop` (deb/rpm) or the system root (Arch) and adds:
- `/usr/bin/k9` launcher symlink
- `.desktop` entry and icons under `/usr/share`

## Building locally

```bash
git lfs pull
./scripts/package.sh
./scripts/validate-packages.sh dist
```

Requires `bsdtar`, `dpkg-deb`, and `rpmbuild` (Arch: `dpkg`, `rpm-tools`).