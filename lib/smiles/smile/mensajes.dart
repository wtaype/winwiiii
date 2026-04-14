import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../wicss.dart';
import '../widev.dart';

class MensajesPage extends StatefulWidget {
  const MensajesPage({super.key});

  @override
  State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
  static const _limit = 50;

  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<_MensajeDoc> _mensajes = [];
  bool _loading = true;
  bool _sending = false;
  bool _online = false;
  String _displayUsuario = 'Usuario';
  String _activeEmail = '';
  Timer? _realtimeTimer;

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
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final user = _user;
    if (user != null) {
      _activeEmail = await _emailActual(user);
    }
    await _loadPerfil();
    await _loadCache();
    if (!mounted) return;
    setState(() => _loading = false);
    await _syncMensajes(silent: true);
    _startRealtime();
    _scrollEnd();
  }

  void _startRealtime() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _syncMensajes(silent: true);
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
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  Future<void> _loadPerfil() async {
    final user = _user;
    if (user == null) return;
    final wiSmile = await _leerWiSmile();
    final nombre = _nombreCompleto(
      wiSmile['nombre'] as String?,
      wiSmile['apellidos'] as String?,
    ).trim();
    final usuario = (wiSmile['usuario'] as String? ?? '').trim();
    final email = (wiSmile['email'] as String? ?? user.email ?? '').trim();
    final display = nombre.isNotEmpty
        ? nombre
        : (usuario.isNotEmpty ? usuario : (email.isNotEmpty ? email : 'Usuario'));
    if (!mounted) return;
    setState(() => _displayUsuario = display);
  }

  Future<String> _usuarioActual(User user) async {
    final wiSmile = await _leerWiSmile();
    final nombre = _nombreCompleto(
      wiSmile['nombre'] as String?,
      wiSmile['apellidos'] as String?,
    ).trim();
    if (nombre.isNotEmpty) return nombre;
    final usuario = (wiSmile['usuario'] as String? ?? '').trim();
    if (usuario.isNotEmpty) return usuario;
    final emailWiSmile = (wiSmile['email'] as String? ?? '').trim();
    if (emailWiSmile.isNotEmpty) return emailWiSmile;
    return user.email?.trim().isNotEmpty == true ? user.email!.trim() : 'Usuario';
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
    return 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/wiMensajes/$id';
  }

  String _cacheKey(String email) => 'wiMensajesCache:$email';

  Future<void> _loadCache() async {
    final email = _activeEmail.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(email));
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final parsed = decoded
          .whereType<Map<String, dynamic>>()
          .map(_MensajeDoc.fromJson)
          .where((m) => m.mensaje.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));
      _mensajes = parsed;
      if (!mounted) return;
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final email = _activeEmail.trim();
    if (email.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = _mensajes.map((e) => e.toJson()).toList();
    await prefs.setString(_cacheKey(email), jsonEncode(payload));
  }

  bool _sameList(List<_MensajeDoc> a, List<_MensajeDoc> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].email != b[i].email ||
          a[i].usuario != b[i].usuario ||
          a[i].mensaje != b[i].mensaje ||
          a[i].fecha.millisecondsSinceEpoch != b[i].fecha.millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  }

  String _strField(Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f is Map<String, dynamic>) {
      final s = f['stringValue'];
      if (s is String) return s;
    }
    return '';
  }

  DateTime _tsField(Map<String, dynamic> fields, String key) {
    final f = fields[key];
    if (f is Map<String, dynamic>) {
      final ts = f['timestampValue'];
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    }
    return DateTime.now();
  }

  List<_MensajeDoc> _parseRunQuery(String body) {
    final raw = jsonDecode(body);
    if (raw is! List) return [];
    final out = <_MensajeDoc>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final doc = item['document'];
      if (doc is! Map<String, dynamic>) continue;
      final name = doc['name'] as String? ?? '';
      final id = name.split('/').last;
      final fields = doc['fields'];
      if (fields is! Map<String, dynamic>) continue;
      final mensaje = _strField(fields, 'mensaje').trim();
      if (mensaje.isEmpty) continue;
      out.add(
        _MensajeDoc(
          id: _strField(fields, 'id').trim().isEmpty ? id : _strField(fields, 'id').trim(),
          email: _strField(fields, 'email').trim(),
          usuario: _strField(fields, 'usuario').trim().isEmpty ? 'Usuario' : _strField(fields, 'usuario').trim(),
          mensaje: mensaje,
          fecha: _tsField(fields, 'fecha'),
        ),
      );
    }
    out.sort((a, b) => a.fecha.compareTo(b.fecha));
    return out;
  }

  Future<void> _syncMensajes({bool silent = false}) async {
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
            {'collectionId': 'wiMensajes'}
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

      final incoming = _parseRunQuery(res.body);
      final changed = !_sameList(_mensajes, incoming);
      if (changed) {
        _mensajes = incoming;
        await _saveCache();
      }
      if (!mounted) return;
      setState(() => _online = true);
      if (changed) _scrollEnd();
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = false);
      if (!silent) Notificacion.wrn(context, 'Sin conexión a Firebase');
    }
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final user = _user;
    if (user == null) return;
    final email = await _emailActual(user);
    final mensaje = _textCtrl.text.trim();
    if (email.isEmpty || mensaje.isEmpty || _sending) return;
    setState(() => _sending = true);

    final id = 'm${DateTime.now().millisecondsSinceEpoch}';
    final usuario = await _usuarioActual(user);
    final local = _MensajeDoc(
      id: id,
      email: email,
      usuario: usuario,
      mensaje: mensaje,
      fecha: DateTime.now(),
    );
    _mensajes = [..._mensajes, local]..sort((a, b) => a.fecha.compareTo(b.fecha));
    _textCtrl.clear();
    await _saveCache();
    if (mounted) setState(() {});
    _scrollEnd();

    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse(_docUrl(id)),
        headers: headers,
        body: jsonEncode({
          'fields': {
            'id': {'stringValue': local.id},
            'email': {'stringValue': local.email},
            'usuario': {'stringValue': local.usuario},
            'mensaje': {'stringValue': local.mensaje},
            'fecha': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore write error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
      await _syncMensajes(silent: true);
    } catch (_) {
      _mensajes.removeWhere((m) => m.id == id);
      await _saveCache();
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'Error al guardar en Firebase');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMensaje(String id) async {
    final ok = await Mensaje(context, titulo: 'Eliminar', msg: '¿Eliminar mensaje?');
    if (ok != true) return;
    final backup = List<_MensajeDoc>.from(_mensajes);
    _mensajes.removeWhere((m) => m.id == id);
    await _saveCache();
    if (mounted) setState(() {});

    try {
      final headers = await _authHeaders();
      final res = await http.delete(Uri.parse(_docUrl(id)), headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Firestore delete error ${res.statusCode}');
      }
      if (mounted) setState(() => _online = true);
    } catch (_) {
      _mensajes = backup;
      await _saveCache();
      if (mounted) {
        setState(() => _online = false);
        Notificacion.err(context, 'Error al eliminar en Firebase');
      }
    }
  }

  Future<void> _copyMensaje(String txt) async {
    if (txt.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: txt));
    if (mounted) Notificacion.ok(context, 'Mensaje copiado');
  }

  String _hora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _labelFecha(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'Hoy';
    if (day == yesterday) return 'Ayer';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final authEmail = (user?.email ?? '').trim();
    if (user == null) {
      return const Vacio(msg: 'Inicia sesión para usar Mensajes', ico: Icons.lock_rounded);
    }
    if (_loading) return const Load(msg: 'Cargando mensajes...');

    return Column(
      children: [
        Row(
          children: [
            Text('Mensajes', style: AppStyle.h3),
            const SizedBox(width: 8),
            wiBox(Icons.chat_rounded, 'wiMensajes', AppCSS.primary),
            const SizedBox(width: 8),
            Text('${Saludar()} $_displayUsuario', style: AppStyle.sm),
            const Spacer(),
            wiBox(
              _online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              _online ? 'Online' : 'Offline',
              _online ? AppCSS.success : AppCSS.warning,
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _syncMensajes(),
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sincronizar',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: AppCSS.glass300,
            child: _mensajes.isEmpty
                ? const Vacio(msg: 'Sin mensajes aún', ico: Icons.chat_bubble_outline_rounded)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _mensajes.length,
                    itemBuilder: (context, i) {
                      final item = _mensajes[i];
                      final msg = item.mensaje.trim();
                      if (msg.isEmpty) return const SizedBox.shrink();
                      final mio = item.email.trim() == _activeEmail || item.email.trim() == authEmail;
                      final fecha = item.fecha;
                      final label = _labelFecha(fecha);
                      final prevLabel = i > 0 ? _labelFecha(_mensajes[i - 1].fecha) : '';
                      final showSep = i == 0 || label != prevLabel;
                      return Column(
                        children: [
                          if (showSep)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(label, style: AppStyle.sm.copyWith(fontWeight: FontWeight.w700)),
                            ),
                          Align(
                            alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _copyMensaje(msg),
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 560),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: mio ? AppCSS.primary.withValues(alpha: 0.18) : AppCSS.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppCSS.border.withValues(alpha: 0.45)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.usuario,
                                            style: AppStyle.sm.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppCSS.primary,
                                            ),
                                          ),
                                        ),
                                        if (mio)
                                          InkWell(
                                            onTap: () => _deleteMensaje(item.id),
                                            child: const Icon(Icons.delete_outline_rounded, size: 16),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(msg, style: AppStyle.bdS),
                                    const SizedBox(height: 4),
                                    Text(_hora(fecha), style: AppStyle.sm),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                onSubmitted: (_) => _send(),
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: AppCSS.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppCSS.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MensajeDoc {
  _MensajeDoc({
    required this.id,
    required this.email,
    required this.usuario,
    required this.mensaje,
    required this.fecha,
  });

  final String id;
  final String email;
  final String usuario;
  final String mensaje;
  final DateTime fecha;

  factory _MensajeDoc.fromJson(Map<String, dynamic> json) {
    return _MensajeDoc(
      id: (json['id'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      usuario: (json['usuario'] as String? ?? 'Usuario').trim(),
      mensaje: (json['mensaje'] as String? ?? '').trim(),
      fecha: DateTime.tryParse((json['fecha'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'usuario': usuario,
        'mensaje': mensaje,
        'fecha': fecha.toUtc().toIso8601String(),
      };
}
