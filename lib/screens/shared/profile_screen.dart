import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final tr = context.tr;
    final currentLocale = ref.read(appLocaleProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tr.selectLanguageTitle,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Text('🇫🇷', style: TextStyle(fontSize: 26)),
                  title: const Text('Français (Défaut)', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'fr'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentLocale.languageCode == 'fr',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(appLocaleProvider.notifier).setLocale('fr');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Text('🇩🇿', style: TextStyle(fontSize: 26)),
                  title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'ar'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentLocale.languageCode == 'ar',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(appLocaleProvider.notifier).setLocale('ar');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 26)),
                  title: const Text('English', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLocale.languageCode == 'en'
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentLocale.languageCode == 'en',
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
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

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    final tr = context.tr;
    final currentThemeMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tr.chooseThemeTitle,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded, size: 26, color: AppTheme.primary),
                  title: Text(tr.themeSystem, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentThemeMode == ThemeMode.system
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentThemeMode == ThemeMode.system,
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_rounded, size: 26, color: Colors.amber),
                  title: Text(tr.themeLight, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentThemeMode == ThemeMode.light
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentThemeMode == ThemeMode.light,
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.nightlight_round, size: 26, color: AppTheme.secondary),
                  title: Text(tr.themeDark, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentThemeMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  selected: currentThemeMode == ThemeMode.dark,
                  selectedTileColor: AppTheme.primary.withOpacity(0.08),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
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
    HapticFeedback.lightImpact();
    final tr = context.tr;
    final client = ref.read(apiClientProvider);
    final storage = ref.read(secureStorageProvider);
    final urlController = TextEditingController(text: client.dio.options.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.cloud_sync_rounded, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(tr.apiBaseUrlSetting, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environnements disponibles :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.cloud_outlined, size: 16),
                  label: const Text('Staging (HTTPS)'),
                  onPressed: () {
                    urlController.text = AppConfig.stagingBaseUrl;
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android_rounded, size: 16),
                  label: const Text('Émulateur 10.0.2.2'),
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
            const SizedBox(height: 16),
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
              HapticFeedback.mediumImpact();
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                client.updateBaseUrl(newUrl);
                await storage.saveBaseUrl(newUrl);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr.save),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(tr.signOut),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte Akrili ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
            ),
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

  String _getThemeDisplayName(BuildContext context, ThemeMode mode) {
    final tr = context.tr;
    switch (mode) {
      case ThemeMode.light:
        return tr.themeLight;
      case ThemeMode.dark:
        return tr.themeDark;
      case ThemeMode.system:
        return tr.themeSystem;
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final activeRole = ref.watch(activeRoleModeProvider);
    final appLocale = ref.watch(appLocaleProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
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
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.primaryButtonShadow,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      tr.welcomeToAkrili,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          tr.createAccount,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.language_rounded, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(tr.languageSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(_getLocaleDisplayName(appLocale.languageCode)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showLanguageBottomSheet(context, ref),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getThemeIcon(currentThemeMode), color: AppTheme.primary, size: 20),
                            ),
                            title: Text(tr.themeModeSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(_getThemeDisplayName(context, currentThemeMode)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showThemeBottomSheet(context, ref),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(tr.apiBaseUrlSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              ref.watch(apiClientProvider).dio.options.baseUrl,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Radiant Gradient User Profile Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.primaryButtonShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
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
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (user.email != null)
                              Text(
                                user.email!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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

                // Fluid Mode Switcher (Guest / Host)
                if (user.isHost) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHostMode
                            ? AppTheme.primary.withOpacity(0.5)
                            : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                        width: isHostMode ? 1.5 : 1,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isHostMode
                                ? AppTheme.primary.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isHostMode ? Icons.storefront_rounded : Icons.explore_rounded,
                            color: isHostMode ? AppTheme.primary : Colors.grey[700],
                            size: 26,
                          ),
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
                                    ? 'Gérer vos annonces et réservations'
                                    : 'Découvrir des séjours en Algérie',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isHostMode,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            HapticFeedback.mediumImpact();
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

                // Settings Group 1: Preferences & System
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.language_rounded, color: AppTheme.primary, size: 20),
                        ),
                        title: Text(tr.languageSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_getLocaleDisplayName(appLocale.languageCode)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showLanguageBottomSheet(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getThemeIcon(currentThemeMode), color: AppTheme.primary, size: 20),
                        ),
                        title: Text(tr.themeModeSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_getThemeDisplayName(context, currentThemeMode)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showThemeBottomSheet(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                        ),
                        title: Text(tr.apiBaseUrlSetting, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          ref.watch(apiClientProvider).dio.options.baseUrl,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showServerSettingsDialog(context, ref),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_outlined, color: AppTheme.primary, size: 20),
                        ),
                        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Alertes de réservation et messages'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/notifications'),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    tr.signOut,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 20),

                // App version & branding footer
                Center(
                  child: Text(
                    'Akrili Mobile v1.0.0\nPlateforme de locations de courte durée en Algérie 🇩🇿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      height: 1.4,
                    ),
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
