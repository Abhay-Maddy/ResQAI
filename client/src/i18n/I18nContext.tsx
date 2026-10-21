import React, { createContext, useContext, useState, useEffect } from 'react';
import en from './en.json';
import hi from './hi.json';

type Language = 'en' | 'hi';

interface I18nContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (path: string, fallback?: string) => string;
}

const translations: Record<Language, any> = { en, hi };

const I18nContext = createContext<I18nContextType>({
  language: 'en',
  setLanguage: () => {},
  t: (path: string) => path,
});

export const I18nProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => {
    const saved = localStorage.getItem('resqai_lang');
    return (saved === 'hi' || saved === 'en') ? saved : 'en';
  });

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
    localStorage.setItem('resqai_lang', lang);
    document.documentElement.lang = lang;
    if (lang === 'hi') {
      document.body.style.fontFamily = 'var(--font-family-hindi)';
    } else {
      document.body.style.fontFamily = 'var(--font-family-base)';
    }
  };

  useEffect(() => {
    document.documentElement.lang = language;
    if (language === 'hi') {
      document.body.style.fontFamily = 'var(--font-family-hindi)';
    } else {
      document.body.style.fontFamily = 'var(--font-family-base)';
    }
  }, [language]);

  const t = (path: string, fallback?: string): string => {
    const parts = path.split('.');
    
    // Check in selected language
    let current: any = translations[language];
    for (const part of parts) {
      if (current && typeof current === 'object' && part in current) {
        current = current[part];
      } else {
        current = undefined;
        break;
      }
    }
    
    if (typeof current === 'string') return current;

    // Fallback to English
    current = translations.en;
    for (const part of parts) {
      if (current && typeof current === 'object' && part in current) {
        current = current[part];
      } else {
        current = undefined;
        break;
      }
    }

    if (typeof current === 'string') return current;
    return fallback || path;
  };

  return (
    <I18nContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </I18nContext.Provider>
  );
};

export const useTranslation = () => useContext(I18nContext);
