import 'package:ai_scene_manager/screens/splash_screen.dart';
import 'package:ai_scene_manager/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('SplashScreen shows the logo and the Arabic title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );

    expect(find.text('مدير المشاهد'), findsOneWidget);
    expect(find.text('AI Scene Manager'), findsOneWidget);
    expect(
      find.text('إدارة مشاهد السيناريو بالذكاء الاصطناعي'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The logo image (asset) is rendered inside a rounded container.
    final image = find.byWidgetPredicate(
      (widget) => widget is Image && widget.image is AssetImage,
    );
    expect(image, findsOneWidget);
    final assetImage =
        (tester.widget(image) as Image).image as AssetImage;
    expect(assetImage.assetName, 'assets/images/logo.png');
  });
}
