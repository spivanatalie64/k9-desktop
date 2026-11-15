#!/usr/bin/env bash
set -euo pipefail

# Determine latest Thunderbird ESR version
ESR=$(curl -s https://product-details.mozilla.org/1.0/thunderbird_versions.json \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['THUNDERBIRD_ESR'])")
VER="${ESR%esr}"
BUILDID="$(date -u +%Y%m%d%H%M%S)"
echo "Target ESR: $ESR  (version $VER, build $BUILDID)"

# Skip if already released
if git rev-parse "v${VER}" >/dev/null 2>&1; then
  echo "Tag v${VER} already exists; nothing to do."
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

# Download and extract the ESR tarball
URL="https://ftp.mozilla.org/pub/thunderbird/releases/${ESR}/linux-x86_64/en-US/thunderbird-${ESR}.tar.xz"
echo "Downloading $URL"
curl -fsSL -o thunderbird.tar.xz "$URL"
tar -xJf thunderbird.tar.xz

# Move contents to repo root layout
cd thunderbird
# dereference symlinks
find . -type l -print0 | while IFS= read -r -d '' l; do
  if [ -e "$l" ]; then
    cp -L -- "$l" "$l.__tmp" && mv -f "$l.__tmp" "$l"
  fi
done

# move everything up one level into a staging dir
STAGE="$WORK/stage"
mkdir -p "$STAGE"
cp -a . "$STAGE/"
cd "$STAGE"

# rename binaries
[ -f thunderbird ] && mv -f thunderbird k9
[ -f thunderbird-bin ] && mv -f thunderbird-bin k9-bin

# sanitize absolute home paths
for f in $(grep -rl "/home/natalie" . 2>/dev/null || true); do
  sed -i 's#/home/natalie#/home/user#g' "$f"
done

# Write branded application.ini
cat > application.ini <<EOF
; This file is not used. If you modify it and want the application to use
; your modifications, start with the "-app /path/to/application.ini"
; argument.


[App]
Vendor=AcreetionOS
Name=K9Desktop
RemotingName=k9-default
CodeName=K-9 Desktop
Version=${VER}
Profile=k9
BuildID=${BUILDID}
SourceStamp=01ada2b85d92111c65b34af0364dc860d3f8e04b
ID={3550f703-e582-4d05-9a08-453d09bdfdc6}

[Gecko]
MinVersion=${VER}
MaxVersion=${VER}

[XRE]
EnableProfileMigrator=1
EOF

cat > platform.ini <<EOF

[Build]
BuildID=${BUILDID}
Milestone=${VER}
SourceStamp=ee9f2b2aedc3c58347d66ca8d7b9f92ef1df3f53
EOF

# Disable telemetry and data collection (K9Desktop is the de-telemetered build)
rm -f pingsender crashreporter crashhelper
mkdir -p defaults/pref
cat > defaults/pref/k9-privacy.js <<'EOF'
// K9Desktop: privacy-first defaults (no telemetry, no experiments)
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.archive.enabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("app.shield.optoutstudies.enabled", false);
pref("browser.discovery.enabled", false);
pref("breakpad.reportURL", "");
pref("dom.ipc.plugins.flash.subprocess.crashreporter.enabled", false);
pref("toolkit.crashreporter.enabled", false);
pref("services.settings.server", "");
pref("app.update.enabled", false);
pref("app.update.auto", false);
EOF

cat > defaults/pref/k9-branding.js <<'EOF'
// K9Desktop: branding overrides (de-telemetered Thunderbird)
pref("mailnews.start_page.url", "https://acreetionos.org/");
pref("mailnews.start_page.override_url", "https://acreetionos.org/");
pref("app.vendorURL", "https://acreetionos.org/");
pref("mail.inappnotifications.url", "");
pref("app.update.url.manual", "https://github.com/spivanatalie64/k9-desktop/releases");
pref("app.update.url.details", "https://github.com/spivanatalie64/k9-desktop/releases");
// Use built-in browser (Gecko) for OAuth instead of external system browser
pref("mailnews.oauth.useExternalBrowser", false);
pref("mailnews.oauth.useSchemeRedirect", false);
pref("mailnews.oauth.loglevel", "Warn");
EOF

# --- Rebrand: replace Thunderbird branding with K9Desktop ---
# Replace icons with AcreetionOS logo (acreetion.png is square, ideal for icons)
if [ -f "$REPO/chrome/icons/default/default256.png" ]; then
  SRC_LOGO=""
  for cand in "$REPO/../acreetionos/acreetion.png" "/home/natalie/.ai/.src/acreetionos/acreetion.png" "/usr/share/pixmaps/acreetion.png"; do
    if [ -f "$cand" ]; then SRC_LOGO="$cand"; break; fi
  done
  if [ -n "$SRC_LOGO" ] && command -v magick >/dev/null 2>&1; then
    for s in 16 22 24 32 48 64 128 256; do
      magick "$SRC_LOGO" -resize ${s}x${s} -background none -gravity center -extent ${s}x${s} "chrome/icons/default/default${s}.png"
    done
    magick "$SRC_LOGO" -resize 128x128 icons/updater.png || true
    cat > chrome/icons/default/TB-symbolic.svg <<'SVG'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
  <circle cx="16" cy="16" r="14" fill="#0a2540"/>
  <text x="16" y="20" text-anchor="middle" font-family="sans-serif" font-size="10" font-weight="bold" fill="white">K9</text>
</svg>
SVG
  fi
fi

# Patch omni.ja branding (unpack, replace, repack)
if [ -f omni.ja ]; then
  OMNI_TMP="$(mktemp -d)"
  bsdtar -xf omni.ja -C "$OMNI_TMP"
  # brand strings
  if [ -f "$OMNI_TMP/chrome/en-US/locale/branding/brand.properties" ]; then
    cat > "$OMNI_TMP/chrome/en-US/locale/branding/brand.properties" <<'BRAND'
brandShortName=K9Desktop
brandShorterName=K9Desktop
brandFullName=K9Desktop
vendorShortName=AcreetionOS
BRAND
  fi
  if [ -f "$OMNI_TMP/localization/en-US/branding/brand.ftl" ]; then
    cat > "$OMNI_TMP/localization/en-US/branding/brand.ftl" <<'BRANDFTL'
-brand-shorter-name = K9Desktop
-brand-short-name = K9Desktop
-brand-full-name = K9Desktop
-brand-product-name = K9Desktop
-vendor-short-name = AcreetionOS
trademarkInfo = K9Desktop is a de-telemetered build of Mozilla Thunderbird for AcreetionOS.
BRANDFTL
  fi
  # thunderbird-branding.js -> k9 values
  if [ -f "$OMNI_TMP/defaults/pref/thunderbird-branding.js" ]; then
    cat > "$OMNI_TMP/defaults/pref/thunderbird-branding.js" <<'BRANDJS'
// K9Desktop branding (replaces thunderbird-branding.js)
pref("mailnews.start_page.url", "https://acreetionos.org/");
pref("app.vendorURL", "https://acreetionos.org/");
pref("mail.inappnotifications.url", "");
pref("app.update.url.manual", "https://github.com/spivanatalie64/k9-desktop/releases");
pref("app.update.url.details", "https://github.com/spivanatalie64/k9-desktop/releases");
BRANDJS
  fi
  # Replace branding icons inside omni.ja with generated ones if available
  for s in 32 48 64 128 256; do
    if [ -f "chrome/icons/default/default${s}.png" ] && [ -f "$OMNI_TMP/chrome/messenger/content/branding/icon${s}.png" ]; then
      cp -f "chrome/icons/default/default${s}.png" "$OMNI_TMP/chrome/messenger/content/branding/icon${s}.png"
    fi
  done
  if [ -f "chrome/icons/default/default256.png" ]; then
    for f in "$OMNI_TMP/chrome/messenger/content/branding/about-logo.png" "$OMNI_TMP/chrome/messenger/content/branding/about.png"; do
      [ -f "$f" ] && cp -f "chrome/icons/default/default256.png" "$f"
    done
    if [ -f "$OMNI_TMP/chrome/messenger/content/branding/about-logo@2x.png" ]; then
      magick "chrome/icons/default/default256.png" -resize 512x512 "$OMNI_TMP/chrome/messenger/content/branding/about-logo@2x.png" 2>/dev/null || cp -f "chrome/icons/default/default256.png" "$OMNI_TMP/chrome/messenger/content/branding/about-logo@2x.png"
    fi
  fi
  # Force OAuth to use internal (Firefox/Gecko) browser: patch providers to not require external
  if [ -f "$OMNI_TMP/modules/OAuth2Providers.sys.mjs" ]; then
    sed -i 's/useExternalBrowser: true/useExternalBrowser: false/g' "$OMNI_TMP/modules/OAuth2Providers.sys.mjs" || true
  fi
  # Repack omni.ja
  (cd "$OMNI_TMP" && zip -qr -0 "$STAGE/omni.ja" . )
  cp -f "$STAGE/omni.ja" omni.ja
  rm -rf "$OMNI_TMP"
fi

# Copy stage into repo root (overwrite)
REPO="${GITHUB_WORKSPACE:-/home/natalie/.ai/.src/k9-desktop}"
rsync -a --delete --exclude='.git' --exclude='.github' --exclude='scripts' --exclude='.gitattributes' --exclude='.gitignore' "$STAGE/" "$REPO/"

cd "$REPO"

# LFS tracking for binaries
git lfs install >/dev/null 2>&1 || true
git add -A
git commit -m "Autobuild K9Desktop ${VER} based on Thunderbird ESR ${ESR}" || echo "No changes to commit"
git tag -a "v${VER}" -m "K9Desktop ${VER} release based on Mozilla Thunderbird LTS ${ESR}"
git push origin main || echo "push to main blocked; continuing with release"
git push origin "v${VER}" || echo "tag push blocked; continuing with release"

echo "Released v${VER}"