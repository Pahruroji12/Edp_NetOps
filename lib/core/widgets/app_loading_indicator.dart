import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final bool showMessage;
  final bool isCard;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 28.0,
    this.showMessage = true,
    this.isCard = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: context.accentColor,
        strokeWidth: size * 0.08,
      ),
    );

    if (isCard) {
      indicator = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.accentColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: context.accentColor.withOpacity(0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: indicator,
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          if (showMessage && message != null) ...[
            SizedBox(height: isCard ? 16 : 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
