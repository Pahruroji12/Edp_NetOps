/// Desktop initializer — implementasi native (Desktop/Mobile).
/// Window Manager dan Ping Controller diinisialisasi di sini.

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/network_tools/ping/presentation/ping_controller.dart';
import 'feature_availability.dart';

/// Inisialisasi Window Manager — hanya Desktop.
Future<void> initDesktopWindow() async {
  if (!FeatureAvailability.canUseWindowManager) return;

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(800, 600),
    center: true,
    title: 'EDP NetOps',
    titleBarStyle: TitleBarStyle.normal,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Inisialisasi Ping Controller — hanya Windows.
Future<void> initPingController() async {
  if (!FeatureAvailability.canUsePing) return;
  await PingController.instance.init();
}
