import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/voice_languages.dart';
import '../../../core/di/injector.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/voice/voice_assistant_bloc.dart';

/// Hands-free voice conversation with the assistant.
///
/// Opened from the chat screen's top bar. Expects a [ChatBloc] above it
/// in the tree (the chat screen passes its own with `BlocProvider.value`)
/// so each finished question/answer also lands in the chat log.
class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  /// Pushes the voice screen on top of the chat, sharing the chat's bloc.
  static Future<void> open(BuildContext context) {
    final chatBloc = context.read<ChatBloc>();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => BlocProvider.value(
          value: chatBloc,
          child: const VoiceAssistantScreen(),
        ),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => autoInjector.get<VoiceAssistantBloc>()
        ..add(const VoiceSessionStarted()),
      child: const _VoiceAssistantView(),
    );
  }
}

class _VoiceAssistantView extends StatefulWidget {
  const _VoiceAssistantView();

  @override
  State<_VoiceAssistantView> createState() => _VoiceAssistantViewState();
}

class _VoiceAssistantViewState extends State<_VoiceAssistantView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _close() {
    context.read<VoiceAssistantBloc>().add(const VoiceSessionEnded());
    Navigator.of(context).maybePop();
  }

  Future<void> _pickLanguage() async {
    final bloc = context.read<VoiceAssistantBloc>();
    final chosen = await showModalBottomSheet<VoiceLanguage>(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(
        selected: bloc.state.language,
        supports: bloc.state.supports,
      ),
    );
    if (chosen != null) bloc.add(VoiceLanguageChanged(chosen));
  }

  @override
  Widget build(BuildContext context) {
    final accent = SectionTheme.home.accent;
    return BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
      listenWhen: (a, b) => a.lastExchange?.id != b.lastExchange?.id,
      listener: (context, state) {
        final ex = state.lastExchange;
        if (ex == null) return;
        // Mirror the spoken turn into the chat so it's there to read back.
        context.read<ChatBloc>().add(
              ChatVoiceExchangeAdded(transcript: ex.transcript, reply: ex.reply),
            );
      },
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            context.read<VoiceAssistantBloc>().add(const VoiceSessionEnded());
          }
        },
        child: Scaffold(
          backgroundColor: SectionTheme.home.backgroundGradient[0],
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SectionTheme.home.backgroundGradient[2],
                  SectionTheme.home.backgroundGradient[0],
                  SectionTheme.home.backgroundGradient[1],
                ],
              ),
            ),
            child: SafeArea(
              child: BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _topBar(state),
                      const Gap(8),
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: _Orb(
                            phase: state.phase,
                            level: state.level,
                            pulse: _pulse,
                            accent: accent,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context
                                  .read<VoiceAssistantBloc>()
                                  .add(const VoiceOrbTapped());
                            },
                          ),
                        ),
                      ),
                      _statusLine(state),
                      _liveTranscript(state),
                      const Gap(12),
                      Expanded(
                        flex: 4,
                        child: _transcriptPanel(state),
                      ),
                      _controls(state),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar: close · title · language ────────────────────────
  Widget _topBar(VoiceAssistantState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: DashboardColors.textOnDark, size: 28),
            tooltip: 'Back to chat',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KStyles().bold(
                  text: 'Ayurlive Assistant',
                  size: 15,
                  color: DashboardColors.textOnDark,
                ),
                KStyles().reg(
                  text: 'Voice conversation',
                  size: 10,
                  color: DashboardColors.textOnDarkMuted,
                ),
              ],
            ),
          ),
          _LanguageChip(language: state.language, onTap: _pickLanguage),
        ],
      ),
    );
  }

  // ── What the assistant is doing right now ────────────────────
  Widget _statusLine(VoiceAssistantState state) {
    final accent = SectionTheme.home.accent;
    String text;
    Color color = DashboardColors.textOnDarkSecondary;
    switch (state.phase) {
      case VoicePhase.idle:
        text = 'Tap to speak';
        break;
      case VoicePhase.listening:
        text = state.heardSpeech ? 'Listening…' : "Go ahead, I'm listening";
        color = accent;
        break;
      case VoicePhase.thinking:
        text = 'Thinking…';
        break;
      case VoicePhase.speaking:
        text = state.muted ? 'Answer (muted)' : 'Speaking…';
        color = const Color(0xFF4ADE80);
        break;
      case VoicePhase.error:
        text = state.error ?? 'Something went wrong';
        color = const Color(0xFFFCA5A5);
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey('${state.phase}-$text'),
          child: KStyles().semiBold(
            text: text,
            size: 14,
            color: color,
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ),
      ),
    );
  }

  // ── The words being recognised, live, while the user talks ──
  Widget _liveTranscript(VoiceAssistantState state) {
    final show = (state.phase == VoicePhase.listening ||
            state.phase == VoicePhase.thinking) &&
        state.liveTranscript.trim().isNotEmpty;
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: show
          ? Padding(
              padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 96),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    state.liveTranscript,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DashboardColors.textOnDark.withValues(
                          alpha: state.phase == VoicePhase.thinking ? 0.7 : 1),
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  // ── Latest question + answer ─────────────────────────────────
  Widget _transcriptPanel(VoiceAssistantState state) {
    final ex = state.lastExchange;
    if (ex == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: KStyles().reg(
            text:
                'Ask about revenue, patients, appointments or anything on your dashboard. '
                'I will listen in ${state.language.name} and answer out loud.',
            size: 12.5,
            height: 1.45,
            color: DashboardColors.textOnDarkMuted,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ex.transcript.isNotEmpty) ...[
                _label('You said'),
                const Gap(4),
                SelectableText(
                  ex.transcript,
                  style: const TextStyle(
                    color: DashboardColors.textOnDarkSecondary,
                    fontSize: 13,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Gap(12),
              ],
              if (ex.replyPlainText.isNotEmpty) ...[
                _label('Assistant'),
                const Gap(4),
                SelectableText(
                  ex.replyPlainText,
                  style: const TextStyle(
                    color: DashboardColors.textOnDark,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ] else if (ex.transcript.isNotEmpty)
                KStyles().reg(
                  text: 'The answer was spoken only.',
                  size: 12,
                  color: DashboardColors.textOnDarkMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => KStyles().semiBold(
        text: text.toUpperCase(),
        size: 10,
        height: 1.2,
        color: DashboardColors.textOnDarkMuted,
      );

  // ── Bottom controls: mute · mic · end ────────────────────────
  Widget _controls(VoiceAssistantState state) {
    final accent = SectionTheme.home.accent;
    final listening = state.phase == VoicePhase.listening;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundControl(
            icon: state.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            label: state.muted ? 'Unmute' : 'Mute',
            background: Colors.white.withValues(alpha: state.muted ? 0.22 : 0.1),
            foreground: DashboardColors.textOnDark,
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<VoiceAssistantBloc>().add(const VoiceMuteToggled());
            },
          ),
          _RoundControl(
            icon: listening ? Icons.stop_rounded : Icons.mic_rounded,
            label: switch (state.phase) {
              VoicePhase.listening => state.heardSpeech ? 'Send' : 'Stop',
              VoicePhase.thinking => 'Cancel',
              VoicePhase.speaking => 'Interrupt',
              VoicePhase.idle || VoicePhase.error => 'Speak',
            },
            size: 68,
            background: listening ? accent : accent.withValues(alpha: 0.85),
            foreground: Colors.white,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<VoiceAssistantBloc>().add(const VoiceOrbTapped());
            },
          ),
          _RoundControl(
            icon: Icons.close_rounded,
            label: 'End',
            background: const Color(0xFFEF4444).withValues(alpha: 0.9),
            foreground: Colors.white,
            onTap: _close,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  The orb: breathes when idle, swells with the mic level when
//  listening, orbits while thinking, ripples while speaking.
// ─────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final VoicePhase phase;
  final double level;
  final Animation<double> pulse;
  final Color accent;
  final VoidCallback onTap;

  const _Orb({
    required this.phase,
    required this.level,
    required this.pulse,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (_, __) {
          final t = pulse.value; // 0..1, loops every 2.4s
          final breathe = 0.5 + 0.5 * math.sin(t * 2 * math.pi);

          final Color core;
          double ring1, ring2, ring3;
          switch (phase) {
            case VoicePhase.listening:
              core = accent;
              // Rings expand with how loud the speaker is, plus a slow
              // breath so silence doesn't look frozen.
              ring1 = 1.10 + level * 0.30 + breathe * 0.03;
              ring2 = 1.30 + level * 0.55 + breathe * 0.05;
              ring3 = 1.50 + level * 0.85 + breathe * 0.07;
              break;
            case VoicePhase.thinking:
              core = accent.withValues(alpha: 0.75);
              ring1 = 1.12 + breathe * 0.08;
              ring2 = 1.28 + (1 - breathe) * 0.10;
              ring3 = 1.45 + breathe * 0.12;
              break;
            case VoicePhase.speaking:
              core = const Color(0xFF4ADE80);
              // Fast ripple: three rings offset in phase.
              double ripple(double offset) =>
                  0.5 + 0.5 * math.sin((t * 3 + offset) * 2 * math.pi);
              ring1 = 1.10 + ripple(0.00) * 0.14;
              ring2 = 1.30 + ripple(0.33) * 0.22;
              ring3 = 1.52 + ripple(0.66) * 0.30;
              break;
            case VoicePhase.error:
              core = const Color(0xFFEF4444);
              ring1 = 1.10;
              ring2 = 1.25;
              ring3 = 1.40;
              break;
            case VoicePhase.idle:
              core = accent.withValues(alpha: 0.55);
              ring1 = 1.08 + breathe * 0.04;
              ring2 = 1.22 + breathe * 0.06;
              ring3 = 1.36 + breathe * 0.08;
              break;
          }

          const base = 120.0;
          return SizedBox(
            width: base * 2.6,
            height: base * 2.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ring(base * ring3, core.withValues(alpha: 0.10)),
                _ring(base * ring2, core.withValues(alpha: 0.16)),
                _ring(base * ring1, core.withValues(alpha: 0.26)),
                if (phase == VoicePhase.thinking)
                  Transform.rotate(
                    angle: t * 2 * math.pi,
                    child: SizedBox(
                      width: base * 1.02,
                      height: base * 1.02,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: 0.28,
                        strokeCap: StrokeCap.round,
                        color: Colors.white.withValues(alpha: 0.85),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                Container(
                  width: base * 0.92,
                  height: base * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.35),
                      colors: [
                        Color.lerp(core, Colors.white, 0.35)!,
                        core,
                        Color.lerp(core, Colors.black, 0.25)!,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: core.withValues(alpha: 0.55),
                        blurRadius: 30 + level * 30,
                        spreadRadius: 2 + level * 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    switch (phase) {
                      VoicePhase.listening => Icons.mic_rounded,
                      VoicePhase.thinking => Icons.auto_awesome_rounded,
                      VoicePhase.speaking => Icons.graphic_eq_rounded,
                      VoicePhase.error => Icons.refresh_rounded,
                      VoicePhase.idle => Icons.mic_none_rounded,
                    },
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ring(double size, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Small round control with a caption
// ─────────────────────────────────────────────────────────────
class _RoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final double size;
  final VoidCallback onTap;

  const _RoundControl({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: foreground, size: size * 0.46),
            ),
          ),
        ),
        const Gap(6),
        KStyles().reg(
          text: label,
          size: 11,
          color: DashboardColors.textOnDarkSecondary,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Language chip + picker sheet
// ─────────────────────────────────────────────────────────────
class _LanguageChip extends StatelessWidget {
  final VoiceLanguage language;
  final VoidCallback onTap;

  const _LanguageChip({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate_rounded,
                  color: DashboardColors.textOnDark, size: 16),
              const Gap(6),
              KStyles().semiBold(
                text: language.name,
                size: 12,
                height: 1.2,
                color: DashboardColors.textOnDark,
              ),
              const Gap(2),
              const Icon(Icons.expand_more_rounded,
                  color: DashboardColors.textOnDarkMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final VoiceLanguage selected;

  /// Whether this device's recogniser handles a language. Unsupported
  /// ones are shown dimmed and cannot be picked.
  final bool Function(VoiceLanguage) supports;

  const _LanguageSheet({required this.selected, required this.supports});

  @override
  Widget build(BuildContext context) {
    final accent = SectionTheme.home.accent;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(14),
            KStyles().bold(
              text: 'Speak and listen in',
              size: 15,
              color: DashboardColors.textOnDark,
            ),
            const Gap(2),
            KStyles().reg(
              text: 'The assistant hears you and answers in this language.',
              size: 11.5,
              color: DashboardColors.textOnDarkMuted,
            ),
            const Gap(8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                itemCount: VoiceLanguages.all.length,
                separatorBuilder: (_, __) => const Gap(2),
                itemBuilder: (_, i) {
                  final lang = VoiceLanguages.all[i];
                  final isSelected = lang == selected;
                  final available = supports(lang);
                  final textColor = available
                      ? DashboardColors.textOnDark
                      : DashboardColors.textOnDark.withValues(alpha: 0.35);
                  return Material(
                    color: isSelected
                        ? accent.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      dense: true,
                      enabled: available,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: available
                          ? () => Navigator.of(context).pop(lang)
                          : null,
                      leading: Container(
                        width: 40,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: available ? 0.08 : 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: KStyles().bold(
                          text: lang.shortLabel,
                          size: 11,
                          color: isSelected ? accent : textColor,
                        ),
                      ),
                      title: KStyles().semiBold(
                        text: lang.name,
                        size: 13.5,
                        height: 1.2,
                        color: textColor,
                      ),
                      subtitle: KStyles().reg(
                        text: available
                            ? lang.nativeName
                            : 'Not available on this device',
                        size: 11.5,
                        color: available
                            ? DashboardColors.textOnDarkMuted
                            : const Color(0xFFFCA5A5).withValues(alpha: 0.8),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: accent, size: 20)
                          : available
                              ? null
                              : Icon(Icons.block_rounded,
                                  color: DashboardColors.textOnDarkMuted
                                      .withValues(alpha: 0.5),
                                  size: 18),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
