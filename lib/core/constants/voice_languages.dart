/// A language the voice assistant can listen and reply in.
///
/// [code] is a BCP-47 tag, which is what Google Cloud Speech-to-Text and
/// Text-to-Speech both take as `languageCode`. The server forwards it to
/// Google as-is, so only add codes both Google services support.
class VoiceLanguage {
  /// BCP-47 code sent to the server, e.g. `en-IN`.
  final String code;

  /// English name shown in the picker.
  final String name;

  /// The name written in the language itself, shown under [name].
  final String nativeName;

  const VoiceLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  /// Short label for the chip in the voice screen's top bar.
  String get shortLabel {
    final dash = code.indexOf('-');
    return dash < 0 ? code.toUpperCase() : code.substring(0, dash).toUpperCase();
  }

  @override
  bool operator ==(Object other) => other is VoiceLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'VoiceLanguage($code)';
}

/// Languages offered in the voice assistant. Order is the order in the
/// picker. English (India) is the default because that's what the
/// dashboard's users speak most.
class VoiceLanguages {
  VoiceLanguages._();

  static const englishIndia = VoiceLanguage(
    code: 'en-IN',
    name: 'English (India)',
    nativeName: 'English',
  );

  static const all = <VoiceLanguage>[
    englishIndia,
    VoiceLanguage(code: 'en-US', name: 'English (US)', nativeName: 'English'),
    VoiceLanguage(code: 'hi-IN', name: 'Hindi', nativeName: 'हिन्दी'),
    VoiceLanguage(code: 'ml-IN', name: 'Malayalam', nativeName: 'മലയാളം'),
    VoiceLanguage(code: 'ta-IN', name: 'Tamil', nativeName: 'தமிழ்'),
    VoiceLanguage(code: 'kn-IN', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    VoiceLanguage(code: 'te-IN', name: 'Telugu', nativeName: 'తెలుగు'),
    VoiceLanguage(code: 'mr-IN', name: 'Marathi', nativeName: 'मराठी'),
    VoiceLanguage(code: 'gu-IN', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    VoiceLanguage(code: 'bn-IN', name: 'Bengali', nativeName: 'বাংলা'),
  ];

  static const VoiceLanguage fallback = englishIndia;

  /// Looks a language up by its code; falls back to English (India) when
  /// the stored code is unknown (e.g. a language was removed from [all]).
  static VoiceLanguage byCode(String? code) {
    if (code == null) return fallback;
    for (final l in all) {
      if (l.code == code) return l;
    }
    return fallback;
  }
}
