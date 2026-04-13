import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../wicss.dart';
import '../widev.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({
    super.key,
    this.initialName,
    this.initialPhotoPath,
    this.userEmail,
    this.onChanged,
  });

  final String? initialName;
  final String? initialPhotoPath;
  final String? userEmail;
  final void Function(String? photoPath, String displayName)? onChanged;

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidosCtrl;
  String? _photoPath;
  bool _saving = false;

  String _usuario = '';
  String _email = '';
  String _rol = 'smile';
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _apellidosCtrl = TextEditingController();
    _photoPath = widget.initialPhotoPath;
    _loadWiSmile();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    super.dispose();
  }

  String _nombreCompleto(String nombre, String apellidos) {
    final n = nombre.trim();
    final a = apellidos.trim();
    if (n.isEmpty) return a;
    if (a.isEmpty) return n;
    return '$n $a';
  }

  String _iniciales(String nombre, String apellidos) {
    final n = nombre.trim();
    final a = apellidos.trim();
    final n1 = n.isNotEmpty ? n[0] : '';
    final a1 = a.isNotEmpty ? a[0] : '';
    final v = '$n1$a1'.trim();
    return v.isEmpty ? 'U' : v.toUpperCase();
  }

  Future<void> _loadWiSmile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wiSmile');
    if (raw == null || raw.isEmpty) {
      final full = (widget.initialName ?? '').trim();
      final chunks = full.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (chunks.isNotEmpty) {
        _nombreCtrl.text = chunks.first;
        _apellidosCtrl.text = chunks.length > 1 ? chunks.sublist(1).join(' ') : '';
      }
      _email = (widget.userEmail ?? '').trim();
      if (_usuario.isEmpty && _email.contains('@')) _usuario = _email.split('@').first;
      if (!mounted) return;
      setState(() {});
      return;
    }

    try {
      final wi = jsonDecode(raw);
      if (wi is! Map<String, dynamic>) return;
      _nombreCtrl.text = (wi['nombre'] as String? ?? '').trim();
      _apellidosCtrl.text = (wi['apellidos'] as String? ?? '').trim();
      _usuario = (wi['usuario'] as String? ?? '').trim();
      _email = (wi['email'] as String? ?? widget.userEmail ?? '').trim();
      _rol = (wi['rol'] as String? ?? 'smile').trim();
      _uid = (wi['uid'] as String? ?? '').trim();
      final img = (wi['imagen'] as String? ?? '').trim();
      if (img.isNotEmpty) _photoPath = img;
      if (_nombreCtrl.text.isEmpty && widget.initialName != null) {
        final chunks = widget.initialName!.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
        if (chunks.isNotEmpty) {
          _nombreCtrl.text = chunks.first;
          _apellidosCtrl.text = chunks.length > 1 ? chunks.sublist(1).join(' ') : '';
        }
      }
      if (_email.isEmpty) _email = (widget.userEmail ?? '').trim();
      if (_usuario.isEmpty && _email.contains('@')) _usuario = _email.split('@').first;
      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
    final path = result?.files.single.path;
    if (path == null || path.trim().isEmpty) return;
    setState(() => _photoPath = path.trim());
    await _save();
  }

  Future<void> _removePhoto() async {
    setState(() => _photoPath = null);
    await _save();
  }

  Future<void> _copyUid() async {
    if (_uid.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _uid.trim()));
    if (mounted) Notificacion.ok(context, 'UID copiado');
  }

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      Notificacion.wrn(context, 'Ingresa tu nombre');
      return;
    }
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wiSmile');
    Map<String, dynamic> wi = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) wi = decoded;
      } catch (_) {}
    }

    final apellidos = _apellidosCtrl.text.trim();
    final full = _nombreCompleto(nombre, apellidos);
    final email = (wi['email'] as String? ?? widget.userEmail ?? '').trim();
    final usuarioActual = (wi['usuario'] as String? ?? '').trim();
    final usuarioEmail = email.contains('@') ? email.split('@').first : '';
    final usuario = usuarioActual.isNotEmpty
        ? usuarioActual
        : (usuarioEmail.isNotEmpty ? usuarioEmail : full.toLowerCase().replaceAll(' ', ''));

    wi['nombre'] = nombre;
    wi['apellidos'] = apellidos;
    wi['email'] = email;
    wi['usuario'] = usuario;
    wi['rol'] = (wi['rol'] as String? ?? 'smile').trim();
    wi['uid'] = (wi['uid'] as String? ?? '').trim();
    wi['imagen'] = _photoPath ?? '';

    await prefs.setString('wiSmile', jsonEncode(wi));
    await prefs.setString('wi_profile_name', full);
    if (_photoPath != null && _photoPath!.isNotEmpty) {
      await prefs.setString('wi_profile_photo', _photoPath!);
    } else {
      await prefs.remove('wi_profile_photo');
    }

    _usuario = usuario;
    _email = email;
    _rol = (wi['rol'] as String? ?? 'smile').trim();
    _uid = (wi['uid'] as String? ?? '').trim();
    widget.onChanged?.call(_photoPath, full);

    if (!mounted) return;
    setState(() => _saving = false);
    Notificacion.ok(context, 'Perfil actualizado');
  }

  Widget _avatar(double size) {
    if (_photoPath != null && _photoPath!.isNotEmpty && File(_photoPath!).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(_photoPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        'assets\\smile.avif',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppCSS.primary.withValues(alpha: 0.16),
          alignment: Alignment.center,
          child: Text(
            _iniciales(_nombreCtrl.text, _apellidosCtrl.text),
            style: AppStyle.h2.copyWith(color: AppCSS.primary),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData ico, String label, String val, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppCSS.border.withValues(alpha: 0.35))),
      ),
      child: Row(
        children: [
          Icon(ico, size: 16, color: AppCSS.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: AppStyle.sm),
          ),
          Expanded(
            child: Text(
              val.trim().isEmpty ? '-' : val,
              style: AppStyle.bdS,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = _nombreCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    final full = _nombreCompleto(nombre, apellidos).trim();
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AppCSS.glass300,
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppCSS.primary.withValues(alpha: 0.35), width: 2),
                      ),
                    ),
                    _avatar(88),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(full.isEmpty ? 'Usuario' : full, style: AppStyle.h3),
                      const SizedBox(height: 4),
                      Text(_usuario.isEmpty ? '@usuario' : '@$_usuario', style: AppStyle.sm),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: AppCSS.primary.withValues(alpha: 0.12),
                          border: Border.all(color: AppCSS.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_rounded, size: 14, color: AppCSS.primary),
                            const SizedBox(width: 5),
                            Text(_rol.isEmpty ? 'smile' : _rol, style: AppStyle.sm.copyWith(color: AppCSS.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppCSS.glass300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 18, color: AppCSS.primary),
                          const SizedBox(width: 7),
                          Text('Editar perfil', style: AppStyle.h3),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          filled: true,
                          fillColor: AppCSS.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppCSS.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apellidosCtrl,
                        decoration: InputDecoration(
                          labelText: 'Apellidos',
                          filled: true,
                          fillColor: AppCSS.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppCSS.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Cambiar foto'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _removePhoto,
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Quitar foto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded),
                          label: const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppCSS.glass300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_rounded, size: 18, color: AppCSS.primary),
                          const SizedBox(width: 7),
                          Text('Datos de cuenta', style: AppStyle.h3),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _infoRow(Icons.email_rounded, 'Email', _email),
                      _infoRow(Icons.alternate_email_rounded, 'Usuario', _usuario.isEmpty ? '' : '@$_usuario'),
                      _infoRow(Icons.shield_rounded, 'Rol', _rol),
                      _infoRow(
                        Icons.fingerprint_rounded,
                        'UID',
                        _uid,
                        trailing: IconButton(
                          onPressed: _uid.trim().isEmpty ? null : _copyUid,
                          tooltip: 'Copiar UID',
                          icon: const Icon(Icons.copy_rounded, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
