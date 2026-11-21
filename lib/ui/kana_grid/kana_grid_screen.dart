import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ippo/domain/models/item.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/routing/routes.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
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
              padding: Gaps.pagePadding(context),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Gaps.medium,
                for (final section in state.sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Semantics(
                      header: true,
                      child: Text(
                        switch (section.group) {
                          KanaGroup.basic => 'Basic',
                          KanaGroup.voiced => 'Voiced',
                          KanaGroup.combination => 'Combination',
                          KanaGroup.mark => 'Marks',
                        },
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  for (final row in section.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (var i = 0; i < row.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: row[i] == null
                                  ? const SizedBox.shrink()
                                  : _StatusTile(cell: row[i]!),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.cell});

  final KanaCell cell;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground) = switch (cell.status) {
      KanaStatus.notStarted => (
          tokens.tileNotStarted,
          tokens.onTileNotStarted,
        ),
      KanaStatus.learning => (tokens.tileLearning, tokens.onTileLearning),
      KanaStatus.known => (tokens.tileKnown, tokens.onTileKnown),
    };
    final kana = cell.item.kana;
    return KanaTile(
      character: kana.character,
      caption: kana.romaji,
      background: background,
      foreground: foreground,
      semanticLabel: '${kana.romaji}, ${switch (cell.status) {
        KanaStatus.notStarted => 'not started',
        KanaStatus.learning => 'learning',
        KanaStatus.known => 'known',
      }}',
      onTap: () => context.push(Routes.kanaDetail(cell.item.id)),
    );
  }
}
