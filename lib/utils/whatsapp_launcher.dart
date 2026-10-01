/// Helpers for opening WhatsApp chats via [wa.me] links.
class WhatsAppLauncher {
  /// Strips formatting and returns E.164-style digits (no leading +) for wa.me.
  ///
  /// Ten-digit numbers are treated as Indian mobiles and prefixed with [91].
  static String? normalizePhoneForWhatsApp(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return null;

    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return null;

    if (hasPlus) {
      return digitsOnly;
    }
    if (digitsOnly.length == 10) {
      return '91$digitsOnly';
    }
    return digitsOnly;
  }

  /// Builds `https://wa.me/<phone>?text=<encoded message>`.
  static Uri? buildWhatsAppUri({
    required String phone,
    required String message,
  }) {
    final normalized = normalizePhoneForWhatsApp(phone);
    if (normalized == null || normalized.isEmpty) return null;

    return Uri(
      scheme: 'https',
      host: 'wa.me',
      path: normalized,
      queryParameters: {'text': message},
    );
  }
}
