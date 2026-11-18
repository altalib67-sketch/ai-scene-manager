import 'package:ai_scene_manager/services/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PromptBuilder.buildScenarioCommand', () {
    test('command contains the idea text verbatim', () {
      const idea = 'قصة عن صياد في النيل يجد كنزاً قديماً.';
      final command = PromptBuilder.buildScenarioCommand(idea: idea);
      expect(command, contains(idea));
    });

    test('command contains the scene count and duration', () {
      final command = PromptBuilder.buildScenarioCommand(
        idea: 'فكرة تجريبية',
        sceneCount: 12,
        sceneDuration: '10s',
      );
      expect(command, contains('12'));
      expect(command, contains('10s'));
    });

    test('command contains the import schema keys', () {
      final command = PromptBuilder.buildScenarioCommand(idea: 'فكرة');
      for (final key in [
        '"title"',
        '"scenes"',
        '"number"',
        '"description"',
        '"dialogue"',
        '"characters"',
        '"prompt"',
        '"camera_movement"',
        '"location"',
        '"duration"',
      ]) {
        expect(command, contains(key));
      }
    });

    test('command requires Sudanese dialect dialogue', () {
      final command = PromptBuilder.buildScenarioCommand(idea: 'فكرة');
      expect(command.toLowerCase(), contains('sudanese arabic dialect'));
    });

    test('command requires JSON-only output', () {
      final command = PromptBuilder.buildScenarioCommand(idea: 'فكرة');
      expect(command, contains('ONLY a valid JSON object'));
      expect(command, contains('No markdown code fences'));
    });

    test('command includes optional genre, characters and setting', () {
      final command = PromptBuilder.buildScenarioCommand(
        idea: 'فكرة',
        genre: 'دراما',
        characters: 'أمين: شاب سوداني.',
        setting: 'أهرامات مروي',
      );
      expect(command, contains('دراما'));
      expect(command, contains('أمين: شاب سوداني.'));
      expect(command, contains('أهرامات مروي'));
    });

    test('empty idea throws ArgumentError', () {
      expect(
        () => PromptBuilder.buildScenarioCommand(idea: '   '),
        throwsArgumentError,
      );
    });
  });
}
