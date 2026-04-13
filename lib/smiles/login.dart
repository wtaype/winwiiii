import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'pantallas.dart';
import 'wicss.dart';
import 'widev.dart';

class AuthBootstrap extends StatelessWidget {
	const AuthBootstrap({super.key});

	@override
	Widget build(BuildContext context) {
		return FutureBuilder<FirebaseApp>(
			future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
			builder: (context, snap) {
				if (snap.connectionState != ConnectionState.done) {
					return const WiScaffold(body: Load(msg: 'Inicializando sesión...'));
				}
				if (snap.hasError) {
					return WiScaffold(
						title: 'Error',
						body: Center(
							child: wiCard(
								child: Text('Error iniciando Firebase. Revisa tu conexión/configuración.', style: AppStyle.bd),
							),
						),
					);
				}
				return const AuthGate();
			},
		);
	}
}

class AuthGate extends StatelessWidget {
	const AuthGate({super.key});

	@override
	Widget build(BuildContext context) {
		return StreamBuilder<User?>(
			stream: FirebaseAuth.instance.authStateChanges(),
			initialData: FirebaseAuth.instance.currentUser,
			builder: (context, snap) {
				if (snap.hasError) {
					return WiScaffold(
						title: 'Error de sesión',
						body: Center(
							child: wiCard(
								child: Text('No se pudo validar sesión Firebase.', style: AppStyle.bd),
							),
						),
					);
				}
				final user = snap.data ?? FirebaseAuth.instance.currentUser;
				return user == null ? const LoginPage() : const PantallaPrincipal(initialIndex: 0);
			},
		);
	}
}

class LoginPage extends StatefulWidget {
	const LoginPage({super.key});

	@override
	State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
	final _form = GlobalKey<FormState>();
	final _email = TextEditingController();
	final _pass = TextEditingController();
	bool _register = false;
	bool _loading = false;

	@override
	void dispose() {
		_email.dispose();
		_pass.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppCSS.bgLight,
			body: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 420),
					child: Glass(
						pad: const EdgeInsets.all(20),
						child: Form(
							key: _form,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									Center(child: AppCSS.logoCirculo(size: 70)),
									const SizedBox(height: 10),
									Text('Iniciar sesión', textAlign: TextAlign.center, style: AppStyle.h2),
									const SizedBox(height: 4),
									Text(
										_register ? 'Crea tu cuenta profesional' : 'Accede para continuar',
										textAlign: TextAlign.center,
										style: AppStyle.bdS,
									),
									const SizedBox(height: 16),
									Campo(
										lbl: 'Correo',
										hint: 'tu@email.com',
										ico: Icons.email_rounded,
										kb: TextInputType.emailAddress,
										ctrl: _email,
										vld: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
									),
									const SizedBox(height: 10),
									Campo(
										lbl: 'Contraseña',
										hint: '********',
										ico: Icons.lock_rounded,
										pass: true,
										ctrl: _pass,
										vld: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
									),
									const SizedBox(height: 16),
									Btn(
										txt: _register ? 'Crear cuenta' : 'Entrar',
										ico: _register ? Icons.person_add_rounded : Icons.login_rounded,
										load: _loading,
										onTap: _submit,
									),
									const SizedBox(height: 8),
									TextButton(
										onPressed: _loading ? null : () => setState(() => _register = !_register),
										child: Text(
											_register ? 'Ya tengo cuenta' : 'Crear cuenta nueva',
											style: AppStyle.bdS.copyWith(color: AppCSS.primary),
										),
									),
								],
							),
						),
					),
				),
			),
		);
	}

	Future<void> _submit() async {
		if (!_form.currentState!.validate()) return;
		setState(() => _loading = true);
		try {
			if (_register) {
				await FirebaseAuth.instance.createUserWithEmailAndPassword(
					email: _email.text.trim(),
					password: _pass.text,
				);
			} else {
				await FirebaseAuth.instance.signInWithEmailAndPassword(
					email: _email.text.trim(),
					password: _pass.text,
				);
			}
			if (mounted) Notificacion.ok(context, 'Bienvenido a Winwii');
		} on FirebaseAuthException catch (e) {
			if (!mounted) return;
			Notificacion.err(context, _firebaseMsg(e));
		} catch (_) {
			if (!mounted) return;
			Notificacion.err(context, 'No se pudo iniciar sesión');
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	String _firebaseMsg(FirebaseAuthException e) {
		switch (e.code) {
			case 'user-not-found':
			case 'wrong-password':
			case 'invalid-credential':
				return 'Credenciales incorrectas';
			case 'email-already-in-use':
				return 'Este correo ya está registrado';
			case 'invalid-email':
				return 'Correo inválido';
			case 'weak-password':
				return 'Contraseña muy débil';
			default:
				return e.message ?? 'Error de autenticación';
		}
	}
}
