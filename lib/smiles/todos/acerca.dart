import 'package:flutter/material.dart';
import '../wicss.dart';
import '../widev.dart';
import '../wii.dart';

class AcercaPage extends StatelessWidget {
	const AcercaPage({super.key});

	@override
	Widget build(BuildContext context) {
		return wiCard(
			child: Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						wiPageHeader(
							icon: Icons.info_rounded,
							title: wii.app,
							subtitle: wii.desc,
							color: AppCSS.bg6,
						),
						const SizedBox(height: 10),
						Text('Versión ${wii.version}', style: AppStyle.bdS),
						Text('Autor ${wii.autor}', style: AppStyle.sm),
					],
				),
			),
		);
	}
}
