import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../wicss.dart';
import '../widev.dart';

class MensajesPage extends StatefulWidget {
	const MensajesPage({super.key});

	@override
	State<MensajesPage> createState() => _MensajesPageState();
}

class _MensajesPageState extends State<MensajesPage> {
	final _textCtrl = TextEditingController();
	final _scrollCtrl = ScrollController();
	final List<_MensajeDoc> _mensajes = [];
	bool _loading = true;
	bool _sending = false;

	User? get _user => FirebaseAuth.instance.currentUser;

	@override
	void initState() {
		super.initState();
		_loadMensajes();
	}

	@override
	void dispose() {
		_textCtrl.dispose();
		_scrollCtrl.dispose();
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

	Future<void> _loadMensajes() async {
		final prefs = await SharedPreferences.getInstance();
		final raw = prefs.getString('wiMensajes');
		if (raw != null && raw.isNotEmpty) {
			try {
				final data = jsonDecode(raw) as List<dynamic>;
				_mensajes
					..clear()
					..addAll(
						data
							.map((e) => _MensajeDoc.fromMap(e as Map<String, dynamic>))
							.where((e) => e.mensaje.trim().isNotEmpty),
					);
			} catch (_) {
				_mensajes.clear();
			}
		}

		_mensajes.sort((a, b) => a.fecha.compareTo(b.fecha));
		if (!mounted) return;
		setState(() => _loading = false);
		_scrollEnd();
	}

	Future<void> _saveMensajes() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setString('wiMensajes', jsonEncode(_mensajes.map((m) => m.toMap()).toList()));
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
		final mensaje = _textCtrl.text.trim();
		final email = user?.email?.trim();
		if (user == null || email == null || email.isEmpty || mensaje.isEmpty || _sending) return;

		setState(() => _sending = true);
		try {
			final nowMs = DateTime.now().millisecondsSinceEpoch;
			final docId = 'm$nowMs';
			final now = DateTime.now();
			final usuario = await _usuarioActual(user);

			_mensajes.add(
				_MensajeDoc(
					email: email,
					fecha: now,
					id: docId,
					mensaje: mensaje,
					usuario: usuario,
				),
			);
			_mensajes.sort((a, b) => a.fecha.compareTo(b.fecha));
			await _saveMensajes();

			setState(() {});
			_textCtrl.clear();
			_scrollEnd();
		} catch (_) {
			if (mounted) Notificacion.err(context, 'No se pudo enviar el mensaje');
		} finally {
			if (mounted) setState(() => _sending = false);
		}
	}

	DateTime _toDate(dynamic v) {
		if (v is DateTime) return v;
		if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
		return DateTime.now();
	}

	String _fmtFecha(DateTime dt) {
		final d = dt.day.toString().padLeft(2, '0');
		final m = dt.month.toString().padLeft(2, '0');
		final y = dt.year;
		final h = dt.hour.toString().padLeft(2, '0');
		final min = dt.minute.toString().padLeft(2, '0');
		return '$d/$m/$y $h:$min';
	}

	@override
	Widget build(BuildContext context) {
		final user = _user;
		final email = user?.email;
		if (user == null || email == null || email.isEmpty) {
			return const Vacio(msg: 'Inicia sesión para usar Mensajes', ico: Icons.lock_rounded);
		}

		if (_loading) {
			return const Load(msg: 'Cargando mensajes...');
		}

		return Column(
			children: [
				Row(
					children: [
						Text('Mensajes', style: AppStyle.h3),
						const SizedBox(width: 8),
						wiBox(Icons.chat_rounded, 'wiMensajes', AppCSS.primary),
						const Spacer(),
						wiBox(Icons.layers_rounded, '${_mensajes.length}', AppCSS.info),
					],
				),
				const SizedBox(height: 8),
				Expanded(
					child: Container(
						decoration: AppCSS.glass300,
						child: _mensajes.isEmpty
								? const Vacio(msg: 'No hay mensajes todavía', ico: Icons.chat_bubble_outline_rounded)
								: ListView.builder(
										controller: _scrollCtrl,
										padding: const EdgeInsets.all(12),
										itemCount: _mensajes.length,
										itemBuilder: (context, i) {
											final item = _mensajes[i];
											final msg = item.mensaje.trim();
											if (msg.isEmpty) return const SizedBox.shrink();
											final mio = item.email.trim() == email;
											final fecha = _toDate(item.fecha);

											return Align(
												alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
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
															Text(item.usuario, style: AppStyle.sm.copyWith(fontWeight: FontWeight.w700, color: AppCSS.primary)),
															const SizedBox(height: 2),
															Text(msg, style: AppStyle.bdS),
															const SizedBox(height: 4),
															Text(_fmtFecha(fecha), style: AppStyle.sm),
														],
													),
												),
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
		required this.email,
		required this.fecha,
		required this.id,
		required this.mensaje,
		required this.usuario,
	});

	final String email;
	final DateTime fecha;
	final String id;
	final String mensaje;
	final String usuario;

	Map<String, dynamic> toMap() => {
			'email': email,
			'fecha': fecha.toIso8601String(),
			'id': id,
			'mensaje': mensaje,
			'usuario': usuario,
		};

	factory _MensajeDoc.fromMap(Map<String, dynamic> map) => _MensajeDoc(
			email: (map['email'] as String? ?? '').trim(),
			fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
			id: (map['id'] as String? ?? '').trim(),
			mensaje: (map['mensaje'] as String? ?? '').trim(),
			usuario: (map['usuario'] as String? ?? 'Usuario').trim(),
		);
}
