import 'package:flutter/material.dart';
import '../../domain/ticket_model.dart';
import '../ticket_controller.dart';
import 'ticket_card.dart';

class TicketDesktopTable extends StatefulWidget {
  final TicketController ctrl;
  final List<TicketModel> filtered;
  final Function(TicketModel) onDetail;
  final Function(TicketModel) onUpdate;
  final Function(TicketModel) onDelete;

  const TicketDesktopTable({
    super.key,
    required this.ctrl,
    required this.filtered,
    required this.onDetail,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TicketDesktopTable> createState() => _TicketDesktopTableState();
}

class _TicketDesktopTableState extends State<TicketDesktopTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final double tableWidth = viewportWidth > 1170 ? viewportWidth : 1170;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: false,
          trackVisibility: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  TicketTableHeader(ctrl: widget.ctrl),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: widget.filtered.length,
                      itemBuilder: (_, i) => TicketCard(
                        ticket: widget.filtered[i],
                        index: i,
                        onDetail: () => widget.onDetail(widget.filtered[i]),
                        onUpdate: () => widget.onUpdate(widget.filtered[i]),
                        onDelete: () => widget.onDelete(widget.filtered[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
