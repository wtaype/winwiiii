import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../wicss.dart';
import '../widev.dart';

class PlanificarPage extends StatefulWidget {
  const PlanificarPage({super.key});

  @override
  State<PlanificarPage> createState() => _PlanificarPageState();
}

class _PlanificarPageState extends State<PlanificarPage> {
  static const _cacheKey = 'wii_planificar_v1';

  final _buscarCtrl = TextEditingController();
  String _displayUsuario = 'Usuario';
  List<_Tarea> _tareas = [];
  bool _saving = false;

  static const _columnas = <String, ({String label, IconData icono, Color color})>{
    'planificacion': (label: 'Planificación', icono: Icons.assignment_rounded, color: Color(0xFF90EE90)),
    'analisis': (label: 'Análisis', icono: Icons.search_rounded, color: Color(0xFF87CEEB)),
    'completado': (label: 'Completado', icono: Icons.check_circle_rounded, color: Color(0xFF29C72E)),
  };

  static const _tipos = <String, ({String label, IconData icono})>{
    'trabajo': (label: 'Trabajo', icono: Icons.work_rounded),
    'estudio': (label: 'Estudio', icono: Icons.menu_book_rounded),
    'web': (label: 'Web/Dev', icono: Icons.language_rounded),
    'personal': (label: 'Personal', icono: Icons.person_rounded),
    'otros': (label: 'Otros', icono: Icons.star_rounded),
  };

  static const _prios = <String, Color>{
    'alta': Color(0xFFFF5C69),
    'media': Color(0xFFFFB800),
    'baja': Color(0xFF29C72E),
  };

  static const _colores = <Color>[
    Color(0xFF90EE90),
    Color(0xFF87CEEB),
    Color(0xFF29C72E),
    Color(0xFF7000FF),
    Color(0xFFFF5C69),
    Color(0xFFFFB800),
    Color(0xFF94A3B8),
    Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadPerfil();
    await _loadCache();
    if (mounted) setState(() {});
  }

  Future<void> _loadPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wiSmile');
    if (raw == null || raw.isEmpty) return;
    try {
      final wi = jsonDecode(raw);
      if (wi is! Map<String, dynamic>) return;
      final nombre = (wi['nombre'] as String? ?? '').trim();
      final apellidos = (wi['apellidos'] as String? ?? '').trim();
      final usuario = (wi['usuario'] as String? ?? '').trim();
      final email = (wi['email'] as String? ?? '').trim();
      final full = [nombre, apellidos].where((e) => e.isNotEmpty).join(' ').trim();
      _displayUsuario = full.isNotEmpty ? full : (usuario.isNotEmpty ? usuario : (email.isNotEmpty ? email : 'Usuario'));
    } catch (_) {}
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw);
      if (data is! List) return;
      _tareas = data.map((e) => _Tarea.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _tareas = [];
    }
  }

  Future<void> _saveCache() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_tareas.map((e) => e.toMap()).toList()));
    if (!mounted) return;
    setState(() => _saving = false);
  }

  int _countCol(String col) => _tareas.where((e) => e.columna == col).length;

  List<_Tarea> _enColumna(String col) {
    final q = _buscarCtrl.text.trim().toLowerCase();
    return _tareas.where((t) {
      if (t.columna != col) return false;
      if (q.isEmpty) return true;
      return t.titulo.toLowerCase().contains(q) ||
          t.descripcion.toLowerCase().contains(q) ||
          (_tipos[t.tipo]?.label.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _agregar(String col) async {
    final id = 'pl_${DateTime.now().millisecondsSinceEpoch}';
    _tareas.insert(
      0,
      _Tarea(
        id: id,
        titulo: '',
        descripcion: '',
        columna: col,
        prio: 'media',
        tipo: 'trabajo',
        color: _columnas[col]!.color.value,
        creado: DateTime.now().toIso8601String(),
      ),
    );
    setState(() {});
    await _saveCache();
  }

  Future<void> _eliminar(String id) async {
    final ok = await Mensaje(context, titulo: 'Eliminar', msg: '¿Eliminar tarea?');
    if (ok != true) return;
    _tareas.removeWhere((e) => e.id == id);
    setState(() {});
    await _saveCache();
  }

  Future<void> _mover(_Tarea t, String col) async {
    if (t.columna == col) return;
    t.columna = col;
    t.color = _columnas[col]!.color.value;
    if (col == 'completado') {
      Notificacion.ok(context, '🎉 Tarea completada');
    }
    setState(() {});
    await _saveCache();
  }

  Future<void> _editar(_Tarea t) async {
    final titulo = TextEditingController(text: t.titulo);
    final desc = TextEditingController(text: t.descripcion);
    String tipo = t.tipo;
    String prio = t.prio;
    int color = t.color;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar tarea', style: AppStyle.h3),
        content: StatefulBuilder(
          builder: (ctx, setDialog) => SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titulo,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: desc,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  items: _tipos.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.label)))
                      .toList(),
                  onChanged: (v) => setDialog(() => tipo = v ?? 'trabajo'),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: prio,
                  items: _prios.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1))))
                      .toList(),
                  onChanged: (v) => setDialog(() => prio = v ?? 'media'),
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _colores.map((c) {
                    final act = color == c.value;
                    return InkWell(
                      onTap: () => setDialog(() => color = c.value),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: act ? AppCSS.black : Colors.transparent, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
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
    t.titulo = titulo.text.trim();
    t.descripcion = desc.text.trim();
    t.tipo = tipo;
    t.prio = prio;
    t.color = color;
    setState(() {});
    await _saveCache();
  }

  String _fmtFecha(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  Widget _card(_Tarea t) {
    final tipo = _tipos[t.tipo] ?? _tipos['trabajo']!;
    final prioColor = _prios[t.prio] ?? AppCSS.warning;
    final baseColor = Color(t.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppCSS.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppCSS.border.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: prioColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.titulo.trim().isEmpty ? 'Nueva tarea' : t.titulo,
                    style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editar(t);
                    if (v == 'delete') _eliminar(t.id);
                    if (v == 'planificacion') _mover(t, 'planificacion');
                    if (v == 'analisis') _mover(t, 'analisis');
                    if (v == 'completado') _mover(t, 'completado');
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'planificacion', child: Text('Mover a Planificación')),
                    PopupMenuItem(value: 'analisis', child: Text('Mover a Análisis')),
                    PopupMenuItem(value: 'completado', child: Text('Mover a Completado')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                  child: const Icon(Icons.more_vert_rounded, size: 18),
                ),
              ],
            ),
            if (t.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.descripcion, style: AppStyle.sm),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tipo.icono, size: 12, color: baseColor),
                      const SizedBox(width: 4),
                      Text(tipo.label, style: AppStyle.sm.copyWith(color: baseColor)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_fmtFecha(t.creado), style: AppStyle.sm),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _columna(String key) {
    final c = _columnas[key]!;
    final items = _enColumna(key);
    return Expanded(
      child: Container(
        decoration: AppCSS.glass300,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(c.icono, color: c.color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c.label,
                      style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  wiBox(Icons.layers_rounded, '${items.length}', c.color),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => _agregar(key),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    tooltip: 'Agregar tarea',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('Sin tareas'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => _card(items[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = _countCol('planificacion');
    final anal = _countCol('analisis');
    final comp = _countCol('completado');
    final total = _tareas.length;

    return Column(
      children: [
        Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets\\smile.avif',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => AppCSS.logoCirculo(size: 44),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planificador', style: AppStyle.h3),
                  Text('${Saludar()} $_displayUsuario', style: AppStyle.sm),
                ],
              ),
            ),
            wiBox(Icons.assignment_rounded, '$plan', const Color(0xFF90EE90)),
            const SizedBox(width: 6),
            wiBox(Icons.search_rounded, '$anal', const Color(0xFF87CEEB)),
            const SizedBox(width: 6),
            wiBox(Icons.check_circle_rounded, '$comp', const Color(0xFF29C72E)),
            const SizedBox(width: 6),
            wiBox(Icons.layers_rounded, '$total', AppCSS.info),
            const SizedBox(width: 8),
            wiBox(
              _saving ? Icons.sync_rounded : Icons.cloud_done_rounded,
              _saving ? 'Guardando...' : 'Local',
              _saving ? AppCSS.warning : AppCSS.success,
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _buscarCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Buscar tarea por título, descripción o tipo...',
            filled: true,
            fillColor: AppCSS.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppCSS.border),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              _columna('planificacion'),
              const SizedBox(width: 10),
              _columna('analisis'),
              const SizedBox(width: 10),
              _columna('completado'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tarea {
  _Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.columna,
    required this.prio,
    required this.tipo,
    required this.color,
    required this.creado,
  });

  String id;
  String titulo;
  String descripcion;
  String columna;
  String prio;
  String tipo;
  int color;
  String creado;

  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'columna': columna,
        'prio': prio,
        'tipo': tipo,
        'color': color,
        'creado': creado,
      };

  factory _Tarea.fromMap(Map<String, dynamic> m) => _Tarea(
        id: (m['id'] as String? ?? '').trim(),
        titulo: (m['titulo'] as String? ?? '').trim(),
        descripcion: (m['descripcion'] as String? ?? '').trim(),
        columna: (m['columna'] as String? ?? 'planificacion').trim(),
        prio: (m['prio'] as String? ?? 'media').trim(),
        tipo: (m['tipo'] as String? ?? 'trabajo').trim(),
        color: (m['color'] as num? ?? const Color(0xFF90EE90).value).toInt(),
        creado: (m['creado'] as String? ?? DateTime.now().toIso8601String()).trim(),
      );
}
