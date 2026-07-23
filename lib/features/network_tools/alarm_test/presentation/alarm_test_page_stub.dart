import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AlarmTestPage extends StatelessWidget {
  const AlarmTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.desktop_access_disabled_outlined,
              size: 48,
              color: context.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Test Alarm Dial hanya tersedia di Desktop (Windows)',
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
