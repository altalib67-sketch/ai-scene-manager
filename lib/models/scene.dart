import 'package:uuid/uuid.dart';

/// A single scene of a film / video scenario.
///
/// Unknown JSON fields are kept in [extras] so that an export followed by a
/// re-import loses no data.
class Scene {
  final String id;
  int number;
  String title;
  String description;
  String dialogue;
  String characters;
  String prompt;
  String cameraMovement;

  /// Any extra fields found in the source JSON (e.g. duration, location,
  /// mood, style...). Preserved verbatim on export.
  Map<String, dynamic> extras;

  final DateTime createdAt;
  DateTime updatedAt;

  Scene({
    String? id,
    required this.number,
    required this.title,
    this.description = '',
    this.dialogue = '',
    this.characters = '',
    this.prompt = '',
    this.cameraMovement = '',
    Map<String, dynamic>? extras,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        extras = extras ?? <String, dynamic>{},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Keys that map to a known field (canonical key first, then aliases).
  static const Map<String, List<String>> _fieldAliases = {
    'number': ['number', 'scene_number', 'sceneNumber'],
    'title': ['title', 'name', 'scene_title', 'sceneTitle'],
    'description': ['description'],
    'dialogue': ['dialogue', 'dialog', 'dialogue_text'],
    'characters': [
      'characters',
      'character_description',
      'characterDescription',
      'characters_description',
    ],
    'prompt': [
      'prompt',
      'video_prompt',
      'scene_prompt',
      'videoPrompt',
      'scenePrompt',
    ],
    'cameraMovement': ['camera_movement', 'cameraMovement', 'camera'],
  };

  static const Set<String> _knownKeys = {
    'id',
    'number',
    'scene_number',
    'sceneNumber',
    'title',
    'name',
    'scene_title',
    'sceneTitle',
    'description',
    'dialogue',
    'dialog',
    'dialogue_text',
    'characters',
    'character_description',
    'characterDescription',
    'characters_description',
    'prompt',
    'video_prompt',
    'scene_prompt',
    'videoPrompt',
    'scenePrompt',
    'camera_movement',
    'cameraMovement',
    'camera',
    'createdAt',
    'updatedAt',
  };

  static String _pickString(Map<String, dynamic> json, String field) {
    for (final key in _fieldAliases[field]!) {
      final value = json[key];
      if (value == null) continue;
      if (value is String) return value;
      return value.toString();
    }
    return '';
  }

  static int _pickInt(Map<String, dynamic> json, String field) {
    for (final key in _fieldAliases[field]!) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  static DateTime _pickDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  factory Scene.fromJson(Map<String, dynamic> json) {
    final extras = <String, dynamic>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) {
        extras[entry.key] = entry.value;
      }
    }
    return Scene(
      id: json['id'] is String ? json['id'] as String : null,
      number: _pickInt(json, 'number'),
      title: _pickString(json, 'title'),
      description: _pickString(json, 'description'),
      dialogue: _pickString(json, 'dialogue'),
      characters: _pickString(json, 'characters'),
      prompt: _pickString(json, 'prompt'),
      cameraMovement: _pickString(json, 'cameraMovement'),
      extras: extras,
      createdAt: _pickDate(json, 'createdAt'),
      updatedAt: _pickDate(json, 'updatedAt'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'description': description,
      'dialogue': dialogue,
      'characters': characters,
      'prompt': prompt,
      'camera_movement': cameraMovement,
      ...extras,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Scene copyWithNewId({int? number}) {
    return Scene(
      number: number ?? this.number,
      title: title,
      description: description,
      dialogue: dialogue,
      characters: characters,
      prompt: prompt,
      cameraMovement: cameraMovement,
      extras: Map<String, dynamic>.from(extras),
    );
  }

  /// Plain-text representation used by "copy whole scene".
  String toShareText() {
    final buffer = StringBuffer()
      ..writeln('المشهد $number: $title')
      ..writeln('الوصف: $description');
    if (dialogue.isNotEmpty) buffer.writeln('الحوار: $dialogue');
    if (characters.isNotEmpty) buffer.writeln('الشخصيات: $characters');
    buffer.writeln('Prompt: $prompt');
    if (cameraMovement.isNotEmpty) {
      buffer.writeln('حركة الكاميرا: $cameraMovement');
    }
    for (final entry in extras.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString().trim();
  }
}
