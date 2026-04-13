import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
	late final TextEditingController _nameCtrl;
	String? _photoPath;
	bool _saving = false;

	@override
	void initState() {
		super.initState();
		_nameCtrl = TextEditingController(text: widget.initialName ?? 'Usuario');
		_photoPath = widget.initialPhotoPath;
	}

	@override
	void dispose() {
		_nameCtrl.dispose();
		super.dispose();
	}

	Future<void> _pickPhoto() async {
		final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
		final path = result?.files.single.path;
		if (path == null || path.isEmpty) return;
		setState(() => _photoPath = path);
		await _save();
	}

	Future<void> _removePhoto() async {
		setState(() => _photoPath = null);
		await _save();
	}

	Future<void> _save() async {
		setState(() => _saving = true);
		final prefs = await SharedPreferences.getInstance();
		final name = _nameCtrl.text.trim().isEmpty ? 'Usuario' : _nameCtrl.text.trim();

		await prefs.setString('wi_profile_name', name);
		if (_photoPath != null && _photoPath!.isNotEmpty) {
			await prefs.setString('wi_profile_photo', _photoPath!);
		} else {
			await prefs.remove('wi_profile_photo');
		}

		widget.onChanged?.call(_photoPath, name);
		if (mounted) {
			setState(() => _saving = false);
			Notificacion.ok(context, 'Perfil actualizado');
		}
	}

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					wiCard(
						margin: EdgeInsets.zero,
						child: Column(
							children: [
								_avatar(52),
								const SizedBox(height: 8),
								Text('Foto de perfil', style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
								const SizedBox(height: 8),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									alignment: WrapAlignment.center,
									children: [
										OutlinedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Cambiar foto')),
										OutlinedButton.icon(onPressed: _removePhoto, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Quitar foto')),
									],
								),
							],
						),
					),
					const SizedBox(height: 10),
					wiCard(
						margin: EdgeInsets.zero,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Datos', style: AppStyle.h3),
								const SizedBox(height: 8),
								TextField(
									controller: _nameCtrl,
									decoration: InputDecoration(
										labelText: 'Nombre',
										filled: true,
										fillColor: AppCSS.white,
										border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppCSS.border)),
									),
								),
								const SizedBox(height: 8),
								Container(
									width: double.infinity,
									padding: const EdgeInsets.all(10),
									decoration: AppCSS.glass300,
									child: Text(widget.userEmail ?? 'Sin correo', style: AppStyle.bdS),
								),
								const SizedBox(height: 12),
								Align(
									alignment: Alignment.centerRight,
									child: FilledButton.icon(
										onPressed: _saving ? null : _save,
										icon: _saving
												? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
												: const Icon(Icons.save_rounded),
										label: const Text('Guardar'),
									),
								),
							],
						),
					),
				],
			),
		);
	}

	Widget _avatar(double r) {
		final initial = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim()[0].toUpperCase() : 'U';
		if (_photoPath != null && _photoPath!.isNotEmpty && File(_photoPath!).existsSync()) {
			return CircleAvatar(radius: r, backgroundImage: FileImage(File(_photoPath!)));
		}
		return CircleAvatar(
			radius: r,
			backgroundColor: AppCSS.primary.withValues(alpha: 0.18),
			child: Text(initial, style: AppStyle.h2.copyWith(color: AppCSS.primary)),
		);
	}
}
