import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useContext, useEffect, useState } from 'react';
import { refreshExchangeRates } from '../lib/currency';

export type Currency = {
    code: string;
    symbol: string;
    region: string;
};

export const CURRENCIES: Currency[] = [
    { code: 'KRW', symbol: '₩', region: 'kr' },
    { code: 'USD', symbol: '$', region: 'us' },
    { code: 'PHP', symbol: '₱', region: 'ph' },
];

export type Language = {
    code: string;
    label: string;    // native name shown in picker
    english: string;  // English name shown as subtitle
    flag: string;     // emoji flag
};

export const LANGUAGES: Language[] = [
    { code: 'en', label: 'English', english: 'English', flag: '🌐' },
    { code: 'tl', label: 'Filipino', english: 'Filipino', flag: '🇵🇭' },
    { code: 'id', label: 'Bahasa Indonesia', english: 'Indonesian', flag: '🇮🇩' },
    { code: 'ms', label: 'Bahasa Melayu', english: 'Malay', flag: '🇲🇾' },
    { code: 'th', label: 'ภาษาไทย', english: 'Thai', flag: '🇹🇭' },
    { code: 'vi', label: 'Tiếng Việt', english: 'Vietnamese', flag: '🇻🇳' },
    { code: 'my', label: 'မြန်မာဘာသာ', english: 'Burmese', flag: '🇲🇲' },
    { code: 'km', label: 'ភាសាខ្មែរ', english: 'Khmer', flag: '🇰🇭' },
    { code: 'lo', label: 'ພາສາລາວ', english: 'Lao', flag: '🇱🇦' },
    { code: 'ko', label: '한국어', english: 'Korean', flag: '🇰🇷' },
    { code: 'ja', label: '日本語', english: 'Japanese', flag: '🇯🇵' },
    { code: 'zh-CN', label: '中文（简体）', english: 'Chinese (Simplified)', flag: '🇨🇳' },
    { code: 'zh-TW', label: '中文（繁體）', english: 'Chinese (Traditional)', flag: '🇹🇼' },
];

interface SettingsContextType {
    currency: Currency;
    setCurrency: (code: string) => void;
    language: Language;
    setLanguage: (code: string) => void;
}

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export const SettingsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [currency, setCurrencyState] = useState<Currency>(CURRENCIES[0]); // KRW default
    const [language, setLanguageState] = useState<Language>(LANGUAGES[0]);  // English default

    useEffect(() => {
        // Restore persisted currency choice
        AsyncStorage.getItem('selected_currency').then((val) => {
            if (val) {
                const found = CURRENCIES.find(c => c.code === val);
                if (found) setCurrencyState(found);
            }
        });

        // Restore persisted language choice
        AsyncStorage.getItem('selected_language').then((val) => {
            if (val) {
                const found = LANGUAGES.find(l => l.code === val);
                if (found) setLanguageState(found);
            }
        });

        // Hydrate exchange rates with live data in the background
        refreshExchangeRates();
    }, []);

    const setCurrency = (code: string) => {
        const found = CURRENCIES.find(c => c.code === code);
        if (found) {
            setCurrencyState(found);
            AsyncStorage.setItem('selected_currency', code);
        }
    };

    const setLanguage = (code: string) => {
        const found = LANGUAGES.find(l => l.code === code);
        if (found) {
            setLanguageState(found);
            AsyncStorage.setItem('selected_language', code);
        }
    };

    return (
        <SettingsContext.Provider value={{ currency, setCurrency, language, setLanguage }}>
            {children}
        </SettingsContext.Provider>
    );
};

export const useSettings = () => {
    const context = useContext(SettingsContext);
    if (context === undefined) {
        throw new Error('useSettings must be used within a SettingsProvider');
    }
    return context;
};