import 'package:uuid/uuid.dart';

import 'scene.dart';

/// A project = one film / story, holding its scenes.
class Project {
  final String id;
  String name;
  List<Scene> scenes;
  final DateTime createdAt;
  DateTime updatedAt;

  Project({
    String? id,
    required this.name,
    List<Scene>? scenes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        scenes = scenes ?? <Scene>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawScenes = json['scenes'];
    final scenes = <Scene>[];
    if (rawScenes is List) {
      for (final raw in rawScenes) {
        if (raw is Map<String, dynamic>) {
          scenes.add(Scene.fromJson(raw));
        }
      }
    }
    DateTime parseDate(String key) {
      final value = json[key];
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Project(
      id: json['id'] is String ? json['id'] as String : null,
      name: (json['name'] ?? json['title'] ?? 'مشروع جديد').toString(),
      scenes: scenes,
      createdAt: parseDate('createdAt'),
      updatedAt: parseDate('updatedAt'),
    );
  }

  /// Storage format (keeps scene ids + timestamps).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Export format: the same schema the importer accepts, so an exported
  /// file can be imported again without losing information.
  Map<String, dynamic> toExportJson() {
    return {
      'title': name,
      'scenes': scenes.map((s) => s.toJson()).toList(),
    };
  }
}
