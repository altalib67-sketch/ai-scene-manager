# مدير المشاهد — AI Scene Manager

تطبيق Flutter لإدارة وتنظيم مشاهد الأفلام والفيديوهات المُولّدة بالذكاء الاصطناعي،
اعتماداً على ملفات JSON يولّدها نموذج AI خارجي.

## ما الذي يفعله التطبيق؟

1. **استيراد ملف JSON** يحتوي على مشاهد سيناريو (من الهاتف أو الكمبيوتر).
2. **تحويل كل مشهد إلى بطاقة مستقلة** تلقائياً: رقم المشهد واسمه، الوصف، الحوار،
   الشخصيات، الـ Prompt، حركة الكاميرا، وأي حقول إضافية في الملف.
3. **البحث الفوري** برقم المشهد أو الاسم أو الوصف أو الحوار أو الـ Prompt.
4. **تعديل المشاهد وحذفها وتكرارها وإعادة ترتيبها** بالسحب.
5. **نسخ Prompt أي مشهد بضغطة واحدة** (أو نسخ المشهد كاملاً).
6. **حفظ المشاريع محلياً** (تخزين محلي، بلا خادم وبلا اشتراك).
7. **تصدير المشروع مرة أخرى بصيغة JSON** بنفس البنية الأصلية، بحيث يمكن
   استيراده مجدداً دون فقدان أي بيانات.

واجهة عربية كاملة (RTL)، تصميم Material 3، وضع فاتح وداكن، ومتجاوبة مع
الهواتف والأجهزة اللوحية والكمبيوتر.

## صيغة ملف JSON

يقبل التطبيق عدة أشكال:

```json
{
  "title": "أهرامات مروي — قصة قصيرة",
  "scenes": [
    {
      "number": 1,
      "title": "شروق الشمس على أهرامات مروي",
      "description": "فجر هادئ فوق أهرامات مروي القديمة...",
      "dialogue": "أمين: شوف يا سارة، الشمس طالعة...",
      "characters": "أمين: شاب سوداني في الثلاثينات...",
      "prompt": "Cinematic wide shot of the ancient pyramids of Meroe...",
      "camera_movement": "لقطة واسعة ثابتة ثم تقريب بطيء",
      "duration": "8s",
      "location": "أهرامات مروي، السودان"
    }
  ]
}
```

كما يقبل قائمة مشاهد مباشرة `[{...}, {...}]`، أو الشكل
`{"project": {"title": "...", "scenes": [...]}}`.

أسماء الحقول البديلة المقبولة: `scene_number` بدل `number`، و`name` /
`scene_title` بدل `title`، و`dialog` بدل `dialogue`، و`video_prompt` /
`scene_prompt` بدل `prompt`، و`camera` / `cameraMovement` بدل
`camera_movement`. أي حقل آخر (مثل `duration` و`location`) يُحفظ كما هو
ويُعاد تصديره دون فقدان.

ملف تجريبي جاهز: `assets/sample_scenes.json` (3 مشاهد من قصة سودانية قصيرة
عند أهرامات مروي وضفة النيل) — جرّبه من زر «تحميل مشروع تجريبي» في التطبيق.

## التشغيل

```bash
flutter pub get
flutter run            # على جهاز أو محاكي متصل
flutter run -d chrome  # على الويب
flutter build apk --release
flutter build web --release
```

## الاختبارات والتحليل

```bash
flutter analyze   # لا مشاكل (0 issues)
flutter test      # 15 اختباراً ناجحاً
```

## الإصدارات المُتحقق منها (2026-11-18)

- Flutter: **3.50.0** (stable، revision ab2912035e، بتاريخ 2026-11-09)
- Dart: **3.14.0** — DevTools 2.61.0
- **ملاحظة مهمة عن Flutter 3.50:** حزمة `package:flutter/material.dart`
  أصبحت مهملة (deprecated بعد v3.47.0) واستُبدلت بالحزمة الرسمية المستقلة
  `package:material_ui/material_ui.dart` — وهذا ما يستخدمه قالب
  `flutter create` وما يستخدمه هذا التطبيق في كل الملفات. كذلك
  `GlobalCupertinoLocalizations` يؤخذ من حزمة `cupertino_ui`.
- Android Gradle Plugin (AGP): **9.3.1**
- Gradle: **9.5.0** (`gradle-9.5.0-all.zip`)
- Kotlin: **2.4.20**
- Java / Kotlin JVM target: **17**
- compileSdk: **36** — targetSdk: **36** — minSdk: **24** — NDK: **28.2.13676358**
  (قيم افتراضية من إضافة Flutter Gradle، من `android/app/build.gradle.kts`)
- الحزم (من `pubspec.lock`): material_ui **1.11.1**، provider **6.1.5+1**،
  shared_preferences **2.5.6**، file_picker **13.4.0**، uuid **4.6.0**،
  cupertino_ui **1.1.7**، flutter_lints **6.0.0**، cupertino_icons **1.0.9**

## بنية المجلدات

```
lib/
  main.dart                  # نقطة الدخول، MaterialApp عربي RTL
  models/
    scene.dart               # نموذج المشهد + الحقول الإضافية extras
    project.dart             # نموذج المشروع
  services/
    json_service.dart        # تحليل JSON والتحقق منه + التصدير
    storage_service.dart     # الحفظ المحلي (SharedPreferences)
  providers/
    app_provider.dart        # الحالة (ChangeNotifier) + الحفظ التلقائي
  screens/
    projects_screen.dart     # قائمة المشاريع
    scenes_screen.dart       # مشاهد المشروع + البحث + إعادة الترتيب
    scene_edit_screen.dart   # تحرير مشهد
  widgets/
    scene_card.dart          # بطاقة المشهد القابلة للطي
    project_card.dart        # بطاقة المشروع
  theme/
    app_theme.dart           # Material 3 فاتح/داكن (Teal 0xFF0D7377)
assets/
  sample_scenes.json         # مشروع تجريبي
test/
  json_service_test.dart     # اختبارات الاستيراد والتصدير
  scene_model_test.dart      # اختبارات النماذج
```

## ملاحظات

- لا يعتمد التطبيق على أي خادم خارجي أو اشتراك مدفوع.
- مفتاح التخزين المحلي: `ai_scene_manager_projects_v1`.
- عند البحث، يُعطَّل السحب لإعادة الترتيب مؤقتاً حتى لا يختل ترتيب المشاهد
  الحقيقي؛ ألغِ البحث ثم أعد الترتيب.
- على الشاشات الواسعة تُوسَّط البطاقات بعرض أقصى 900px؛ القائمة تبقى قائمة
  (بدل شبكة) لأن إعادة الترتيب بالسحب تعمل بشكل موثوق في القائمة.
- في file_picker 13.x تغيّرت الواجهة: `FilePicker.pickFiles()` ساكنة وتعيد
  `List<PlatformFile>`، وتُقرأ المحتويات عبر `readAsBytes()`، و`saveFile()`
  تعيد `Uri?` — والتطبيق يستخدم هذه الواجهة الجديدة.

---

## AI Scene Manager (English summary)

A Flutter app to manage AI-generated film/video scenes from JSON files:
import a scenario JSON, get one card per scene, search instantly, edit /
delete / duplicate / reorder scenes, copy any scene's prompt with one tap,
save projects locally (SharedPreferences, no server, no subscription), and
export the project back to JSON with the original structure preserved
(including unknown fields). Arabic RTL UI, Material 3, light + dark themes,
responsive layout. See the Arabic section above for the JSON schema and
how to run it.
