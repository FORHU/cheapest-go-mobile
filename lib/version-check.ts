/**
 * Version gate — checks /api/mobile/version-check on startup.
 *
 * If forceUpdate is true AND the installed app version is below minVersion,
 * the caller should block the UI with a ForceUpdateModal.
 *
 * Uses semver-compatible comparison (major.minor.patch only).
 */

import { WEB_API_URL, APP_VERSION } from './config';

export interface VersionConfig {
    minVersion: string;
    latestVersion: string;
    forceUpdate: boolean;
    updateMessage: string;
}

const FALLBACK: VersionConfig = {
    minVersion: '0.0.0',
    latestVersion: APP_VERSION,
    forceUpdate: false,
    updateMessage: '',
};

/**
 * Fetch version config from the backend.
 * Returns the fallback (no gate) if the network request fails — never blocks the app on error.
 */
export async function fetchVersionConfig(): Promise<VersionConfig> {
    try {
        const res = await fetch(`${WEB_API_URL}/api/mobile/version-check`, {
            // Short timeout — don't stall startup
            signal: AbortSignal.timeout(5_000),
        });
        if (!res.ok) return FALLBACK;
        const data = await res.json();
        return {
            minVersion:    String(data.minVersion    ?? '0.0.0'),
            latestVersion: String(data.latestVersion ?? APP_VERSION),
            forceUpdate:   Boolean(data.forceUpdate),
            updateMessage: String(data.updateMessage ?? ''),
        };
    } catch {
        return FALLBACK;
    }
}

/**
 * Compare two semver strings (major.minor.patch).
 * Returns: -1 if a < b, 0 if equal, 1 if a > b
 */
function compareSemver(a: string, b: string): number {
    const parse = (v: string) => v.split('.').map(n => parseInt(n, 10) || 0);
    const [aMaj, aMin, aPat] = parse(a);
    const [bMaj, bMin, bPat] = parse(b);
    if (aMaj !== bMaj) return aMaj < bMaj ? -1 : 1;
    if (aMin !== bMin) return aMin < bMin ? -1 : 1;
    if (aPat !== bPat) return aPat < bPat ? -1 : 1;
    return 0;
}

/**
 * Returns true if the user must update before using the app.
 */
export function isUpdateRequired(config: VersionConfig): boolean {
    return config.forceUpdate && compareSemver(APP_VERSION, config.minVersion) < 0;
}

/**
 * Returns true if a newer version is available (soft prompt).
 */
export function isUpdateAvailable(config: VersionConfig): boolean {
    return compareSemver(APP_VERSION, config.latestVersion) < 0;
}
