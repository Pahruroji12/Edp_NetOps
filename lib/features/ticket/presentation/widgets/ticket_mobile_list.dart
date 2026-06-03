import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/ticket_model.dart';
import 'ticket_card.dart';

class TicketMobileList extends StatelessWidget {
  final List<TicketModel> filtered;
  final Function(TicketModel) onDetail;
  final Function(TicketModel) onUpdate;
  final Function(TicketModel) onDelete;

  const TicketMobileList({
    key,
    required this.filtered,
    required this.onDetail,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        context.pagePaddingH, 8, context.pagePaddingH, 24,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) => TicketCard(
        ticket: filtered[i],
        index: i,
        onDetail: () => onDetail(filtered[i]),
        onUpdate: () => onUpdate(filtered[i]),
        onDelete: () => onDelete(filtered[i]),
      ),
    );
  }
}
