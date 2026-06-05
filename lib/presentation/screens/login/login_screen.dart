import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/di/injector.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../base_url/base_url_screen.dart';
import '../branch/branch_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const _tag = 'LoginScreen';

  final _formKey = GlobalKey<FormState>();
  final _accountIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _entry;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  // Staggered field reveals — each delayed slightly.
  late Animation<double> _accountFieldAnim;
  late Animation<double> _usernameFieldAnim;
  late Animation<double> _passwordFieldAnim;
  late Animation<double> _rememberMeAnim;
  late Animation<double> _buttonAnim;

  @override
  void initState() {
    super.initState();
    AppLogger.info(_tag, 'init');

    // Prefill if rememberMe was enabled previously
    final storage = autoInjector.get<LocalStorageService>();
    if (storage.rememberMe) {
      _accountIdController.text = storage.savedAccountId ?? '';
      _usernameController.text = storage.savedUsername ?? '';
      _rememberMe = true;
    }

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));

    // Build per-field reveals using interval curves
    _accountFieldAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
    );
    _usernameFieldAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
    );
    _passwordFieldAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
    );
    _rememberMeAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    );
    _buttonAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _accountIdController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppLogger.info(_tag, 'submit');
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(LoginSubmitted(
          accountId: _accountIdController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        ));
  }

  Future<void> _changeServer() async {
    AppLogger.info(_tag, 'changeServer requested');
    final storage = autoInjector.get<LocalStorageService>();
    await storage.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BaseUrlScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const theme = SectionTheme.home;

    return Scaffold(
      backgroundColor: theme.backgroundGradient[0],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) => prev.status != curr.status,
            listener: (context, state) {
              if (state.status == AuthStatus.loginSuccess) {
                AppLogger.info(_tag, 'login success → navigate to Branch');
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => const BranchScreen(),
                    transitionsBuilder: (_, anim, __, child) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                  ),
                );
              } else if (state.status == AuthStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(state.errorMessage ?? StringConstants.loginFailed),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(40),
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: _header(theme),
                        ),
                      ),
                      const Gap(32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _staggered(
                              _accountFieldAnim,
                              _glassField(
                                controller: _accountIdController,
                                label: StringConstants.accountId,
                                hint: StringConstants.accountIdHint,
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? StringConstants.accountIdRequired
                                        : null,
                              ),
                            ),
                            const Gap(14),
                            _staggered(
                              _usernameFieldAnim,
                              _glassField(
                                controller: _usernameController,
                                label: StringConstants.username,
                                hint: StringConstants.usernameHint,
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? StringConstants.usernameRequired
                                        : null,
                              ),
                            ),
                            const Gap(14),
                            _staggered(
                              _passwordFieldAnim,
                              _glassField(
                                controller: _passwordController,
                                label: StringConstants.password,
                                hint: StringConstants.passwordHint,
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                trailing: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: DashboardColors.textOnDarkMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? StringConstants.passwordRequired
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(14),
                      _staggered(_rememberMeAnim, _rememberMeRow()),
                      const Gap(28),
                      _staggered(
                        _buttonAnim,
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => _submitButton(
                            loading: state.status == AuthStatus.loggingIn,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Gap(12),
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

  Widget _staggered(Animation<double> anim, Widget child) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _header(SectionTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              Icons.lock_outlined,
              color: theme.accentSoft,
              size: 28,
            ),
          ),
        ),
        const Gap(20),
        Center(
          child: KStyles().bold(
            text: StringConstants.logintext,
            size: 28,
            color: DashboardColors.textOnDark,
          ),
        ),
        const Gap(6),
        InkWell(
          onTap: _changeServer,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: theme.accentSoft,
                ),
                const Gap(4),
                KStyles().med(
                  text: 'Change server',
                  size: 12,
                  color: theme.accentSoft,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? trailing,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KStyles().med(
          text: label,
          size: 12,
          color: DashboardColors.textOnDarkSecondary,
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            autocorrect: false,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: DashboardColors.textOnDark,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: DashboardColors.textOnDarkMuted, size: 20),
              suffixIcon: trailing,
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Roboto',
                color: DashboardColors.textOnDarkMuted,
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              errorStyle: const TextStyle(
                fontFamily: 'Roboto',
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rememberMeRow() {
    return InkWell(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    _rememberMe ? SectionTheme.home.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _rememberMe
                      ? SectionTheme.home.accent
                      : Colors.white.withValues(alpha: 0.4),
                  width: 1.6,
                ),
              ),
              child: _rememberMe
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const Gap(10),
            KStyles().med(
              text: StringConstants.rememberMe,
              size: 13,
              color: DashboardColors.textOnDarkSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton({required bool loading}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: SectionTheme.home.accent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor:
              SectionTheme.home.accent.withValues(alpha: 0.5),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.4),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KStyles().semiBold(
                    text: StringConstants.signIn,
                    size: 15,
                    color: Colors.white,
                  ),
                  const Gap(8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}
