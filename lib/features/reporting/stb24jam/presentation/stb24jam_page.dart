import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import 'stb24jam_controller.dart';
import '../data/stb24jam_service.dart';
import '../data/stb24jam_repository.dart';
import '../../../ticket/presentation/widgets/custom_calendar_popup.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../../core/utils/role_helper.dart';

class Stb24JamPage extends StatefulWidget {
  const Stb24JamPage({super.key});

  @override
  State<Stb24JamPage> createState() => _Stb24JamPageState();
}

class _Stb24JamPageState extends State<Stb24JamPage> {
  late final Stb24JamController _controller;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Stb24JamController();
    _controller.addListener(_onControllerChanged);
    
    // Non-blocking initialization after page is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.refreshFilePaths();
        _controller.loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickDate(Stb24JamController controller) async {
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: controller.tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.setTanggal(picked);
    }
  }

  Future<void> _generate(Stb24JamController controller) async {
    await controller.generate();
    if (!mounted) return;

    final result = controller.lastResult;
    if (result != null) {
      showInfoDialog(
        context,
        title: result.success ? 'Berhasil' : 'Gagal',
        message: result.message,
        icon: result.success
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        iconColor: result.success ? context.successColor : context.dangerColor,
      );
    }
  }

  Future<void> _report(Stb24JamController controller) async {
    await controller.report();
    if (!mounted) return;
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Hapus Riwayat?',
      message:
          'Apakah Anda yakin ingin menghapus entri riwayat ini secara permanen dari database?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDanger: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirm == true) {
      await _controller.deleteHistory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final monthlyPath = controller.monthlyPath;
    final pingPaths = controller.pingPaths;
    final hasMissingPingFiles = controller.hasMissingPingFiles;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(
      controller.tanggal.year,
      controller.tanggal.month,
      controller.tanggal.day,
    );
    final isPastDate = selectedDate.isBefore(today);
    final isFutureDate = selectedDate.isAfter(today);

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: PageEntryTransition(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.pagePaddingH,
                  context.scaledPadding(20),
                  context.pagePaddingH,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Bagian Konfigurasi & Berkas ──
                    const SectionHeader(
                      title: "KONFIGURASI & BERKAS REKAP",
                      icon: Icons.settings_system_daydream_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris Pemilih Tanggal
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: context.accentColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.date_range_rounded,
                                  color: context.accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tanggal Terpilih",
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${controller.tanggal.day.toString().padLeft(2, '0')}/${controller.tanggal.month.toString().padLeft(2, '0')}/${controller.tanggal.year}',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickDate(controller),
                                icon: const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 16,
                                ),
                                label: const Text('Pilih Tanggal'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.borderColor),
                                  foregroundColor: context.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message: 'Refresh Berkas',
                                child: OutlinedButton(
                                  onPressed: () => controller.refreshFilePaths(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.borderColor),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: context.accentColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color: context.borderColor.withOpacity(0.6),
                            ),
                          ),
                          // Daftar Berkas & Auto Scheduler Split Row
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Column: Berkas List
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFileRow(
                                        icon: Icons.table_chart_rounded,
                                        iconColor: context.secondaryAccent,
                                        label: 'Laporan Bulanan',
                                        path: monthlyPath,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Divider(
                                          color: context.borderColor.withOpacity(0.3),
                                        ),
                                      ),
                                      ...pingPaths.entries.map((e) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10.0),
                                          child: _buildFileRow(
                                            icon: Icons.network_check_rounded,
                                            iconColor: context.accentColor,
                                            label: e.key,
                                            path: e.value,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                // Right Column: Auto Scheduler (Hanya untuk Administrator)
                                if (RoleHelper.isAdministrator) ...[
                                  const SizedBox(width: 20),
                                  Container(
                                    width: 1,
                                    color: context.borderColor.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.primaryColor.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.accentColor.withOpacity(0.15),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.auto_awesome_rounded,
                                                color: context.accentColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Auto Process",
                                                style: TextStyle(
                                                  color: context.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const Spacer(),
                                              Switch.adaptive(
                                                value: controller.autoEnabled,
                                                activeColor: context.accentColor,
                                                onChanged: (val) {
                                                  controller.toggleAuto(val);
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Auto Generate & Report",
                                            style: TextStyle(
                                              color: context.textPrimary.withOpacity(0.9),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              "Mengeksekusi rekap harian jam 04.00 pagi secara otomatis, lalu melaporkan ke Telegram setelah berhasil.",
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 9.5,
                                                height: 1.3,
                                              ),
                                              overflow: TextOverflow.clip,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (controller.autoEnabled
                                                      ? context.successColor
                                                      : context.textSecondary)
                                                  .withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: (controller.autoEnabled
                                                        ? context.successColor
                                                        : context.textSecondary)
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: controller.autoEnabled
                                                        ? context.successColor
                                                        : context.textSecondary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  controller.autoEnabled ? 'Scheduler Aktif' : 'Nonaktif',
                                                  style: TextStyle(
                                                    color: controller.autoEnabled
                                                        ? context.successColor
                                                        : context.textSecondary,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Tombol Aksi ──
                    Row(
                      children: [
                        // Tombol Generate
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (controller.loading ||
                                    controller.reporting ||
                                    hasMissingPingFiles ||
                                    isPastDate ||
                                    isFutureDate)
                                ? null
                                : () => _generate(controller),
                            icon: controller.loading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: context.primaryColor,
                                    ),
                                  )
                                : Icon(
                                    Icons.auto_fix_high_rounded,
                                    color: context.primaryColor,
                                  ),
                            label: Text(
                              controller.loading
                                  ? 'Memproses...'
                                  : 'Generate Sheet STB 24 Jam',
                              style: TextStyle(
                                color: context.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.accentColor,
                              disabledBackgroundColor: context.accentColor
                                  .withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shadowColor: context.accentColor.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tombol Report ke Telegram
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (controller.loading ||
                                    controller.reporting ||
                                    hasMissingPingFiles ||
                                    isPastDate ||
                                    isFutureDate)
                                ? null
                                : () => _report(controller),
                            icon: controller.reporting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                  ),
                            label: Text(
                              controller.reporting
                                  ? 'Mengirim...'
                                  : 'Report ke Telegram',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26A5E4),
                              disabledBackgroundColor: const Color(
                                0xFF26A5E4,
                              ).withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shadowColor: const Color(
                                0xFF26A5E4,
                              ).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isPastDate) ...[
                      const SizedBox(height: 16),
                      _buildAlertBanner(
                        message: 'Generate untuk tanggal ${controller.tanggal.day.toString().padLeft(2, '0')}/${controller.tanggal.month.toString().padLeft(2, '0')}/${controller.tanggal.year} sudah selesai & tidak diperkenankan generate ulang untuk tanggal lampau.',
                        color: context.successColor,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ] else if (isFutureDate) ...[
                      const SizedBox(height: 16),
                      _buildAlertBanner(
                        message: 'Berkas hasil ping untuk tanggal ${controller.tanggal.day.toString().padLeft(2, '0')}/${controller.tanggal.month.toString().padLeft(2, '0')}/${controller.tanggal.year} belum tersedia. Penggenerate-an belum dapat dilakukan.',
                        color: context.dangerColor,
                        icon: Icons.error_outline_rounded,
                      ),
                    ] else if (hasMissingPingFiles) ...[
                      const SizedBox(height: 16),
                      _buildAlertBanner(
                        message: 'Berkas hasil ping untuk hari ini belum lengkap. Pastikan 4 file ping harian telah tersedia di folder Hasil Ping.',
                        color: context.warningColor,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Ringkasan Hasil Terakhir ──
                    if (controller.lastResult != null &&
                        controller.lastResult!.success) ...[
                      const SectionHeader(
                        title: "RINGKASAN REKAPITULASI",
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(controller.lastResult!),
                    ],
                    const SizedBox(height: 24),

                    // ── Riwayat Aktivitas ──
                    const SectionHeader(
                      title: "RIWAYAT AKTIVITAS",
                      icon: Icons.history_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildHistorySection(controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
          ? null
          : const Center(child: AppHamburgerButton()),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REKAP STB 24 JAM",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "Laporan Bulanan STB — Network Tools",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFileRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String? path,
  }) {
    final bool isMissing = path == null || path.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isMissing ? Icons.cancel_outlined : icon,
          color: isMissing ? context.dangerColor : iconColor,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isMissing ? context.dangerColor : context.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMissing
                    ? 'Berkas tidak ditemukan di folder Hasil Ping!'
                    : path,
                style: TextStyle(
                  color: isMissing
                      ? context.dangerColor.withOpacity(0.8)
                      : context.textSecondary,
                  fontSize: 11,
                  fontFamily: isMissing ? null : 'monospace',
                  fontStyle: isMissing ? FontStyle.italic : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(GenerateResult r) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  title: 'Total Toko',
                  value: r.totalToko.toString(),
                  color: context.textPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _buildMetricItem(
                  title: 'Status OK',
                  value: r.totalOk.toString(),
                  color: context.successColor,
                ),
              ),
              Container(width: 1, height: 40, color: context.borderColor),
              Expanded(
                child: _buildMetricItem(
                  title: 'Status NOK',
                  value: r.totalNok.toString(),
                  color: context.dangerColor,
                ),
              ),
            ],
          ),
          if (r.tokoTanpaDataPing.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.warningColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${r.tokoTanpaDataPing.length} entri toko/jam tidak ditemukan datanya di file hasil ping (otomatis ditandai NOK agar termonitor).',
                        style: TextStyle(
                          color: context.warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ── History Section ──────────────────────────────────────────

  Widget _buildHistorySection(Stb24JamController controller) {
    if (controller.historyLoading && controller.historyItems.isEmpty) {
      return _buildCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.accentColor,
              ),
            ),
          ),
        ),
      );
    }

    if (controller.historyItems.isEmpty) {
      return _buildCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 32,
                  color: context.textSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada riwayat aktivitas',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final showScroll = controller.historyItems.length > 4;

    final historyList = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < controller.historyItems.length; i++) ...[
          if (i > 0)
            Divider(color: context.borderColor.withOpacity(0.5), height: 20),
          _buildHistoryRow(controller.historyItems[i]),
        ],
      ],
    );

    return _buildCard(
      child: showScroll
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 270),
              child: Scrollbar(
                controller: _historyScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _historyScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 12),
                  child: historyList,
                ),
              ),
            )
          : historyList,
    );
  }

  Widget _buildHistoryRow(Stb24JamHistoryItem item) {
    final isGenerate = item.actionType == 'generate';
    final actionLabel = isGenerate ? 'Generate Sheet' : 'Report Telegram';
    final actionIcon = isGenerate
        ? Icons.auto_fix_high_rounded
        : Icons.send_rounded;
    final actionColor = isGenerate
        ? context.accentColor
        : const Color(0xFF26A5E4);

    final tanggalStr =
        '${item.tanggal.day.toString().padLeft(2, '0')}/'
        '${item.tanggal.month.toString().padLeft(2, '0')}/'
        '${item.tanggal.year}';

    final local = item.createdAt.toLocal();
    final waktuStr =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    final userRole = AuthState.instance.role.toLowerCase();
    final isRootOrSuper = userRole == 'root' || userRole == 'administrator';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(actionIcon, size: 16, color: actionColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$actionLabel \u2014 $tanggalStr',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (item.success
                                    ? context.successColor
                                    : context.dangerColor)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (item.success
                                      ? context.successColor
                                      : context.dangerColor)
                                  .withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        item.success ? 'Sukses' : 'Gagal',
                        style: TextStyle(
                          color: item.success
                              ? context.successColor
                              : context.dangerColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.success && item.totalToko > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'OK : ${item.totalOk} | NOK : ${item.totalNok} \u2014 dari ${item.totalToko} toko',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.userName ?? 'Unknown'} \u2022 $waktuStr',
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isRootOrSuper) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: context.dangerColor.withOpacity(0.8),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
              onPressed: () => _confirmDelete(context, item.id),
              tooltip: 'Hapus Riwayat',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
