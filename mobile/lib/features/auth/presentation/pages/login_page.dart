import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:alertaya/core/constants/app_colors.dart';
import 'package:alertaya/core/constants/app_text_styles.dart';
import 'package:alertaya/core/widgets/alertaya_button.dart';
import 'package:alertaya/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;
  bool _isGoogleAuth = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _formKey.currentState?.reset();
      _confirmPasswordController.clear();
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    _isGoogleAuth = false;
    final bloc = context.read<AuthBloc>();
    if (_isRegistering) {
      bloc.add(AuthEmailSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    } else {
      bloc.add(AuthEmailSignInRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  void _signInWithGoogle() {
    FocusScope.of(context).unfocus();
    _isGoogleAuth = true;
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navegación inmediata — el snackbar puede vivir en la página destino.
          context.go('/map');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_mapError(state.message)),
              backgroundColor: AppColors.severityCritical,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: AutofillGroup(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical -
                      32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      // ── Logo (versión negativa: campana blanca + "Ya" ámbar)
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/logo/alertaya_logo_horizontal_white.svg',
                          height: 56,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // ── Headline
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _isRegistering
                              ? 'Crea tu cuenta'
                              : 'Ingresa a tu cuenta',
                          key: ValueKey(_isRegistering),
                          style: AppTextStyles.headlineMd,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anónimo para todos, más seguro para ti.',
                        style: AppTextStyles.bodyMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // ── Google
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state is AuthLoading && _isGoogleAuth;
                          return _GoogleSignInButton(
                            isLoading: isLoading,
                            onPressed:
                                state is AuthLoading ? null : _signInWithGoogle,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('o', style: AppTextStyles.bodyMd),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ── Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        decoration: _inputDecoration(
                          hint: 'correo@gmail.com',
                          icon: Icons.mail_outline,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu email';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // ── Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegistering
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted:
                            _isRegistering ? null : (_) => _submit(),
                        autofillHints: [
                          _isRegistering
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: _inputDecoration(
                          hint: 'Contraseña',
                          icon: Icons.lock_outline,
                          helper: _isRegistering ? 'Mínimo 6 caracteres' : null,
                          suffix: _VisibilityToggle(
                            obscured: _obscurePassword,
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      // ── Confirmar password (solo registro) — con AnimatedSize
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: _isRegistering
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  autofillHints: const [
                                    AutofillHints.newPassword
                                  ],
                                  decoration: _inputDecoration(
                                    hint: 'Confirma tu contraseña',
                                    icon: Icons.lock_outline,
                                    suffix: _VisibilityToggle(
                                      obscured: _obscureConfirmPassword,
                                      onTap: () => setState(() =>
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (!_isRegistering) return null;
                                    if (v == null || v.isEmpty) {
                                      return 'Confirma tu contraseña';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 24),
                      // ── Submit
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading =
                              state is AuthLoading && !_isGoogleAuth;
                          return AlertaYaButton(
                            label: _isRegistering ? 'Crear cuenta' : 'Ingresar',
                            onPressed: state is AuthLoading ? null : _submit,
                            isLoading: isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // ── Toggle login/register
                      Center(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          onPressed: _toggleMode,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.bodyMd,
                              children: [
                                TextSpan(
                                  text: _isRegistering
                                      ? '¿Ya tienes cuenta? '
                                      : '¿No tienes cuenta? ',
                                ),
                                TextSpan(
                                  text: _isRegistering
                                      ? 'Ingresar'
                                      : 'Regístrate',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // ── Términos & privacidad (solo registro) + identidad anónima
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        alignment: Alignment.bottomCenter,
                        child: _isRegistering
                            ? const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Al crear tu cuenta, aceptas nuestros Términos del servicio y nuestra Política de privacidad.',
                                  style: AppTextStyles.labelMd,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Tu identidad es anónima para otros usuarios y autoridades.',
                          style: AppTextStyles.labelMd,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    String? helper,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd,
        helperText: helper,
        helperStyle: AppTextStyles.labelMd,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.severityCritical),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.severityCritical),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _mapError(String raw) {
    if (raw.contains('unauthorized') || raw.contains('Unauthorized')) {
      return 'Email o contraseña incorrectos';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con ese email';
    }
    if (raw.contains('weak-password')) {
      return 'La contraseña es muy débil. Usa mínimo 6 caracteres';
    }
    if (raw.contains('network_error') ||
        raw.contains('network') ||
        raw.contains('Network')) {
      return 'Sin conexión. Verifica tu internet';
    }
    if (raw.contains('rateLimit') || raw.contains('RateLimit')) {
      return 'Demasiados intentos. Espera unos minutos';
    }
    if (raw.contains('sign_in_failed') || raw.contains('DEVELOPER_ERROR')) {
      return 'Error al iniciar sesión con Google. Verifica tu conexión o intenta más tarde';
    }
    return 'Ocurrió un error. Intenta de nuevo';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.onPressed});
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.outline),
        disabledForegroundColor: AppColors.onSurfaceVariant,
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/google_g.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Continuar con Google',
                  style: AppTextStyles.bodyLg
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onTap});
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.onSurfaceVariant,
      ),
      splashRadius: 22,
      tooltip: obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
      onPressed: onTap,
    );
  }
}
