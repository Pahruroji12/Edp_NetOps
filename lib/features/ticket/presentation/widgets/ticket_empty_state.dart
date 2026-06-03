import 'package:flutter/material.dart';
import 'package:edp_netops/core/widgets/app_empty_state.dart';

class TicketEmptyState extends StatelessWidget {
  const TicketEmptyState({super.key, this.message, this.subtitle});

  final String? message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: message ?? 'Tidak ada tiket ditemukan',
      message: subtitle ?? 'Coba ubah filter atau kata kunci pencarian',
      icon: Icons.inbox_outlined,
    );
  }
}
