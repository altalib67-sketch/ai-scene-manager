import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/scene.dart';
import '../providers/app_provider.dart';
import '../widgets/scene_card.dart';
import 'scene_edit_screen.dart';

/// Scenes of the active project: live search, reorder, edit, export.
class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  Future<void> _importMore(BuildContext context, Project project) async {
    final provider = context.read<AppProvider>();
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final content = utf8.decode(await file.readAsBytes());
      provider.importScenesInto(project.id, content);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استيراد المشاهد إلى المشروع')),
      );
    } on FormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر استيراد الملف: $e')),
      );
    }
  }

  Future<void> _export(BuildContext context, Project project) async {
    final provider = context.read<AppProvider>();
    final fileName = '${project.name}-scenes.json';
    try {
      final json = provider.exportProjectJson(project);
      final result = await FilePicker.saveFile(
        dialogTitle: 'تصدير المشروع',
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (!context.mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء التصدير')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تصدير المشروع: $fileName')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر التصدير: $e')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required AppProvider provider,
    required Project project,
    required Scene scene,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشهد'),
        content: Text(
          'سيتم حذف المشهد ${scene.number}: "${scene.title}". هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      provider.deleteScene(project.id, scene.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المشهد')),
        );
      }
    }
  }

  void _openEdit(BuildContext context, Project project, Scene? scene) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SceneEditScreen(project: project, scene: scene),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final project = provider.activeProject;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المشاهد')),
        body: const Center(child: Text('لا يوجد مشروع مفتوح')),
      );
    }

    final searching = provider.searchQuery.trim().isNotEmpty;
    final scenes = provider.filteredScenes(project);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'المظهر',
            icon: Icon(
              provider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : provider.themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            onSelected: provider.setThemeMode,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('حسب النظام'),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text('فاتح'),
              ),
              PopupMenuItem(value: ThemeMode.dark, child: Text('داكن')),
            ],
          ),
          IconButton(
            tooltip: 'استيراد مشاهد إضافية',
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importMore(context, project),
          ),
          IconButton(
            tooltip: 'تصدير JSON',
            icon: const Icon(Icons.download),
            onPressed: () => _export(context, project),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText:
                        'ابحث برقم المشهد أو الاسم أو الوصف أو الحوار أو الـ Prompt...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searching
                        ? IconButton(
                            tooltip: 'مسح البحث',
                            icon: const Icon(Icons.clear),
                            onPressed: () => provider.setSearchQuery(''),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    searching
                        ? 'نتائج البحث: ${scenes.length} من ${project.scenes.length} مشهداً'
                        : '${project.scenes.length} مشهداً'
                            '${project.scenes.isEmpty ? '' : ' • اسحب بالمقبض لإعادة الترتيب'}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Expanded(
                child: project.scenes.isEmpty
                    ? const _EmptyScenes()
                    : searching
                        // Reordering a filtered list would corrupt the real
                        // order, so search results use a plain list.
                        ? ListView.builder(
                            itemCount: scenes.length,
                            itemBuilder: (context, index) {
                              final scene = scenes[index];
                              return _buildCard(
                                context,
                                provider,
                                project,
                                scene,
                                index,
                              );
                            },
                          )
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: scenes.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                provider.reorderScenes(
                              project.id,
                              oldIndex,
                              newIndex,
                            ),
                            itemBuilder: (context, index) {
                              final scene = scenes[index];
                              return _buildCard(
                                context,
                                provider,
                                project,
                                scene,
                                index,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'إضافة مشهد',
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        onPressed: () => _openEdit(context, project, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppProvider provider,
    Project project,
    Scene scene,
    int index,
  ) {
    return SceneCard(
      key: ValueKey(scene.id),
      scene: scene,
      index: index,
      onEdit: () => _openEdit(context, project, scene),
      onDelete: () => _confirmDelete(
        context,
        provider: provider,
        project: project,
        scene: scene,
      ),
      onDuplicate: () {
        provider.duplicateScene(project.id, scene.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تكرار المشهد')),
        );
      },
    );
  }
}

class _EmptyScenes extends StatelessWidget {
  const _EmptyScenes();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 72),
          SizedBox(height: 16),
          Text(
            'لا توجد مشاهد في هذا المشروع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'استورد ملف JSON أو أضف مشهداً جديداً بالزر (+).',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
