import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
              'Android Emulator: http://10.0.2.2:8000\nAppareil physique: http://<LAN-IP>:8000',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'http://10.0.2.2:8000',
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
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/logo_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr.joinAkrili,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr.joinSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account Type Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'tenant'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'tenant'
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    tr.roleRenter,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _selectedRole == 'tenant'
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = 'owner'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'owner'
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    tr.roleHost,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _selectedRole == 'owner'
                                          ? Colors.white
                                          : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr.fullName,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
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
                        prefixIcon: const Icon(Icons.email_outlined),
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
                        prefixIcon: const Icon(Icons.phone_outlined),
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
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
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

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr.createAccount,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Link to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr.alreadyHaveAccount,
                          style: const TextStyle(fontSize: 14),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
