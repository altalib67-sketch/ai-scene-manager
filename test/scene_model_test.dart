import 'package:ai_scene_manager/models/project.dart';
import 'package:ai_scene_manager/models/scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scene model', () {
    test('toJson/fromJson round-trip preserves every field', () {
      final scene = Scene(
        number: 3,
        title: 'العودة إلى القرية',
        description: 'ليلة مقمرة',
        dialogue: 'أمين: وصلنا أخيراً.',
        characters: 'أمين وسارة',
        prompt: 'Moonlit Nubian village, cinematic',
        cameraMovement: 'تتبع بطيء',
        extras: {'duration': '8s', 'location': 'مروي'},
      );
      final restored = Scene.fromJson(scene.toJson());
      expect(restored.id, scene.id);
      expect(restored.number, 3);
      expect(restored.title, 'العودة إلى القرية');
      expect(restored.description, 'ليلة مقمرة');
      expect(restored.dialogue, 'أمين: وصلنا أخيراً.');
      expect(restored.characters, 'أمين وسارة');
      expect(restored.prompt, 'Moonlit Nubian village, cinematic');
      expect(restored.cameraMovement, 'تتبع بطيء');
      expect(restored.extras['duration'], '8s');
      expect(restored.extras['location'], 'مروي');
    });

    test('copyWithNewId gets a fresh id and keeps the data', () {
      final scene = Scene(number: 1, title: 'أ', prompt: 'p');
      final copy = scene.copyWithNewId(number: 9);
      expect(copy.id, isNot(scene.id));
      expect(copy.number, 9);
      expect(copy.title, 'أ');
      expect(copy.prompt, 'p');
    });

    test('toShareText contains the key fields', () {
      final scene = Scene(
        number: 1,
        title: 'البداية',
        description: 'وصف',
        prompt: 'a prompt',
      );
      final text = scene.toShareText();
      expect(text, contains('المشهد 1: البداية'));
      expect(text, contains('a prompt'));
    });
  });

  group('Project model', () {
    test('toJson/fromJson round-trip preserves scenes', () {
      final project = Project(
        name: 'فيلمي',
        scenes: [
          Scene(number: 1, title: 'أ', prompt: 'p1'),
          Scene(number: 2, title: 'ب', prompt: 'p2', extras: {'x': 1}),
        ],
      );
      final restored = Project.fromJson(project.toJson());
      expect(restored.id, project.id);
      expect(restored.name, 'فيلمي');
      expect(restored.scenes.length, 2);
      expect(restored.scenes[1].extras['x'], 1);
    });

    test('toExportJson uses the importable schema', () {
      final project = Project(
        name: 'فيلمي',
        scenes: [Scene(number: 1, title: 'أ', prompt: 'p1')],
      );
      final exported = project.toExportJson();
      expect(exported['title'], 'فيلمي');
      expect(exported['scenes'], isA<List>());
      expect((exported['scenes'] as List).length, 1);
    });
  });
}
