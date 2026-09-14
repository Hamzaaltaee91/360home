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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'سيتم حذف حسابك وجميع بياناتك نهائياً. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService().deleteAccount();
      if (mounted) {
        context.go('/login');
      }
    } catch (error) {
      if (mounted) {
        final message = error is AppException
            ? error.message
            : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: _userFuture,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(title: const Text('الملف الشخصي')),
          body: _buildBody(context, snapshot),
          bottomNavigationBar: _buildBottomNavigationBar(context, snapshot),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<AppUser> snapshot) {
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
          if (user.role == 'buyer') ...[
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('سجّل كوسيط'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/verification'),
            ),
            const Divider(height: 1),
          ],
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _confirmDeleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomNavigationBar(
    BuildContext context,
    AsyncSnapshot<AppUser> snapshot,
  ) {
    final user = snapshot.data;
    if (user == null) {
      return null;
    }

    if (user.role == 'buyer') {
      return BottomNavigationBar(
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'العروض',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'الدردشات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        onTap: (index) {
          if (index == 0) context.go('/buyer-home');
          if (index == 1) context.go('/browse-offers');
          if (index == 2) context.go('/chats');
          // index == 3: نحن بالفعل على '/profile' — لا شيء
        },
      );
    }

    if (user.role == 'realtor') {
      return BottomNavigationBar(
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'الدردشات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
        onTap: (index) {
          if (index == 0) context.go('/realtor-home');
          if (index == 1) context.go('/browse-requests');
          if (index == 2) context.go('/chats');
          // index == 3: نحن بالفعل على '/profile' — لا شيء
        },
      );
    }

    // admin (وأي دور آخر غير معروف) → لا شريط سفلي
    return null;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'buyer':
        return 'عادي';
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
