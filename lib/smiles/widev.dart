import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wicss.dart';

// 🎯 WIDGETS Y HELPERS v11 OPTIMIZADO _______

// 👋 Saludo _______
String Saludar() {
  final h = DateTime.now().hour;
  return h < 12 ? 'Buenos días ☀️' : h < 18 ? 'Buenas tardes 🌤️' : 'Buenas noches 🌙';
}

// 📅 Fecha _______
String wiFecha(String f, {bool anio = false}) {
  try {
    final d = DateTime.parse(f);
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return anio ? '${d.day} ${m[d.month - 1]} ${d.year}' : '${d.day} ${m[d.month - 1]}';
  } catch (_) { return f; }
}

// 📆 Dia _______
String wiDia() {
  const dias = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
  const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  final n = DateTime.now();
  return '${dias[n.weekday % 7]}, ${n.day} ${m[n.month - 1]}';
}

// ⏳ Dias restantes _______
Widget diasRestantes(String f) {
  try {
    final diff = DateTime.parse(f).difference(DateTime.now()).inDays;
    if (diff < 0) return Text('${-diff}d atrás', style: AppStyle.sm.copyWith(color: AppCSS.error, fontWeight: FontWeight.w600));
    if (diff == 0) return Text('Hoy', style: AppStyle.sm.copyWith(color: AppCSS.primary, fontWeight: FontWeight.w600));
    return Text('${diff}d', style: AppStyle.sm.copyWith(color: AppCSS.success, fontWeight: FontWeight.w600));
  } catch (_) { return const SizedBox.shrink(); }
}

// 🎨 Color hex _______
Color wicoHx(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try { return Color(int.parse('0xFF${hex.replaceAll('#', '')}')); }
  catch (_) { return fallback; }
}

// 🌈 Gradient texto _______
Widget gdTexto(String tx, {double sz = 24}) => ShaderMask(
  shaderCallback: (b) => AppCSS.gradGreen.createShader(b),
  child: Text(tx, style: GoogleFonts.poppins(fontSize: sz, fontWeight: FontWeight.w700, color: Colors.white)),
);

// 🔔 Notificacion _______
class Notificacion {
  static void ok(BuildContext c, String m) => _show(c, m, AppCSS.success, Icons.check_circle);
  static void err(BuildContext c, String m) => _show(c, m, AppCSS.error, Icons.error);
  static void wrn(BuildContext c, String m) => _show(c, m, AppCSS.warning, Icons.warning_amber);
  static void info(BuildContext c, String m) => _show(c, m, AppCSS.info, Icons.info);

  static void _show(BuildContext c, String m, Color clr, IconData ico) {
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ico, color: AppCSS.white),
        AppCSS.gapHS,
        Expanded(child: Text(m, style: AppStyle.bdS.copyWith(color: AppCSS.white))),
      ]),
      backgroundColor: clr,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad8)),
      duration: AppCSS.trans1,
    ));
  }
}

// 🗑️ Mensaje _______
Future<bool?> Mensaje(BuildContext ctx, {String titulo = 'Eliminar', required String msg}) =>
  showDialog<bool>(
    context: ctx,
    builder: (c) => AlertDialog(
      title: Text(titulo, style: AppStyle.h3),
      content: Text(msg, style: AppStyle.bd),
      backgroundColor: AppCSS.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad12)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text('Cancelar', style: AppStyle.bdS.copyWith(color: AppCSS.gray)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(c, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppCSS.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad8)),
          ),
          child: Text('Eliminar', style: AppStyle.bdS.copyWith(color: AppCSS.white)),
        ),
      ],
    ),
  );

// 🏷️ wiBox _______
Widget wiBox(IconData ico, String lbl, Color clr) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(color: clr.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(ico, size: 10, color: clr),
    const SizedBox(width: 3),
    Text(lbl, style: AppStyle.sm.copyWith(color: clr)),
  ]),
);

// 🔘 wiBoxs _______
Widget wiBoxs(String lbl, Color clr) => Row(mainAxisSize: MainAxisSize.min, children: [
  Container(width: 8, height: 8, decoration: BoxDecoration(color: clr, shape: BoxShape.circle)),
  const SizedBox(width: 3),
  Text(lbl, style: AppStyle.sm),
]);

// 🔘 wiFiltro _______
Widget wiFiltro({
  required String keyF, required String lbl, required IconData ico,
  required Color clr, required String sel, required VoidCallback onTap, int? count,
}) {
  final activo = sel == keyF;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? clr.withValues(alpha: 0.15) : AppCSS.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppCSS.rad8),
        border: Border.all(color: activo ? clr : AppCSS.border.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ico, size: 14, color: activo ? clr : AppCSS.gray),
        const SizedBox(width: 4),
        Text(lbl, style: AppStyle.sm.copyWith(
          color: activo ? clr : AppCSS.text500,
          fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
        )),
        if (count != null && count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: activo ? clr : AppCSS.gray.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: AppStyle.sm.copyWith(
              color: activo ? AppCSS.white : AppCSS.text300, fontSize: 10,
            )),
          ),
        ],
      ]),
    ),
  );
}

// 📊 wiStat _______
Widget wiStat(String val, String lbl, IconData ico, Color clr, {bool vertical = true}) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: AppCSS.glass500,
    child: vertical
      ? Column(children: [
          Icon(ico, size: 18, color: clr),
          const SizedBox(height: 2),
          Text(val, style: AppStyle.bdS.copyWith(color: clr, fontWeight: FontWeight.w700)),
          Text(lbl, style: AppStyle.sm),
        ])
      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(ico, size: 16, color: clr),
          const SizedBox(width: 6),
          Text(val, style: AppStyle.bdS.copyWith(color: clr, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(lbl, style: AppStyle.sm),
        ]),
  ),
);

// 📈 wiProgress _______
Widget wiProgress(double value, Color clr, {double h = 6}) => ClipRRect(
  borderRadius: BorderRadius.circular(h / 2),
  child: LinearProgressIndicator(
    value: value.clamp(0.0, 1.0), minHeight: h,
    backgroundColor: AppCSS.border.withValues(alpha: 0.3),
    valueColor: AlwaysStoppedAnimation<Color>(clr),
  ),
);

// 💳 Glass _______
class Glass extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? pad;
  const Glass({super.key, required this.child, this.onTap, this.pad});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: pad ?? const EdgeInsets.all(AppCSS.sp16),
      decoration: AppCSS.glass500,
      child: child,
    ),
  );
}

// 📊 Stat _______
class Stat extends StatelessWidget {
  final String val, lbl;
  final IconData ico;
  final Color color;
  const Stat({super.key, required this.val, required this.lbl, required this.ico, this.color = AppCSS.primary});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(AppCSS.sp16),
    decoration: AppCSS.glass500,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(ico, color: color, size: 28),
      const SizedBox(height: 6),
      Text(val, style: AppStyle.h3.copyWith(color: color)),
      Text(lbl, style: AppStyle.sm),
    ]),
  );
}

// 😢 Vacio _______
class Vacio extends StatelessWidget {
  final String msg;
  final IconData ico;
  final String? txtBtn;
  final VoidCallback? onTap;
  const Vacio({super.key, required this.msg, this.ico = Icons.inbox, this.txtBtn, this.onTap});

  @override
  Widget build(BuildContext ctx) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(ico, size: 80, color: AppCSS.border),
      AppCSS.gapM,
      Text(msg, style: AppStyle.h3, textAlign: TextAlign.center),
      if (txtBtn != null && onTap != null) ...[
        AppCSS.gapL,
        Btn(txt: txtBtn!, onTap: onTap!, ico: Icons.refresh),
      ],
    ]),
  );
}

// 🔄 Load _______
class Load extends StatelessWidget {
  final String? msg;
  const Load({super.key, this.msg});

  @override
  Widget build(BuildContext ctx) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(color: AppCSS.primary),
      if (msg != null) ...[AppCSS.gapM, Text(msg!, style: AppStyle.bd)],
    ]),
  );
}

// 🎯 Btn _______
class Btn extends StatelessWidget {
  final String txt;
  final VoidCallback onTap;
  final IconData? ico;
  final bool load;
  final Color? color;
  const Btn({super.key, required this.txt, required this.onTap, this.ico, this.load = false, this.color});

  @override
  Widget build(BuildContext ctx) => ElevatedButton.icon(
    onPressed: load ? null : onTap,
    icon: load
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Icon(ico ?? Icons.check),
    label: Text(txt),
    style: ElevatedButton.styleFrom(
      backgroundColor: color ?? AppCSS.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppCSS.sp24, vertical: AppCSS.sp16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCSS.rad12)),
    ),
  );
}

// 📝 Campo _______
class Campo extends StatelessWidget {
  final String lbl;
  final String? hint;
  final IconData? ico;
  final bool pass;
  final TextEditingController? ctrl;
  final String? Function(String?)? vld;
  final TextInputType kb;
  const Campo({super.key, required this.lbl, this.hint, this.ico, this.pass = false, this.ctrl, this.vld, this.kb = TextInputType.text});

  @override
  Widget build(BuildContext ctx) => TextFormField(
    controller: ctrl, obscureText: pass, validator: vld, keyboardType: kb,
    style: AppStyle.bd,
    decoration: InputDecoration(
      labelText: lbl, hintText: hint,
      prefixIcon: ico != null ? Icon(ico, color: AppCSS.primary) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppCSS.rad12), borderSide: BorderSide(color: AppCSS.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppCSS.rad12), borderSide: const BorderSide(color: AppCSS.primary, width: 2)),
      filled: true, fillColor: AppCSS.inputBg,
    ),
  );
}

// 🎯 WiAppBar _______
AppBar wiAppBar(String title, {List<Widget>? actions}) => AppBar(
  title: Text(title, style: AppStyle.btn),
  backgroundColor: AppCSS.primary,
  foregroundColor: AppCSS.white,
  centerTitle: true,
  automaticallyImplyLeading: false,
  actions: actions,
);

// 💳 WiCard _______
Widget wiCard({required Widget child, EdgeInsets? margin, EdgeInsets? padding}) => Container(
  margin: margin ?? AppCSS.padM,
  padding: padding ?? AppCSS.padL,
  decoration: AppCSS.glass500,
  child: child,
);

// ⭕ WiIconCircle _______
Widget wiIconCircle(IconData icon, {Color? color, double size = 80}) => Container(
  width: size, height: size,
  decoration: BoxDecoration(color: color ?? AppCSS.primary, shape: BoxShape.circle),
  child: Icon(icon, size: size / 2, color: AppCSS.white),
);

// 🏠 WiScaffold _______
class WiScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  const WiScaffold({super.key, this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext ctx) => Scaffold(
    appBar: title != null ? wiAppBar(title!, actions: actions) : null,
    backgroundColor: AppCSS.bgLight,
    body: body,
  );
}

// 📄 WiPageHeader _______
Widget wiPageHeader({
  required IconData icon, required String title, required String subtitle, Color? color,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    wiIconCircle(icon, color: color),
    AppCSS.gapM,
    Text(title, style: AppStyle.h2.copyWith(color: color ?? AppCSS.primary)),
    AppCSS.gapS,
    Text(subtitle, style: AppStyle.bd, textAlign: TextAlign.center),
  ],
);