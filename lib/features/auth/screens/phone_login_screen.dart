// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../services/auth_provider.dart';
import '../../../core/theme.dart';
import '../../discover/screens/home_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Lütfen geçerli bir numara girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ensure phone format, defaults to +90 if omitted
      String formattedPhone = phone;
      if (!phone.startsWith('+')) {
        formattedPhone = '+90' + phone.replaceAll(RegExp(r'[^0-9]'), '');
      }

      await authProvider.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (Android only)
          await _signIn(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String friendlyMessage = 'Doğrulama başarısız oldu. Lütfen tekrar deneyin.';
          if (e.code == 'too-many-requests') {
            friendlyMessage = 'Çok fazla SMS talebinde bulundunuz. Güvenlik nedeniyle geçici olarak engellendiniz. Lütfen birkaç saat sonra tekrar deneyin.';
          } else if (e.code == 'invalid-phone-number') {
            friendlyMessage = 'Girdiğiniz telefon numarası geçersiz. Lütfen kontrol edip tekrar deneyin.';
          } else if (e.code == 'network-request-failed') {
            friendlyMessage = 'İnternet bağlantınızı kontrol edin.';
          } else if (e.code == 'quota-exceeded') {
            friendlyMessage = 'Uygulamanın günlük SMS limiti doldu.';
          }
          setState(() {
            _isLoading = false;
            _errorMessage = friendlyMessage;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            _codeSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6 || _verificationId == null) {
      setState(() => _errorMessage = 'Geçerli bir kod girin');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _signIn(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kod hatalı veya süresi dolmuş';
      });
    }
  }

  Future<void> _signIn(AuthCredential credential) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithPhoneCredential(credential);
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Giriş yapılamadı: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(Icons.message_outlined, size: 60, color: AppTheme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            _codeSent ? 'Kodu Doğrula' : 'Telefonla Giriş',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _codeSent 
                              ? 'Telefonunuza gelen 6 haneli kodu girin.' 
                              : 'Telefon numaranıza bir doğrulama kodu göndereceğiz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 32),
                          if (!_codeSent)
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Telefon Numarası',
                                hintText: '5XX XXX XX XX',
                                prefixIcon: const Icon(Icons.phone),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade50,
                              ),
                            )
                          else
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, letterSpacing: 8),
                              decoration: InputDecoration(
                                hintText: '------',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF2A2A35) : Colors.grey.shade50,
                                counterText: '',
                              ),
                            ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.errorColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading 
                                ? null 
                                : (_codeSent ? _verifyCode : _sendCode),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_codeSent ? 'Doğrula' : 'Kod Gönder'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
