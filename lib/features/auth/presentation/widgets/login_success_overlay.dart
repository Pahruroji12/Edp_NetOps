import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

class LoginSuccessOverlay extends StatelessWidget {
  final bool show;
  final String successName;
  final String successStatus;
  final AnimationController pulseController;
  final Animation<double> pulseAnimation;

  const LoginSuccessOverlay({
    super.key,
    required this.show,
    required this.successName,
    required this.successStatus,
    required this.pulseController,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSuccessSpinner(context),
                  const SizedBox(height: 32),
                  Text(
                    'Halo, $successName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      successStatus,
                      key: ValueKey(successStatus),
                      style: TextStyle(
                        color: context.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessSpinner(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: pulseController,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.accentColor.withOpacity(0.2),
                  width: 3,
                ),
              ),
            ),
          ),
          RotationTransition(
            turns: pulseController,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                border: Border(
                  top: BorderSide(color: Color(0xFF00E676), width: 3),
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: pulseAnimation,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: context.accentColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: context.accentColor.withOpacity(0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFF00E676),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
