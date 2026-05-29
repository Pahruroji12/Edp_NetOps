import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// SecurityCard — form ubah password dengan field lama + baru.
///
/// Lokasi: features/profile/presentation/widgets/security_card.dart
///
/// StatefulWidget karena mengelola TextEditingController sendiri.
/// Business logic (validasi, API call) didelegasikan via [onSubmit].
///
class SecurityCard extends StatefulWidget {
  final bool obscureOld;
  final bool obscureNew;
  final VoidCallback onToggleOldVisibility;
  final VoidCallback onToggleNewVisibility;
  final Future<bool> Function(String oldPass, String newPass) onSubmit;

  const SecurityCard({
    super.key,
    required this.obscureOld,
    required this.obscureNew,
    required this.onToggleOldVisibility,
    required this.onToggleNewVisibility,
    required this.onSubmit,
  });

  @override
  State<SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends State<SecurityCard> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await widget.onSubmit(
      _oldPassCtrl.text.trim(),
      _newPassCtrl.text.trim(),
    );
    if (success) {
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          _buildCardHeader(context),
          const SizedBox(height: 20),
          _buildPasswordFields(context),
          const SizedBox(height: 20),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.accentColor.withOpacity(0.2)),
          ),
          child: Icon(Icons.lock_outline, color: context.accentColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ubah Password",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Perbarui password login Anda secara berkala.",
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 480;
        final oldField = _buildTextField(
          context,
          "Password Lama",
          _oldPassCtrl,
          prefixIcon: Icons.lock_outline,
          isObs: widget.obscureOld,
          onObsToggle: widget.onToggleOldVisibility,
        );
        final newField = _buildTextField(
          context,
          "Password Baru",
          _newPassCtrl,
          prefixIcon: Icons.lock_reset_outlined,
          isObs: widget.obscureNew,
          onObsToggle: widget.onToggleNewVisibility,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: oldField),
              const SizedBox(width: 14),
              Expanded(child: newField),
            ],
          );
        }
        return Column(
          children: [
            oldField,
            const SizedBox(height: 14),
            newField,
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController ctrl, {
    IconData? prefixIcon,
    bool isObs = false,
    VoidCallback? onObsToggle,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: context.accentColor,
          selectionColor: context.accentColor.withOpacity(0.3),
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextFormField(
        controller: ctrl,
        obscureText: isObs,
        cursorColor: context.accentColor,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: context.textSecondary, size: 18)
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
          filled: true,
          fillColor: context.cardColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
          suffixIcon: onObsToggle != null
              ? IconButton(
                  icon: Icon(
                    isObs
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  onPressed: onObsToggle,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleSubmit,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor,
                  context.accentColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  "Ubah Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
