import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/network/health_provider.dart';
import '../../../../localization/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(healthProvider.notifier).checkServerHealth(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;
      final state = ref.read(authProvider);
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showComingSoon(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Masuk dengan $method segera hadir. Silakan gunakan Email.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final healthState = ref.watch(healthProvider);
    final isServerDown = healthState == HealthState.unhealthy;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => context.go('/onboarding'),
        ),
        actions: [
          // Hidden debug entry — long press
          GestureDetector(
            onLongPress: () => context.push('/debug'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Icon(Icons.more_horiz, color: Color(0xFFEBEBEB)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Modern Illustration
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Image.asset(
                        'assets/images/onboarding/login_illustration.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Title & Subtitle
                    Text(
                      'Masuk ke Kopdes',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Akses marketplace UMKM dan layanan koperasi digital desa.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Server health warning
                    if (isServerDown) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Server tidak dapat dihubungi. Silakan coba lagi nanti.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.errorText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Social login options
                    _buildSocialButton(
                      logo: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          children: [
                            TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                            TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                            TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                            TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                            TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                            TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                          ],
                        ),
                      ),
                      label: 'Masuk dengan Google',
                      onPressed: () => _showComingSoon('Google'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSocialButton(
                      logo: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF6B7280), size: 18),
                      label: 'Masuk dengan Nomor HP',
                      onPressed: () => _showComingSoon('Nomor HP'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSocialButton(
                      logo: const Icon(Icons.mail_outline_rounded, color: Color(0xFF6B7280), size: 18),
                      label: 'Masuk dengan Email',
                      onPressed: () {
                        // Tapping "Masuk dengan Email" focuses on the email input field
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Divider "atau"
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFEBEBEB), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                          child: Text(
                            'atau',
                            style: AppTypography.caption.copyWith(color: AppColors.mutedSoft),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFEBEBEB), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Credentials fields
                    TextFormField(
                      controller: _emailController,
                      enabled: !isServerDown,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.ink, fontSize: 15),
                      decoration: _buildInputDecoration(
                        label: 'Email',
                        icon: Icons.mail_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),

                    TextFormField(
                      controller: _passwordController,
                      enabled: !isServerDown,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.ink, fontSize: 15),
                      decoration: _buildInputDecoration(
                        label: 'Kata Sandi',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.muted,
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
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isServerDown
                            ? null
                            : () => context.go('/forgot-password'),
                        child: Text(
                          'Lupa Kata Sandi?',
                          style: AppTypography.buttonSm.copyWith(
                            color: isServerDown
                                ? AppColors.mutedSoft
                                : AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Login Button (Primary CTA)
                    Container(
                      height: 54,
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(211, 47, 47, 0.15),
                            offset: Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (authState.status == AuthStatus.loading || isServerDown)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24), // Rounded 24px
                          ),
                        ),
                        child: authState.status == AuthStatus.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Text(
                                'Masuk Sekarang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum memiliki akun? ',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                        ),
                        GestureDetector(
                          onTap: isServerDown
                              ? null
                              : () => context.go('/register'),
                          child: Text(
                            'Daftar',
                            style: AppTypography.buttonSm.copyWith(
                              color: isServerDown
                                  ? AppColors.mutedSoft
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  // Premium custom input decoration with rounded 16px, light gray border, and red focus state
  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.errorText, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
    );
  }

  // Premium social buttons: large, white background, soft border, left-side icon
  Widget _buildSocialButton({
    required Widget logo,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Color(0xFFEBEBEB), width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Large rounded corners 20px
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: logo,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
