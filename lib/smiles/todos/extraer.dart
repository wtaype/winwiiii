import 'package:flutter/material.dart';
import '../wicss.dart';
import '../widev.dart';

class ExtraerPage extends StatelessWidget {
	const ExtraerPage({super.key});

	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			child: Column(
				children: [
					wiCard(
						child: wiPageHeader(
							icon: Icons.auto_awesome_motion_rounded,
							title: 'Extraer',
							subtitle: 'Convierte y extrae contenido con flujo rápido.',
							color: AppCSS.bg2,
						),
					),
					const SizedBox(height: 10),
					Row(
						children: [
							wiStat('MP4', 'Entrada', Icons.video_file_rounded, AppCSS.bg2),
							SizedBox(width: 10),
							wiStat('MP3', 'Salida', Icons.audio_file_rounded, AppCSS.success),
							SizedBox(width: 10),
							wiStat('1x', 'Cola', Icons.queue_music_rounded, AppCSS.warning),
						],
					),
					const SizedBox(height: 10),
					wiCard(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Proceso actual', style: AppStyle.h3),
								const SizedBox(height: 6),
								Text('Video_demo.mp4 → Audio_demo.mp3', style: AppStyle.bdS),
								const SizedBox(height: 10),
								wiProgress(0.35, AppCSS.bg2, h: 8),
								const SizedBox(height: 8),
								Text('35% completado', style: AppStyle.sm),
								const SizedBox(height: 12),
								Wrap(
									spacing: 8,
									runSpacing: 8,
									children: [
										Btn(txt: 'Elegir archivo', onTap: () {}, ico: Icons.upload_file_rounded),
										Btn(txt: 'Convertir', onTap: () {}, ico: Icons.play_arrow_rounded, color: AppCSS.success),
									],
								),
							],
						),
					),
				],
			),
		);
	}
}
