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

  Widget _sectionHeader(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _section(
    IconData icon,
    String label,
    String value, {
    bool selectable = false,
    bool quote = false,
    bool codeBlock = false,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final body = selectable
        ? SelectableText(value, style: const TextStyle(height: 1.6))
        : Text(value, style: const TextStyle(height: 1.6));
    final Widget content;
    if (quote) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
        ),
        child: body,
      );
    } else if (codeBlock) {
      content = Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: body,
      );
    } else {
      content = body;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon, label),
          const SizedBox(height: 6),
          content,
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
                  _section(Icons.description_outlined, 'الوصف',
                      scene.description),
                  _section(Icons.format_quote_outlined, 'الحوار',
                      scene.dialogue,
                      quote: true),
                  _section(Icons.people_outline, 'الشخصيات',
                      scene.characters),
                  _section(Icons.terminal_outlined, 'Prompt', scene.prompt,
                      selectable: true, codeBlock: true),
                  _section(Icons.videocam_outlined, 'حركة الكاميرا',
                      scene.cameraMovement),
                  for (final entry in scene.extras.entries)
                    _section(Icons.label_outline, entry.key,
                        entry.value.toString()),
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
