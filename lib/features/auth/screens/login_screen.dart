// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_provider.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../services/update_service.dart';
import 'register_screen.dart';
import 'phone_login_screen.dart';
import '../../discover/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Sıfırla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('E-posta adresinize şifre sıfırlama bağlantısı gönderilecek.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !AppUtils.isValidEmail(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir e-posta girin')),
                );
                return;
              }
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.sendPasswordResetEmail(email);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Şifre sıfırlama bağlantısı gönderildi!'), backgroundColor: AppTheme.successColor),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı!', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.successColor),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 45,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Tekrar Hoş Geldiniz',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giriş yaparak eşleşmeye devam edin',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Glassmorphic Form Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.email,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    fillColor: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade50,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Lütfen e-posta adresinizi girin';
                                    if (!AppUtils.isValidEmail(value.trim())) return AppStrings.invalidEmail;
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.password,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    fillColor: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade50,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Lütfen şifrenizi girin';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                    child: const Text(AppStrings.forgotPassword, style: TextStyle(color: AppTheme.primaryColor)),
                                  ),
                                ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: AppTheme.errorColor),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text(AppStrings.login),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('veya', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                      final isNewUser = await authProvider.signInWithGoogle();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Google ile giriş başarili!', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.successColor),
                                        );
                                        if (isNewUser) {
                                          // Yeni kullanici — cinsiyet ve dogum tarihi doldurmali
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                            (route) => false,
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('📅 Lütfen profilinizi tamamlayın (yaş ve cinsiyet gerekli)', style: TextStyle(color: Colors.white)),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 4),
                                            ),
                                          );
                                        } else {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hata: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.errorColor),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.g_mobiledata, size: 32, color: AppTheme.primaryColor),
                                  label: Text('Google ile giriş yap', style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
                                  },
                                  icon: const Icon(Icons.phone_android, size: 28, color: AppTheme.primaryColor),
                                  label: Text('Telefon ile giriş yap', style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(AppStrings.dontHaveAccount, style: TextStyle(color: Colors.white)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                          },
                          child: const Text(AppStrings.register, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sürüm ${AppConstants.appVersion}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
