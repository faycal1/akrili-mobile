import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final currentLocale = ref.read(appLocaleProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tr.selectLanguageTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                  title: const Text('Français (Défaut)', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'fr'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: currentLocale.languageCode == 'fr',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale('fr');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Text('🇩🇿', style: TextStyle(fontSize: 24)),
                  title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'ar'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: currentLocale.languageCode == 'ar',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale('ar');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  selected: currentLocale.languageCode == 'en',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    ref.read(appLocaleProvider.notifier).setLocale('en');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showServerSettingsDialog(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final client = ref.read(apiClientProvider);
    final storage = ref.read(secureStorageProvider);
    final urlController = TextEditingController(text: client.dio.options.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.apiBaseUrlSetting),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environnements :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_outlined, size: 16),
                  label: const Text('Staging'),
                  onPressed: () {
                    urlController.text = AppConfig.stagingBaseUrl;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android_rounded, size: 16),
                  label: const Text('Émulateur'),
                  onPressed: () {
                    urlController.text = AppConfig.localEmulatorBaseUrl;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.laptop_rounded, size: 16),
                  label: const Text('Localhost'),
                  onPressed: () {
                    urlController.text = AppConfig.localDesktopBaseUrl;
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: AppConfig.stagingBaseUrl,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                client.updateBaseUrl(newUrl);
                await storage.saveBaseUrl(newUrl);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: Text(tr.save),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.confirmSignOutTitle),
        content: Text(tr.confirmSignOutMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
            child: Text(tr.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  String _getLocaleDisplayName(String code) {
    switch (code) {
      case 'fr':
        return 'Français (Défaut)';
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final activeRole = ref.watch(activeRoleModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.profileAndSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: tr.apiBaseUrlSetting,
            onPressed: () => _showServerSettingsDialog(context, ref),
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 44,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr.welcomeToAkrili,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr.signIn,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/register'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr.createAccount,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language_rounded, color: AppTheme.primary),
                            title: Text(tr.languageSetting),
                            subtitle: Text(_getLocaleDisplayName(appLocale.languageCode)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showLanguageBottomSheet(context, ref),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.tune_rounded, color: AppTheme.primary),
                            title: Text(tr.apiBaseUrlSetting),
                            subtitle: Text(
                              ref.watch(apiClientProvider).dio.options.baseUrl,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showServerSettingsDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final isHostMode = activeRole == 'host';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isVerified)
                                  const Icon(Icons.verified_rounded, size: 18, color: AppTheme.primary),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (user.email != null)
                              Text(
                                user.email!,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            if (user.phone != null)
                              Text(
                                user.phone!,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: user.roles.map((r) {
                                final label = r.toLowerCase() == 'tenant'
                                    ? tr.guestBadge
                                    : r.toLowerCase() == 'owner'
                                        ? tr.hostBadge
                                        : r.toLowerCase() == 'admin'
                                            ? tr.adminBadge
                                            : r.toUpperCase();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Mode Switcher (Guest / Host)
                if (user.isHost) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isHostMode
                          ? AppTheme.primary.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHostMode
                            ? AppTheme.primary.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isHostMode ? Icons.storefront_rounded : Icons.explore_outlined,
                          color: isHostMode ? AppTheme.primary : Colors.grey[700],
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHostMode ? tr.switchToGuestMode : tr.switchToHostMode,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isHostMode ? AppTheme.primary : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHostMode
                                    ? 'Gestion de vos annonces et réservations reçues'
                                    : 'Explorer et réserver des séjours en Algérie',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isHostMode,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            final newMode = val ? 'host' : 'guest';
                            ref.read(authNotifierProvider.notifier).switchRoleMode(newMode);
                            if (newMode == 'host') {
                              context.go('/host');
                            } else {
                              context.go('/explore');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Profile Menu Options
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.language_rounded, color: AppTheme.primary),
                        title: Text(tr.languageSetting),
                        subtitle: Text(_getLocaleDisplayName(appLocale.languageCode)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showLanguageBottomSheet(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune_rounded, color: AppTheme.primary),
                        title: Text(tr.apiBaseUrlSetting),
                        subtitle: Text(
                          ref.watch(apiClientProvider).dio.options.baseUrl,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showServerSettingsDialog(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
                        title: const Text('Confidentialité & Notifications'),
                        subtitle: const Text('Notifications push actives pour cet appareil'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondary,
                    side: const BorderSide(color: AppTheme.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(tr.signOut),
                ),
                const SizedBox(height: 20),

                // App version note
                const Center(
                  child: Text(
                    'Akrili Mobile v1.0.0 (Phase 4)\nLocations de courte durée en Algérie',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
