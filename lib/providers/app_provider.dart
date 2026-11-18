import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/project.dart';
import '../models/scene.dart';
import '../services/json_service.dart';
import '../services/storage_service.dart';

/// Single source of truth for the UI. Every mutation persists
/// automatically (autosave) and notifies listeners.
class AppProvider extends ChangeNotifier {
  final StorageService _storage;

  AppProvider(this._storage);

  List<Project> _projects = [];
  String? _activeProjectId;
  String _searchQuery = '';
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get isLoaded => _loaded;
  String get searchQuery => _searchQuery;
  ThemeMode get themeMode => _themeMode;

  Project? get activeProject {
    for (final project in _projects) {
      if (project.id == _activeProjectId) return project;
    }
    return null;
  }

  Future<void> init() async {
    _projects = _storage.loadProjects();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.saveProjects(_projects);
  }

  void _changed() {
    notifyListeners();
    // Fire-and-forget autosave; the in-memory state is already updated.
    unawaited(_persist());
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setActiveProject(String? projectId) {
    _activeProjectId = projectId;
    _searchQuery = '';
    notifyListeners();
  }

  /// Scenes of [project] filtered by the current search query.
  /// Matches scene number, title, description, dialogue and prompt.
  List<Scene> filteredScenes(Project project) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return project.scenes;
    final lower = query.toLowerCase();
    return project.scenes.where((scene) {
      return scene.number.toString().contains(query) ||
          scene.title.toLowerCase().contains(lower) ||
          scene.description.toLowerCase().contains(lower) ||
          scene.dialogue.toLowerCase().contains(lower) ||
          scene.prompt.toLowerCase().contains(lower);
    }).toList();
  }

  // ---------------------------------------------------------------- projects

  Project createProject(String name) {
    final project =
        Project(name: name.trim().isEmpty ? 'مشروع جديد' : name.trim());
    _projects.insert(0, project);
    _activeProjectId = project.id;
    _changed();
    return project;
  }

  void renameProject(String projectId, String newName) {
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null || newName.trim().isEmpty) return;
    project.name = newName.trim();
    project.updatedAt = DateTime.now();
    _changed();
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    if (_activeProjectId == projectId) _activeProjectId = null;
    _changed();
  }

  /// Parses [jsonContent] (validated first — nothing is imported on error)
  /// and creates a new project from it.
  Project importScenes(String jsonContent, {String? fileName}) {
    final result = JsonService.parseImport(jsonContent);
    var name = result.projectName;
    if (name == 'مشروع جديد' && fileName != null && fileName.isNotEmpty) {
      name = fileName.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
    }
    final project = Project(name: name, scenes: result.scenes);
    _projects.insert(0, project);
    _activeProjectId = project.id;
    _changed();
    return project;
  }

  /// Adds the scenes of [jsonContent] to an existing project.
  void importScenesInto(String projectId, String jsonContent) {
    final result = JsonService.parseImport(jsonContent);
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    var nextNumber = project.scenes.isEmpty
        ? 1
        : project.scenes.map((s) => s.number).reduce((a, b) => a > b ? a : b) +
            1;
    for (final scene in result.scenes) {
      // Keep imported numbers when they do not clash, otherwise renumber.
      if (project.scenes.any((s) => s.number == scene.number)) {
        scene.number = nextNumber++;
      } else if (scene.number >= nextNumber) {
        nextNumber = scene.number + 1;
      }
      project.scenes.add(scene);
    }
    project.scenes.sort((a, b) => a.number.compareTo(b.number));
    project.updatedAt = DateTime.now();
    _changed();
  }

  String exportProjectJson(Project project) {
    return JsonService.encodeExport(project);
  }

  // ------------------------------------------------------------------ scenes

  void addScene(String projectId, Scene scene) {
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    if (scene.number <= 0) {
      scene.number = project.scenes.isEmpty
          ? 1
          : project.scenes.map((s) => s.number).reduce((a, b) => a > b ? a : b) +
              1;
    }
    project.scenes.add(scene);
    project.scenes.sort((a, b) => a.number.compareTo(b.number));
    project.updatedAt = DateTime.now();
    _changed();
  }

  void updateScene(String projectId, Scene updated) {
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    final index = project.scenes.indexWhere((s) => s.id == updated.id);
    if (index == -1) return;
    updated.updatedAt = DateTime.now();
    project.scenes[index] = updated;
    project.scenes.sort((a, b) => a.number.compareTo(b.number));
    project.updatedAt = DateTime.now();
    _changed();
  }

  void deleteScene(String projectId, String sceneId) {
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    project.scenes.removeWhere((s) => s.id == sceneId);
    project.updatedAt = DateTime.now();
    _changed();
  }

  void duplicateScene(String projectId, String sceneId) {
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    final index = project.scenes.indexWhere((s) => s.id == sceneId);
    if (index == -1) return;
    final original = project.scenes[index];
    final copy = original.copyWithNewId(
      number: project.scenes
              .map((s) => s.number)
              .reduce((a, b) => a > b ? a : b) +
          1,
    );
    copy.title = '${original.title} (نسخة)';
    project.scenes.add(copy);
    project.scenes.sort((a, b) => a.number.compareTo(b.number));
    project.updatedAt = DateTime.now();
    _changed();
  }

  void reorderScenes(String projectId, int oldIndex, int newIndex) {
    // Called from ReorderableListView.onReorderItem, whose newIndex is
    // already adjusted for the removal of the item at oldIndex.
    final project = _projects.where((p) => p.id == projectId).firstOrNull;
    if (project == null) return;
    final scene = project.scenes.removeAt(oldIndex);
    project.scenes.insert(newIndex, scene);
    project.updatedAt = DateTime.now();
    _changed();
  }
}
