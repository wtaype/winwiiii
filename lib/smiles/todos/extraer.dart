import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';
import '../wicss.dart';
import '../widev.dart';

class ExtraerPage extends StatefulWidget {
  const ExtraerPage({super.key});

  @override
  State<ExtraerPage> createState() => _ExtraerPageState();
}

class _ExtraerPageState extends State<ExtraerPage> {
  static const List<String> _videoExts = ['.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm'];
  static const List<String> _qualities = ['320', '192', '128', '96'];

  String? _videoPath;
  int _videoSize = 0;
  Duration _videoDuration = Duration.zero;
  String _quality = '128';
  String _outputDirectory = '';
  bool _isDragging = false;
  bool _isExtracting = false;
  double _progress = 0;
  String? _outputPath;
  int? _outputSize;
  String _statusText = 'Listo para extraer';

  @override
  void initState() {
    super.initState();
    _setDesktopAsDefaultOutput();
  }

  Future<void> _setDesktopAsDefaultOutput() async {
    final userProfile = Platform.environment['USERPROFILE'];
    final desktopPath = userProfile == null ? null : p.join(userProfile, 'Desktop');
    final desktop = desktopPath != null ? Directory(desktopPath) : null;
    final downloads = await getDownloadsDirectory();
    if (!mounted) return;
    setState(() {
      _outputDirectory = (desktop != null && desktop.existsSync()) ? desktop.path : (downloads?.path ?? Directory.current.path);
    });
  }

  Future<void> _pickVideo() async {
    if (_isExtracting) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _loadVideo(path);
  }

  Future<void> _pickOutputFolder() async {
    if (_isExtracting) return;
    final dir = await FilePicker.getDirectoryPath();
    if (dir == null || !mounted) return;
    setState(() => _outputDirectory = dir);
  }

  Future<void> _loadVideo(String path) async {
    final ext = p.extension(path).toLowerCase();
    if (!_videoExts.contains(ext)) {
      Notificacion.wrn(context, 'Selecciona un video válido (MP4, MKV, AVI, MOV, WMV, FLV, WEBM).');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      Notificacion.err(context, 'No se encontró el archivo seleccionado.');
      return;
    }

    final size = await file.length();
    if (!mounted) return;
    setState(() {
      _videoPath = path;
      _videoSize = size;
      _videoDuration = _estimateDuration(size);
      _outputPath = null;
      _outputSize = null;
      _progress = 0;
      _statusText = 'Video cargado y listo';
    });
  }

  Duration _estimateDuration(int bytes) {
    // Estimación visual para UI cuando no se usa reproductor embebido.
    final estSeconds = (bytes / (1.8 * 1024 * 1024)).round().clamp(10, 7200);
    return Duration(seconds: estSeconds);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _estimateOutputSize() {
    if (_videoPath == null) return 0;
    final kbps = int.tryParse(_quality) ?? 128;
    final durationSec = _videoDuration.inSeconds > 0 ? _videoDuration.inSeconds : 60;
    return ((durationSec * kbps * 1000) / 8).round();
  }

  Future<void> _removeVideo() async {
    if (_isExtracting) {
      Notificacion.wrn(context, 'No puedes eliminar mientras se extrae.');
      return;
    }
    if (_videoPath == null) return;
    final ok = await Mensaje(context, titulo: 'Eliminar video', msg: '¿Deseas quitar el video seleccionado?');
    if (!mounted || ok != true) return;
    setState(() {
      _videoPath = null;
      _videoSize = 0;
      _videoDuration = Duration.zero;
      _outputPath = null;
      _outputSize = null;
      _progress = 0;
      _statusText = 'Listo para extraer';
    });
  }

  String _ffmpegPath() => p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'ffmpeg', 'ffmpeg.exe');

  Future<void> _extractAudio() async {
    if (_videoPath == null) {
      Notificacion.wrn(context, 'Primero selecciona un video.');
      return;
    }
    if (_outputDirectory.isEmpty) {
      Notificacion.err(context, 'No hay carpeta de salida configurada.');
      return;
    }

    final ffmpeg = _ffmpegPath();
    if (!File(ffmpeg).existsSync()) {
      Notificacion.err(context, 'No se encontró ffmpeg en assets/ffmpeg/ffmpeg.exe');
      return;
    }

    final input = _videoPath!;
    final name = p.basenameWithoutExtension(input);
    final output = p.join(_outputDirectory, '$name.mp3');

    if (!mounted) return;
    setState(() {
      _isExtracting = true;
      _progress = 0.05;
      _statusText = 'Extrayendo audio...';
      _outputPath = null;
      _outputSize = null;
    });

    final shell = Shell();
    try {
      for (final v in [0.15, 0.3, 0.45, 0.6, 0.75, 0.9]) {
        await Future.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() => _progress = v);
      }

      await shell.run(
        '"$ffmpeg" -i "$input" -vn -ab ${_quality}k -ar 44100 -y "$output"',
      );

      final outSize = await File(output).length();
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _isExtracting = false;
        _outputPath = output;
        _outputSize = outSize;
        _statusText = 'Extracción completada';
      });
      Notificacion.ok(context, 'Audio extraído correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
        _statusText = 'Error al extraer';
        _progress = 0;
      });
      Notificacion.err(context, 'Error al extraer: $e');
    }
  }

  Widget _leftPanel() {
    final hasVideo = _videoPath != null;
    final estimated = _estimateOutputSize();
    final reduction = hasVideo && _videoSize > 0 ? ((1 - (estimated / _videoSize)) * 100) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppCSS.glass500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppCSS.info, size: 20),
                  const SizedBox(width: 8),
                  Text('Extraer Contenido', style: AppStyle.h3),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onDoubleTap: _pickVideo,
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  height: (MediaQuery.of(context).size.height * 0.09).clamp(68.0, 110.0),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _isDragging ? AppCSS.bgSoft : AppCSS.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isDragging ? AppCSS.success : AppCSS.primary, width: 1.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_rounded, color: _isDragging ? AppCSS.success : AppCSS.primary, size: 34),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Arrastra o selecciona un video',
                          style: AppStyle.bdS,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Btn(txt: 'Seleccionar', onTap: _pickVideo, ico: Icons.folder_open_rounded, color: AppCSS.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Btn(txt: 'Eliminar', onTap: _removeVideo, ico: Icons.delete_rounded, color: AppCSS.error),
                  ),
                ],
              ),
              if (hasVideo) ...[
                const SizedBox(height: 12),
                _statGrid(),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppCSS.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppCSS.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_rounded, size: 16, color: AppCSS.info),
                          const SizedBox(width: 6),
                          Text('Vista Previa', style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('Original: ${_formatBytes(_videoSize)}', style: AppStyle.sm)),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppCSS.primary),
                          Expanded(child: Text('Estimado: ${_formatBytes(estimated)}', style: AppStyle.sm.copyWith(color: AppCSS.success))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${reduction >= 0 ? '-' : '+'}${reduction.abs().toStringAsFixed(1)}%',
                        style: AppStyle.bdS.copyWith(
                          color: reduction >= 0 ? AppCSS.success : AppCSS.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppCSS.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppCSS.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present_rounded, size: 18, color: AppCSS.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.basename(_videoPath!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statGrid() {
    String ext = '--';
    if (_videoPath != null) {
      ext = p.extension(_videoPath!).replaceFirst('.', '').toUpperCase();
    }
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard('Duración', _formatDuration(_videoDuration), Icons.schedule_rounded),
        _statCard('Resolución', '--', Icons.desktop_windows_rounded),
        _statCard('Tamaño', _formatBytes(_videoSize), Icons.sd_storage_rounded),
        _statCard('Formato', ext, Icons.video_file_rounded),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppCSS.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppCSS.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppCSS.info),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppStyle.sm),
                Text(value, style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightPanel() {
    final hasVideo = _videoPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasVideo)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppCSS.glass500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calidad MP3', style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _quality,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: AppCSS.inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppCSS.border),
                              ),
                            ),
                            items: _qualities
                                .map((q) => DropdownMenuItem(value: q, child: Text('$q kbps', style: AppStyle.bdS)))
                                .toList(),
                            onChanged: _isExtracting ? null : (q) => setState(() => _quality = q ?? '128'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Salida', style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppCSS.inputBg,
                                    border: Border.all(color: AppCSS.border),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _outputDirectory,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyle.sm,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _pickOutputFolder,
                                tooltip: 'Cambiar carpeta',
                                icon: const Icon(Icons.folder_open_rounded, color: AppCSS.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Btn(
                  txt: _isExtracting ? 'Extrayendo...' : 'Extraer Audio (MP3)',
                  onTap: _isExtracting ? () {} : _extractAudio,
                  ico: _isExtracting ? Icons.hourglass_top_rounded : Icons.download_rounded,
                  color: AppCSS.success,
                  load: _isExtracting,
                ),
                const SizedBox(height: 10),
                if (_isExtracting || _progress > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      wiProgress(_progress, AppCSS.success, h: 9),
                      const SizedBox(height: 6),
                      Text('${(_progress * 100).toInt()}%  •  $_statusText', style: AppStyle.bdS.copyWith(color: AppCSS.success)),
                    ],
                  ),
                if (_outputPath != null && _outputSize != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppCSS.bgSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppCSS.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audio_file_rounded, color: AppCSS.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${p.basename(_outputPath!)} (${_formatBytes(_outputSize!)})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.bdS.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Abrir en carpeta',
                          onPressed: () => Process.run('explorer', ['/select,', _outputPath!]),
                          icon: const Icon(Icons.visibility_rounded, color: AppCSS.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        if (_isExtracting) return;
        final files = details.files;
        if (files.isEmpty) return;
        await _loadVideo(files.first.path);
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                wiStat('MP4', 'Entrada', Icons.video_file_rounded, AppCSS.info),
                const SizedBox(width: 10),
                wiStat('MP3', 'Salida', Icons.audio_file_rounded, AppCSS.success),
                const SizedBox(width: 10),
                wiStat(_videoPath == null ? '0' : '1', 'Cola', Icons.queue_music_rounded, AppCSS.warning),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (_, c) {
                final mobile = c.maxWidth < 900;
                if (mobile) {
                  return Column(
                    children: [
                      wiCard(child: _leftPanel()),
                      const SizedBox(height: 10),
                      wiCard(child: _rightPanel()),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: wiCard(child: _leftPanel())),
                    const SizedBox(width: 10),
                    Expanded(child: wiCard(child: _rightPanel())),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
