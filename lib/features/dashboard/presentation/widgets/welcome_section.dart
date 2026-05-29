import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../features/auth/domain/auth_state.dart';

/// WelcomeSection — kartu selamat datang + jam realtime.
///
/// Lokasi: features/dashboard/presentation/widgets/welcome_section.dart
///
class WelcomeSection extends StatelessWidget {
  final String timeString;
  final String dateString;

  const WelcomeSection({
    super.key,
    required this.timeString,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context) {
    final userName = AuthState.instance.name;

    return Container(
      padding: EdgeInsets.all(context.scaledPadding(22)),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Radial glow ───────────────────────────────────────
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.accentColor.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 420;

              final greetingPart = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: context.scaledFont(13),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName.isNotEmpty ? userName : 'User',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: context.scaledFont(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.accentColor.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00FF88),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x8800FF88),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Monitoring Infrastruktur Jaringan',
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final clockPart = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: context.scaledFont(20),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateString,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WIB',
                      style: TextStyle(
                        color: context.accentColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: greetingPart),
                    const SizedBox(width: 16),
                    clockPart,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greetingPart,
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: clockPart),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
