// About Screen
//
// Displays app information, version, and links to the privacy policy and
// terms of service.

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.home_work_outlined,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text('دبّرلي', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'الإصدار $_appVersion',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'عن التطبيق'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'دبّرلي منصة عقارية تربط المشترين بالوسطاء العقاريين الموثوقين، '
                'وتتيح إنشاء الطلبات واستقبال العروض ومتابعتها بسهولة وأمان.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'قانوني'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('سياسة الخصوصية'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openPolicy(
                    context,
                    title: 'سياسة الخصوصية',
                    body: _privacyPolicy,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('شروط الاستخدام'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openPolicy(
                    context,
                    title: 'شروط الاستخدام',
                    body: _termsOfService,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'تواصل معنا'),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.email_outlined),
                  title: Text('البريد الإلكتروني'),
                  subtitle: Text('support@dabberli.com'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language_outlined),
                  title: Text('الموقع الإلكتروني'),
                  subtitle: Text('www.dabberli.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 دبّرلي. جميع الحقوق محفوظة.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _openPolicy(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PolicyScreen(title: title, body: body),
      ),
    );
  }

  static const String _privacyPolicy = '''
نحن في دبّرلي نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.

1. البيانات التي نجمعها
نجمع المعلومات التي تقدمها عند التسجيل، مثل الاسم والبريد الإلكتروني ورقم الهاتف، إضافة إلى بيانات الاستخدام اللازمة لتشغيل الخدمة.

2. كيفية استخدام البيانات
نستخدم بياناتك لتقديم خدمات المنصة، وربط المشترين بالوسطاء، وإرسال الإشعارات المتعلقة بالعروض والطلبات.

3. مشاركة البيانات
لا نشارك بياناتك الشخصية مع أطراف ثالثة إلا بموافقتك أو عند وجود التزام قانوني.

4. أمان البيانات
نطبق إجراءات أمنية مناسبة لحماية بياناتك من الوصول غير المصرح به.

5. حقوقك
يحق لك الوصول إلى بياناتك وتصحيحها أو طلب حذف حسابك في أي وقت.
''';

  static const String _termsOfService = '''
باستخدامك لتطبيق دبّرلي فإنك توافق على الشروط التالية:

1. الأهلية
يجب أن تكون بعمر 18 عاماً على الأقل لاستخدام المنصة.

2. مسؤولية المستخدم
تلتزم بتقديم معلومات صحيحة ودقيقة، وعدم استخدام المنصة لأي غرض غير قانوني.

3. المحتوى
أنت مسؤول عن المحتوى الذي تنشره، ولا يجوز نشر محتوى مضلل أو مخالف.

4. الوسطاء العقاريون
يخضع الوسطاء لعملية توثيق، ويمكن إيقاف الحسابات المخالفة.

5. التعديلات
نحتفظ بحق تعديل هذه الشروط، وسيتم إشعارك بأي تغييرات جوهرية.
''';
}

class _PolicyScreen extends StatelessWidget {
  const _PolicyScreen({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
