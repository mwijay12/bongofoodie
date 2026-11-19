import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_theme.dart';
import 'core/theme/app_type.dart';
import 'core/theme/readable_text_scaler.dart';
import 'router/app_router.dart';
import 'state/settings_provider.dart';
import 'state/text_size_provider.dart';

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
    final textSize = ref.watch(textSizeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BongoFoodie TZ',
      debugShowCheckedModeBanner: false,
      theme: withAccessibleTypography(buildAppTheme(), dark: false),
      darkTheme: withAccessibleTypography(AppTheme.dark(), dark: true),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final base = dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
        final media = MediaQuery.of(context);
        final scaler = ReadableTextScaler(
          systemScaler: media.textScaler,
          userScaleFactor: textSize.scaleFactor,
          minimumFontSize: AppType.minReadableFontSize,
          maxScaleFactor: AppType.maxTextScale,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: scaler),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            key: const ValueKey('app-system-ui'),
            value: base.copyWith(
              statusBarColor: AppColors.clear,
              systemNavigationBarColor: AppColors.clear,
              systemNavigationBarContrastEnforced: false,
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
