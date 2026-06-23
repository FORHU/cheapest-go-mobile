import { WEB_API_URL, APP_VERSION } from './config';

type Level = 'info' | 'warn' | 'error' | 'debug';

interface LogPayload {
    level?: Level;
    tag?: string;
    message: string;
    data?: unknown;
    screen?: string;
}

/**
 * Fire-and-forget log to the Next.js backend terminal.
 * Also echoes to the local Metro console so you see it in both places.
 *
 * Usage:
 *   remoteLog({ level: 'error', tag: 'Login', screen: 'login', message: 'Sign-in failed', data: err });
 */
export function remoteLog({ level = 'info', tag = '', message, data, screen }: LogPayload): void {
    const payload = { level, tag, message, data, screen, build: APP_VERSION, timestamp: Date.now() };

    // Echo to Metro terminal
    const prefix = `[${tag || screen || 'mobile'}]`;
    if (level === 'error') console.error(prefix, message, data ?? '');
    else if (level === 'warn') console.warn(prefix, message, data ?? '');
    else console.log(prefix, message, data ?? '');

    // Ship to backend — fire and forget, never throws
    fetch(`${WEB_API_URL}/api/mobile/log`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    }).catch(() => {/* ignore network failures silently */});
}

/** Shorthand helpers */
export const rLog   = (tag: string, screen: string, msg: string, data?: unknown) =>
    remoteLog({ level: 'info',  tag, screen, message: msg, data });
export const rWarn  = (tag: string, screen: string, msg: string, data?: unknown) =>
    remoteLog({ level: 'warn',  tag, screen, message: msg, data });
export const rError = (tag: string, screen: string, msg: string, data?: unknown) =>
    remoteLog({ level: 'error', tag, screen, message: msg, data });
