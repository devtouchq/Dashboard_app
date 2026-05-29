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
import '../login/login_screen.dart';

class BaseUrlScreen extends StatefulWidget {
  const BaseUrlScreen({super.key});

  @override
  State<BaseUrlScreen> createState() => _BaseUrlScreenState();
}

class _BaseUrlScreenState extends State<BaseUrlScreen>
    with TickerProviderStateMixin {
  static const _tag = 'BaseUrlScreen';

  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  late AnimationController _entry;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    final storage = autoInjector.get<LocalStorageService>();
    final saved = storage.baseUrl;
    AppLogger.info(_tag, 'init — saved baseUrl="${saved ?? "<null>"}"');

    // Prefill if there's a saved URL (and it's not the broken https one
    // that confused us). User can edit and submit.
    if (saved != null && saved.isNotEmpty) {
      _urlController.text = saved;
    }

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entry, curve: Curves.elasticOut),
    );

    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final entered = _urlController.text.trim();
    AppLogger.info(_tag, 'submit — entered="$entered"');
    context.read<AuthBloc>().add(BaseUrlSubmitted(entered));
  }

  Future<void> _resetAll() async {
    AppLogger.info(_tag, 'resetAll (long-press)');
    final storage = autoInjector.get<LocalStorageService>();
    await storage.clearAll();
    _urlController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = SectionTheme.home;

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
              if (state.status == AuthStatus.baseUrlSaved) {
                AppLogger.info(_tag, 'baseUrl saved → navigate to Login');
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => const LoginScreen(),
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
                    content: Text(state.errorMessage ?? 'Failed to save'),
                    backgroundColor: Colors.redAccent,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Gap(40),
                      GestureDetector(
                        onLongPress: _resetAll,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: _logo(theme),
                        ),
                      ),
                      const Gap(28),
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: Column(
                            children: [
                              KStyles().bold(
                                text: StringConstants.setupServer,
                                size: 26,
                                color: DashboardColors.textOnDark,
                              ),
                              const Gap(6),
                              KStyles().reg(
                                text: StringConstants.enterServerUrl,
                                size: 13,
                                color: DashboardColors.textOnDarkSecondary,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Gap(36),
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: _form(),
                        ),
                      ),
                      const Gap(10),
                      // Quick "Clear" button so the user can wipe a bad
                      // URL without long-pressing the logo.
                      FadeTransition(
                        opacity: _fade,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetAll,
                            icon: Icon(
                              Icons.refresh,
                              size: 14,
                              color: DashboardColors.iconRed,
                            ),
                            label: KStyles().med(
                              text: 'Clear and start over',
                              size: 11,
                              color: DashboardColors.iconRed,
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                      const Gap(35),
                      // FadeTransition(
                      //   opacity: _fade,
                      //   child: KStyles().reg(
                      //     text: 'Tip: include http:// or https:// in the URL',
                      //     size: 11,
                      //     color: DashboardColors.textOnDarkMuted,
                      //   ),
                      // ),
                      const Gap(20),
                      FadeTransition(
                        opacity: _fade,
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) => _submitButton(
                            loading: state.status == AuthStatus.baseUrlSaving,
                          ),
                        ),
                      ),
                      const Spacer(),
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

  Widget _logo(SectionTheme theme) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.cloud_outlined,
        size: 48,
        color: theme.accentSoft,
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: _glassField(
        controller: _urlController,
        label: StringConstants.serverUrl,
        hint: 'http://192.168.1.100/webapis',
        icon: Icons.link,
        keyboardType: TextInputType.url,
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return StringConstants.urlRequired;
          }
          final trimmed = v.trim();
          if (trimmed.length < 4 || !trimmed.contains('.')) {
            return StringConstants.urlInvalid;
          }
          return null;
        },
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
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
                    text: StringConstants.continueText,
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
