import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/scene.dart';

/// One expandable card for a single scene.
class SceneCard extends StatefulWidget {
  final Scene scene;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const SceneCard({
    super.key,
    required this.scene,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  State<SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<SceneCard> {
  bool _expanded = false;

  Future<void> _copy(
    BuildContext context,
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _section(String label, String value, {bool selectable = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final body = selectable
        ? SelectableText(value, style: const TextStyle(height: 1.6))
        : Text(value, style: const TextStyle(height: 1.6));
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                scene.number.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              scene.title.isEmpty ? 'مشهد ${scene.number}' : scene.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _expanded
                ? null
                : Text(
                    scene.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _expanded ? 'طي البطاقة' : 'فتح البطاقة',
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                // Drag handle for ReorderableListView.
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('الوصف', scene.description),
                  _section('الحوار', scene.dialogue),
                  _section('الشخصيات', scene.characters),
                  _section('Prompt', scene.prompt, selectable: true),
                  _section('حركة الكاميرا', scene.cameraMovement),
                  for (final entry in scene.extras.entries)
                    _section(entry.key, entry.value.toString()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _copy(
                          context,
                          scene.prompt,
                          'تم نسخ الـ Prompt',
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('نسخ Prompt'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _copy(
                          context,
                          scene.toShareText(),
                          'تم نسخ المشهد بالكامل',
                        ),
                        icon: const Icon(Icons.content_copy, size: 18),
                        label: const Text('نسخ المشهد'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onDuplicate,
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: const Text('تكرار'),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('حذف'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
