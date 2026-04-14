import 'package:flutter/material.dart';
import 'smiles/login.dart';
import 'smiles/wicss.dart';
import 'smiles/wii.dart';

void main() => runApp(const WinwiiApp());

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
