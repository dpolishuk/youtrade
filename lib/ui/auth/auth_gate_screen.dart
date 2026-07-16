import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failures.dart';
import '../../domain/auth/auth_failure.dart';
import '../../presentation/auth/auth_guard_provider.dart';
import '../../presentation/auth/auth_state.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/theme/theme_extensions.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return switch (authState) {
      AuthAuthenticated() => widget.child,
      AuthUnknown() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthUnauthenticated() || AuthError() => _buildGate(authState),
    };
  }

  Widget _buildGate(AuthState state) {
    final failure = state is AuthError ? state.failure : null;
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final accent = appColors?.accent ?? theme.colorScheme.primary;
    final foreground = appColors?.foreground ?? theme.colorScheme.onSurface;
    final muted = appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant;
    final cardBg = const Color(0xFF0E131F);
    final borderColor = appColors?.borderSubtle ?? const Color(0x12FFFFFF);
    final subtleText = appColors?.subtleText ?? const Color(0x8CFFFFFF);

    final notifier = ref.read(authNotifierProvider.notifier);
    final pinSet = notifier.isPinSet;
    final canUseBiometrics = notifier.isBiometricAvailable && pinSet;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _GateCard(
                borderColor: borderColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Logo(accent: accent),
                    const SizedBox(height: 28),
                    Text(
                      pinSet ? 'YouTrade is locked' : 'Set up PIN',
                      textAlign: TextAlign.center,
                      style: AppTheme.display(color: foreground, fontSize: 28)
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.02,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pinSet
                          ? 'Authenticate to continue'
                          : 'Create a 4-digit PIN to secure YouTrade',
                      textAlign: TextAlign.center,
                      style: AppTheme.mono(
                        color: muted,
                        fontSize: 13,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),
                    if (canUseBiometrics) ...[
                      _BiometricButton(
                        accent: accent,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        subtleText: subtleText,
                        onPressed: () {
                          ref
                              .read(authNotifierProvider.notifier)
                              .authenticateWithBiometrics();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _PinField(
                      controller: _pinController,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      foreground: foreground,
                      subtleText: subtleText,
                      hint: pinSet ? 'Enter PIN' : 'Choose a 4-digit PIN',
                      onSubmitted: (_) => _submitPin(),
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      accent: accent,
                      foregroundColor: const Color(0xFF06080F),
                      label: pinSet ? 'Unlock with PIN' : 'Set PIN',
                      onPressed: _submitPin,
                    ),
                    if (failure != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        _failureMessage(failure),
                        textAlign: TextAlign.center,
                        style: AppTheme.mono(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPin() {
    final pin = _pinController.text;
    ref.read(authNotifierProvider.notifier).authenticateWithPin(pin);
  }

  String _failureMessage(Failure failure) {
    if (failure is AuthFailure) return failure.message;
    return failure.message;
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: -4,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(34, 34),
          painter: _LockPainter(color: Colors.white),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({
    required this.accent,
    required this.cardBg,
    required this.borderColor,
    required this.subtleText,
    required this.onPressed,
  });

  final Color accent;
  final Color cardBg;
  final Color borderColor;
  final Color subtleText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fingerprint, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                'Unlock with biometrics',
                style: AppTheme.mono(
                  color: subtleText,
                  fontSize: 12,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.cardBg,
    required this.borderColor,
    required this.foreground,
    required this.subtleText,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final Color cardBg;
  final Color borderColor;
  final Color foreground;
  final Color subtleText;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          style: AppTheme.mono(
            color: foreground,
            fontSize: 18,
          ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.mono(
              color: subtleText,
              fontSize: 14,
            ).copyWith(fontWeight: FontWeight.w500),
            border: InputBorder.none,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.accent,
    required this.foregroundColor,
    required this.label,
    required this.onPressed,
  });

  final Color accent;
  final Color foregroundColor;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.45),
            blurRadius: 22,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: foregroundColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: AppTheme.display(
            color: foregroundColor,
            fontSize: 15,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('authGateCard'),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131F),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _LockPainter extends CustomPainter {
  const _LockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bodyPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.18,
            size.height * 0.44,
            size.width * 0.64,
            size.height * 0.46,
          ),
          Radius.circular(size.width * 0.08),
        ),
      );

    final shacklePath = Path()
      ..addArc(
        Rect.fromLTWH(
          size.width * 0.26,
          size.height * 0.16,
          size.width * 0.48,
          size.width * 0.44,
        ),
        3.14,
        3.14,
      );

    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(shacklePath, paint);

    final keyholePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final keyholeY = size.height * 0.62;
    canvas.drawCircle(
      Offset(size.width * 0.5, keyholeY - size.height * 0.06),
      size.width * 0.07,
      keyholePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.44,
        keyholeY - size.height * 0.04,
        size.width * 0.12,
        size.height * 0.16,
      ),
      keyholePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
