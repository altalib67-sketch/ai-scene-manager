import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/project_card.dart';
import 'import_helper.dart';
import 'paste_json_screen.dart';
import 'prompt_builder_screen.dart';
import 'scenes_screen.dart';

/// Home screen: list of projects, create / import / open / delete.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  Future<String?> _askForName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم المشروع',
            hintText: 'مثال: فيلم أهرامات مروي',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
    return result ?? false;
  }

  Future<void> _importJson(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final content = utf8.decode(await file.readAsBytes());
      if (!context.mounted) return;
      await ImportHelper.importJsonContent(
        context,
        content,
        fileName: file.name,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر استيراد الملف: $e')),
      );
    }
  }

  Future<void> _showImportOptions(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('استيراد ملف JSON'),
              subtitle: const Text('اختر ملف JSON من الهاتف أو الكمبيوتر'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('لصق نص JSON'),
              subtitle: const Text('الصق نص JSON منسوخاً من أداة ذكاء اصطناعي'),
              onTap: () => Navigator.of(context).pop('paste'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'file') {
      await _importJson(context);
    } else if (choice == 'paste') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PasteJsonScreen()),
      );
    }
  }

  void _openPromptBuilder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PromptBuilderScreen()),
    );
  }

  Future<void> _loadSample(BuildContext context) async {
    final provider = context.read<AppProvider>();
    try {
      final content =
          await rootBundle.loadString('assets/sample_scenes.json');
      final project = provider.importScenes(content);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحميل المشروع التجريبي "${project.name}" '
            '(${project.scenes.length} مشاهد)',
          ),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScenesScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر تحميل المشروع التجريبي: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/logo.png'),
          ),
        ),
        title: const Text('مشاريعي'),
        actions: [
          IconButton(
            tooltip: 'توليد أمر سيناريو',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => _openPromptBuilder(context),
          ),
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
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('داكن'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: provider.projects.isEmpty
              ? _EmptyState(
                  onImport: () => _showImportOptions(context),
                  onSample: () => _loadSample(context),
                  onPromptBuilder: () => _openPromptBuilder(context),
                  onCreate: () async {
                    final name = await _askForName(
                      context,
                      title: 'مشروع جديد',
                    );
                    if (name != null && name.trim().isNotEmpty) {
                      provider.createProject(name);
                    }
                  },
                )
              : ListView.builder(
                  itemCount: provider.projects.length,
                  itemBuilder: (context, index) {
                    final project = provider.projects[index];
                    return ProjectCard(
                      key: ValueKey(project.id),
                      project: project,
                      onOpen: () {
                        provider.setActiveProject(project.id);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ScenesScreen(),
                          ),
                        );
                      },
                      onRename: () async {
                        final name = await _askForName(
                          context,
                          title: 'إعادة تسمية المشروع',
                          initial: project.name,
                        );
                        if (name != null) {
                          provider.renameProject(project.id, name);
                        }
                      },
                      onDelete: () async {
                        final ok = await _confirm(
                          context,
                          title: 'حذف المشروع',
                          message:
                              'سيتم حذف مشروع "${project.name}" وجميع مشاهده '
                              '(${project.scenes.length} مشهداً). هل أنت متأكد؟',
                        );
                        if (ok) provider.deleteProject(project.id);
                      },
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: provider.projects.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'import',
                  tooltip: 'استيراد ملف JSON',
                  onPressed: () => _showImportOptions(context),
                  child: const Icon(Icons.upload_file),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'create',
                  tooltip: 'مشروع جديد',
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  onPressed: () async {
                    final name = await _askForName(
                      context,
                      title: 'مشروع جديد',
                    );
                    if (name != null && name.trim().isNotEmpty) {
                      provider.createProject(name);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onSample;
  final VoidCallback onCreate;
  final VoidCallback onPromptBuilder;

  const _EmptyState({
    required this.onImport,
    required this.onSample,
    required this.onCreate,
    required this.onPromptBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo.png',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مشاريع بعد',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'استورد ملف JSON يحتوي على مشاهد سيناريو، أو أنشئ مشروعاً '
            'جديداً، أو جرّب المشروع التجريبي.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file),
            label: const Text('استيراد ملف JSON'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPromptBuilder,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('توليد أمر سيناريو من فكرة'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onSample,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('تحميل مشروع تجريبي'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء مشروع فارغ'),
          ),
        ],
      ),
    );
  }
}
