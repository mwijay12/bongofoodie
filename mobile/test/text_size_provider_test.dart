import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bongo_foodie/core/theme/app_type.dart';
import 'package:bongo_foodie/state/text_size_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reading size hydrates, persists and maps to scale factors', () async {
    SharedPreferences.setMockInitialValues({
      TextSizeNotifier.storageKey: AppTextSize.larger.storageValue,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(textSizeProvider.notifier);
    await notifier.ready;
    expect(container.read(textSizeProvider), AppTextSize.larger);
    expect(
      container.read(textSizeProvider).scaleFactor,
      AppType.largerTextScale,
    );

    await notifier.setTextSize(AppTextSize.large);
    expect(container.read(textSizeProvider), AppTextSize.large);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(TextSizeNotifier.storageKey),
      AppTextSize.large.storageValue,
    );
    SharedPreferences.setMockInitialValues({});
  });
}
