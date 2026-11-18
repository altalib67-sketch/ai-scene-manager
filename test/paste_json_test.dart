import 'package:ai_scene_manager/providers/app_provider.dart';
import 'package:ai_scene_manager/screens/paste_json_screen.dart';
import 'package:ai_scene_manager/screens/scenes_screen.dart';
import 'package:ai_scene_manager/services/storage_service.dart';
import 'package:ai_scene_manager/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppProvider> _emptyProvider() async {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService(await SharedPreferences.getInstance());
  final provider = AppProvider(storage);
  await provider.init();
  return provider;
}

Widget _app(AppProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.light,
      home: const PasteJsonScreen(),
    ),
  );
}

void main() {
  testWidgets('paste screen shows field and actions', (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(provider));
    expect(find.text('لصق نص JSON'), findsWidgets);
    expect(find.text('لصق من الحافظة'), findsOneWidget);
    expect(find.text('استيراد'), findsOneWidget);
    expect(find.text('مسح'), findsOneWidget);
  });

  testWidgets('invalid JSON shows an error SnackBar', (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(provider));
    await tester.enterText(find.byType(TextField), 'not json at all');
    await tester.tap(find.text('استيراد'));
    await tester.pump();
    expect(find.textContaining('غير صالح'), findsOneWidget);
    expect(provider.projects, isEmpty);
  });

  testWidgets('sample JSON imports and opens the scenes screen',
      (tester) async {
    final provider = await _emptyProvider();
    await tester.pumpWidget(_app(provider));
    final sample = await rootBundle.loadString('assets/sample_scenes.json');
    await tester.enterText(find.byType(TextField), sample);
    await tester.tap(find.text('استيراد'));
    await tester.pumpAndSettle();
    expect(provider.projects.length, 1);
    expect(provider.projects.first.scenes.length, 3);
    expect(find.byType(ScenesScreen), findsOneWidget);
    expect(find.text('أهرامات مروي — قصة قصيرة'), findsOneWidget);
  });
}
