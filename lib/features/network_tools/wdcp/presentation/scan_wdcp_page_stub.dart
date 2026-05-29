/// Stub ScanWdcpPage untuk Web — tidak import dart:io.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ScanWdcpPage extends StatelessWidget {
  const ScanWdcpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_access_disabled_outlined,
                size: 48, color: context.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('Scan WDCP hanya tersedia di Desktop',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
