import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'router/app_router.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: BongoFoodieApp(),
    ),
  );
}

class BongoFoodieApp extends ConsumerWidget {
  const BongoFoodieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BongoFoodie TZ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final base = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          key: const ValueKey('app-system-ui'),
          value: base.copyWith(
            statusBarColor: AppColors.clear,
            systemNavigationBarColor: AppColors.clear,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
    );
  }
}
