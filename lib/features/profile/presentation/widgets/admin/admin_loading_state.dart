import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_loading_indicator.dart';

class AdminLoadingWidget extends StatelessWidget {
  final String message;

  const AdminLoadingWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AppLoadingIndicator(
      message: message,
      size: 28,
      showMessage: true,
    );
  }
}
