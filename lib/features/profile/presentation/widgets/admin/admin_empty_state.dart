import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_empty_state.dart';

class AdminEmptyWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyWidget({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Tidak Ada Data',
      message: message,
      icon: icon,
    );
  }
}
