import 'dart:convert';

import '../models/project.dart';
import '../models/scene.dart';

/// Result of a successful JSON import.
class ImportResult {
  final String projectName;
  final List<Scene> scenes;

  const ImportResult({required this.projectName, required this.scenes});
}

/// Parses and validates scenario JSON produced by an external AI tool.
///
/// Accepted top-level shapes:
/// * a bare list of scenes: `[{...}, {...}]`
/// * `{"title": "...", "scenes": [...]}`
/// * `{"scenes": [...]}`
/// * `{"project": {"title": "...", "scenes": [...]}}`
///
/// All errors are thrown as [FormatException] with an Arabic, user-facing
/// message. Nothing is imported when validation fails.
class JsonService {
  static ImportResult parseImport(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('الملف فارغ.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw FormatException('ملف JSON غير صالح: ${e.message}');
    }

    List<dynamic>? rawScenes;
    var projectName = 'مشروع جديد';

    if (decoded is List) {
      rawScenes = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['scenes'] is List) {
        rawScenes = decoded['scenes'] as List;
        projectName = _nameFrom(decoded) ?? projectName;
      } else if (decoded['project'] is Map<String, dynamic>) {
        final projectMap = decoded['project'] as Map<String, dynamic>;
        if (projectMap['scenes'] is List) {
          rawScenes = projectMap['scenes'] as List;
          projectName = _nameFrom(projectMap) ?? projectName;
        }
      }
    }

    if (rawScenes == null) {
      throw const FormatException(
        'لم يتم العثور على أي مشاهد في الملف. '
        'تأكد أن الملف يحتوي على قائمة مشاهد أو على حقل "scenes".',
      );
    }
    if (rawScenes.isEmpty) {
      throw const FormatException('الملف لا يحتوي على أي مشاهد.');
    }

    final scenes = <Scene>[];
    for (var i = 0; i < rawScenes.length; i++) {
      final raw = rawScenes[i];
      if (raw is! Map<String, dynamic>) {
        throw FormatException('المشهد رقم ${i + 1} ليس كائناً صالحاً.');
      }
      final scene = Scene.fromJson(raw);
      if (scene.prompt.trim().isEmpty &&
          scene.description.trim().isEmpty) {
        throw FormatException(
          'المشهد رقم ${i + 1} يفتقد الـ Prompt والوصف معاً. '
          'يجب أن يحتوي كل مشهد على وصف أو Prompt على الأقل.',
        );
      }
      if (scene.number <= 0) {
        scene.number = i + 1;
      }
      scenes.add(scene);
    }

    return ImportResult(projectName: projectName, scenes: scenes);
  }

  static String? _nameFrom(Map<String, dynamic> map) {
    for (final key in ['title', 'name', 'project_name', 'projectName']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Pretty-printed export JSON (same schema the importer accepts).
  static String encodeExport(Project project) {
    return const JsonEncoder.withIndent('  ').convert(project.toExportJson());
  }
}
