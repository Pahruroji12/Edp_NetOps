import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Berisi helper dan widget reusable untuk keperluan form pada StoreFormPage.
class StoreFormWidgets {
  static Widget buildCard({
    required BuildContext context,
    required Widget child,
    Color? accentLeft,
  }) {
    final radius = BorderRadius.circular(20);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radius,
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
        if (accentLeft != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(width: 4, color: accentLeft),
            ),
          ),
      ],
    );
  }

  static Widget buildCardHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static Widget buildIpSubSection({
    required BuildContext context,
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  static Widget buildFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool required = false,
    bool isIp = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                "*",
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: context.accentColor,
              selectionColor: context.accentColor.withOpacity(0.3),
              selectionHandleColor: context.accentColor,
            ),
          ),
          child: TextFormField(
            controller: controller,
            cursorColor: context.accentColor,
            keyboardType: isIp ? TextInputType.number : TextInputType.text,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontFamily: isIp ? 'monospace' : null,
              letterSpacing: isIp ? 0.5 : 0,
            ),
            validator: required
                ? (value) =>
                    (value == null || value.isEmpty) ? 'Wajib diisi' : null
                : null,
            decoration: InputDecoration(
              hintText: hint ?? 'Masukkan $label',
              hintStyle: TextStyle(
                color: context.textSecondary.withOpacity(0.4),
                fontSize: 12,
              ),
              prefixIcon: icon != null
                  ? Icon(icon, size: 16, color: context.textSecondary)
                  : null,
              filled: true,
              fillColor: context.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.accentColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B6B),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B6B),
                  width: 1.5,
                ),
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildFormDropdown({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: context.cardColor,
          isExpanded: true,
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.textSecondary,
            size: 18,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: context.textSecondary),
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
          items: items
              .map(
                (val) => DropdownMenuItem(
                  value: val,
                  child: Text(
                    val,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildToggleField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool active,
    required ValueChanged<bool> onToggle,
    required Color activeColor,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1.0 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? context.textSecondary
                      : context.textSecondary.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: active,
                  onChanged: onToggle,
                  activeColor: activeColor,
                  activeTrackColor: activeColor.withOpacity(0.25),
                  inactiveThumbColor: context.textSecondary.withOpacity(0.4),
                  inactiveTrackColor: context.borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: activeColor,
                selectionColor: activeColor.withOpacity(0.3),
                selectionHandleColor: activeColor,
              ),
            ),
            child: TextFormField(
              controller: controller,
              enabled: active,
              cursorColor: activeColor,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: '10.x.x.x',
                hintStyle: TextStyle(
                  color: context.textSecondary.withOpacity(0.4),
                  fontSize: 12,
                ),
                prefixIcon: Icon(
                  icon,
                  size: 16,
                  color: active
                      ? activeColor.withOpacity(0.7)
                      : context.textSecondary.withOpacity(0.3),
                ),
                filled: true,
                fillColor: active
                    ? context.cardColor
                    : context.cardColor.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: activeColor.withOpacity(0.35)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: context.borderColor.withOpacity(0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: activeColor, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
