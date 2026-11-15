#!/usr/bin/env bash
set -euo pipefail

ESR=$(curl -s https://product-details.mozilla.org/1.0/thunderbird_versions.json | python3 -c "import sys,json; print(json.load(sys.stdin)['THUNDERBIRD_ESR'])")
VER="${ESR%esr}"
REPO="${GITHUB_WORKSPACE:-/home/natalie/.ai/.src/k9-desktop}"
DIST="$REPO/dist"
mkdir -p "$DIST"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BUILD_DATE="$(date +%s)"

rebrand_omni() {
  local omni="$1"
  [ -f "$omni" ] || return 0
  # skip LFS pointer
  if head -c 100 "$omni" | grep -q "git-lfs"; then return 0; fi
  if ! command -v zip >/dev/null 2>&1; then return 0; fi
  local tmp
  tmp="$(mktemp -d)"
  bsdtar -xf "$omni" -C "$tmp" 2>/dev/null || { rm -rf "$tmp"; return 0; }
  if [ -f "$tmp/chrome/en-US/locale/branding/brand.properties" ]; then
    cat > "$tmp/chrome/en-US/locale/branding/brand.properties" <<'BRAND'
brandShortName=K9Desktop
brandShorterName=K9Desktop
brandFullName=K9Desktop
vendorShortName=AcreetionOS
BRAND
  fi
  if [ -f "$tmp/localization/en-US/branding/brand.ftl" ]; then
    cat > "$tmp/localization/en-US/branding/brand.ftl" <<'BRANDFTL'
-brand-shorter-name = K9Desktop
-brand-short-name = K9Desktop
-brand-full-name = K9Desktop
-brand-product-name = K9Desktop
-vendor-short-name = AcreetionOS
trademarkInfo = K9Desktop is a de-telemetered build of Mozilla Thunderbird for AcreetionOS.
BRANDFTL
  fi
  if [ -f "$tmp/defaults/pref/thunderbird-branding.js" ]; then
    cat > "$tmp/defaults/pref/thunderbird-branding.js" <<'BRANDJS'
// K9Desktop branding (replaces thunderbird-branding.js)
pref("mailnews.start_page.url", "https://acreetionos.org/");
pref("app.vendorURL", "https://acreetionos.org/");
pref("mail.inappnotifications.url", "");
pref("app.update.url.manual", "https://github.com/spivanatalie64/k9-desktop/releases");
pref("app.update.url.details", "https://github.com/spivanatalie64/k9-desktop/releases");
BRANDJS
  fi
  for s in 32 48 64 128 256; do
    if [ -f "$REPO/chrome/icons/default/default${s}.png" ] && [ -f "$tmp/chrome/messenger/content/branding/icon${s}.png" ]; then
      cp -f "$REPO/chrome/icons/default/default${s}.png" "$tmp/chrome/messenger/content/branding/icon${s}.png"
    fi
  done
  if [ -f "$REPO/chrome/icons/default/default256.png" ]; then
    for f in "$tmp/chrome/messenger/content/branding/about-logo.png" "$tmp/chrome/messenger/content/branding/about.png"; do
      [ -f "$f" ] && cp -f "$REPO/chrome/icons/default/default256.png" "$f"
    done
    if [ -f "$tmp/chrome/messenger/content/branding/about-logo@2x.png" ] && command -v magick >/dev/null 2>&1; then
      magick "$REPO/chrome/icons/default/default256.png" -resize 512x512 "$tmp/chrome/messenger/content/branding/about-logo@2x.png" 2>/dev/null || cp -f "$REPO/chrome/icons/default/default256.png" "$tmp/chrome/messenger/content/branding/about-logo@2x.png"
    fi
  fi
  if [ -f "$tmp/modules/OAuth2Providers.sys.mjs" ]; then
    sed -i 's/useExternalBrowser: true/useExternalBrowser: false/g' "$tmp/modules/OAuth2Providers.sys.mjs" || true
  fi
  local out
  out="$(mktemp)"
  (cd "$tmp" && zip -qr -0 "$out" .)
  cat "$out" > "$omni"
  rm -rf "$tmp" "$out"
}

DESKTOP_FILE='[Desktop Entry]
Name=K9Desktop
Comment=K9Desktop mail client based on Mozilla Thunderbird LTS
Exec=k9 %u
Type=Application
Icon=k9-desktop
Terminal=false
Categories=Network;Email;
MimeType=x-scheme-handler/mailto;
StartupNotify=true
'

# --- Arch Linux package (.pkg.tar.zst) ---
ARCHSTAGE="$WORK/arch"
mkdir -p "$ARCHSTAGE/opt/k9-desktop"
cp -a "$REPO"/. "$ARCHSTAGE/opt/k9-desktop/"
rm -rf "$ARCHSTAGE/opt/k9-desktop/.git" "$ARCHSTAGE/opt/k9-desktop/.github" "$ARCHSTAGE/opt/k9-desktop/scripts" "$ARCHSTAGE/opt/k9-desktop/dist"
rm -f "$ARCHSTAGE/opt/k9-desktop/pingsender" "$ARCHSTAGE/opt/k9-desktop/crashreporter" "$ARCHSTAGE/opt/k9-desktop/crashhelper"
rebrand_omni "$ARCHSTAGE/opt/k9-desktop/omni.ja"

ARCH_SIZE="$(find "$ARCHSTAGE" -type f ! -name .PKGINFO ! -name .BUILDINFO ! -name .MTREE -printf '%s\n' | awk '{s+=$1} END {print s+0}')"

cat > "$ARCHSTAGE/.PKGINFO" <<EOF
pkgbase = k9-desktop
pkgname = k9-desktop
pkgver = ${VER}-1
pkgdesc = K9Desktop mail client based on Mozilla Thunderbird LTS
url = https://github.com/spivanatalie64/k9-desktop
builddate = ${BUILD_DATE}
packager = AcreetionOS <k9-desktop@acreetionos.org>
size = ${ARCH_SIZE}
arch = x86_64
license = MPL-2.0
EOF

cat > "$ARCHSTAGE/.BUILDINFO" <<EOF
format = 1
pkgname = k9-desktop
pkgbase = k9-desktop
pkgver = ${VER}-1
pkgarch = x86_64
builddate = ${BUILD_DATE}
packager = AcreetionOS <k9-desktop@acreetionos.org>
EOF

# desktop integration
mkdir -p "$ARCHSTAGE/usr/bin" \
         "$ARCHSTAGE/usr/share/applications" \
         "$ARCHSTAGE/usr/share/icons/hicolor/256x256/apps" \
         "$ARCHSTAGE/usr/share/icons/hicolor/scalable/apps"
ln -sfn '../../opt/k9-desktop/k9' "$ARCHSTAGE/usr/bin/k9"
cp -f "$REPO/chrome/icons/default/default256.png" "$ARCHSTAGE/usr/share/icons/hicolor/256x256/apps/k9-desktop.png"
cp -f "$REPO/chrome/icons/default/TB-symbolic.svg" "$ARCHSTAGE/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg"
printf '%s\n' "$DESKTOP_FILE" > "$ARCHSTAGE/usr/share/applications/k9-desktop.desktop"

# libalpm requires the metadata entries (.BUILDINFO/.MTREE/.PKGINFO) to be FIRST
# in the archive with clean names (no "./" prefix). Mirror the layout produced
# by makepkg. Note: bsdtar only honors -T as a file list when it appears BEFORE
# any member operands, so everything goes in one ordered list.
bsdtar -cPf - --format=mtree --uid 0 --gid 0 --uname root --gname root \
    --options='!all,use-set,type,link,uid,gid,uname,gname,mode,size,time,sha256digest' \
    --exclude=.MTREE -C "$ARCHSTAGE" .BUILDINFO .PKGINFO . | gzip -c > "$ARCHSTAGE/.MTREE"
{
  printf '%s\n' .BUILDINFO .MTREE .PKGINFO
  (cd "$ARCHSTAGE" && find . -mindepth 1 -maxdepth 1 \
      ! -name .BUILDINFO ! -name .MTREE ! -name .PKGINFO \
      -printf '%P\n' | sort)
} > "$WORK/pkglist"
(cd "$ARCHSTAGE" && bsdtar --zstd -cf "$DIST/k9-desktop-${VER}-x86_64.pkg.tar.zst" \
    --uid 0 --gid 0 --uname root --gname root -T "$WORK/pkglist")
echo "Created Arch package"

# --- Debian package (.deb) ---
DEB="$WORK/k9-desktop_${VER}_amd64"
mkdir -p "$DEB/DEBIAN" "$DEB/opt/k9-desktop"
cp -a "$REPO"/. "$DEB/opt/k9-desktop/"
rm -rf "$DEB/opt/k9-desktop/.git" "$DEB/opt/k9-desktop/.github" "$DEB/opt/k9-desktop/scripts" "$DEB/opt/k9-desktop/dist"
rm -f "$DEB/opt/k9-desktop/pingsender" "$DEB/opt/k9-desktop/crashreporter" "$DEB/opt/k9-desktop/crashhelper"
rebrand_omni "$DEB/opt/k9-desktop/omni.ja"

DEB_SIZE_KB=0
while IFS= read -r -d '' obj; do
  if [ -L "$obj" ] || [ -f "$obj" ]; then
    sz=$(stat -c '%s' "$obj" 2>/dev/null || echo 0)
    DEB_SIZE_KB=$((DEB_SIZE_KB + (sz + 1023) / 1024))
  else
    DEB_SIZE_KB=$((DEB_SIZE_KB + 1))
  fi
done < <(find "$DEB" -path "$DEB/DEBIAN" -prune -o -mindepth 1 -print0)
# ensure at least 1 KiB baseline
[ "$DEB_SIZE_KB" -gt 0 ] || DEB_SIZE_KB=1

cat > "$DEB/DEBIAN/control" <<EOF
Package: k9-desktop
Version: ${VER}
Section: mail
Priority: optional
Architecture: amd64
Installed-Size: ${DEB_SIZE_KB}
Maintainer: AcreetionOS <k9-desktop@acreetionos.org>
Description: K9Desktop mail client based on Mozilla Thunderbird LTS
EOF

# desktop integration
mkdir -p "$DEB/usr/bin" \
         "$DEB/usr/share/applications" \
         "$DEB/usr/share/icons/hicolor/256x256/apps" \
         "$DEB/usr/share/icons/hicolor/scalable/apps"
ln -sfn '../../opt/k9-desktop/k9' "$DEB/usr/bin/k9"
cp -f "$REPO/chrome/icons/default/default256.png" "$DEB/usr/share/icons/hicolor/256x256/apps/k9-desktop.png"
cp -f "$REPO/chrome/icons/default/TB-symbolic.svg" "$DEB/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg"
printf '%s\n' "$DESKTOP_FILE" > "$DEB/usr/share/applications/k9-desktop.desktop"

dpkg-deb --build "$DEB" "$DIST/k9-desktop_${VER}_amd64.deb"
echo "Created deb"

# --- RPM package (.rpm) ---
if command -v rpmbuild >/dev/null 2>&1; then
  RPMBUILD="$WORK/rpmbuild"
  mkdir -p "$RPMBUILD"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
  mkdir -p "$WORK/k9-desktop-${VER}"
  cp -a "$REPO"/. "$WORK/k9-desktop-${VER}/"
  rm -rf "$WORK/k9-desktop-${VER}/.git" "$WORK/k9-desktop-${VER}/.github" "$WORK/k9-desktop-${VER}/scripts" "$WORK/k9-desktop-${VER}/dist"
  rm -f "$WORK/k9-desktop-${VER}/pingsender" "$WORK/k9-desktop-${VER}/crashreporter" "$WORK/k9-desktop-${VER}/crashhelper"
  rebrand_omni "$WORK/k9-desktop-${VER}/omni.ja"
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
mkdir -p %{buildroot}/usr/bin %{buildroot}/usr/share/applications %{buildroot}/usr/share/icons/hicolor/256x256/apps %{buildroot}/usr/share/icons/hicolor/scalable/apps
ln -s ../../opt/k9-desktop/k9 %{buildroot}/usr/bin/k9
cp chrome/icons/default/default256.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/k9-desktop.png
cp chrome/icons/default/TB-symbolic.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg
cat > %{buildroot}/usr/share/applications/k9-desktop.desktop <<'DESKTOP'
${DESKTOP_FILE}
DESKTOP

%files
/opt/k9-desktop
/usr/bin/k9
/usr/share/applications/k9-desktop.desktop
/usr/share/icons/hicolor/256x256/apps/k9-desktop.png
/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg

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

# --- Snap package (.snap) ---
SNAP="$WORK/k9-desktop_${VER}_snap"
rm -rf "$SNAP"
mkdir -p "$SNAP/meta/gui"
cp -a "$REPO"/. "$SNAP/"
rm -rf "$SNAP/.git" "$SNAP/.github" "$SNAP/scripts" "$SNAP/dist"
rm -f "$SNAP/pingsender" "$SNAP/crashreporter" "$SNAP/crashhelper"
rebrand_omni "$SNAP/omni.ja"
mkdir -p "$SNAP/meta/gui"
cp -f "$REPO/chrome/icons/default/default256.png" "$SNAP/meta/gui/icon.png"
cat > "$SNAP/meta/gui/k9-desktop.desktop" <<EOF
[Desktop Entry]
Name=K9Desktop
Comment=K9Desktop mail client based on Mozilla Thunderbird LTS
Exec=k9
Type=Application
Icon=k9-desktop
Terminal=false
Categories=Network;Email;
EOF
cat > "$SNAP/meta/snap.yaml" <<EOF
name: k9-desktop
version: "${VER}"
summary: K9Desktop mail client
description: Privacy-first mail client based on Mozilla Thunderbird LTS.
grade: stable
confinement: strict
base: core22
architectures:
  - build-on: amd64
    run-on: amd64
apps:
  k9-desktop:
    command: k9
    desktop: meta/gui/k9-desktop.desktop
    plugs: [home, network, desktop, desktop-legacy, wayland, x11]
EOF
if command -v mksquashfs >/dev/null 2>&1; then
  mksquashfs "$SNAP" "$DIST/k9-desktop_${VER}_amd64.snap" -noappend -comp xz -quiet
  echo "Created snap"
else
  echo "mksquashfs not available; skipping snap"
fi

# --- AppImage (.AppImage) ---
APPDIR="$WORK/K9Desktop.AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/lib/k9-desktop" "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp -a "$REPO"/. "$APPDIR/usr/lib/k9-desktop/"
rm -rf "$APPDIR/usr/lib/k9-desktop/.git" "$APPDIR/usr/lib/k9-desktop/.github" \
       "$APPDIR/usr/lib/k9-desktop/scripts" "$APPDIR/usr/lib/k9-desktop/dist"
rm -f "$APPDIR/usr/lib/k9-desktop/pingsender" "$APPDIR/usr/lib/k9-desktop/crashreporter" \
      "$APPDIR/usr/lib/k9-desktop/crashhelper"
rebrand_omni "$APPDIR/usr/lib/k9-desktop/omni.ja"
ln -sfn ../lib/k9-desktop/k9 "$APPDIR/usr/bin/k9"
cp -f "$REPO/chrome/icons/default/default256.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/k9-desktop.png"
cp -f "$REPO/chrome/icons/default/TB-symbolic.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg" 2>/dev/null || true
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"
cp -f "$REPO/chrome/icons/default/TB-symbolic.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/k9-desktop.svg"
cat > "$APPDIR/usr/share/applications/k9-desktop.desktop" <<EOF
$DESKTOP_FILE
EOF
cp "$APPDIR/usr/share/applications/k9-desktop.desktop" "$APPDIR/k9-desktop.desktop"
cp "$APPDIR/usr/share/icons/hicolor/256x256/apps/k9-desktop.png" "$APPDIR/k9-desktop.png"
ln -sfn usr/bin/k9 "$APPDIR/AppRun"
if ! command -v appimagetool >/dev/null 2>&1; then
  if curl -fsSL -o "$WORK/appimagetool" \
      "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" 2>/dev/null; then
    chmod +x "$WORK/appimagetool"
    APPIMAGETOOL="$WORK/appimagetool"
  else
    APPIMAGETOOL=""
  fi
else
  APPIMAGETOOL="appimagetool"
fi
if [ -n "$APPIMAGETOOL" ]; then
  ( cd "$WORK" && APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" \
      "$DIST/K9Desktop-${VER}-x86_64.AppImage" ) && echo "Created AppImage" || echo "AppImage build failed; skipping"
else
  echo "appimagetool not available; skipping AppImage"
fi

# --- Flatpak (.flatpak) ---
FLATPAK_STAGE="$WORK/flatpak-stage"
rm -rf "$FLATPAK_STAGE"
mkdir -p "$FLATPAK_STAGE"
cp -a "$REPO"/. "$FLATPAK_STAGE/"
rm -rf "$FLATPAK_STAGE/.git" "$FLATPAK_STAGE/.github" "$FLATPAK_STAGE/scripts" "$FLATPAK_STAGE/dist"
rm -f "$FLATPAK_STAGE/pingsender" "$FLATPAK_STAGE/crashreporter" "$FLATPAK_STAGE/crashhelper"
rebrand_omni "$FLATPAK_STAGE/omni.ja"
mkdir -p "$FLATPAK_STAGE/usr/share/applications" "$FLATPAK_STAGE/usr/share/icons/hicolor/256x256/apps"
# flatpak installs under /app; keep files at stage root and copy in build
cp -f "$REPO/chrome/icons/default/default256.png" "$FLATPAK_STAGE/icon.png"
cat > "$FLATPAK_STAGE/k9-desktop.desktop" <<EOF
$DESKTOP_FILE
EOF
cat > "$WORK/org.acreetionos.K9Desktop.yml" <<EOF
app-id: org.acreetionos.K9Desktop
runtime: org.freedesktop.Platform
runtime-version: '24.08'
sdk: org.freedesktop.Sdk
command: k9
finish-args:
  - --share=ipc
  - --socket=fallback-x11
  - --socket=wayland
  - --device=dri
  - --filesystem=home
modules:
  - name: k9-desktop
    buildsystem: simple
    build-commands:
      - install -d /app/lib/k9-desktop
      - cp -a . /app/lib/k9-desktop/
      - ln -sf /app/lib/k9-desktop/k9 /app/bin/k9
      - install -Dm644 k9-desktop.desktop /app/share/applications/org.acreetionos.K9Desktop.desktop
      - install -Dm644 icon.png /app/share/icons/hicolor/256x256/apps/org.acreetionos.K9Desktop.png
    sources:
      - type: dir
        path: $FLATPAK_STAGE
EOF
if command -v flatpak-builder >/dev/null 2>&1; then
  if flatpak-builder --force-clean --repo="$WORK/flatpak-repo" "$WORK/flatpak-build" "$WORK/org.acreetionos.K9Desktop.yml" >/tmp/opencode/flatpak.log 2>&1; then
    flatpak build-bundle "$WORK/flatpak-repo" "$DIST/k9-desktop_${VER}_x86_64.flatpak" org.acreetionos.K9Desktop && echo "Created flatpak" || echo "flatpak bundle failed; skipping"
  else
    echo "flatpak-builder failed; skipping flatpak (see /tmp/opencode/flatpak.log)"
  fi
else
  echo "flatpak-builder not available; skipping flatpak"
fi

ls -lh "$DIST"