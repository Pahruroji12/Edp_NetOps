import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../helpers/role_style.dart';
import '../../domain/user_model.dart';
import 'delete_user_dialog.dart';

/// UserListCard — daftar personil terdaftar dengan search dan delete.
///
/// Lokasi: features/profile/presentation/widgets/user_list_card.dart
///
class UserListCard extends StatelessWidget {
  final List<UserModel> users;
  final bool isLoading;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearch;
  final Future<void> Function(String id, String nik, String nama) onDeleteUser;

  const UserListCard({
    super.key,
    required this.users,
    required this.isLoading,
    required this.searchController,
    required this.scrollController,
    required this.onSearch,
    required this.onDeleteUser,
  });

  @override
  Widget build(BuildContext context) {
    final isAdministrator =
        AuthState.instance.role.toLowerCase() == 'administrator';

    return Container(
      width: double.infinity,
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
          _buildHeader(context),
          if (isLoading)
            _buildLoadingState(context)
          else if (users.isEmpty)
            _buildEmptyState(context)
          else
            _buildList(context, isAdministrator),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final titleWidget = _buildTitle(context);
        final badgeWidget = _buildBadge(context);
        final searchWidget = _buildSearch(context, isWide);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            border: Border(bottom: BorderSide(color: context.borderColor)),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: titleWidget),
                    searchWidget,
                    const SizedBox(width: 10),
                    badgeWidget,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: titleWidget),
                        badgeWidget,
                      ],
                    ),
                    const SizedBox(height: 12),
                    searchWidget,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00C9A7).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF00C9A7).withOpacity(0.3),
            ),
          ),
          child: const Icon(
            Icons.group_outlined,
            color: Color(0xFF00C9A7),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Personil Terdaftar",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Pengguna yang memiliki akses sistem",
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00C9A7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00C9A7).withOpacity(0.3),
        ),
      ),
      child: Text(
        "${users.length} Orang",
        style: const TextStyle(
          color: Color(0xFF00C9A7),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context, bool isWide) {
    return SizedBox(
      width: isWide ? 190 : double.infinity,
      height: 36,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: context.accentColor,
            selectionColor: context.accentColor.withOpacity(0.3),
            selectionHandleColor: context.accentColor,
          ),
        ),
        child: TextField(
          controller: searchController,
          onChanged: onSearch,
          cursorColor: context.accentColor,
          style: TextStyle(color: context.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: "Cari nama atau NIK...",
            hintStyle: TextStyle(
              color: context.textSecondary.withOpacity(0.5),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: context.textSecondary,
              size: 18,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: context.textSecondary,
                      size: 16,
                    ),
                    onPressed: () {
                      searchController.clear();
                      onSearch('');
                    },
                  )
                : null,
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
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
          ),
        ),
      ),
    );
  }

  // ── STATES ──────────────────────────────────────────────────────

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Memuat data tim...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              color: context.textSecondary.withOpacity(0.4),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              "Tidak ada personil ditemukan.",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST ─────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, bool isAdministrator) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: RawScrollbar(
        controller: scrollController,
        thumbColor: context.accentColor.withOpacity(0.4),
        radius: const Radius.circular(4),
        thickness: 4,
        child: ListView.builder(
          controller: scrollController,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isLast = index == users.length - 1;
            return _UserListItem(
              user: user,
              isAdministrator: isAdministrator,
              isLast: isLast,
              onDelete: onDeleteUser,
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PRIVATE: Single user list item
// ═══════════════════════════════════════════════════════════════════

class _UserListItem extends StatelessWidget {
  final UserModel user;
  final bool isAdministrator;
  final bool isLast;
  final Future<void> Function(String id, String nik, String nama) onDelete;

  const _UserListItem({
    required this.user,
    required this.isAdministrator,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = user.nik == AuthState.instance.nik;
    final roleStyle = RoleStyle.forListItem(
      user.role,
      fallbackAccent: context.accentColor,
    );
    final initials = RoleStyle.initialsFrom(user.nama);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildAvatar(context, roleStyle, initials),
              const SizedBox(width: 12),
              _buildInfo(context, roleStyle, isMe),
              _buildActions(context, roleStyle, isMe),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: context.borderColor.withOpacity(0.5),
            indent: 72,
          ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    RoleStyle roleStyle,
    String initials,
  ) {
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: roleStyle.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: roleStyle.accent.withOpacity(0.25)),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: roleStyle.accent,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.borderColor),
            ),
            child: Icon(roleStyle.icon, size: 10, color: roleStyle.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, RoleStyle roleStyle, bool isMe) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  user.nama,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    "ANDA",
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 11,
                color: context.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                user.nik,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    RoleStyle roleStyle,
    bool isMe,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: roleStyle.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: roleStyle.accent.withOpacity(0.3)),
          ),
          child: Text(
            roleStyle.label,
            style: TextStyle(
              color: roleStyle.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (isAdministrator && !isMe) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => showDeleteUserDialog(
              context,
              nama: user.nama,
              nik: user.nik,
              onConfirm: () => onDelete(user.id, user.nik, user.nama),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFFF6B6B),
                size: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
