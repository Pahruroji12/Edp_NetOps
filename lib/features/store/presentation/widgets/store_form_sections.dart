import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../controllers/store_form_controller.dart';
import 'store_form_widgets.dart';

class StoreFormInfoSection extends StatelessWidget {
  final StoreFormController controller;

  const StoreFormInfoSection({super.key, required this.controller});

  Widget _twoCol({
    required Widget left,
    required Widget right,
    double threshold = 460,
    double spacing = 14,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth >= threshold) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreFormWidgets.buildCard(
      context: context,
      accentLeft: context.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreFormWidgets.buildCardHeader(
            context: context,
            title: "Informasi Utama",
            icon: Icons.storefront_outlined,
            color: context.accentColor,
          ),
          const SizedBox(height: 20),

          // Kode Toko + Nama Toko
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 400;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.codeController,
                        label: "Kode Toko",
                        icon: Icons.qr_code_outlined,
                        required: true,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.nameController,
                        label: "Nama Toko",
                        icon: Icons.badge_outlined,
                        required: true,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StoreFormWidgets.buildFormField(
                      context: context,
                      controller: controller.codeController,
                      label: "Kode Toko",
                      icon: Icons.qr_code_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    StoreFormWidgets.buildFormField(
                      context: context,
                      controller: controller.nameController,
                      label: "Nama Toko",
                      icon: Icons.badge_outlined,
                      required: true,
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // Koneksi Utama + Koneksi Backup
          _twoCol(
            threshold: 460,
            left: StoreFormWidgets.buildFormDropdown(
              context: context,
              label: "Koneksi Utama",
              icon: Icons.cable_outlined,
              items: StoreFormController.connectionTypes,
              value: controller.selectedConnection,
              onChanged: controller.setConnection,
              accentColor: const Color(0xFF00E676),
            ),
            right: StoreFormWidgets.buildFormDropdown(
              context: context,
              label: "Koneksi Backup",
              icon: Icons.settings_backup_restore_outlined,
              items: StoreFormController.backupTypes,
              value: controller.selectedBackup,
              onChanged: controller.setBackup,
              accentColor: const Color(0xFFFFB347),
            ),
          ),
          const SizedBox(height: 14),

          // SID Utama + SID Backup
          _twoCol(
            left: StoreFormWidgets.buildFormField(
              context: context,
              controller: controller.sidUtamaController,
              label: "SID Utama",
              hint: "SID utama",
              icon: Icons.sim_card_outlined,
            ),
            right: StoreFormWidgets.buildFormField(
              context: context,
              controller: controller.sidBackupController,
              label: "SID Backup",
              hint: "SID backup",
              icon: Icons.sim_card_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class StoreFormIpSection extends StatelessWidget {
  final StoreFormController controller;

  const StoreFormIpSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StoreFormWidgets.buildCard(
      context: context,
      accentLeft: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StoreFormWidgets.buildCardHeader(
                  context: context,
                  title: "Pengaturan IP Address",
                  icon: Icons.device_hub_outlined,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              // Tombol hapus semua IP
              Tooltip(
                message: 'Hapus semua IP',
                child: InkWell(
                  onTap: controller.clearAllIp,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_sweep_outlined,
                          size: 14,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'HAPUS SEMUA IP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: Colors.red.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Di layar lebar (≥700): kiri = Jaringan+Station, kanan = Lainnya+CCTV
          LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 700;

              final leftCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoreFormWidgets.buildIpSubSection(
                    context: context,
                    title: "JARINGAN UTAMA",
                    color: context.accentColor,
                    icon: Icons.wifi_outlined,
                    children: [
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.gatewayController,
                        label: "IP Gateway",
                        hint: "10.x.x.x",
                        icon: Icons.router_outlined,
                        isIp: true,
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.vsatController,
                        label: "IP VSAT",
                        hint: "10.x.x.x",
                        icon: Icons.satellite_alt_outlined,
                        isIp: true,
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.rbWdcpController,
                        label: "IP RB WDCP",
                        hint: "10.x.x.x",
                        icon: Icons.settings_input_antenna_outlined,
                        isIp: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StoreFormWidgets.buildIpSubSection(
                    context: context,
                    title: "STATION / KASIR",
                    color: const Color(0xFF00C9A7),
                    icon: Icons.point_of_sale_outlined,
                    children: [
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.station1Controller,
                        label: "Station 1",
                        icon: Icons.computer_outlined,
                        active: controller.station1Active,
                        activeColor: const Color(0xFF00C9A7),
                        onToggle: (v) => controller.setToggle('station1', v),
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.station2Controller,
                        label: "Station 2",
                        icon: Icons.computer_outlined,
                        active: controller.station2Active,
                        activeColor: const Color(0xFF00C9A7),
                        onToggle: (v) => controller.setToggle('station2', v),
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.station3Controller,
                        label: "Station 3",
                        icon: Icons.computer_outlined,
                        active: controller.station3Active,
                        activeColor: const Color(0xFF00C9A7),
                        onToggle: (v) => controller.setToggle('station3', v),
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.station4Controller,
                        label: "Station 4",
                        icon: Icons.computer_outlined,
                        active: controller.station4Active,
                        activeColor: const Color(0xFF00C9A7),
                        onToggle: (v) => controller.setToggle('station4', v),
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.station5Controller,
                        label: "Station 5",
                        icon: Icons.computer_outlined,
                        active: controller.station5Active,
                        activeColor: const Color(0xFF00C9A7),
                        onToggle: (v) => controller.setToggle('station5', v),
                      ),
                    ],
                  ),
                ],
              );

              final rightCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StoreFormWidgets.buildIpSubSection(
                    context: context,
                    title: "PERANGKAT LAINNYA",
                    color: const Color(0xFFFFB347),
                    icon: Icons.devices_outlined,
                    children: [
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.stbController,
                        label: "IP STB",
                        hint: "10.x.x.x",
                        icon: Icons.tv_outlined,
                        isIp: true,
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.ikioskController,
                        label: "IP iKiosk",
                        icon: Icons.touch_app_outlined,
                        active: controller.ikioskActive,
                        activeColor: const Color(0xFFFFB347),
                        onToggle: (v) => controller.setToggle('ikiosk', v),
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildToggleField(
                        context: context,
                        controller: controller.timbanganController,
                        label: "IP Timbangan",
                        icon: Icons.scale_outlined,
                        active: controller.timbanganActive,
                        activeColor: const Color(0xFFFFB347),
                        onToggle: (v) => controller.setToggle('timbangan', v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StoreFormWidgets.buildIpSubSection(
                    context: context,
                    title: "CCTV / NVR",
                    color: const Color(0xFFFF6B6B),
                    icon: Icons.videocam_outlined,
                    children: [
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.cctv1Controller,
                        label: "CCTV 1",
                        hint: "10.x.x.x",
                        icon: Icons.videocam_outlined,
                        isIp: true,
                      ),
                      const SizedBox(height: 12),
                      StoreFormWidgets.buildFormField(
                        context: context,
                        controller: controller.cctv2Controller,
                        label: "CCTV 2",
                        hint: "10.x.x.x",
                        icon: Icons.videocam_outlined,
                        isIp: true,
                      ),
                    ],
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftCol),
                    const SizedBox(width: 18),
                    Expanded(child: rightCol),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [leftCol, const SizedBox(height: 18), rightCol],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
