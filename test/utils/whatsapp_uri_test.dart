import 'package:flutter_test/flutter_test.dart';
import 'package:trueup_lite_flutter/utils/whatsapp_launcher.dart';

void main() {
  group('normalizePhoneForWhatsApp', () {
    test('prefixes 91 for ten-digit Indian mobile', () {
      expect(
        WhatsAppLauncher.normalizePhoneForWhatsApp('9769266253'),
        '919769266253',
      );
    });

    test('strips plus and keeps country code digits', () {
      expect(
        WhatsAppLauncher.normalizePhoneForWhatsApp('+919769266253'),
        '919769266253',
      );
    });

    test('returns null for empty or non-numeric input', () {
      expect(WhatsAppLauncher.normalizePhoneForWhatsApp(''), isNull);
      expect(WhatsAppLauncher.normalizePhoneForWhatsApp('   '), isNull);
      expect(WhatsAppLauncher.normalizePhoneForWhatsApp('abc'), isNull);
    });
  });

  group('buildWhatsAppUri', () {
    test('builds wa.me path and encoded text query', () {
      final uri = WhatsAppLauncher.buildWhatsAppUri(
        phone: '9769266253',
        message: 'Hello & thanks',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919769266253');
      expect(uri.queryParameters['text'], 'Hello & thanks');
    });

    test('returns null when phone is invalid', () {
      expect(
        WhatsAppLauncher.buildWhatsAppUri(phone: '', message: 'Hi'),
        isNull,
      );
    });
  });
}
