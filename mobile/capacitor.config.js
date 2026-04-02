'use strict';

/**
 * server.url is only set when CAPACITOR_SERVER_URL is non-empty AND CAPACITOR_OFFLINE is not set.
 * - Dev (Rails in Docker): CAPACITOR_SERVER_URL=http://10.0.2.2:3024 → WebView loads remote app.
 * - Perf / shell test: CAPACITOR_OFFLINE=1 → loads mobile/www only (no 10.0.2.2; not your full Rails UI).
 * For real production, point CAPACITOR_SERVER_URL at your HTTPS origin or ship a static export into www.
 */
/** @type {import('@capacitor/cli').CapacitorConfig} */
const config = {
  appId: 'com.blindjam.player',
  appName: 'BlindJam',
  webDir: 'www',
  android: {
    allowMixedContent: true,
    // Hardware-accelerated WebView rendering for better scroll/paint perf.
    webContentsDebuggingEnabled: true,
  },
  plugins: {
    SplashScreen: {
      // Don't hold the splash longer than needed; the WebView is ready faster.
      launchAutoHide: true,
      launchShowDuration: 0,
      androidScaleType: 'CENTER_CROP',
    },
  },
};

const offline =
  process.env.CAPACITOR_OFFLINE === '1' || process.env.CAPACITOR_OFFLINE === 'true';
const url = offline ? '' : (process.env.CAPACITOR_SERVER_URL || '').trim();

if (url.length > 0) {
  config.server = {
    url,
    cleartext: url.startsWith('http://'),
  };
}

module.exports = config;
