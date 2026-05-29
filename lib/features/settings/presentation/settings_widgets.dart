import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// SettingsWidgets — reusable UI components untuk SettingsPage.
///
/// Lokasi: features/settings/presentation/settings_widgets.dart
///
/// Menggantikan private methods dari _SettingsPageState:
///   - _buildCard → SettingsCard
///   - _buildCardHeader → SettingsCardHeader
///   - _buildRouterSubCard → SettingsSubCard
///   - _buildModernTextField → SettingsTextField
///   - _buildSmallButton → SettingsSmallButton
///   - _buildPrimaryButton → SettingsPrimaryButton
///   - _responsiveRow → SettingsResponsiveRow
///   - _buildLoadingOverlay → SettingsLoadingOverlay
///   - _buildRestrictedAccessWidget → SettingsRestrictedAccess

// ══════════════════════════════════════════════════════════════
// RESPONSIVE ROW
// ══════════════════════════════════════════════════════════════

class SettingsResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double threshold;
  final double spacing;

  const SettingsResponsiveRow({
    super.key,
    required this.children,
    this.threshold = 500,
    this.spacing = 14,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= threshold;
        if (isWide) {
          final items = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            items.add(children[i]);
            if (i < children.length - 1) items.add(SizedBox(width: spacing));
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          );
        } else {
          final items = <Widget>[];
          for (int i = 0; i < children.length; i++) {
            Widget child = children[i];
            if (child is Expanded) child = child.child;
            if (child is Flexible) child = child.child;
            items.add(SizedBox(width: double.infinity, child: child));
            if (i < children.length - 1) items.add(SizedBox(height: spacing));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          );
        }
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// LOADING OVERLAY
// ══════════════════════════════════════════════════════════════

class SettingsLoadingOverlay extends StatelessWidget {
  const SettingsLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Memproses...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// RESTRICTED ACCESS
// ══════════════════════════════════════════════════════════════

class SettingsRestrictedAccess extends StatelessWidget {
  const SettingsRestrictedAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gpp_bad_outlined,
              size: 64,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Akses Dibatasi",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Halaman pengaturan sistem dan manajemen pengguna\nhanya dapat diakses oleh akun dengan level Administrator.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARD (with left accent bar)
// ══════════════════════════════════════════════════════════════

class SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? accentLeft;

  const SettingsCard({super.key, required this.child, this.accentLeft});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: accentLeft != null ? 28 : 24,
            right: 24,
            top: 24,
            bottom: 24,
          ),
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
          child: child,
        ),
        if (accentLeft != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentLeft!, accentLeft!.withOpacity(0.25)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARD HEADER
// ══════════════════════════════════════════════════════════════

class SettingsCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const SettingsCardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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

// ══════════════════════════════════════════════════════════════
// SUB CARD (e.g. RB KONEKSI, PORT GLOBAL)
// ══════════════════════════════════════════════════════════════

class SettingsSubCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final IconData? icon;

  const SettingsSubCard({
    super.key,
    required this.title,
    required this.accentColor,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 13, color: accentColor),
                )
              else
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MODERN TEXT FIELD
// ══════════════════════════════════════════════════════════════

class SettingsTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final bool isPass;
  final bool isObs;
  final VoidCallback? onObsToggle;
  final bool isNum;
  final bool readOnly;
  final String? helperText;

  const SettingsTextField(
    this.label,
    this.controller, {
    super.key,
    this.prefixIcon,
    this.isPass = false,
    this.isObs = false,
    this.onObsToggle,
    this.isNum = false,
    this.readOnly = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: context.accentColor,
          selectionColor: context.accentColor.withOpacity(0.3),
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPass ? isObs : false,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
        cursorColor: context.accentColor,
        style: TextStyle(
          color: readOnly ? context.textSecondary : context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: TextStyle(
            color: context.textSecondary.withOpacity(0.7),
            fontSize: 10,
          ),
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
          suffixIcon: isPass && onObsToggle != null
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
}

// ══════════════════════════════════════════════════════════════
// SMALL BUTTON (outline style)
// ══════════════════════════════════════════════════════════════

class SettingsSmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;

  const SettingsSmallButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRIMARY BUTTON (gradient style)
// ══════════════════════════════════════════════════════════════

class SettingsPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const SettingsPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? context.accentColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [buttonColor, buttonColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
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
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MODERN DROPDOWN
// ══════════════════════════════════════════════════════════════

class SettingsRoleDropdown extends StatelessWidget {
  final String selectedRole;
  final List<String> roles;
  final ValueChanged<String> onChanged;

  const SettingsRoleDropdown({
    super.key,
    required this.selectedRole,
    required this.roles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      dropdownColor: context.cardColor,
      style: TextStyle(color: context.textPrimary, fontSize: 13),
      icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary),
      decoration: InputDecoration(
        labelText: "Role Akses",
        labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
        prefixIcon: Icon(
          Icons.admin_panel_settings_outlined,
          color: context.textSecondary,
          size: 18,
        ),
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
      ),
      items: roles
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                e.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}
