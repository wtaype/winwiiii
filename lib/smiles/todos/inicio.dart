import 'package:flutter/material.dart';
import '../wicss.dart';
import '../widev.dart';

class InicioPage extends StatelessWidget {
	const InicioPage({super.key, this.onOpen});

	final void Function(int index)? onOpen;

	@override
	Widget build(BuildContext context) {
		final modules = [
			('Extraer', Icons.auto_awesome_motion_rounded, AppCSS.bg2, 1),
			('Emojis', Icons.emoji_emotions_rounded, AppCSS.bg3, 2),
			('Planificar', Icons.event_note_rounded, AppCSS.bg4, 3),
			('Acerca', Icons.info_rounded, AppCSS.bg6, 4),
			('Notas', Icons.note_alt_rounded, AppCSS.warning, 5),
			('Mensajes', Icons.message_rounded, AppCSS.info, 6),
			('Perfil', Icons.person_rounded, AppCSS.primary, 7),
		];

		return SingleChildScrollView(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					wiCard(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('${Saludar()}, bienvenido', style: AppStyle.h2),
								const SizedBox(height: 8),
								Text('Centro de control compacto para acceso rápido.', style: AppStyle.bd),
							],
						),
					),
					const SizedBox(height: 12),
					Row(
						children: [
							wiStat('8', 'Módulos', Icons.apps_rounded, AppCSS.primary),
							SizedBox(width: 10),
							wiStat('Cloud', 'Firebase', Icons.shield_rounded, AppCSS.info),
							SizedBox(width: 10),
							wiStat('Fast', 'Compacto', Icons.bolt_rounded, AppCSS.success),
						],
					),
					const SizedBox(height: 12),
					GridView.builder(
						itemCount: modules.length,
						shrinkWrap: true,
						physics: const NeverScrollableScrollPhysics(),
						gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
							crossAxisCount: 2,
							crossAxisSpacing: 10,
							mainAxisSpacing: 10,
							childAspectRatio: 2.7,
						),
						itemBuilder: (context, i) {
							final (title, icon, color, idx) = modules[i];
							return Glass(
								onTap: onOpen == null ? null : () => onOpen!(idx),
								child: Row(
									children: [
										wiIconCircle(icon, color: color, size: 42),
										const SizedBox(width: 10),
										Expanded(
											child: Column(
												mainAxisAlignment: MainAxisAlignment.center,
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Text(title, style: AppStyle.h3),
													Text('Abrir módulo', style: AppStyle.sm),
												],
											),
										),
										const Icon(Icons.arrow_forward_ios_rounded, size: 14),
									],
								),
							);
						},
					),
				],
			),
		);
	}
}
