// Settings Screen
//
// Lets the user change the app language, toggle notifications, and switch
// between light and dark themes. Preferences are persisted locally through
// [SettingsService].

import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _settings.load();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'اللغة'),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'ar',
                  groupValue: _settings.language,
                  title: const Text('العربية'),
                  onChanged: (value) {
                    if (value != null) _settings.setLanguage(value);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: _settings.language,
                  title: const Text('English'),
                  onChanged: (value) {
                    if (value != null) _settings.setLanguage(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'الإشعارات'),
          Card(
            child: SwitchListTile(
              value: _settings.notificationsEnabled,
              title: const Text('تفعيل الإشعارات'),
              subtitle: const Text('استلام تنبيهات العروض والطلبات'),
              onChanged: _settings.setNotificationsEnabled,
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'المظهر'),
          Card(
            child: SwitchListTile(
              value: _settings.darkMode,
              title: const Text('الوضع الليلي'),
              subtitle: const Text('استخدام المظهر الداكن'),
              onChanged: _settings.setDarkMode,
            ),
          ),
        ],
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
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
