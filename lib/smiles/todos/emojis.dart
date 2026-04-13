import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../wicss.dart';
import '../widev.dart';

class EmojisPage extends StatefulWidget {
  const EmojisPage({super.key});

  @override
  State<EmojisPage> createState() => _EmojisPageState();
}

class _EmojisPageState extends State<EmojisPage> {
  static const _cacheNotepad = 'wii_emojis_notepad';
  static const _cacheRecientes = 'wii_emojis_recientes';

  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _categoriaActual = 'caras';
  String _displayUsuario = 'Usuario';
  List<String> _recientes = [];

  static const _categorias = <String, ({IconData icono, String label})>{
    'recientes': (icono: Icons.history_rounded, label: 'Recientes'),
    'caras': (icono: Icons.tag_faces_rounded, label: 'Caras'),
    'corazones': (icono: Icons.favorite_rounded, label: 'Corazones'),
    'manos': (icono: Icons.waving_hand_rounded, label: 'Manos'),
    'animales': (icono: Icons.pets_rounded, label: 'Animales'),
    'comida': (icono: Icons.restaurant_rounded, label: 'Comida'),
    'objetos': (icono: Icons.lightbulb_rounded, label: 'Objetos'),
    'simbolos': (icono: Icons.auto_awesome_rounded, label: 'Símbolos'),
    'banderas': (icono: Icons.flag_rounded, label: 'Banderas'),
  };

  static const _emojis = <String, List<String>>{
    'caras': [
      '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚','😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔','🤐','🤨','😐','😑','😶','😏','😒','🙄','😬','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','😟','🙁','☹️','😮','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','🥱','😤','😡','😠','🤬','😈','👿','💀','☠️','💩','🤡','👹','👺','👻','👽','👾','🤖','😺','😸','😹','😻','😼','😽','🙀','😿','😾'
    ],
    'corazones': [
      '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','♥️','🫀','❤️‍🔥','❤️‍🩹','🩷','🩵','🩶','💌','💋','👄','🫦','💑','👩‍❤️‍👨','👨‍❤️‍👨','👩‍❤️‍👩','💏','👩‍❤️‍💋‍👨','👨‍❤️‍💋‍👨','👩‍❤️‍💋‍👩','🥰','😍','😘','😻','💐','🌹','🥀','🌷','🌸','💮'
    ],
    'manos': [
      '👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🧠','🫀','🫁','🦷','🦴','👀','👁️','👅','👄','🫦','💋','👶','🧒','👦','👧','🧑','👱','👨','🧔','👩','🧓','👴','👵'
    ],
    'animales': [
      '🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐻‍❄️','🐨','🐯','🦁','🐮','🐷','🐽','🐸','🐵','🙈','🙉','🙊','🐒','🐔','🐧','🐦','🐤','🐣','🐥','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🪱','🐛','🦋','🐌','🐞','🐜','🪰','🪲','🪳','🦟','🦗','🕷️','🦂','🐢','🐍','🦎','🦖','🦕','🐙','🦑','🦐','🦞','🦀','🐡','🐠','🐟','🐬','🐳','🐋','🦈','🐊','🐅','🐆','🦓','🦍','🦧','🦣','🐘','🦛','🦏','🐪','🐫','🦒','🦘'
    ],
    'comida': [
      '🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🍆','🥑','🥦','🥬','🥒','🌶️','🫑','🌽','🥕','🫒','🧄','🧅','🥔','🍠','🥐','🥯','🍞','🥖','🥨','🧀','🥚','🍳','🧈','🥞','🧇','🥓','🥩','🍗','🍖','🦴','🌭','🍔','🍟','🍕','🫓','🥪','🥙','🧆','🌮','🌯','🫔','🥗','🥘','🫕','🍝','🍜','🍲','🍛','🍣','🍱','🥟','🦪','🍤','🍙','🍚','🍘','🍥','🥠','🥮','🍢','🍡','🍧','🍨','🍦','🥧','🧁','🍰','🎂','🍮','🍭','🍬','🍫','🍿','🍩','🍪','🌰','🥜','🍯'
    ],
    'objetos': [
      '📱','💻','⌨️','🖥️','🖨️','🖱️','🖲️','💽','💾','💿','📀','📼','📷','📸','📹','🎥','📽️','🎞️','📞','☎️','📟','📠','📺','📻','🎙️','🎚️','🎛️','🧭','⏱️','⏲️','⏰','🕰️','⌛','⏳','📡','🔋','🔌','💡','🔦','🕯️','🧯','🛢️','💸','💵','💴','💶','💷','🪙','💰','💳','💎','⚖️','🪜','🧰','🪛','🔧','🔨','⚒️','🛠️','⛏️','🪚','🔩','⚙️','🪤','🧱','⛓️','🧲','🔫','💣','🧨','🪓','🔪','🗡️','⚔️','🛡️','🚬','⚰️','🪦','⚱️','🏺'
    ],
    'simbolos': [
      '⭐','🌟','✨','💫','⚡','🔥','💥','☀️','🌙','🌈','☁️','❄️','💧','🌊','🎯','🏆','🥇','🥈','🥉','🏅','🎖️','🎗️','🎪','🎭','🎨','🎬','🎤','🎧','🎼','🎹','🥁','🎷','🎺','🎸','🪕','🎻','🎲','♟️','🎯','🎳','🎮','🕹️','🎰','🧩','♠️','♥️','♦️','♣️','🃏','🀄','🎴','🔮','✅','❌','❓','❗','💯','🔴','🟠','🟡','🟢','🔵','🟣','⚫','⚪','🟤','🔶','🔷','🔸','🔹','🔺','🔻','💠','🔘','🔳','🔲','▪️','▫️','◾','◽'
    ],
    'banderas': [
      '🏳️','🏴','🏁','🚩','🏳️‍🌈','🏳️‍⚧️','🇦🇷','🇧🇴','🇧🇷','🇨🇱','🇨🇴','🇨🇷','🇨🇺','🇩🇴','🇪🇨','🇸🇻','🇬🇹','🇭🇳','🇲🇽','🇳🇮','🇵🇦','🇵🇾','🇵🇪','🇵🇷','🇺🇾','🇻🇪','🇪🇸','🇺🇸','🇬🇧','🇫🇷','🇩🇪','🇮🇹','🇵🇹','🇯🇵','🇰🇷','🇨🇳','🇮🇳','🇷🇺','🇦🇺','🇨🇦','🇳🇱','🇧🇪','🇨🇭','🇦🇹','🇸🇪','🇳🇴','🇩🇰','🇫🇮'
    ],
  };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _noteCtrl.text = prefs.getString(_cacheNotepad) ?? '';
    _recientes = _leerRecientes(prefs);
    await _loadPerfil();
    if (mounted) setState(() {});
  }

  Future<void> _loadPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wiSmile');
    if (raw == null || raw.isEmpty) return;
    try {
      final wi = jsonDecode(raw);
      if (wi is! Map<String, dynamic>) return;
      final nombre = (wi['nombre'] as String? ?? '').trim();
      final apellidos = (wi['apellidos'] as String? ?? '').trim();
      final usuario = (wi['usuario'] as String? ?? '').trim();
      final email = (wi['email'] as String? ?? '').trim();
      final full = [nombre, apellidos].where((e) => e.isNotEmpty).join(' ').trim();
      _displayUsuario = full.isNotEmpty ? full : (usuario.isNotEmpty ? usuario : (email.isNotEmpty ? email : 'Usuario'));
    } catch (_) {}
  }

  List<String> _leerRecientes(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheRecientes);
    if (raw == null || raw.isEmpty) return [];
    try {
      final d = jsonDecode(raw);
      if (d is List) return d.map((e) => '$e').where((e) => e.isNotEmpty).take(32).toList();
    } catch (_) {}
    return [];
  }

  Future<void> _guardarRecientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheRecientes, jsonEncode(_recientes.take(32).toList()));
  }

  Future<void> _guardarNotepad() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheNotepad, _noteCtrl.text);
  }

  List<String> _emojisFiltrados() {
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty) {
      return _emojis.values.expand((e) => e).where((e) => e.contains(q)).toList();
    }
    if (_categoriaActual == 'recientes') return _recientes;
    return _emojis[_categoriaActual] ?? const [];
  }

  Future<void> _copiar(String txt, {String? okMsg}) async {
    if (txt.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: txt));
    if (!mounted) return;
    Notificacion.ok(context, okMsg ?? 'Copiado');
  }

  Future<void> _usarEmoji(String emoji) async {
    await _copiar(emoji, okMsg: '$emoji Copiado');

    _recientes = [emoji, ..._recientes.where((e) => e != emoji)].take(32).toList();
    await _guardarRecientes();

    final v = _noteCtrl.value;
    final pos = v.selection.baseOffset < 0 ? _noteCtrl.text.length : v.selection.baseOffset;
    final t = _noteCtrl.text;
    final nuevo = t.substring(0, pos) + emoji + t.substring(pos);
    _noteCtrl.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(offset: pos + emoji.length),
    );
    await _guardarNotepad();
    if (mounted) setState(() {});
  }

  Future<void> _copiarTodo() async {
    final txt = _noteCtrl.text.trim();
    if (txt.isEmpty) {
      if (mounted) Notificacion.wrn(context, 'Notepad vacío');
      return;
    }
    await _copiar(txt, okMsg: 'Texto copiado');
  }

  Future<void> _limpiarNotepad() async {
    _noteCtrl.clear();
    await _guardarNotepad();
    if (!mounted) return;
    setState(() {});
    Notificacion.ok(context, 'Notepad limpiado');
  }

  Future<void> _insertarSalto() async {
    final v = _noteCtrl.value;
    final pos = v.selection.baseOffset < 0 ? _noteCtrl.text.length : v.selection.baseOffset;
    final t = _noteCtrl.text;
    final nuevo = t.substring(0, pos) + '\n' + t.substring(pos);
    _noteCtrl.value = TextEditingValue(
      text: nuevo,
      selection: TextSelection.collapsed(offset: pos + 1),
    );
    await _guardarNotepad();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = _emojisFiltrados();
    final cat = _categorias[_categoriaActual]!;
    return Column(
      children: [
        Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets\\smile.avif',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => AppCSS.logoCirculo(size: 44),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emojis', style: AppStyle.h3),
                  Text('${Saludar()} $_displayUsuario', style: AppStyle.sm),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _copiarTodo,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar todo'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _limpiarNotepad,
              tooltip: 'Limpiar',
              icon: const Icon(Icons.delete_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 35,
                child: Container(
                  decoration: AppCSS.glass300,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Notepad', style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          wiBox(Icons.text_fields_rounded, '${_noteCtrl.text.length} caracteres', AppCSS.info),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _noteCtrl,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          onChanged: (_) {
                            _guardarNotepad();
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje... y agrega emojis 😊',
                            filled: true,
                            fillColor: AppCSS.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppCSS.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _insertarSalto,
                            icon: const Icon(Icons.subdirectory_arrow_right_rounded),
                            label: const Text('Salto'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _copiarTodo,
                            icon: const Icon(Icons.content_copy_rounded),
                            label: const Text('Copiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 64,
                child: Container(
                  decoration: AppCSS.glass300,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: 'Buscar emoji...',
                          filled: true,
                          fillColor: AppCSS.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppCSS.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categorias.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (_, i) {
                            final key = _categorias.keys.elementAt(i);
                            final c = _categorias[key]!;
                            final active = key == _categoriaActual;
                            return IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _categoriaActual = key);
                              },
                              tooltip: c.label,
                              icon: Icon(c.icono),
                              style: IconButton.styleFrom(
                                backgroundColor: active ? AppCSS.warning.withValues(alpha: 0.16) : Colors.transparent,
                                foregroundColor: active ? AppCSS.warning : AppCSS.gray,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(cat.icono, size: 16, color: AppCSS.warning),
                          const SizedBox(width: 6),
                          Text(cat.label, style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          wiBox(Icons.grid_view_rounded, '${list.length}', AppCSS.info),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: list.isEmpty
                            ? const Vacio(msg: 'No hay emojis', ico: Icons.search_off_rounded)
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                  childAspectRatio: 1,
                                ),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final e = list[i];
                                  return InkWell(
                                    onTap: () => _usarEmoji(e),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: AppCSS.white.withValues(alpha: 0.8),
                                        border: Border.all(color: AppCSS.border.withValues(alpha: 0.45)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(e, style: const TextStyle(fontSize: 22)),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
