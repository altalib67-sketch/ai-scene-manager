import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/prompt_builder.dart';

/// Screen where the user writes a story idea and gets a ready-made
/// instruction ("الأمر") to paste into an external AI tool. The AI then
/// replies with a scenario JSON file that this app can import.
class PromptBuilderScreen extends StatefulWidget {
  const PromptBuilderScreen({super.key});

  @override
  State<PromptBuilderScreen> createState() => _PromptBuilderScreenState();
}

class _PromptBuilderScreenState extends State<PromptBuilderScreen> {
  static const _genres = [
    'دراما',
    'أكشن',
    'كوميديا',
    'خيال علمي',
    'تاريخي',
    'رومانسي',
    'وثائقي',
    'أخرى',
  ];
  static const _durations = ['5s', '8s', '10s'];

  final _ideaController = TextEditingController();
  final _charactersController = TextEditingController();
  final _settingController = TextEditingController();
  final _customGenreController = TextEditingController();

  String? _genre;
  String _duration = '8s';
  int _sceneCount = 8;
  String? _command;

  @override
  void dispose() {
    _ideaController.dispose();
    _charactersController.dispose();
    _settingController.dispose();
    _customGenreController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _generate() {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) {
      _showMessage('اكتب فكرة القصة أولاً.');
      return;
    }
    final genre = _genre == 'أخرى'
        ? _customGenreController.text.trim()
        : (_genre ?? '');
    setState(() {
      _command = PromptBuilder.buildScenarioCommand(
        idea: idea,
        genre: genre,
        sceneCount: _sceneCount,
        characters: _charactersController.text,
        setting: _settingController.text,
        sceneDuration: _duration,
      );
    });
    _showMessage('تم توليد الأمر — انسخه والصقه في أداة ذكاء اصطناعي.');
  }

  Future<void> _copyCommand() async {
    final command = _command;
    if (command == null || command.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: command));
    if (!mounted) return;
    _showMessage('تم نسخ الأمر');
  }

  void _clear() {
    setState(() {
      _ideaController.clear();
      _charactersController.clear();
      _settingController.clear();
      _customGenreController.clear();
      _genre = null;
      _duration = '8s';
      _sceneCount = 8;
      _command = null;
    });
  }

  void _fillSample() {
    setState(() {
      _ideaController.text = PromptBuilder.sampleIdea;
      _genre = 'دراما';
      _charactersController.text =
          'أمين: شاب سوداني في الثلاثينات، يرتدي جلابية بيضاء. '
          'سارة: فتاة في العشرينات، تحمل كاميرا قديمة.';
      _settingController.text = 'أهرامات مروي، ضفة النيل، قرية نوبية — السودان';
      _sceneCount = 8;
      _duration = '8s';
      _command = null;
    });
    _showMessage('تم تعبئة مثال — عدّل عليه ثم اضغط "توليد الأمر".');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('توليد أمر سيناريو')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اكتب فكرتك، وسيقوم التطبيق بدمجها مع أمر يشرح لأداة '
                  'الذكاء الاصطناعي كيف ترد عليك: ملف JSON جاهز للاستيراد.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ideaController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'فكرة القصة *',
                    hintText:
                        'مثال: قصة قصيرة عن شاب يزور أهرامات مروي عند الشروق...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _genre,
                  decoration: const InputDecoration(
                    labelText: 'نوع الفيلم',
                    border: OutlineInputBorder(),
                  ),
                  items: _genres
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() => _genre = value),
                ),
                if (_genre == 'أخرى') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customGenreController,
                    decoration: const InputDecoration(
                      labelText: 'اكتب النوع',
                      hintText: 'مثال: إثارة وتشويق',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'عدد المشاهد:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _sceneCount.toDouble(),
                        min: 3,
                        max: 20,
                        divisions: 17,
                        label: '$_sceneCount',
                        onChanged: (value) =>
                            setState(() => _sceneCount = value.round()),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$_sceneCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _charactersController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'الشخصيات (اختياري)',
                    hintText: 'مثال: أمين: شاب سوداني... سارة: فتاة تحمل كاميرا...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _settingController,
                  decoration: const InputDecoration(
                    labelText: 'المكان والزمان (اختياري)',
                    hintText: 'مثال: أهرامات مروي، السودان — عند شروق الشمس',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _duration,
                  decoration: const InputDecoration(
                    labelText: 'مدة كل مشهد',
                    border: OutlineInputBorder(),
                  ),
                  items: _durations
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _duration = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'سيكون الحوار باللهجة السودانية، والـ Prompt بالإنجليزية.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      label: const Text('توليد الأمر'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _command == null ? null : _copyCommand,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ الأمر'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _fillSample,
                      icon: const Icon(Icons.lightbulb_outline, size: 18),
                      label: const Text('مثال'),
                    ),
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('مسح'),
                    ),
                  ],
                ),
                if (_command != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: colorScheme.primaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.terminal,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الأمر المُولَّد',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'نسخ الأمر',
                                icon: Icon(
                                  Icons.copy,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                onPressed: _copyCommand,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            _command!,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'بعد أن يرد الذكاء الاصطناعي بملف JSON، الصقه من: '
                    'المشاريع ← استيراد ← لصق نص JSON.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
