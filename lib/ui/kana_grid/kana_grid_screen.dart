import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/routing/routes.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:ippo/ui/kana_grid/kana_grid_ui_state.dart';
import 'package:ippo/ui/kana_grid/kana_grid_view_model.dart';
import 'package:provider/provider.dart';

class KanaGridScreen extends StatelessWidget {
  const KanaGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KanaGridViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: AppBar(title: const Text('Kana')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Gaps.page),
              children: [
                SegmentedButton<KanaScript>(
                  segments: const [
                    ButtonSegment(
                      value: KanaScript.hiragana,
                      label: Text('Hiragana'),
                    ),
                    ButtonSegment(
                      value: KanaScript.katakana,
                      label: Text('Katakana'),
                    ),
                  ],
                  selected: {state.script},
                  onSelectionChanged: (selection) =>
                      viewModel.selectScript(selection.first),
                ),
                Gaps.medium,
                Text(
                  '${state.knownCount} known, ${state.learningCount} learning, '
                  '${state.totalCount - state.knownCount - state.learningCount}'
                  ' not started',
                  textAlign: TextAlign.center,
                ),
                Gaps.medium,
                for (final row in state.rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        for (var i = 0; i < row.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: row[i] == null
                                ? const SizedBox.shrink()
                                : _KanaTile(cell: row[i]!),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _KanaTile extends StatelessWidget {
  const _KanaTile({required this.cell});

  final KanaCell cell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (cell.status) {
      KanaStatus.notStarted => (scheme.surfaceContainerHighest, scheme.outline),
      KanaStatus.learning => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      KanaStatus.known => (scheme.primary, scheme.onPrimary),
    };
    final kana = cell.item.kana;
    return Semantics(
      label: '${kana.romaji}, ${switch (cell.status) {
        KanaStatus.notStarted => 'not started',
        KanaStatus.learning => 'learning',
        KanaStatus.known => 'known',
      }}',
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.kanaDetail(cell.item.id)),
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kana.character,
                  locale: const Locale('ja'),
                  style: TextStyle(fontSize: 28, color: foreground),
                ),
                Text(
                  kana.romaji,
                  style: TextStyle(fontSize: 12, color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
