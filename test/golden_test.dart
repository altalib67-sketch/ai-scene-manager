import 'package:ai_scene_manager/providers/app_provider.dart';
import 'package:ai_scene_manager/screens/projects_screen.dart';
import 'package:ai_scene_manager/screens/prompt_builder_screen.dart';
import 'package:ai_scene_manager/screens/splash_screen.dart';
import 'package:ai_scene_manager/services/storage_service.dart';
import 'package:ai_scene_manager/theme/app_theme.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Golden screenshots of the splash screen and the empty projects screen.
/// Regenerate with: flutter test --update-goldens
Future<AppProvider> _emptyProvider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService(await SharedPreferences.getInstance());
  final provider = AppProvider(storage);
  await provider.init();
  return provider;
}

Widget _app(Widget home, AppProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light,
      home: home,
    ),
  );
}

void main() {
  // Load the bundled Tajawal Arabic font explicitly: the test
  // environment does not reliably pick up pubspec fonts on its own,
  // and without this Arabic renders as tofu boxes in the goldens.
  setUpAll(() async {
    final loader = FontLoader('Tajawal')
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
    await loader.load();
  });

  testWidgets('golden: splash screen', (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(const SplashScreen(), provider));
    // Asset images load via real async work, which fake-time pumps do
    // not advance: precache the logo explicitly so it is painted in
    // the golden. (Without this the logo area captures as blank.)
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/logo.png'),
        tester.element(find.byType(Scaffold)),
      );
    });
    await tester.pump();
    await expectLater(
      find.byType(SplashScreen),
      matchesGoldenFile('goldens/splash_screen.png'),
    );
  });

  testWidgets('golden: projects empty state', (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(const ProjectsScreen(), provider));
    await expectLater(
      find.byType(ProjectsScreen),
      matchesGoldenFile('goldens/projects_empty.png'),
    );
  });

  testWidgets('golden: prompt builder form', (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(const PromptBuilderScreen(), provider));
    await tester.pump();
    await expectLater(
      find.byType(PromptBuilderScreen),
      matchesGoldenFile('goldens/prompt_builder.png'),
    );
  });
}
