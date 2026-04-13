import 'package:flutter/material.dart';
import '../wicss.dart';
import '../widev.dart';

class PlanificarPage extends StatelessWidget {
	const PlanificarPage({super.key});

	@override
	Widget build(BuildContext context) {
		final tareas = ['Reunión equipo', 'Diseño módulo', 'Entrega avance', 'Revisión final'];
		return SingleChildScrollView(
			child: Column(
				children: [
					wiCard(
						child: wiPageHeader(
							icon: Icons.event_note_rounded,
							title: 'Planificar',
							subtitle: 'Vista semanal compacta con tareas clave.',
							color: AppCSS.bg4,
						),
					),
					const SizedBox(height: 10),
					Row(
						children: [
							wiStat('7', 'Días', Icons.calendar_month_rounded, AppCSS.bg4),
							SizedBox(width: 10),
							wiStat('24h', 'Bloques', Icons.schedule_rounded, AppCSS.info),
							SizedBox(width: 10),
							wiStat('4', 'Pendientes', Icons.list_alt_rounded, AppCSS.warning),
						],
					),
					const SizedBox(height: 10),
					wiCard(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Tareas del día', style: AppStyle.h3),
								const SizedBox(height: 8),
								...tareas.map(
									(e) => Padding(
										padding: const EdgeInsets.only(bottom: 6),
										child: Row(
											children: [
												const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppCSS.bg4),
												const SizedBox(width: 8),
												Expanded(child: Text(e, style: AppStyle.bdS)),
											],
										),
									),
								),
								const SizedBox(height: 10),
								Btn(txt: 'Agregar tarea', onTap: () {}, ico: Icons.add_task_rounded, color: AppCSS.bg4),
							],
						),
					),
				],
			),
		);
	}
}
