import 'package:flutter/material.dart';
import '../../../core/models/note.dart';
import '../../../core/models/question.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/question_generator.dart';

/// ──────────────────────────────────
/// Notlar Ekranı
///
/// Kullanıcı metin yapıştırarak veya
/// yazarak not ekler. Not eklendikten
/// sonra otomatik soru üretilir.
/// ──────────────────────────────────
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _db = DatabaseService.instance;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = _db.getAllNotes();
    });
  }

  void _showAddNoteSheet() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tutamak
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Yeni Not Ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Başlık (ör: TCK Madde 141)',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Hukuk metnini buraya yapıştırın veya yazın...\n\n'
                      'Metin içindeki süreler, madde numaraları ve '
                      'hukuki terimler otomatik tespit edilerek soru üretilecektir.',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _saveNote(
                  ctx,
                  titleController.text.trim(),
                  contentController.text.trim(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kaydet ve Soru Üret',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote(BuildContext ctx, String title, String content) async {
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metin alanı boş olamaz')),
      );
      return;
    }

    final note = Note()
      ..id = DateTime.now().millisecondsSinceEpoch.toString()
      ..title = title.isEmpty ? 'Adsız Not' : title
      ..content = content
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _db.saveNote(note);

    // Otomatik soru üret
    final generator = QuestionGenerator();
    final generated = generator.generateFromText(content);
    final questions = generated.map((g) {
      return Question()
        ..id = '${note.id}_${DateTime.now().microsecondsSinceEpoch}'
        ..noteId = note.id
        ..type = g.type == GenQuestionType.cloze ? 0 : 1
        ..questionText = g.questionText
        ..correctAnswer = g.correctAnswer
        ..options = g.options
        ..sourceSnippet = g.sourceSnippet
        ..createdAt = DateTime.now();
    }).toList();

    await _db.saveQuestions(questions);

    if (ctx.mounted) Navigator.pop(ctx);
    _loadNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${questions.length} soru otomatik üretildi!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _deleteNote(String id) async {
    await _db.deleteNote(id);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Notlarım'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteSheet,
        backgroundColor: const Color(0xFFFF6D00),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add_outlined,
                      size: 64, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz not eklenmedi',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+ butonuyla hukuk metni ekleyin',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final questionCount =
                    _db.getQuestionsForNote(note.id).length;

                return Dismissible(
                  key: Key(note.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade800,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) => _deleteNote(note.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        note.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          note.content.length > 80
                              ? '${note.content.substring(0, 80)}...'
                              : note.content,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6D00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$questionCount soru',
                          style: const TextStyle(
                            color: Color(0xFFFF6D00),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
