/**
 * Currency conversion utilities — mirrors the web app's src/lib/currency.ts.
 *
 * Static fallback rates are used until `refreshExchangeRates()` succeeds.
 * Call `refreshExchangeRates()` once on app startup (SettingsContext does this).
 * All rates are in "USD per 1 unit" format (e.g. PHP: 0.01739 means 1 PHP = $0.01739).
 */

// Static fallback rates (USD-per-1-unit format) — mirrors web app src/lib/currency.ts
const STATIC_RATES: Record<string, number> = {
    USD: 1.0,
    PHP: 0.018,    // 1 PHP = $0.018 → 1 USD ≈ ₱55.6
    KRW: 0.00075,  // 1 KRW = $0.00075 → 1 USD ≈ ₩1333
};

/**
 * Live-updated exchange rates. Starts with static values; updated in-place
 * when `refreshExchangeRates()` succeeds so all consumers see fresh rates.
 */
export const EXCHANGE_RATES: Record<string, number> = { ...STATIC_RATES };

let _lastRefresh = 0;

/** AbortController-based timeout compatible with React Native */
function fetchWithTimeout(url: string, ms: number): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), ms);
    return fetch(url, { signal: controller.signal }).finally(() => clearTimeout(timer));
}

/**
 * Fetch live rates from Frankfurter (ECB data, free, no API key needed).
 * Skips the fetch if rates were already refreshed within the last hour.
 * Tries the v1 endpoint first, falls back to the legacy endpoint.
 */
export async function refreshExchangeRates(): Promise<boolean> {
    if (_lastRefresh && Date.now() - _lastRefresh < 60 * 60 * 1000) return false;

    const urls = [
        'https://api.frankfurter.dev/v1/latest?base=USD&symbols=PHP,KRW',
        'https://api.frankfurter.app/latest?base=USD&symbols=PHP,KRW',
    ];

    for (const url of urls) {
        try {
            const res = await fetchWithTimeout(url, 6000);
            if (!res.ok) continue;
            const data = await res.json();
            if (!data?.rates) continue;

            // Frankfurter: "1 USD = X units" → convert to "1 unit = Y USD"
            for (const [ccy, rate] of Object.entries(data.rates as Record<string, number>)) {
                if (rate > 0) EXCHANGE_RATES[ccy] = 1 / rate;
            }
            _lastRefresh = Date.now();
            return true;
        } catch {
            // Try next URL
        }
    }
    return false; // Both URLs failed — static rates remain active
}

/**
 * Convert `amount` from one currency to another using current EXCHANGE_RATES.
 * Returns the original amount unchanged if a rate is missing.
 *
 * Formula: amount_in_to = (amount_in_from × from_USD_rate) / to_USD_rate
 *
 *   150000 KRW → USD: (150000 × 0.00075) / 1.0 = 112.5 USD ✓
 *   112 USD    → KRW: (112 × 1.0) / 0.00075     = 149333 KRW ✓
 *   6000 PHP   → USD: (6000 × 0.018) / 1.0       = 108 USD ✓
 */
export function convertCurrency(
    amount: number,
    fromCurrency: string,
    toCurrency: string
): number {
    const from = fromCurrency.toUpperCase();
    const to = toCurrency.toUpperCase();
    if (from === to) return amount;
    const fromRate = EXCHANGE_RATES[from];
    const toRate = EXCHANGE_RATES[to];
    if (!fromRate || !toRate) return amount;
    return (amount * fromRate) / toRate;
}

export function getCurrencySymbol(currency: string): string {
    switch (currency.toUpperCase()) {
        case 'USD': return '$';
        case 'PHP': return '₱';
        case 'KRW': return '₩';
        default: return currency;
    }
}

/**
 * Format a converted price: KRW shows no decimal places, others round to whole numbers.
 */
export function formatPrice(amount: number, currency: string): string {
    const rounded = Math.round(amount);
    if (currency.toUpperCase() === 'KRW') {
        return rounded.toLocaleString();
    }
    return rounded.toLocaleString();
}
