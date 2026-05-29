/// Stub FtpPage untuk Web — tidak import dart:io / ftpconnect.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FtpPage extends StatelessWidget {
  final String targetIp;
  final String storeCode;
  final String storeName;

  const FtpPage({
    super.key,
    required this.targetIp,
    required this.storeCode,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        title: Text('FTP — $storeCode',
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
            Text('FTP Transfer hanya tersedia di Desktop',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('Gunakan aplikasi Desktop untuk mengakses fitur ini.',
                style: TextStyle(
                    color: context.textSecondary.withOpacity(0.6),
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
