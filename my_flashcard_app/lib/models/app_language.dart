enum AppLanguage { vi, en, ja, ko, zh }

AppLanguage appLanguageFromCode(String? code) {
  return AppLanguage.values.firstWhere(
    (language) => language.code == code,
    orElse: () => AppLanguage.vi,
  );
}

extension AppLanguageInfo on AppLanguage {
  String get code => name;

  String get nativeName {
    switch (this) {
      case AppLanguage.vi:
        return 'Tiếng Việt';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ja:
        return '日本語';
      case AppLanguage.ko:
        return '한국어';
      case AppLanguage.zh:
        return '中文';
    }
  }
}
