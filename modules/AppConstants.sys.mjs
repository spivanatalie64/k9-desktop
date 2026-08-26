

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * AppConstants is a set of immutable constants that are defined at build time.
 * These should not depend on any other JavaScript module.
 */
export var AppConstants = Object.freeze({
  // See this wiki page for more details about channel specific build
  // defines: https://wiki.mozilla.org/Platform/Channel-specific_build_defines
  NIGHTLY_BUILD: false,

  ENABLE_EXPLICIT_RESOURCE_MANAGEMENT: false,

  RELEASE_OR_BETA: true,

  EARLY_BETA_OR_EARLIER: false,

  IS_ESR: true,

  ACCESSIBILITY: true,

  // Official corresponds, roughly, to whether this build is performed
  // on Mozilla's continuous integration infrastructure. You should
  // disable developer-only functionality when this flag is set.
  MOZILLA_OFFICIAL: false,

  MOZ_OFFICIAL_BRANDING: true,

  MOZ_DEV_EDITION: false,

  MOZ_SERVICES_SYNC: false,

  MOZ_DATA_REPORTING: true,

  MOZ_SANDBOX: true,

  MOZ_TELEMETRY_REPORTING:
//@line 46 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  false,
//@line 48 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  MOZ_UPDATER: false,

  MOZ_WEBRTC: true,

  MOZ_WIDGET_GTK:
//@line 55 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  true,
//@line 59 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  MOZ_WMF_CDM: false,

  XP_UNIX:
//@line 64 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  true,
//@line 68 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

// NOTE! XP_LINUX has to go after MOZ_WIDGET_ANDROID otherwise Android
// builds will be misidentified as linux.
  platform:
//@line 73 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  "linux",
//@line 87 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

// Most of our frontend code assumes that any desktop Unix platform
// is "linux". Add the distinction for code that needs it.
  unixstyle:
//@line 92 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    "linux",
//@line 104 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  isPlatformAndVersionAtLeast(platform, version) {
    let platformVersion = Services.sysinfo.getProperty("version");
    return platform == this.platform &&
           Services.vc.compare(platformVersion, version) >= 0;
  },

  isPlatformAndVersionAtMost(platform, version) {
    let platformVersion = Services.sysinfo.getProperty("version");
    return platform == this.platform &&
           Services.vc.compare(platformVersion, version) <= 0;
  },

  MOZ_CRASHREPORTER: false,

  MOZ_NORMANDY: false,

  MOZ_MAINTENANCE_SERVICE: false,

  MOZ_BACKGROUNDTASKS: true,

  MOZ_UPDATE_AGENT: false,

  MOZ_BITS_DOWNLOAD: false,

  DEBUG: false,

  ASAN: false,

  ASAN_REPORTER: false,

  TSAN: false,

  MOZ_SYSTEM_NSS: false,

  MOZ_PLACES: true,

  MOZ_REQUIRE_SIGNING: false,

  MOZ_UNSIGNED_APP_SCOPE: false,

  MOZ_UNSIGNED_SYSTEM_SCOPE: false,

  MOZ_ALLOW_ADDON_SIDELOAD: true,

  MOZ_WEBEXT_WEBIDL_ENABLED: false,

  MOZ_GECKOVIEW_HISTORY: false,

  MOZ_GECKO_PROFILER: true,

  BROWSER_NEWTAB_AS_ADDON: false,

  DLL_PREFIX: "lib",
  DLL_SUFFIX: ".so",

  MOZ_APP_NAME: "k9",
  MOZ_APP_BASENAME: "K9Desktop",
  // N.b.: you almost certainly want brandShortName/brand-short-name:
  // MOZ_APP_DISPLAYNAME should only be used for static user-visible
  // fields (e.g., DLL properties, Mac Bundle name, or similar).
  MOZ_APP_DISPLAYNAME_DO_NOT_USE: "K-9 Desktop",
  MOZ_APP_VERSION: "140.14.0",
  MOZ_APP_VERSION_DISPLAY: "140.14.0esr",
  MOZ_BUILDID: "20260824181028",
  MOZ_BUILD_APP: "comm/mail",
  MOZ_MACBUNDLE_ID: "",
  MOZ_MACBUNDLE_NAME: "",
  MOZ_UPDATE_CHANNEL: "default",
  MOZ_WIDGET_TOOLKIT: "gtk",

  DEBUG_JS_MODULES: "",

  MOZ_BING_API_CLIENTID: "no-bing-api-clientid",
  MOZ_BING_API_KEY: "no-bing-api-key",
  MOZ_GOOGLE_LOCATION_SERVICE_API_KEY: "no-google-location-service-api-key",
  MOZ_GOOGLE_SAFEBROWSING_API_KEY: "no-google-safebrowsing-api-key",
  MOZ_MOZILLA_API_KEY: "no-mozilla-api-key",

  BROWSER_CHROME_URL: "chrome://messenger/content/extensionPopup.xhtml",

  OMNIJAR_NAME: "omni.ja",

  // URL to the hg revision this was built from (e.g.
  // "https://hg.mozilla.org/mozilla-central/rev/6256ec9113c1")
  // On unofficial builds, this is an empty string.
//@line 193 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  SOURCE_REVISION_URL: "",

  HAVE_USR_LIB64_DIR:
//@line 199 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    false,
//@line 201 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  HAVE_SHELL_SERVICE: true,

  MOZ_CODE_COVERAGE: false,

  TELEMETRY_PING_FORMAT_VERSION: 4,

  ENABLE_WEBDRIVER: true,

  REMOTE_SETTINGS_SERVER_URL:
//@line 212 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    "https://thunderbird-settings.thunderbird.net/v1",
//@line 216 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  REMOTE_SETTINGS_VERIFY_SIGNATURE:
//@line 219 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    false,
//@line 223 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  REMOTE_SETTINGS_DEFAULT_BUCKET:
//@line 226 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    "thunderbird",
//@line 230 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  MOZ_GLEAN_ANDROID: false,

  MOZ_JXL: false,

//@line 236 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  MOZ_CAN_FOLLOW_SYSTEM_TIME:
//@line 243 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    true,
//@line 251 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  MOZ_SYSTEM_POLICIES: true,

  MOZ_SELECTABLE_PROFILES: true,

  SQLITE_LIBRARY_FILENAME:
//@line 260 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
  "libmozsqlite3.so",
//@line 262 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  MOZ_GECKOVIEW:
//@line 267 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"
    false,
//@line 269 "$SRCDIR/toolkit/modules/AppConstants.sys.mjs"

  USE_LIBZ_RS: false,
});
