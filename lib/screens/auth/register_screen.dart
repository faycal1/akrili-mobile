import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'tenant';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _parseErrorMessage(dynamic error, AppLocalizations tr) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return tr.connectionTimeoutMsg;
      }
      if (error.type == DioExceptionType.connectionError) {
        return tr.cannotConnectMsg;
      }
      final response = error.response;
      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('errors') && data['errors'] is Map) {
            final errorsMap = data['errors'] as Map;
            if (errorsMap.isNotEmpty) {
              final firstValue = errorsMap.values.first;
              if (firstValue is List && firstValue.isNotEmpty) {
                return firstValue.first.toString();
              } else if (firstValue is String) {
                return firstValue;
              }
            }
          }
          if (data.containsKey('message') && data['message'] is String) {
            return data['message'] as String;
          }
        }
      }
      if (response?.statusCode == 422) {
        return 'Veuillez vérifier les informations saisies.';
      }
      if (response?.statusCode == 429) {
        return tr.tooManyAttemptsMsg;
      }
      if (response?.statusCode == 500) {
        return tr.serverErrorMsg;
      }
      return error.message ?? tr.serverErrorMsg;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmPasswordController.text,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        final activeRole = ref.read(activeRoleModeProvider);
        if (activeRole == 'host') {
          context.go('/host');
        } else {
          context.go('/explore');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseErrorMessage(e, context.tr);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showServerSettingsDialog() {
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

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.createAccount),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/explore');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: tr.apiBaseUrlSetting,
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Header
                    // Brand Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr.joinAkrili,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.joinSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account Type Selector Cards
                    Row(
                      children: [
                        Expanded(
                          child: _RoleSelectCard(
                            title: tr.roleRenter,
                            subtitle: 'Je cherche un logement',
                            icon: Icons.luggage_rounded,
                            isSelected: _selectedRole == 'tenant',
                            onTap: () => setState(() => _selectedRole = 'tenant'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RoleSelectCard(
                            title: tr.roleHost,
                            subtitle: 'Je loue mes biens',
                            icon: Icons.vpn_key_rounded,
                            isSelected: _selectedRole == 'owner',
                            onTap: () => setState(() => _selectedRole = 'owner'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.secondary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Elevated Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                        ),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          // Full Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: tr.fullName,
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 20),
                              hintText: 'ex. Amina Benali',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return tr.enterFullName;
                              }
                              if (value.trim().length < 2) {
                                return 'Le nom doit comporter au moins 2 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: tr.emailAddress,
                              prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.primary, size: 20),
                              hintText: 'nom@exemple.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return tr.enterValidEmail;
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return tr.enterValidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone Field (Optional)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: tr.phoneOptional,
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primary, size: 20),
                              hintText: '+213 555 12 34 56',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: tr.password,
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.enterPassword;
                              }
                              if (value.length < 6) {
                                return tr.passwordMinLength;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: tr.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return tr.confirmPassword;
                              }
                              if (value != _passwordController.text) {
                                return tr.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          // Submit Button with Gradient & Shadow
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isLoading ? null : AppTheme.primaryButtonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          tr.createAccount,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Link to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr.alreadyHaveAccount,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.pushReplacement('/login');
                            }
                          },
                          child: Text(
                            tr.signIn,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),

                    // Continue as guest
                    TextButton(
                      onPressed: () => context.go('/explore'),
                      child: Text(
                        tr.continueAsGuest,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(isDark ? 0.2 : 0.08)
                : (isDark ? Colors.grey[900] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primary : (isDark ? Colors.white12 : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? AppTheme.primary : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

