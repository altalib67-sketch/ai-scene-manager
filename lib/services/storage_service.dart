import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';

/// Local persistence of all projects, as one JSON document in
/// SharedPreferences. No server, no account, data survives app restarts.
class StorageService {
  static const String projectsKey = 'ai_scene_manager_projects_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    return StorageService(await SharedPreferences.getInstance());
  }

  List<Project> loadProjects() {
    final raw = _prefs.getString(projectsKey);
    if (raw == null || raw.isEmpty) return <Project>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Project>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Project.fromJson)
          .toList();
    } catch (_) {
      // Corrupted stored data: start empty rather than crash.
      return <Project>[];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    final raw = jsonEncode(projects.map((p) => p.toJson()).toList());
    await _prefs.setString(projectsKey, raw);
  }
}
