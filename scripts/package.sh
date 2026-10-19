#!/usr/bin/env bash
set -euo pipefail

ESR=$(curl -s https://product-details.mozilla.org/1.0/thunderbird_versions.json | python3 -c "import sys,json; print(json.load(sys.stdin)['THUNDERBIRD_ESR'])")
VER="${ESR%esr}"
REPO="${GITHUB_WORKSPACE:-/home/natalie/.ai/.src/k9-desktop}"
DIST="$REPO/dist"
mkdir -p "$DIST"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

EXCLUDES=(--exclude=.git --exclude=.github --exclude=scripts --exclude=dist)

# --- Arch Linux tarball (.pkg.tar.zst) ---
tar --zstd -cf "$DIST/k9-desktop-${VER}-x86_64.pkg.tar.zst" -C "$REPO" "${EXCLUDES[@]}" .
echo "Created Arch tarball"

# --- Debian package (.deb) ---
DEB="$WORK/k9-desktop_${VER}_amd64"
mkdir -p "$DEB/DEBIAN" "$DEB/opt/k9-desktop"
cp -a "$REPO"/. "$DEB/opt/k9-desktop/"
# remove excluded dirs from payload
rm -rf "$DEB/opt/k9-desktop/.git" "$DEB/opt/k9-desktop/.github" "$DEB/opt/k9-desktop/scripts" "$DEB/opt/k9-desktop/dist"
cat > "$DEB/DEBIAN/control" <<EOF
Package: k9-desktop
Version: ${VER}
Section: mail
Priority: optional
Architecture: amd64
Maintainer: AcreetionOS <k9-desktop@acreetionos.org>
Description: K9Desktop mail client based on Mozilla Thunderbird LTS
EOF
dpkg-deb --build "$DEB" "$DIST/k9-desktop_${VER}_amd64.deb"
echo "Created deb"

# --- RPM package (.rpm) ---
if command -v rpmbuild >/dev/null 2>&1; then
  RPMBUILD="$WORK/rpmbuild"
  mkdir -p "$RPMBUILD"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  mkdir -p "$WORK/k9-desktop-${VER}"
  cp -a "$REPO"/. "$WORK/k9-desktop-${VER}/"
  rm -rf "$WORK/k9-desktop-${VER}/.git" "$WORK/k9-desktop-${VER}/.github" "$WORK/k9-desktop-${VER}/scripts" "$WORK/k9-desktop-${VER}/dist"
  tar -czf "$RPMBUILD/SOURCES/k9-desktop-${VER}.tar.gz" -C "$WORK" "k9-desktop-${VER}"
  cat > "$RPMBUILD/SPECS/k9-desktop.spec" <<EOF
Name: k9-desktop
Version: ${VER}
Release: 1
Summary: K9Desktop mail client based on Mozilla Thunderbird LTS
License: MPL-2.0
BuildArch: x86_64
Source0: k9-desktop-${VER}.tar.gz
%global debug_package %{nil}

%description
K9Desktop mail client based on Mozilla Thunderbird LTS.

%prep
%setup -q

%install
mkdir -p %{buildroot}/opt/k9-desktop
cp -a . %{buildroot}/opt/k9-desktop/

%files
/opt/k9-desktop

%changelog
* $(date '+%a %b %d %Y') AcreetionOS <k9-desktop@acreetionos.org> - ${VER}-1
- Autobuild based on Mozilla Thunderbird LTS
EOF
  rpmbuild --define "_topdir $RPMBUILD" -bb "$RPMBUILD/SPECS/k9-desktop.spec"
  find "$RPMBUILD/RPMS" -name '*.rpm' -exec cp {} "$DIST/" \;
  echo "Created rpm (if rpmbuild succeeded)"
else
  echo "rpmbuild not available; skipping rpm"
fi

ls -lh "$DIST"