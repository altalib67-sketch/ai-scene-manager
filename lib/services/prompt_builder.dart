/// Builds the instruction ("الأمر") the user pastes into an external AI
/// tool so that the AI replies with a scenario JSON file that this app can
/// import directly (see [JsonService]).
///
/// Pure function: no Flutter, no I/O, fully unit-testable.
class PromptBuilder {
  /// A ready-made idea used by the "مثال" button in the UI.
  static const String sampleIdea =
      'قصة قصيرة عن شاب سوداني اسمه أمين وفتاة اسمها سارة، يزوران '
      'أهرامات مروي عند شروق الشمس، ثم يجلسان على ضفة النيل عند الغروب، '
      'ويعودان إلى قريتهما النوبية في ليلة مقمرة.';

  /// Returns one English instruction for an external AI. The user's
  /// [idea] is embedded verbatim; optional details are added only when
  /// provided. Throws [ArgumentError] when [idea] is blank.
  static String buildScenarioCommand({
    required String idea,
    String genre = '',
    int sceneCount = 8,
    String characters = '',
    String setting = '',
    String sceneDuration = '8s',
  }) {
    final trimmedIdea = idea.trim();
    if (trimmedIdea.isEmpty) {
      throw ArgumentError('اكتب فكرة القصة أولاً.');
    }
    final count = sceneCount.clamp(3, 20);
    final duration = sceneDuration.trim().isEmpty ? '8s' : sceneDuration.trim();

    final buffer = StringBuffer()
      ..writeln(
        'You are an expert screenwriter and AI-video scene-prompt generator.',
      )
      ..writeln()
      ..writeln(
        'TASK: Turn the following story idea into exactly $count cinematic '
        'video scenes for AI video generation. Each scene must be a '
        'self-contained shot that can be generated on its own.',
      )
      ..writeln()
      ..writeln('STORY IDEA:')
      ..writeln(trimmedIdea);
    if (genre.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('GENRE: ${genre.trim()}');
    }
    if (characters.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('MAIN CHARACTERS:')
        ..writeln(characters.trim());
    }
    if (setting.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('SETTING (time and place):')
        ..writeln(setting.trim());
    }
    buffer
      ..writeln()
      ..writeln('SCENE COUNT: exactly $count scenes, numbered sequentially '
          'from 1 to $count.')
      ..writeln('PER-SCENE DURATION: $duration per scene.')
      ..writeln()
      ..writeln('LANGUAGE RULES:')
      ..writeln(
        '- Write every "dialogue" in Sudanese Arabic dialect '
        '(اللهجة السودانية), as people in Sudan actually speak.',
      )
      ..writeln(
        '- Write every "description" in Arabic.',
      )
      ..writeln(
        '- Write every "prompt" as a detailed English cinematic '
        'video-generation prompt (camera, lighting, setting, characters, '
        'mood, style, duration).',
      )
      ..writeln(
        '- Write "title", "characters", "camera_movement" and "location" '
        'in Arabic.',
      )
      ..writeln()
      ..writeln('OUTPUT FORMAT — STRICT:')
      ..writeln(
        '- Reply with ONLY a valid JSON object. No markdown code fences, '
        'no explanations, no text before or after the JSON.',
      )
      ..writeln('- Use EXACTLY this structure:')
      ..writeln(
        '{"title": "...", "scenes": [{"number": 1, "title": "...", '
        '"description": "...", "dialogue": "...", "characters": "...", '
        '"prompt": "...", "camera_movement": "...", "location": "...", '
        '"duration": "$duration"}]}',
      )
      ..writeln()
      ..writeln('RULES:')
      ..writeln(
        '- Every scene must include ALL fields: number, title, '
        'description, dialogue, characters, prompt, camera_movement, '
        'location, duration.',
      )
      ..writeln(
        '- Keep the same characters, names and visual style consistent '
        'across all scenes.',
      )
      ..writeln(
        '- Keep the story in chronological order from scene 1 to scene '
        '$count.',
      )
      ..writeln(
        '- Escape all quotes and special characters so the JSON is valid '
        'and can be parsed with jsonDecode.',
      );
    return buffer.toString().trimRight();
  }
}
