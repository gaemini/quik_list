import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:qr_check_app/features/home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다!'), backgroundColor: _primary),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user == null) throw Exception('로그인 정보를 가져올 수 없습니다');

      final isProfileComplete = await _authService.isProfileComplete(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 로그인 성공!'), backgroundColor: _primary),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isProfileComplete ? const HomePage() : const ProfileSetupPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithApple();
      final user = userCredential.user;

      if (user == null) throw Exception('로그인 정보를 가져올 수 없습니다');

      final isProfileComplete = await _authService.isProfileComplete(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple 로그인 성공!'), backgroundColor: _primary),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => isProfileComplete ? const HomePage() : const ProfileSetupPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 80, color: _primary),
                  const SizedBox(height: 16),
                  Text(
                    'QR 체크인',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '출석 관리를 간편하게',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      hintText: 'example@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '이메일을 입력해주세요';
                      if (!value.contains('@')) return '올바른 이메일 형식이 아닙니다';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      hintText: '최소 6자 이상',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: _neutral.withOpacity(0.5)),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
                      if (value.length < 6) return '비밀번호는 최소 6자 이상이어야 합니다';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('로그인'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _primary, width: 2)),
                    child: const Text('회원가입', style: TextStyle(color: _primary)),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: Divider(color: _neutral.withOpacity(0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('또는', style: TextStyle(color: _neutral.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Divider(color: _neutral.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('소셜 계정으로 회원가입', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _neutral.withOpacity(0.2)),
                      backgroundColor: Colors.white,
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24, width: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                    ),
                    label: const Text('Google 계정으로 계속하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _neutral)),
                  ),
                  const SizedBox(height: 12),

                  if (Platform.isIOS)
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleAppleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.black),
                        backgroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.apple, size: 24, color: Colors.white),
                      label: const Text('Apple 계정으로 계속하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  const SizedBox(height: 24),

                  Text(
                    '처음 사용하시는 경우 회원가입을 진행해주세요',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
