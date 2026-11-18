import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'import_helper.dart';

/// Screen where the user pastes a scenario JSON text (for example the
/// reply of an external AI tool) and imports it as a new project.
class PasteJsonScreen extends StatefulWidget {
  const PasteJsonScreen({super.key});

  @override
  State<PasteJsonScreen> createState() => _PasteJsonScreenState();
}

class _PasteJsonScreenState extends State<PasteJsonScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحافظة فارغة — انسخ نص JSON أولاً.')),
      );
      return;
    }
    setState(() => _controller.text = text);
  }

  Future<void> _import() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصق نص JSON أولاً.')),
      );
      return;
    }
    await ImportHelper.importJsonContent(context, content);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('لصق نص JSON')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الصق هنا نص JSON الذي أعاده لك الذكاء الاصطناعي '
                  '(أو أي ملف سيناريو)، ثم اضغط "استيراد".',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: '{"title": "...", "scenes": [...]}',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.file_download, size: 20),
                      label: const Text('استيراد'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: const Text('لصق من الحافظة'),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(_controller.clear),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('مسح'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
