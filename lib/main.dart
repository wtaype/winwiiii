import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'smiles/login.dart';
import 'smiles/wicss.dart';
import 'smiles/wii.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(center: true, titleBarStyle: TitleBarStyle.normal);

  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const WinwiiApp());
}

class WinwiiApp extends StatelessWidget {
  const WinwiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: wii.app,
      debugShowCheckedModeBanner: false,
      theme: AppStyle.tema,
      home: const AuthBootstrap(),
    );
  }
}