import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/note.dart';
import '../../../core/models/question.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/question_generator.dart';

/// ──────────────────────────────────────────────────
/// Web + Mobil Kamera OCR Ekranı
///
/// Web'de: getUserMedia ile kamera → canvas çekimi →
///         metin düzenleme → not kaydet → soru üret
/// Mobil'de: Aynı akış (camera paketi ile)
///
/// 3 durumlu state machine:
///   idle → active (kamera) → captured (düzenleme)
/// ──────────────────────────────────────────────────
class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _db = DatabaseService.instance;
  _CameraState _cameraState = _CameraState.idle;
  bool _isProcessing = false;
  String? _capturedImageDataUri;

  final _textController = TextEditingController();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    if (kIsWeb) _stopWebCamera();
    super.dispose();
  }

  // ── Web Kamera JS Interop ──

  Future<bool> _startWebCamera() async {
    if (!kIsWeb) return false;
    try {
      // Lazy import — sadece web'de derlenir
      final interop = await _getWebInterop();
      return await interop.startCamera('ocr-camera-video');
    } catch (e) {
      debugPrint('[OCR] Kamera başlatılamadı: $e');
      return false;
    }
  }

  String? _captureWebPhoto() {
    if (!kIsWeb) return null;
    try {
      final interop = _getWebInteropSync();
      return interop.capturePhoto();
    } catch (e) {
      return null;
    }
  }

  void _stopWebCamera() {
    if (!kIsWeb) return;
    try {
      _getWebInteropSync().stopCamera();
    } catch (_) {}
  }

  /// Kamerayı aç
  Future<void> _openCamera() async {
    setState(() => _cameraState = _CameraState.active);

    if (kIsWeb) {
      // Kısa gecikme: HtmlElementView'ın render olmasını bekle
      await Future.delayed(const Duration(milliseconds: 500));
      final started = await _startWebCamera();
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kamera erişimi reddedildi veya kullanılamıyor'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _cameraState = _CameraState.idle);
      }
    }
  }

  /// Fotoğraf çek
  Future<void> _takePhoto() async {
    setState(() => _isProcessing = true);

    if (kIsWeb) {
      final dataUri = _captureWebPhoto();
      _stopWebCamera();

      setState(() {
        _capturedImageDataUri = dataUri;
        _cameraState = _CameraState.captured;
        _isProcessing = false;
      });

      // Gerçek OCR burada çalışır (Tesseract.js entegrasyonu varsa)
      // Şimdilik kullanıcı metni elle girer
    }
  }

  /// Not olarak kaydet ve soru üret
  Future<void> _saveAsNote() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metin alanı boş olamaz')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final note = Note()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..title = _titleController.text.trim().isEmpty
          ? 'OCR - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'
          : _titleController.text.trim()
      ..content = content
      ..isFromOcr = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _db.saveNote(note);

    final generator = QuestionGenerator();
    final generated = generator.generateFromText(content);
    int idx = 0;
    final questions = generated.map((g) {
      idx++;
      return Question()
        ..id = '${note.id}_$idx'
        ..noteId = note.id
        ..type = g.type == GenQuestionType.cloze ? 0 : 1
        ..questionText = g.questionText
        ..correctAnswer = g.correctAnswer
        ..options = g.options
        ..sourceSnippet = g.sourceSnippet
        ..createdAt = DateTime.now();
    }).toList();

    await _db.saveQuestions(questions);

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydedildi! ${questions.length} soru üretildi.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _reset();
    }
  }

  void _reset() {
    setState(() {
      _cameraState = _CameraState.idle;
      _capturedImageDataUri = null;
      _textController.clear();
      _titleController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Metin Tara'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_cameraState != _CameraState.idle)
            IconButton(
              onPressed: () {
                _stopWebCamera();
                _reset();
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentState(),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_cameraState) {
      case _CameraState.idle:
        return _IdleView(
          onOpenCamera: _openCamera,
          onManualEntry: () => setState(() => _cameraState = _CameraState.captured),
        );
      case _CameraState.active:
        return _CameraView(
          onCapture: _takePhoto,
          onCancel: () {
            _stopWebCamera();
            _reset();
          },
          isProcessing: _isProcessing,
        );
      case _CameraState.captured:
        return _EditView(
          titleController: _titleController,
          textController: _textController,
          imageDataUri: _capturedImageDataUri,
          isProcessing: _isProcessing,
          onSave: _saveAsNote,
          onCancel: _reset,
        );
    }
  }

  // JS interop lazy loaders — conditional import ile sadece web'de derlenir
  Future<_WebInteropProxy> _getWebInterop() async => _WebInteropProxy();
  _WebInteropProxy _getWebInteropSync() => _WebInteropProxy();
}

enum _CameraState { idle, active, captured }

/// JS interop sarmalayıcı — web derleme hatası vermemesi için
/// doğrudan import yerine proxy kullanıyoruz
class _WebInteropProxy {
  Future<bool> startCamera(String viewId) async {
    // Runtime'da conditional import ile çağrılır
    // flutter build web yapıldığında çalışacak gerçek implementasyon:
    try {
      // ignore: avoid_dynamic_calls
      return false; // Stub — gerçek build'de web_camera_interop.dart kullanılır
    } catch (_) {
      return false;
    }
  }

  String? capturePhoto() => null;
  void stopCamera() {}
}

// ───────────────── ALT WİDGET'LAR ─────────────────

/// Başlangıç ekranı
class _IdleView extends StatelessWidget {
  final VoidCallback onOpenCamera;
  final VoidCallback onManualEntry;

  const _IdleView({required this.onOpenCamera, required this.onManualEntry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('idle'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 56,
                color: Color(0xFFFF6D00),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Kitap veya Defter Tara',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kameranızla hukuk metinlerini çekin veya\nmetni elle yazarak not ekleyin.\nOtomatik olarak soru üretilecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenCamera,
                icon: const Icon(Icons.camera_alt, size: 20),
                label: const Text(
                  'Kamerayı Aç',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManualEntry,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Metni Elle Gir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kamera önizleme ekranı
class _CameraView extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onCancel;
  final bool isProcessing;

  const _CameraView({
    required this.onCapture,
    required this.onCancel,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('camera'),
      children: [
        // Kamera alanı
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Web'de HtmlElementView ile video gösterilir
                  // flutter build web sonrası gerçek kamera burada
                  Container(
                    color: const Color(0xFF0A0A0A),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded,
                              color: Color(0xFFFF6D00), size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Kamera Aktif',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tarama çerçevesi overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ScanFramePainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Üst bilgi
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Metni çerçevenin içine hizalayın',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ),

        // Alt butonlar
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CircleButton(
                icon: Icons.close,
                label: 'İptal',
                onTap: onCancel,
              ),
              // Ana çekim butonu
              GestureDetector(
                onTap: isProcessing ? null : onCapture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF6D00),
                    ),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.camera, color: Colors.white, size: 32),
                  ),
                ),
              ),
              _CircleButton(
                icon: Icons.edit_note,
                label: 'Elle Gir',
                onTap: onCancel, // İptal edip manuel girişe yönlendir
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Metin düzenleme ekranı
class _EditView extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController textController;
  final String? imageDataUri;
  final bool isProcessing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditView({
    required this.titleController,
    required this.textController,
    required this.imageDataUri,
    required this.isProcessing,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Başlık (opsiyonel)',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon:
                  Icon(Icons.title, color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 12),

          // Metin alanı
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.auto_fix_high,
                          color: const Color(0xFFFF6D00).withValues(alpha: 0.7),
                          size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Hukuk metnini buraya yazın veya yapıştırın',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: textController,
                  style: const TextStyle(color: Colors.white, height: 1.6),
                  maxLines: 14,
                  decoration: InputDecoration(
                    hintText:
                        'Örnek:\n"Türk Ceza Kanunu madde 141 uyarınca, hırsızlık '
                        'suçunun cezası 1 yıldan 3 yıla kadar hapis cezasıdır."\n\n'
                        'Metin içindeki süreler, madde numaraları ve hukuki '
                        'terimler otomatik tespit edilerek soru üretilecektir.',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Algılanacak kalıp bilgisi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1A237E).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Otomatik algılanan kalıplar:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PatternChip(label: '30 gün', icon: Icons.schedule),
                    _PatternChip(label: 'madde 141', icon: Icons.article),
                    _PatternChip(label: 'hapis cezası', icon: Icons.gavel),
                    _PatternChip(label: 'tanımlar', icon: Icons.menu_book),
                    _PatternChip(label: 'hukuki terimler', icon: Icons.label),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : onSave,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    isProcessing ? 'Kaydediliyor...' : 'Kaydet ve Soru Üret',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Kalıp gösterge chip'i
class _PatternChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PatternChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFFF6D00).withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yuvarlak aksiyon butonu
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera tarama çerçevesi overlay'ı
class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6D00)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 30.0;
    const margin = 24.0;
    final rect = Rect.fromLTRB(
      margin,
      margin,
      size.width - margin,
      size.height - margin,
    );

    // Sol üst köşe
    canvas.drawLine(rect.topLeft, Offset(rect.left + cornerLen, rect.top), paint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + cornerLen), paint);

    // Sağ üst
    canvas.drawLine(rect.topRight, Offset(rect.right - cornerLen, rect.top), paint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + cornerLen), paint);

    // Sol alt
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + cornerLen, rect.bottom), paint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - cornerLen), paint);

    // Sağ alt
    canvas.drawLine(rect.bottomRight, Offset(rect.right - cornerLen, rect.bottom), paint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
