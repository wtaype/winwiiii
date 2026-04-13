import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

	static const _colores = ['Cielo', 'Menta', 'Rosa', 'Lavanda', 'Dorado'];

	User? get _user => FirebaseAuth.instance.currentUser;

	@override
	void initState() {
		super.initState();
		_loadNotas();
	}

	@override
	void dispose() {
		_tituloCtrl.dispose();
		_contenidoCtrl.dispose();
		super.dispose();
	}

	Future<String> _usuarioActual(User user) async {
		final prefs = await SharedPreferences.getInstance();
		final savedName = prefs.getString('wi_profile_name')?.trim();
		if (savedName != null && savedName.isNotEmpty) return savedName;
		if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
			return user.displayName!.trim();
		}
		final emailName = user.email?.split('@').first;
		if (emailName != null && emailName.trim().isNotEmpty) return emailName.trim();
		return 'Usuario';
	}

	Future<void> _loadNotas() async {
		final prefs = await SharedPreferences.getInstance();
		final raw = prefs.getString('wiNotas');
		if (raw != null && raw.isNotEmpty) {
			try {
				final data = jsonDecode(raw) as List<dynamic>;
				_notas
					..clear()
					..addAll(data.map((e) => _NotaDoc.fromMap(e as Map<String, dynamic>)));
			} catch (_) {
				_notas.clear();
			}
		}
		if (!mounted) return;
		setState(() => _loading = false);
	}

	Future<void> _saveNotas() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setString('wiNotas', jsonEncode(_notas.map((n) => n.toMap()).toList()));
	}

	Future<void> _addNota() async {
		final user = _user;
		final email = user?.email?.trim();
		final contenido = _contenidoCtrl.text.trim();
		final titulo = _tituloCtrl.text.trim().isEmpty ? 'Sin titulo' : _tituloCtrl.text.trim();

		if (user == null || email == null || email.isEmpty || contenido.isEmpty || _saving) return;

		setState(() => _saving = true);
		try {
			final nowMs = DateTime.now().millisecondsSinceEpoch;
			final docId = 'nota_$nowMs';
			final now = DateTime.now();
			final usuario = await _usuarioActual(user);

			_notas.add(
				_NotaDoc(
					color: _color,
					contenido: contenido,
					email: email,
					fecha: now,
					id: docId,
					pin: _pin,
					titulo: titulo,
					usuario: usuario,
				),
			);
			await _saveNotas();

			_tituloCtrl.clear();
			_contenidoCtrl.clear();
			setState(() {
				_pin = false;
				_color = 'Cielo';
			});
		} catch (_) {
			if (mounted) Notificacion.err(context, 'No se pudo guardar la nota');
		} finally {
			if (mounted) setState(() => _saving = false);
		}
	}

	Future<void> _togglePin(int index) async {
		try {
			final n = _notas[index];
			_notas[index] = n.copyWith(pin: !n.pin);
			await _saveNotas();
			if (mounted) setState(() {});
		} catch (_) {
			if (mounted) Notificacion.err(context, 'No se pudo actualizar pin');
		}
	}

	Future<void> _delete(int index) async {
		try {
			_notas.removeAt(index);
			await _saveNotas();
			if (mounted) setState(() {});
		} catch (_) {
			if (mounted) Notificacion.err(context, 'No se pudo eliminar la nota');
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
		final email = user?.email;
		if (user == null || email == null || email.isEmpty) {
			return const Vacio(msg: 'Inicia sesión para usar Notas', ico: Icons.lock_rounded);
		}

		if (_loading) {
			return const Load(msg: 'Cargando notas...');
		}

		return Column(
			children: [
				Row(
					children: [
						Text('Notas', style: AppStyle.h3),
						const SizedBox(width: 8),
						wiBox(Icons.note_alt_rounded, 'wiNotas', AppCSS.primary),
						const Spacer(),
						wiBox(Icons.layers_rounded, '${_sortedNotas(email).length}', AppCSS.info),
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
											items: _colores
													.map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
													.toList(),
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
					child: _sortedNotas(email).isEmpty
							? const Vacio(msg: 'No tienes notas aún', ico: Icons.note_alt_outlined)
							: ListView.separated(
									itemCount: _sortedNotas(email).length,
									separatorBuilder: (_, index) => const SizedBox(height: 6),
									itemBuilder: (_, i) {
										final docs = _sortedNotas(email);
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
															Expanded(child: Text(d.titulo, style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700))),
															wiBox(Icons.palette_rounded, d.color, AppCSS.info),
															IconButton(
																onPressed: idxReal < 0 ? null : () => _togglePin(idxReal),
																icon: Icon(
																	d.pin ? Icons.push_pin_rounded : Icons.push_pin_outlined,
																	color: d.pin ? AppCSS.warning : AppCSS.gray,
																),
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

	_NotaDoc copyWith({bool? pin}) => _NotaDoc(
			color: color,
			contenido: contenido,
			email: email,
			fecha: fecha,
			id: id,
			pin: pin ?? this.pin,
			titulo: titulo,
			usuario: usuario,
		);

	Map<String, dynamic> toMap() => {
			'color': color,
			'contenido': contenido,
			'email': email,
			'fecha': fecha.toIso8601String(),
			'id': id,
			'pin': pin,
			'titulo': titulo,
			'usuario': usuario,
		};

	factory _NotaDoc.fromMap(Map<String, dynamic> map) => _NotaDoc(
			color: (map['color'] as String? ?? 'Cielo').trim(),
			contenido: (map['contenido'] as String? ?? '').trim(),
			email: (map['email'] as String? ?? '').trim(),
			fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
			id: (map['id'] as String? ?? '').trim(),
			pin: map['pin'] == true,
			titulo: (map['titulo'] as String? ?? 'Sin titulo').trim(),
			usuario: (map['usuario'] as String? ?? 'Usuario').trim(),
		);
}
