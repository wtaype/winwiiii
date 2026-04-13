import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'smile/mensajes.dart';
import 'smile/notas.dart';
import 'smile/perfil.dart';
import 'todos/acerca.dart';
import 'todos/emojis.dart';
import 'todos/extraer.dart';
import 'todos/inicio.dart';
import 'todos/planificar.dart';
import 'wii.dart';
import 'wicss.dart';
import 'widev.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late int _indiceActual;
  String? _photoPath;
  String _displayName = 'Usuario';

  static const _menu = [
    ('Inicio', Icons.home_rounded),
    ('Extraer', Icons.auto_awesome_motion_rounded),
    ('Emojis', Icons.emoji_emotions_rounded),
    ('Planificar', Icons.event_note_rounded),
    ('Acerca', Icons.info_rounded),
    ('Notas', Icons.note_alt_rounded),
    ('Mensajes', Icons.message_rounded),
    ('Perfil', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.initialIndex;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final savedName = prefs.getString('wi_profile_name')?.trim();
    final emailName = user?.email?.split('@').first;

    if (!mounted) return;
    setState(() {
      _photoPath = prefs.getString('wi_profile_photo');
      _displayName = (savedName != null && savedName.isNotEmpty)
          ? savedName
          : (user?.displayName?.trim().isNotEmpty ?? false)
          ? user!.displayName!.trim()
          : (emailName != null && emailName.isNotEmpty)
          ? emailName
          : 'Usuario';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final paginas = [
      InicioPage(onOpen: _goTo),
      const ExtraerPage(),
      const EmojisPage(),
      const PlanificarPage(),
      const AcercaPage(),
      const NotasPage(),
      const MensajesPage(),
      PerfilPage(
        initialName: _displayName,
        initialPhotoPath: _photoPath,
        userEmail: user?.email,
        onChanged: (photo, name) {
          setState(() {
            _photoPath = photo;
            _displayName = name;
          });
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppCSS.bgSoft, AppCSS.bgLight],
          ),
        ),
        child: Row(
          children: [
            _leftMenu(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                child: Column(
                  children: [
                    _topBar(user),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppCSS.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppCSS.white.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: IndexedStack(
                            index: _indiceActual,
                            children: paginas,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leftMenu() {
    return Container(
      width: 250,
      margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppCSS.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets\\smile.avif',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => AppCSS.logoCirculo(size: 42),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wii.app,
                    style: AppStyle.h3.copyWith(color: AppCSS.primary),
                  ),
                  Text(wiDia(), style: AppStyle.sm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Navegación',
            style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _menu.length,
              separatorBuilder: (_, index) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final item = _menu[i];
                final active = i == _indiceActual;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _goTo(i),
                  child: AnimatedContainer(
                    duration: AppCSS.trans1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppCSS.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppCSS.primary.withValues(alpha: 0.35)
                            : AppCSS.border.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.$2,
                          size: 20,
                          color: active ? AppCSS.primary : AppCSS.text500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: AppStyle.bdS.copyWith(
                              color: active ? AppCSS.primary : AppCSS.text500,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Versión ${wii.version}', style: AppStyle.sm),
        ],
      ),
    );
  }

  Widget _topBar(User? user) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppCSS.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppCSS.white.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_menu[_indiceActual].$1, style: AppStyle.h3),
              Text(_sectionHint(_indiceActual), style: AppStyle.sm),
            ],
          ),
          const Spacer(),
          _headerAction('Notas', Icons.note_alt_rounded, () => _goTo(5)),
          _headerAction('Mensajes', Icons.message_rounded, () => _goTo(6)),
          _headerAction('Perfil', Icons.person_rounded, () => _goTo(7)),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => _goTo(7), child: _avatar(user, 18)),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Salir'),
            style: FilledButton.styleFrom(backgroundColor: AppCSS.error),
          ),
        ],
      ),
    );
  }

  Widget _headerAction(String text, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppCSS.white.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _avatar(User? user, double radius) {
    final initial = (_displayName.isNotEmpty ? _displayName[0] : 'U')
        .toUpperCase();

    ImageProvider? provider;
    if (_photoPath != null &&
        _photoPath!.isNotEmpty &&
        File(_photoPath!).existsSync()) {
      provider = FileImage(File(_photoPath!));
    } else if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      provider = NetworkImage(user.photoURL!);
    }

    if (provider == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppCSS.primary.withValues(alpha: 0.2),
        child: Text(
          initial,
          style: AppStyle.bdS.copyWith(
            color: AppCSS.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: provider,
      backgroundColor: AppCSS.white,
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _menu.length) return;
    setState(() => _indiceActual = index);
  }

  String _sectionHint(int index) {
    switch (index) {
      case 5:
        return 'Notas en colección wiNotas';
      case 6:
        return 'Mensajes en colección wiMensajes';
      case 7:
        return 'Gestiona tu perfil';
      default:
        return 'Panel profesional';
    }
  }
}
