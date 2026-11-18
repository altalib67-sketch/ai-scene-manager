import 'dart:convert';
import 'dart:io';

import 'package:ai_scene_manager/models/project.dart';
import 'package:ai_scene_manager/services/json_service.dart';
import 'package:flutter_test/flutter_test.dart';

Project _projectFrom(ImportResult result) =>
    Project(name: result.projectName, scenes: result.scenes);

void main() {
  group('JsonService.parseImport', () {
    test('parses a bare list of scenes', () {
      const json = '''
[
  {"number": 1, "title": "البداية", "description": "وصف", "prompt": "a prompt"},
  {"number": 2, "title": "النهاية", "description": "وصف آخر", "prompt": "another prompt"}
]
''';
      final result = JsonService.parseImport(json);
      expect(result.scenes.length, 2);
      expect(result.scenes[0].title, 'البداية');
      expect(result.scenes[1].number, 2);
    });

    test('parses {"title": ..., "scenes": [...]} form', () {
      const json = '''
{"title": "فيلمي", "scenes": [
  {"number": 1, "title": "مشهد", "prompt": "p"}
]}
''';
      final result = JsonService.parseImport(json);
      expect(result.projectName, 'فيلمي');
      expect(result.scenes.length, 1);
    });

    test('parses {"project": {...}, "scenes": [...]} form', () {
      const json = '''
{"project": {"title": "مشروع متداخل", "scenes": [
  {"number": 1, "title": "مشهد", "description": "وصف"}
]}}
''';
      final result = JsonService.parseImport(json);
      expect(result.projectName, 'مشروع متداخل');
      expect(result.scenes.length, 1);
    });

    test('accepts field aliases', () {
      const json = '''
[{"scene_number": 5, "name": "الاسم", "video_prompt": "vp",
  "camera": "pan left", "dialog": "حوار"}]
''';
      final result = JsonService.parseImport(json);
      final scene = result.scenes.single;
      expect(scene.number, 5);
      expect(scene.title, 'الاسم');
      expect(scene.prompt, 'vp');
      expect(scene.cameraMovement, 'pan left');
      expect(scene.dialogue, 'حوار');
    });

    test('unknown fields go to extras and survive an export round-trip', () {
      const json = '''
[{"number": 1, "title": "مشهد", "prompt": "p",
  "duration": "8s", "location": "مروي", "mood": "happy"}]
''';
      final first = JsonService.parseImport(json);
      final scene = first.scenes.single;
      expect(scene.extras['duration'], '8s');
      expect(scene.extras['location'], 'مروي');

      final exported = JsonService.encodeExport(_projectFrom(first));
      final second = JsonService.parseImport(exported);
      expect(second.scenes.single.extras['duration'], '8s');
      expect(second.scenes.single.extras['mood'], 'happy');
      expect(second.scenes.single.prompt, 'p');
      // Extras are top-level keys in the exported JSON, not nested.
      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      final exportedScene = decoded['scenes'][0] as Map<String, dynamic>;
      expect(exportedScene['location'], 'مروي');
      expect(exportedScene.containsKey('extras'), isFalse);
    });

    test('invalid JSON throws a FormatException with an Arabic message', () {
      expect(
        () => JsonService.parseImport('{not json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('JSON'),
          ),
        ),
      );
    });

    test('no scenes found throws', () {
      expect(
        () => JsonService.parseImport('{"title": "فارغ"}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => JsonService.parseImport('[]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('scene without prompt and description throws', () {
      expect(
        () => JsonService.parseImport('[{"number": 1, "title": "فارغ"}]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('assigns numbers when missing', () {
      final result = JsonService.parseImport(
        '[{"title": "أ", "prompt": "p"}, {"title": "ب", "prompt": "p"}]',
      );
      expect(result.scenes[0].number, 1);
      expect(result.scenes[1].number, 2);
    });

    test('the bundled sample file imports cleanly', () {
      final content = File('assets/sample_scenes.json').readAsStringSync();
      final result = JsonService.parseImport(content);
      expect(result.projectName, 'أهرامات مروي — قصة قصيرة');
      expect(result.scenes.length, 3);
      expect(result.scenes[0].extras['location'], 'أهرامات مروي، السودان');
      // Export -> re-import must not lose data.
      final exported = JsonService.encodeExport(_projectFrom(result));
      final again = JsonService.parseImport(exported);
      expect(again.scenes.length, 3);
      expect(again.scenes[1].dialogue, contains('سارة'));
      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      final scenes = decoded['scenes'] as List;
      expect(
        (scenes[2] as Map<String, dynamic>)['location'],
        'قرية نوبية، شمال السودان',
      );
    });
  });
}
