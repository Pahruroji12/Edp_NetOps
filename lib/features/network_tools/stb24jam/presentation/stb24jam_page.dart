import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import 'stb24jam_controller.dart';
import '../data/stb24jam_service.dart';

class Stb24JamPage extends StatefulWidget {
  const Stb24JamPage({super.key});

  @override
  State<Stb24JamPage> createState() => _Stb24JamPageState();
}

class _Stb24JamPageState extends State<Stb24JamPage> {
  late final Stb24JamController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Stb24JamController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickDate(Stb24JamController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.accentColor,
              onPrimary: context.primaryColor,
              surface: context.cardColor,
              onSurface: context.textPrimary,
            ),
            dialogBackgroundColor: context.surfaceColor,
          ),
          child: child!,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final monthlyPath = controller.service.getMonthlyFilePath(controller.tanggal);
    final pingPaths = controller.service.resolvePingFilePaths(controller.tanggal);
    final hasMissingPingFiles = pingPaths.values.any((path) => path == null);

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
                    // ── Bagian Tanggal ──
                    const SectionHeader(
                      title: "PILIH TANGGAL REKAP",
                      icon: Icons.calendar_today_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Row(
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
                            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Bagian Berkas ──
                    const SectionHeader(
                      title: "BERKAS YANG AKAN DIPROSES",
                      icon: Icons.folder_open_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: context.borderColor.withOpacity(0.5)),
                          ),
                          ...pingPaths.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
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
                    const SizedBox(height: 28),

                    // ── Tombol Aksi ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (controller.loading || hasMissingPingFiles) ? null : () => _generate(controller),
                        icon: controller.loading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: context.primaryColor,
                                ),
                              )
                            : Icon(Icons.auto_fix_high_rounded, color: context.primaryColor),
                        label: Text(
                          controller.loading ? 'Memproses Rekap STB...' : 'Generate Sheet STB 24 Jam',
                          style: TextStyle(
                            color: context.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.accentColor,
                          disabledBackgroundColor: context.accentColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shadowColor: context.accentColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (hasMissingPingFiles) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.dangerColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded, color: context.dangerColor, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Harap lengkapi seluruh file hasil ping di folder sebelum memulai proses generate.',
                                style: TextStyle(
                                  color: context.dangerColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Ringkasan Hasil Terakhir ──
                    if (controller.lastResult != null && controller.lastResult!.success) ...[
                      const SectionHeader(
                        title: "RINGKASAN REKAPITULASI",
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(controller.lastResult!),
                    ],
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
                isMissing ? 'Berkas tidak ditemukan di folder Hasil Ping!' : path,
                style: TextStyle(
                  color: isMissing ? context.dangerColor.withOpacity(0.8) : context.textSecondary,
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
                    Icon(Icons.warning_amber_rounded, color: context.warningColor, size: 16),
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
}
