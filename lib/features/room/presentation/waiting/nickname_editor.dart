import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tokingo/core/di/injection.dart';
import 'package:tokingo/core/types/ids.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/game/domain/repositories/game_repository.dart';
import 'package:tokingo/features/game/domain/services/nickname.dart';
import 'package:tokingo/features/room/presentation/room_common.dart';

/// "Seu apelido" field shown before the game starts (players and host).
/// The nickname is what everyone sees on the panel, the stream and results.
class NicknameEditor extends StatefulWidget {
  const NicknameEditor({
    required this.gameId,
    required this.uid,
    required this.current,
    super.key,
  });

  final GameId gameId;
  final UserId uid;

  /// Nickname saved now (null while the player list loads).
  final String? current;

  @override
  State<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditor> {
  late final _ctrl = TextEditingController(text: widget.current ?? '');
  bool _saving = false;
  bool _touched = false;
  String? _error;

  @override
  void didUpdateWidget(NicknameEditor old) {
    super.didUpdateWidget(old);
    // Keep in sync with the server until the user starts typing.
    final now = widget.current;
    if (!_touched && now != null && now != _ctrl.text) _ctrl.text = now;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _dirty =>
      Nickname.normalize(_ctrl.text) != (widget.current ?? '').trim();

  Future<void> _save() async {
    final error = Nickname.validate(_ctrl.text);
    setState(() => _error = error);
    if (error != null || !_dirty) return;
    setState(() => _saving = true);
    try {
      await sl<GameRepository>().setNickname(
        widget.gameId,
        widget.uid,
        _ctrl.text,
      );
      if (!mounted) return;
      _ctrl.text = Nickname.normalize(_ctrl.text);
      _touched = false;
      showFriendlyError(context, 'Apelido salvo.');
    } on Object {
      if (mounted) showFriendlyError(context, 'Não deu para salvar o apelido.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Seu apelido', style: AppText.body(14, weight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              enabled: !_saving,
              maxLength: Nickname.maxLength,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[\p{L}\p{N} ._-]', unicode: true),
                ),
              ],
              onChanged: (_) => setState(() {
                _touched = true;
                _error = null;
              }),
              onSubmitted: (_) => _save(),
              style: AppText.body(16, color: AppColors.graphite),
              decoration: InputDecoration(
                hintText: 'Como quer ser chamado',
                errorText: _error,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AppButton(
            label: _saving ? 'Salvando…' : 'Salvar',
            kind: AppButtonKind.outline,
            onPressed: _saving || !_dirty ? null : _save,
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Até ${Nickname.maxLength} caracteres: letras, números, espaço, '
        'ponto, hífen ou _. Dá para trocar até a partida começar.',
        style: AppText.body(12, color: AppColors.graphite),
      ),
    ],
  );
}
