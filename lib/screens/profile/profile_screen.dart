import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<AppUser> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = SupabaseService().getCurrentUser();
  }

  void _reload() {
    setState(() {
      _userFuture = SupabaseService().getCurrentUser();
    });
  }

  Future<void> _signOut() async {
    await SupabaseService().signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: FutureBuilder<AppUser>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is AppException
                ? error.message
                : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(user: user),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<AppUser>(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                    if (updated != null) {
                      _reload();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل الملف الشخصي'),
                ),
                const SizedBox(height: 24),
                _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: user.email,
                ),
                _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: user.phone ?? 'غير محدد',
                ),
                _ProfileInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'نوع الحساب',
                  value: _roleLabel(user.role),
                ),
                _ProfileInfoTile(
                  icon: Icons.verified_outlined,
                  label: 'حالة التوثيق',
                  value: user.isVerified ? 'موثق' : 'غير موثق',
                ),
                _ProfileInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'تاريخ الانضمام',
                  value: DateFormat('yyyy/MM/dd').format(user.createdAt),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ProfileInfoTile(
                    icon: Icons.info_outline,
                    label: 'نبذة',
                    value: user.bio!,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'buyer':
        return 'مشتري';
      case 'realtor':
        return 'وسيط عقاري';
      case 'admin':
        return 'مدير';
      default:
        return role;
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: user.profilePictureUrl != null
              ? NetworkImage(user.profilePictureUrl!)
              : null,
          child: user.profilePictureUrl == null
              ? Text(
                  _initials(user.fullName),
                  style: theme.textTheme.headlineMedium,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(user.fullName, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(user.email, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0];
    return '${parts.first[0]}${parts.last[0]}';
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
