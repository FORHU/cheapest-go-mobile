import { convertCurrency, getCurrencySymbol, formatPrice } from '../../lib/currency';

describe('convertCurrency', () => {
    it('returns the same amount when from and to currency are identical', () => {
        expect(convertCurrency(100, 'USD', 'USD')).toBe(100);
    });

    it('converts KRW to USD', () => {
        // 150000 KRW × 0.00075 / 1.0 = 112.5 USD
        expect(convertCurrency(150000, 'KRW', 'USD')).toBeCloseTo(112.5, 0);
    });

    it('converts USD to KRW', () => {
        // 100 USD × 1.0 / 0.00075 ≈ 133333 KRW
        expect(convertCurrency(100, 'USD', 'KRW')).toBeCloseTo(133333, -2);
    });

    it('converts PHP to USD', () => {
        // 6000 PHP × 0.018 / 1.0 = 108 USD
        expect(convertCurrency(6000, 'PHP', 'USD')).toBeCloseTo(108, 0);
    });

    it('returns the original amount when the from-currency rate is missing', () => {
        expect(convertCurrency(100, 'XYZ', 'USD')).toBe(100);
    });

    it('returns the original amount when the to-currency rate is missing', () => {
        expect(convertCurrency(100, 'USD', 'XYZ')).toBe(100);
    });

    it('is case-insensitive', () => {
        expect(convertCurrency(100, 'usd', 'usd')).toBe(100);
        expect(convertCurrency(150000, 'krw', 'USD')).toBeCloseTo(112.5, 0);
    });
});

describe('getCurrencySymbol', () => {
    it('returns $ for USD', () => {
        expect(getCurrencySymbol('USD')).toBe('$');
    });

    it('returns ₱ for PHP', () => {
        expect(getCurrencySymbol('PHP')).toBe('₱');
    });

    it('returns ₩ for KRW', () => {
        expect(getCurrencySymbol('KRW')).toBe('₩');
    });

    it('returns the currency code itself for unknown currencies', () => {
        expect(getCurrencySymbol('EUR')).toBe('EUR');
    });

    it('is case-insensitive', () => {
        expect(getCurrencySymbol('usd')).toBe('$');
        expect(getCurrencySymbol('php')).toBe('₱');
    });
});

describe('formatPrice', () => {
    it('rounds to whole numbers', () => {
        expect(formatPrice(1234.56, 'USD')).toBe('1,235');
    });

    it('formats KRW with thousands separator', () => {
        expect(formatPrice(150000, 'KRW')).toBe('150,000');
    });

    it('rounds down correctly', () => {
        expect(formatPrice(99.4, 'USD')).toBe('99');
    });
});
