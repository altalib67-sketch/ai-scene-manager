import 'package:material_ui/material_ui.dart';

import '../models/project.dart';

/// One card in the projects list: name, scene count, last update.
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.movie),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${project.scenes.length} مشهد • آخر تعديل '
          '${project.updatedAt.year}-${project.updatedAt.month.toString().padLeft(2, '0')}-'
          '${project.updatedAt.day.toString().padLeft(2, '0')}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'خيارات المشروع',
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('إعادة تسمية'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('حذف المشروع'),
              ),
            ),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}
