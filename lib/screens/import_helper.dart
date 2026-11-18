import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'scenes_screen.dart';

/// Shared import flow used by both the file-picker import and the
/// paste-JSON import: validate + create a project, show the result, and
/// open the new project's scenes. Nothing is imported on error.
class ImportHelper {
  static Future<void> importJsonContent(
    BuildContext context,
    String content, {
    String? fileName,
  }) async {
    final provider = context.read<AppProvider>();
    try {
      final project = provider.importScenes(content, fileName: fileName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم استيراد ${project.scenes.length} مشهداً إلى مشروع '
            '"${project.name}"',
          ),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScenesScreen()),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر الاستيراد: $e')),
      );
    }
  }
}
