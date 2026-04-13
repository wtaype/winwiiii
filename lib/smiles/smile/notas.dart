import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../wicss.dart';
import '../widev.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final _tituloCtrl = TextEditingController();
  final _contenidoCtrl = TextEditingController();
  final List<_NotaDoc> _notas = [];
  String _color = 'Cielo';
  bool _pin = false;
  bool _loading = true;
  bool _saving = false;
  bool _online = false;
  String _displayUsuario = 'Usuario';
  String _activeEmail = '';
  Timer? _realtimeTimer;

  static const _colores = ['Cielo', 'Dulce', 'Paz', 'Mora', 'Sol'];
  static const _limit = 120;

  User? get _user => FirebaseAuth.instance.currentUser;
  String get _projectId => DefaultFirebaseOptions.windows.projectId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _tituloCtrl.dispose();
    _contenidoCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final user = _user;
    if (user != null) {
      _activeEmail = await _emailActual(user);
    }
    await _loadPerfil();
    await _syncNotas(silent: true);
    if (!mounted) return;
    setState(() => _loading = false);
    _startRealtime();
  }

  void _startRealtime() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _syncNotas(silent: true);
    });
  }

  String _nombreCompleto(String? nombre, String? apellidos) {
    final n = (nombre ?? '').trim();
    final a = (apellidos ?? '').trim();
    if (n.isEmpty) return a;
    if (a.isEmpty) return n;
    return '$n $a';
  }

  Future<Map<String, dynamic>> _leerWiSmile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wiSmile');
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    return {};
  }

  String _normalizarColor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'menta':
        return 'Paz';
      case 'rosa':
        return 'Dulce';
      case 'lavanda':
        return 'Mora';
      case 'dorado':
        return 'Sol';
      default:
        return _colores.contains(raw) ? raw : 'Cielo';
    }
  }

  Future<void> _loadPerfil() async {
    final user = _user;
    if (user == null) return;
    final wiSmile = await _leerWiSmile();
    final nombre = _nombreCompleto(wiSmile['nombre'] as String?, wiSmile['apellidos'] as String?).trim();
    final usuario = (wiSmile['usuario'] as String? ?? '').trim();
    final email = (wiSmile['email'] as String? ?? user.email ?? '').trim();
    final display = nombre.isNotEmpty ? nombre : (usuario.isNotEmpty ? usuario : (email.isNotEmpty ? email : 'Usuario'));
    if (!mounted) return;
    setState(() => _displayUsuario = display);
  }

  Future<String> _usuarioActual(User user) async {
    final wiSmile = await _leerWiSmile();
    final nombre = _nombreCompleto(wiSmile['nombre'] as String?, wiSmile['apellidos'] as String?).trim();
    if (nombre.isNotEmpty) return nombre;
    final usuario = (wiSmile['usuario'] as String? ?? '').trim();
    if (usuario.isNotEmpty) return usuario;
    final emailWiSmile = (wiSmile['email'] as String? ?? '').trim();
    if (emailWiSmile.isNotEmpty) return emailWiSmile;
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) return user.displayName!.trim();
    final emailName = user.email?.split('@').first;
    if (emailName != null && emailName.trim().isNotEmpty) return emailName.trim();
    return 'Usuario';
  }

  Future<String> _emailActual(User user) async {
    final wiSmile = await _leerWiSmile();
    final emailWiSmile = (wiSmile['email'] as String? ?? '').trim();
    if (emailWiSmile.isNotEmpty) return emailWiSmile;
    return (user.email ?? '').trim();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _user?.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Sin token Firebase');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String _runQueryUrl() {
    return 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents:runQuery';
  }

  String _docUrl(String id) {
    return 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/wiNotas/$id';
  }

  Map<String, dynamic> _toFirestoreFields(_NotaDoc d, {bool serverTime = false}) {
    return {
      'fields': {
        'id': {'stringValue': d.id},
        'email': {'stringValue': d.email},
        'usuario': {'stringValue': d.usuario},
        'titulo': {'stringValue': d.titulo},
        'contenido': {'stringValue': d.contenido},
        'color': {'stringValue': d.color},
        'pin': {'booleanValue': d.pin},
        'fecha': {
          'timestampValue': serverTime
              ? DateTime.now().toUtc().toIso8601String()
              : d.fecha.toUtc().toIso8601String(),
        },
      }
    };
  }

  String _strField(Map<String, dynamic> fields, String key, {String fallback = ''}) {
    final f = fields[key];
    if (f is Map<String, dynamic>) {
      final s = f['stringValue'];
      if (s is String) return s;
    }
    return fallback;
  }

  bool _boolField(Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f is Map<String, dynamic>) {
      final v = f['booleanValue'];
      if (v is bool) return v;
    }
    return false;
  }

  DateTime _tsField(Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f is Map<String, dynamic>) {
      final ts = f['timestampValue'];
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    }
    return DateTime.now();
  }

  List<_NotaDoc> _parseRunQuery(String body) {
    final raw = jsonDecode(body);
    if (raw is! List) return [];
    final out = <_NotaDoc>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final doc = item['document'];
      if (doc is! Map<String, dynamic>) continue;
      final name = doc['name'] as String? ?? '';
      final idFromName = name.split('/').last;
      final fields = doc['fields'];
      if (fields is! Map<String, dynamic>) continue;
      out.add(
        _NotaDoc(
          id: _strField(fields, 'id').trim().isEmpty ? idFromName : _strField(fields, 'id').trim(),
          email: _strField(fields, 'email').trim(),
          usuario: _strField(fields, 'usuario', fallback: 'Usuario').trim(),
          titulo: _strField(fields, 'titulo', fallback: 'Sin titulo').trim(),
          contenido: _strField(fields, 'contenido').trim(),
          color: _normalizarColor(_strField(fields, 'color', fallback: 'Cielo')),
          pin: _boolField(fields, 'pin'),
          fecha: _tsField(fields, 'fecha'),
        ),
      );
    }
    return out;
  }

  Future<void> _syncNotas({bool silent = false}) async {
    final user = _user;
    if (user == null) return;
    final email = await _emailActual(user);
    if (email.isEmpty) return;
    _activeEmail = email;
    try {
      final headers = await _authHeaders();
      final body = jsonEncode({
        'structuredQuery': {
          'from': [
            {'collectionId': 'wiNotas'}
          ],
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'email'},
              'op': 'EQUAL',
              'value': {'stringValue': email}
            }
          },
          'limit': _limit
        }
      });
      final res = await http.post(Uri.parse(_runQueryUrl()), headers: headers, body: body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore query error ${res.statusCode}');
      }
      _notas
        ..clear()
        ..addAll(_parseRunQuery(res.body));
      if (!mounted) return;
      setState(() => _online = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = false);
      if (!silent) Notificacion.wrn(context, 'Sin conexión a Firebase');
    }
  }

  Future<void> _addNota() async {
    final user = _user;
    if (user == null) return;
    final email = await _emailActual(user);
    final contenido = _contenidoCtrl.text.trim();
    final titulo = _tituloCtrl.text.trim().isEmpty ? 'Sin titulo' : _tituloCtrl.text.trim();
    if (email.isEmpty || contenido.isEmpty || _saving) return;

    setState(() => _saving = true);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final docId = 'nota_$nowMs';
    final local = _NotaDoc(
      id: docId,
      email: email,
      usuario: await _usuarioActual(user),
      titulo: titulo,
      contenido: contenido,
      color: _normalizarColor(_color),
      pin: _pin,
      fecha: DateTime.now(),
    );
    _notas.insert(0, local);
    if (mounted) {
      setState(() {
        _tituloCtrl.clear();
        _contenidoCtrl.clear();
        _pin = false;
        _color = 'Cielo';
      });
    }

    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse(_docUrl(docId)),
        headers: headers,
        body: jsonEncode(_toFirestoreFields(local, serverTime: true)),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore write error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
      await _syncNotas(silent: true);
    } catch (_) {
      _notas.removeWhere((n) => n.id == docId);
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'No se pudo guardar la nota');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _togglePin(int index) async {
    if (index < 0 || index >= _notas.length) return;
    final before = _notas[index];
    final next = before.copyWith(pin: !before.pin);
    _notas[index] = next;
    if (mounted) setState(() {});
    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse(_docUrl(before.id)),
        headers: headers,
        body: jsonEncode(_toFirestoreFields(next, serverTime: true)),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore write error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
      await _syncNotas(silent: true);
    } catch (_) {
      _notas[index] = before;
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'No se pudo actualizar pin');
      }
    }
  }

  Future<void> _editNota(int index) async {
    if (index < 0 || index >= _notas.length) return;
    final base = _notas[index];
    final tituloCtrl = TextEditingController(text: base.titulo);
    final contenidoCtrl = TextEditingController(text: base.contenido);
    String color = _normalizarColor(base.color);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar nota', style: AppStyle.h3),
        content: StatefulBuilder(
          builder: (context, setDialog) => SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Titulo'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contenidoCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Contenido'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: color,
                  items: _colores.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialog(() => color = v ?? 'Cielo'),
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;

    final edited = base.copyWith(
      titulo: tituloCtrl.text.trim().isEmpty ? 'Sin titulo' : tituloCtrl.text.trim(),
      contenido: contenidoCtrl.text.trim(),
      color: _normalizarColor(color),
    );
    _notas[index] = edited;
    if (mounted) setState(() {});
    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse(_docUrl(base.id)),
        headers: headers,
        body: jsonEncode(_toFirestoreFields(edited, serverTime: true)),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore write error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
      await _syncNotas(silent: true);
    } catch (_) {
      _notas[index] = base;
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'No se pudo editar la nota');
      }
    }
  }

  Future<void> _delete(int index) async {
    if (index < 0 || index >= _notas.length) return;
    final ok = await Mensaje(context, titulo: 'Eliminar', msg: '¿Eliminar nota?');
    if (ok != true) return;
    final base = _notas[index];
    _notas.removeAt(index);
    if (mounted) setState(() {});
    try {
      final headers = await _authHeaders();
      final res = await http.delete(Uri.parse(_docUrl(base.id)), headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore delete error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
    } catch (_) {
      _notas.insert(index, base);
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'No se pudo eliminar la nota');
      }
    }
  }

  DateTime _toDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  List<_NotaDoc> _sortedNotas(String email) {
    final docs = _notas.where((n) => n.email.trim() == email.trim()).toList();
    docs.sort((a, b) {
      final ap = a.pin ? 1 : 0;
      final bp = b.pin ? 1 : 0;
      if (ap != bp) return bp.compareTo(ap);
      return b.fecha.compareTo(a.fecha);
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final authEmail = (user?.email ?? '').trim();
    if (user == null) {
      return const Vacio(msg: 'Inicia sesión para usar Notas', ico: Icons.lock_rounded);
    }
    if (_loading) return const Load(msg: 'Cargando notas...');

    final docs = _sortedNotas(_activeEmail.isNotEmpty ? _activeEmail : authEmail);
    return Column(
      children: [
        Row(
          children: [
            Text('Notas', style: AppStyle.h3),
            const SizedBox(width: 8),
            wiBox(Icons.note_alt_rounded, 'wiNotas', AppCSS.primary),
            const SizedBox(width: 8),
            Text('${Saludar()} $_displayUsuario', style: AppStyle.sm),
            const Spacer(),
            wiBox(
              _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              _online ? 'Online' : 'Offline',
              _online ? AppCSS.success : AppCSS.warning,
            ),
            const SizedBox(width: 8),
            wiBox(Icons.layers_rounded, '${docs.length}', AppCSS.info),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _syncNotas(),
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sincronizar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: AppCSS.glass300,
          child: Column(
            children: [
              TextField(
                controller: _tituloCtrl,
                decoration: InputDecoration(
                  labelText: 'Titulo',
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
                controller: _contenidoCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Contenido',
                  filled: true,
                  fillColor: AppCSS.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppCSS.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _color,
                      items: _colores.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _color = v ?? 'Cielo'),
                      decoration: InputDecoration(
                        labelText: 'Color',
                        filled: true,
                        fillColor: AppCSS.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppCSS.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Pin', style: AppStyle.bdS),
                      value: _pin,
                      onChanged: (v) => setState(() => _pin = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _addNota,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text('Guardar nota'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: docs.isEmpty
              ? const Vacio(msg: 'No tienes notas aún', ico: Icons.note_alt_outlined)
              : ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final idxReal = _notas.indexWhere((x) => x.id == d.id);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: AppCSS.glass300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.titulo,
                                  style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              wiBox(Icons.palette_rounded, d.color, AppCSS.info),
                              IconButton(
                                onPressed: idxReal < 0 ? null : () => _togglePin(idxReal),
                                icon: Icon(
                                  d.pin ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                  color: d.pin ? AppCSS.warning : AppCSS.gray,
                                ),
                              ),
                              IconButton(
                                onPressed: idxReal < 0 ? null : () => _editNota(idxReal),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: idxReal < 0 ? null : () => _delete(idxReal),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                          if (d.contenido.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(d.contenido, style: AppStyle.bdS),
                          ],
                          const SizedBox(height: 6),
                          Text('${d.usuario} • ${_fmt(_toDate(d.fecha))}', style: AppStyle.sm),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _NotaDoc {
  _NotaDoc({
    required this.color,
    required this.contenido,
    required this.email,
    required this.fecha,
    required this.id,
    required this.pin,
    required this.titulo,
    required this.usuario,
  });

  final String color;
  final String contenido;
  final String email;
  final DateTime fecha;
  final String id;
  final bool pin;
  final String titulo;
  final String usuario;

  _NotaDoc copyWith({
    bool? pin,
    String? titulo,
    String? contenido,
    String? color,
    DateTime? fecha,
  }) =>
      _NotaDoc(
        color: color ?? this.color,
        contenido: contenido ?? this.contenido,
        email: email,
        fecha: fecha ?? this.fecha,
        id: id,
        pin: pin ?? this.pin,
        titulo: titulo ?? this.titulo,
        usuario: usuario,
      );
}
