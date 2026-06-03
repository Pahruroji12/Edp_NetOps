import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import '../ping_controller.dart';

class PingManualInputCard extends StatefulWidget {
  final PingController engine;

  const PingManualInputCard({
    super.key,
    required this.engine,
  });

  @override
  State<PingManualInputCard> createState() => _PingManualInputCardState();
}

class _PingManualInputCardState extends State<PingManualInputCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.engine.config.manualIps);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronisasi jika config berubah dari luar (misal auto-ping berjalan)
    if (_controller.text != widget.engine.config.manualIps && !widget.engine.isScanning) {
      _controller.text = widget.engine.config.manualIps;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            context,
            "Input IP Manual",
            "Ketik/Paste IP dari Notepad (Satu IP per baris)",
            Icons.paste_outlined,
            const Color(0xFF00B4D8),
          ),
          const SizedBox(height: 20),
          Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: context.accentColor,
                selectionColor: context.accentColor.withOpacity(0.3),
                selectionHandleColor: context.accentColor,
              ),
            ),
            child: TextField(
              controller: _controller,
              cursorColor: context.accentColor,
              maxLines: 5,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText:
                    "Contoh:\n10.73.10.1\n10.73.20.1\n10.73.30.1\ndst ...",
                hintStyle: TextStyle(
                  color: context.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                filled: true,
                fillColor: context.surfaceColor,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.accentColor,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.borderColor.withOpacity(0.5),
                  ),
                ),
              ),
              onChanged: (val) => widget.engine.setManualIps(val),
              enabled: !widget.engine.isScanning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
