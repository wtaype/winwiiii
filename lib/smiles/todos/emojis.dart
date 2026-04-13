import 'package:flutter/material.dart';
import '../wicss.dart';
import '../widev.dart';

class EmojisPage extends StatelessWidget {
	const EmojisPage({super.key});

	@override
	Widget build(BuildContext context) {
		final grupos = [
			('Productividad', '✅ 📌 📅 🧠 🧩', AppCSS.bg3),
			('Motivación', '🚀 🔥 💪 🎯 ✨', AppCSS.success),
			('Estados', '😎 🙂 🤔 😴 😅', AppCSS.warning),
			('Ideas', '💡 📝 📚 🛠️ 📈', AppCSS.info),
		];

		return SingleChildScrollView(
			child: Column(
				children: [
					wiCard(
						child: wiPageHeader(
							icon: Icons.emoji_emotions_rounded,
							title: 'Emojis',
							subtitle: 'Biblioteca rápida para notas y mensajes.',
							color: AppCSS.bg3,
						),
					),
					const SizedBox(height: 10),
					for (final item in grupos) ...[
						wiCard(
							child: Row(
								children: [
									wiIconCircle(Icons.tag_faces_rounded, color: item.$3, size: 40),
									const SizedBox(width: 10),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(item.$1, style: AppStyle.h3),
												const SizedBox(height: 4),
												Text(item.$2, style: AppStyle.bd),
											],
										),
									),
									IconButton(
										onPressed: () => Notificacion.ok(context, 'Emoji copiado (MVP)'),
										icon: const Icon(Icons.copy_rounded),
									),
								],
							),
						),
						const SizedBox(height: 8),
					],
				],
			),
		);
	}
}
