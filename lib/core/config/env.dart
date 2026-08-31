class Env {
  // Groq API Key - ücretsiz: https://console.groq.com/keys
  // Buraya kendi key'ini yaz VEYA --dart-define=GROQ_API_KEY=xxx ile çalıştır
  static const String _hardcodedGroqKey = ''; // <-- BURAYA KEY'İNİ YAZ

  static const String _envGroqKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static String get groqApiKey =>
      _envGroqKey.isNotEmpty ? _envGroqKey : _hardcodedGroqKey;

  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.1-8b-instant',
  );

  // Doğrulanmamış scraper/AI verilerini normal kullanıcı akışında gösterme.
  // Demo/test için mock veriler ayrı bir akıştan açıkça etkinleştirilebilir.
  static const bool enableUntrustedData = false;
}
