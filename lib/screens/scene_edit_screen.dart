import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/scene.dart';
import '../providers/app_provider.dart';

/// Form that edits every field of a scene (or creates a new one).
class SceneEditScreen extends StatefulWidget {
  final Project project;
  final Scene? scene;

  const SceneEditScreen({super.key, required this.project, this.scene});

  @override
  State<SceneEditScreen> createState() => _SceneEditScreenState();
}

class _SceneEditScreenState extends State<SceneEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dialogueController;
  late final TextEditingController _charactersController;
  late final TextEditingController _promptController;
  late final TextEditingController _cameraController;
  late final TextEditingController _extrasController;

  @override
  void initState() {
    super.initState();
    final scene = widget.scene;
    _numberController = TextEditingController(
      text: scene == null ? '' : scene.number.toString(),
    );
    _titleController = TextEditingController(text: scene?.title ?? '');
    _descriptionController =
        TextEditingController(text: scene?.description ?? '');
    _dialogueController = TextEditingController(text: scene?.dialogue ?? '');
    _charactersController =
        TextEditingController(text: scene?.characters ?? '');
    _promptController = TextEditingController(text: scene?.prompt ?? '');
    _cameraController =
        TextEditingController(text: scene?.cameraMovement ?? '');
    _extrasController = TextEditingController(
      text: scene == null || scene.extras.isEmpty
          ? ''
          : const JsonEncoder.withIndent('  ').convert(scene.extras),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dialogueController.dispose();
    _charactersController.dispose();
    _promptController.dispose();
    _cameraController.dispose();
    _extrasController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> extras = <String, dynamic>{};
    final extrasText = _extrasController.text.trim();
    if (extrasText.isNotEmpty) {
      try {
        final decoded = jsonDecode(extrasText);
        if (decoded is! Map<String, dynamic>) {
          _showError(
            'حقل البيانات الإضافية يجب أن يكون كائن JSON، مثال: {"duration": "8s"}',
          );
          return;
        }
        extras = decoded;
      } on FormatException {
        _showError('البيانات الإضافية ليست JSON صالحاً. راجع الأقواس والفواصل.');
        return;
      }
    }

    final number = int.tryParse(_numberController.text.trim()) ?? 0;
    final provider = context.read<AppProvider>();
    final existing = widget.scene;

    if (existing == null) {
      provider.addScene(
        widget.project.id,
        Scene(
          number: number,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dialogue: _dialogueController.text.trim(),
          characters: _charactersController.text.trim(),
          prompt: _promptController.text.trim(),
          cameraMovement: _cameraController.text.trim(),
          extras: extras,
        ),
      );
    } else {
      existing
        ..number = number
        ..title = _titleController.text.trim()
        ..description = _descriptionController.text.trim()
        ..dialogue = _dialogueController.text.trim()
        ..characters = _charactersController.text.trim()
        ..prompt = _promptController.text.trim()
        ..cameraMovement = _cameraController.text.trim()
        ..extras = extras;
      provider.updateScene(widget.project.id, existing);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ المشهد')),
    );
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.scene == null;
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isNew ? 'مشهد جديد' : 'تعديل المشهد ${widget.scene!.number}'),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field(
                  _numberController,
                  'رقم المشهد',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (int.tryParse(value.trim()) == null) {
                      return 'رقم المشهد يجب أن يكون عدداً صحيحاً';
                    }
                    return null;
                  },
                ),
                _field(
                  _titleController,
                  'اسم المشهد',
                  validator: (value) {
                    if ((value == null || value.trim().isEmpty) &&
                        _promptController.text.trim().isEmpty) {
                      return 'اسم المشهد أو الـ Prompt مطلوب';
                    }
                    return null;
                  },
                ),
                _field(
                  _descriptionController,
                  'وصف المشهد',
                  maxLines: 4,
                ),
                _field(
                  _dialogueController,
                  'الحوار',
                  maxLines: 4,
                ),
                _field(
                  _charactersController,
                  'وصف الشخصيات',
                  maxLines: 3,
                ),
                _field(
                  _promptController,
                  'Prompt توليد الفيديو',
                  maxLines: 6,
                  validator: (value) {
                    if ((value == null || value.trim().isEmpty) &&
                        _titleController.text.trim().isEmpty) {
                      return 'اسم المشهد أو الـ Prompt مطلوب';
                    }
                    return null;
                  },
                ),
                _field(
                  _cameraController,
                  'حركة الكاميرا',
                  maxLines: 2,
                ),
                _field(
                  _extrasController,
                  'بيانات إضافية (JSON) — مثال: {"duration": "8s", "location": "مروي"}',
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ المشهد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
