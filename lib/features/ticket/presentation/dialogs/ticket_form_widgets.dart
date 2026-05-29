import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Reusable form widgets untuk TicketDialog.
///
/// Lokasi: features/ticket/presentation/dialogs/ticket_form_widgets.dart
///

// ── Email Chip ─────────────────────────────────────────────────────
class EmailChip extends StatelessWidget {
  final String email;
  final bool isPrimary;

  const EmailChip({super.key, required this.email, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? context.accentColor.withOpacity(0.10)
            : context.primaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? context.accentColor.withOpacity(0.30)
              : context.borderColor,
        ),
      ),
      child: Text(
        email,
        style: TextStyle(
          fontSize: 11,
          color: isPrimary ? context.accentColor : context.textSecondary,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

// ── Field Label ────────────────────────────────────────────────────
class TicketFieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isRequired;

  const TicketFieldLabel({
    super.key,
    required this.text,
    required this.icon,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: context.textSecondary),
          const SizedBox(width: 5),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
              letterSpacing: 0.7,
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Collapsible Email Chips ────────────────────────────────────────
class CollapsibleEmailChips extends StatelessWidget {
  final List<String> emails;
  final bool isPrimary;
  final int maxVisible;

  const CollapsibleEmailChips({
    super.key,
    required this.emails,
    this.isPrimary = false,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) return const SizedBox.shrink();
    final shown = emails.take(maxVisible).toList();
    final hidden = emails.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...shown.map((e) => EmailChip(email: e, isPrimary: isPrimary)),
        if (hidden > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.accentColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '+$hidden lainnya',
              style: TextStyle(
                fontSize: 10,
                color: context.accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Recipient Row (To / CC) ────────────────────────────────────────
class RecipientRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPrimaryChip;
  final bool isEditing;
  final int? minLines;
  final int maxLines;
  final int maxVisible;

  const RecipientRow({
    super.key,
    required this.label,
    required this.controller,
    required this.isPrimaryChip,
    required this.isEditing,
    this.minLines,
    this.maxLines = 1,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: SizedBox(
            width: 22,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  cursorColor: context.accentColor,
                  minLines: minLines,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: 12, color: context.textPrimary),
                  decoration: _recipientFieldDeco(context),
                )
              : CollapsibleEmailChips(
                  emails: controller.text
                      .split(';')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  isPrimary: isPrimaryChip,
                  maxVisible: maxVisible,
                ),
        ),
      ],
    );
  }

  InputDecoration _recipientFieldDeco(BuildContext context) => InputDecoration(
        hintText: 'Pisahkan dengan titik koma (;)',
        hintStyle: TextStyle(fontSize: 11, color: context.textSecondary),
        filled: true,
        fillColor: context.primaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: context.accentColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      );
}

// ── Themed TextField (DRY) ─────────────────────────────────────────
/// TextField standar dialog tiket — menghilangkan duplikasi InputDecoration.
class TicketTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final IconData? prefixIcon;

  const TicketTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: context.accentColor,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: context.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 12, color: context.textSecondary),
        filled: true,
        fillColor: context.primaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.accentColor),
        ),
        contentPadding: maxLines > 1
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 15, color: context.textSecondary)
            : null,
      ),
    );
  }
}
