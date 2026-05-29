/// Stub WdcpControlPage untuk Web — tidak import dart:io.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WdcpControlPage extends StatelessWidget {
  final String ip;
  final String storeName;
  final String storeCode;

  const WdcpControlPage({
    super.key,
    required this.ip,
    required this.storeName,
    required this.storeCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        title: Text('WDCP Control — $storeCode',
            style: TextStyle(color: context.textPrimary, fontSize: 14)),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_access_disabled_outlined,
                size: 48, color: context.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('WDCP Control hanya tersedia di Desktop',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
