import 'package:flutter/material.dart';

import '../models/vocab.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';

enum _ExamStage { setup, answering, result }

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final Set<String> _selectedDeckIds = {};
  final TextEditingController _answerController = TextEditingController();
  int _percentage = 50;
  int _questionIndex = 0;
  int _correctAnswers = 0;
  List<Word> _questions = [];
  _ExamStage _stage = _ExamStage.setup;
  bool _answered = false;
  bool _answerWasCorrect = false;
  bool _savingResult = false;
  String? _answerError;
  String? _resultError;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  int _wordCountFor(Deck deck) => deck.words.length * _percentage ~/ 100;

  void _startExam(AppState state) {
    final selectedDecks =
        state.decks.where((deck) => _selectedDeckIds.contains(deck.id));
    final questions = <Word>[];
    for (final deck in selectedDecks) {
      final words = List<Word>.of(deck.words)..shuffle();
      questions.addAll(words.take(_wordCountFor(deck)));
    }
    questions.shuffle();
    if (questions.isEmpty) return;

    setState(() {
      _questions = questions;
      _questionIndex = 0;
      _correctAnswers = 0;
      _answered = false;
      _answerWasCorrect = false;
      _answerError = null;
      _resultError = null;
      _answerController.clear();
      _stage = _ExamStage.answering;
    });
  }

  void _submitAnswer() {
    if (_answered) return;
    final answer =
        _answerController.text.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (answer.isEmpty) {
      setState(() => _answerError = 'Nhập câu trả lời trước khi kiểm tra.');
      return;
    }

    final acceptedMeanings = _questions[_questionIndex]
        .meaning
        .split(',')
        .map((meaning) => meaning.replaceAll(RegExp(r'\s+'), '').toLowerCase())
        .where((meaning) => meaning.isNotEmpty);
    final isCorrect = acceptedMeanings.contains(answer);
    setState(() {
      _answered = true;
      _answerWasCorrect = isCorrect;
      _answerError = null;
      if (isCorrect) _correctAnswers++;
    });
  }

  Future<void> _advance(AppState state) async {
    if (_questionIndex + 1 < _questions.length) {
      setState(() {
        _questionIndex++;
        _answered = false;
        _answerWasCorrect = false;
        _answerError = null;
        _answerController.clear();
      });
      return;
    }

    setState(() {
      _savingResult = true;
      _resultError = null;
    });
    try {
      await state.recordExamResult(
        wordCount: _questions.length,
        correctCount: _correctAnswers,
      );
      if (!mounted) return;
      setState(() {
        _stage = _ExamStage.result;
        _savingResult = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _savingResult = false;
        _resultError = 'Không thể lưu kết quả bài kiểm tra: $error';
      });
    }
  }

  void _returnToSetup() {
    setState(() {
      _stage = _ExamStage.setup;
      _questions = [];
      _answerController.clear();
      _answerError = null;
      _resultError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final palette = Palette.ofContext(context);
    final accent = palette.accent(state.lang);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: switch (_stage) {
            _ExamStage.setup => _buildSetup(state, palette, accent),
            _ExamStage.answering => _buildQuestion(state, palette, accent),
            _ExamStage.result => _buildResult(palette, accent),
          },
        ),
      ),
    );
  }

  Widget _buildSetup(AppState state, Palette palette, Color accent) {
    final selectedDecks = state.decks
        .where((deck) => _selectedDeckIds.contains(deck.id))
        .toList(growable: false);
    final questionCount = selectedDecks.fold<int>(
        0, (total, deck) => total + _wordCountFor(deck));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text(
          'Bài kiểm tra',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn bộ thẻ và tỷ lệ từ muốn kiểm tra.',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Số từ mỗi bộ thẻ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$_percentage%',
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _percentage.toDouble(),
                min: 10,
                max: 100,
                divisions: 90,
                label: '$_percentage%',
                onChanged: (value) =>
                    setState(() => _percentage = value.round()),
              ),
              Text(
                'Số từ được làm tròn xuống riêng cho từng bộ thẻ.',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chọn bộ thẻ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${_selectedDeckIds.length} đã chọn',
              style: TextStyle(color: palette.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final deck in state.decks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: EdgeInsets.zero,
              child: CheckboxListTile(
                value: _selectedDeckIds.contains(deck.id),
                activeColor: palette.accent(deck.lang),
                title: Text(deck.title),
                subtitle: Text(
                  '${deck.lang.label} · ${_wordCountFor(deck)} / ${deck.words.length} từ',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedDeckIds.add(deck.id);
                    } else {
                      _selectedDeckIds.remove(deck.id);
                    }
                  });
                },
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: questionCount == 0 ? null : () => _startExam(state),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              questionCount == 0
                  ? 'Chọn bộ thẻ có từ để bắt đầu'
                  : 'Bắt đầu kiểm tra · $questionCount từ',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(AppState state, Palette palette, Color accent) {
    final word = _questions[_questionIndex];
    final total = _questions.length;
    final progress = (_questionIndex + 1) / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Thoát bài kiểm tra',
              onPressed: _returnToSetup,
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                'Câu ${_questionIndex + 1} / $total',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, color: accent),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            children: [
              Text(
                word.term,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập chính xác nghĩa của từ',
                style: TextStyle(color: palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _answerController,
          autofocus: true,
          enabled: !_answered,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitAnswer(),
          decoration: InputDecoration(
            labelText: 'Nghĩa của từ',
            errorText: _answerError,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_answered)
          Panel(
            color: _answerWasCorrect
                ? Colors.green.withAlpha(20)
                : Colors.red.withAlpha(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _answerWasCorrect ? 'Chính xác!' : 'Chưa chính xác',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _answerWasCorrect
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                if (!_answerWasCorrect) ...[
                  const SizedBox(height: 6),
                  Text('Đáp án đúng: ${word.meaning}'),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _answered
                ? (_savingResult ? null : () => _advance(state))
                : _submitAnswer,
            child: Text(
              _answered
                  ? (_questionIndex + 1 == total ? 'Xem kết quả' : 'Tiếp theo')
                  : 'Kiểm tra đáp án',
            ),
          ),
        ),
        if (_resultError != null) ...[
          const SizedBox(height: 12),
          Text(
            _resultError!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildResult(Palette palette, Color accent) {
    final total = _questions.length;
    final incorrect = total - _correctAnswers;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 64, color: accent),
        const SizedBox(height: 16),
        const Text(
          'Hoàn thành bài kiểm tra',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            children: [
              _ResultRow(label: 'Tổng số từ', value: '$total'),
              const SizedBox(height: 12),
              _ResultRow(label: 'Trả lời đúng', value: '$_correctAnswers'),
              const SizedBox(height: 12),
              _ResultRow(label: 'Trả lời sai', value: '$incorrect'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _returnToSetup,
          child: const Text('Tạo bài kiểm tra khác'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Quay lại', style: TextStyle(color: palette.muted)),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
