import 'package:flutter/material.dart';
import 'package:tokingo/core/ui/app_theme.dart';
import 'package:tokingo/core/ui/widgets.dart';
import 'package:tokingo/features/room/presentation/create/create_room_controller.dart';
import 'package:tokingo/features/room/presentation/create/create_room_page.dart';
import 'package:tokingo/features/room/presentation/create/create_widgets.dart';

/// 03 – quem pode entrar?
class AccessStep extends StatelessWidget {
  const AccessStep({
    required this.c,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final CreateRoomController c;
  final VoidCallback onBack;
  final VoidCallback onNext;

  static const Map<AccessMode, (String, String)> _defs = {
    AccessMode.domain: ('Domínio', 'Só e-mails dos domínios que você listar.'),
    AccessMode.sameAsHost: (
      'Mesmo que o meu',
      'Só quem tem o mesmo domínio do seu e-mail.',
    ),
    AccessMode.allowlist: (
      'Lista de e-mails',
      'Só convidados específicos (até 60).',
    ),
    AccessMode.public: ('Pública', 'Qualquer conta Google verificada.'),
  };

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SplitTitle('quem pode', 'entrar?'),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: FieldLabel(
            label: 'Nome do evento',
            child: DraftField(
              initial: c.eventName,
              semanticsLabel: 'Nome do evento',
              style: AppText.body(16, color: AppColors.graphite),
              onChanged: (v) => c.eventName = v,
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, box) {
            final perRow = box.maxWidth < 560
                ? 1
                : (box.maxWidth < 900 ? 2 : 4);
            final w = (box.maxWidth - 16 * (perRow - 1)) / perRow;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final m in AccessMode.values)
                  SizedBox(
                    width: w,
                    child: _ModeCard(
                      title: _defs[m]!.$1,
                      desc: _defs[m]!.$2,
                      selected: c.mode == m,
                      onTap: () => c.update(() => c.mode = m),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _ModeConfig(c: c),
        ),
        const SizedBox(height: 32),
        WizardFooter(
          note: 'A regra de acesso fica travada quando o jogo começa.',
          buttons: [
            AppButton(
              label: 'Cancelar',
              onPressed: onBack,
              kind: AppButtonKind.outline,
            ),
            AppButton(label: 'Próximo: cartela', onPressed: onNext),
          ],
        ),
      ],
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.blueSoft : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppColors.navy : AppColors.light,
          width: selected ? 3 : 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(20),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.display(18, color: AppColors.navy)),
              const SizedBox(height: 8),
              Text(desc, style: AppText.body(14, height: 1.4)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModeConfig extends StatelessWidget {
  const _ModeConfig({required this.c});

  final CreateRoomController c;

  @override
  Widget build(BuildContext context) {
    final (label, help) = switch (c.mode) {
      AccessMode.domain => ('Domínios aceitos', 'Separe vários com vírgula.'),
      AccessMode.sameAsHost => (
        'Domínio detectado',
        'Vem da sua conta, não dá para editar.',
      ),
      AccessMode.allowlist => (
        'E-mails convidados',
        'Cole uma lista. ${c.emails.length} de 60 usados.',
      ),
      AccessMode.public => (
        'Atenção',
        'Qualquer pessoa com o código pode entrar. Uma pessoa com várias contas pode ter várias cartelas.',
      ),
    };
    final input = switch (c.mode) {
      AccessMode.domain => DraftField(
        key: const ValueKey('domains'),
        initial: c.domainsText,
        hint: 'suaempresa.com.br',
        semanticsLabel: label,
        style: AppText.body(16, color: AppColors.graphite),
        onChanged: (v) => c.update(() => c.domainsText = v),
      ),
      AccessMode.sameAsHost => DraftField(
        key: ValueKey('host-${c.hostDomain}'),
        initial: c.hostDomain,
        enabled: false,
        semanticsLabel: label,
        style: AppText.body(16, color: AppColors.graphite),
        onChanged: (_) {},
      ),
      AccessMode.allowlist => DraftField(
        key: const ValueKey('emails'),
        initial: c.emailsText,
        hint: 'ana@..., joao@..., marina@...',
        semanticsLabel: label,
        style: AppText.body(16, color: AppColors.graphite),
        onChanged: (v) => c.update(() => c.emailsText = v),
      ),
      AccessMode.public => null,
    };
    return SectionCard(
      color: AppColors.surfaceSoft,
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppText.body(13, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (input != null) ...[input, const SizedBox(height: 10)],
          Text(help, style: AppText.body(13)),
        ],
      ),
    );
  }
}
