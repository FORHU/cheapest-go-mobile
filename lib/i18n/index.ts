import * as Localization from 'expo-localization';
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from './locales/en.json';
import fil from './locales/fil.json';
import id from './locales/id.json';
import ja from './locales/ja.json';
import km from './locales/km.json';
import ko from './locales/ko.json';
import lo from './locales/lo.json';
import ms from './locales/ms.json';
import my from './locales/my.json';
import th from './locales/th.json';
import vi from './locales/vi.json';
import zhTW from './locales/zh-TW.json';
import zh from './locales/zh.json';

export const LOCALE_MAP: Record<string, string> = {
    en: 'en',
    fil: 'fil',
    tl: 'fil',
    id: 'id',
    ja: 'ja',
    km: 'km',
    ko: 'ko',
    lo: 'lo',
    ms: 'ms',
    my: 'my',
    th: 'th',
    vi: 'vi',
    zh: 'zh',
    'zh-TW': 'zh-TW',
};

const deviceLocale = Localization.getLocales()[0]?.languageCode ?? 'en';
const defaultLanguage = LOCALE_MAP[deviceLocale] ?? 'en';

i18n.use(initReactI18next).init({
    compatibilityJSON: 'v4',
    resources: {
        en: { translation: en },
        fil: { translation: fil },
        id: { translation: id },
        ja: { translation: ja },
        km: { translation: km },
        ko: { translation: ko },
        lo: { translation: lo },
        ms: { translation: ms },
        my: { translation: my },
        th: { translation: th },
        vi: { translation: vi },
        zh: { translation: zh },
        'zh-TW': { translation: zhTW },
    },
    lng: defaultLanguage,
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
});

export default i18n;