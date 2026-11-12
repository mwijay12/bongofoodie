import 'package:bongo_foodie/core/config/env_config.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/services/supabase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('supabase status is honest about why there is no live catalog', () {
    test('no credentials means showcase mode, not a failure', () {
      // The unit-test binary is built without --dart-define credentials.
      expect(EnvConfig.isSupabaseConfigured, isFalse);
      expect(SupabaseService.isLive, isFalse);
      expect(SupabaseService.status, SupabaseStatus.showcase);
      expect(SupabaseService.failureReason, isEmpty);
      expect(SupabaseService.client, isNull);
    });

    test('failure reason is empty until initialisation actually fails', () async {
      await SupabaseService.initialize();
      // Still showcase: credentials were never compiled in.
      expect(SupabaseService.status, SupabaseStatus.showcase);
      expect(SupabaseService.failureReason, isEmpty);
    });
  });

  group('connection copy does not blame the user network', () {
    const en = AppStrings(AppLanguage.en);
    const sw = AppStrings(AppLanguage.sw);

    test('server-down copy is distinct from the user network copy', () {
      expect(en.serverTitle, isNot(en.offlineTitle));
      expect(en.serverBody, isNot(en.offlineBody));
      // The server message must not tell the user their connection is the issue.
      expect(en.serverBody.toLowerCase(), contains('server'));
      expect(sw.serverBody.toLowerCase(), contains('seva'));
    });

    test('offline copy is only used for an actual connection problem', () {
      expect(en.offlineBody.toLowerCase(), contains('connection'));
      expect(sw.offlineBody.toLowerCase(), contains('mtandao'));
    });

    test('showcase copy explains how to get live data', () {
      expect(en.showcaseNoticeBody.toLowerCase(), contains('supabase'));
      expect(sw.showcaseNoticeBody.toLowerCase(), contains('supabase'));
      expect(en.showcaseNoticeTitle, isNot(en.serverTitle));
    });
  });
}
