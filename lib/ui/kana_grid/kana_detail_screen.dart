import 'package:flutter/material.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/theme/ippo_tokens.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:ippo/ui/kana_grid/kana_detail_view_model.dart';
import 'package:provider/provider.dart';

class KanaDetailScreen extends StatelessWidget {
  const KanaDetailScreen({super.key});

  Future<void> _editMnemonic(BuildContext context) async {
    final viewModel = context.read<KanaDetailViewModel>();
    final current = viewModel.uiState.mnemonic!;
    await showDialog<void>(
      context: context,
      builder: (_) => _MnemonicDialog(
        initialText: current.text,
        onSave: viewModel.saveMnemonic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KanaDetailViewModel>();
    final state = viewModel.uiState;
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final kana = state.item!.kana;
    final mnemonic = state.mnemonic!;

    return Scaffold(
      appBar: AppBar(title: Text(kana.romaji)),
      body: ListView(
        padding: Gaps.pagePadding(context),
        children: [
          IppoCard(
            child: Column(
              children: [
                KanaText(kana.character, size: 180),
                Text(
                  kana.romaji,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                Gaps.small,
                _StatusLabel(status: state.status),
                Gaps.small,
                AudioButton(onPressed: viewModel.playSound),
              ],
            ),
          ),
          Gaps.large,
          Text(
            mnemonic.isEdited ? 'Your mnemonic' : 'Mnemonic',
            style: theme.textTheme.titleMedium,
          ),
          Gaps.small,
          MnemonicNote(mnemonic.text),
          Gaps.small,
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              if (mnemonic.isEdited)
                TextButton(
                  onPressed: viewModel.restoreDefaultMnemonic,
                  child: const Text('Restore default'),
                ),
              TextButton.icon(
                onPressed: () => _editMnemonic(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Write my own'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The kana's learning status, in the same colours as its grid tile.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final KanaStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground, text) = switch (status) {
      KanaStatus.notStarted => (
          tokens.tileNotStarted,
          tokens.onTileNotStarted,
          'Not started',
        ),
      KanaStatus.learning => (
          tokens.tileLearning,
          tokens.onTileLearning,
          'Learning',
        ),
      KanaStatus.known => (tokens.tileKnown, tokens.onTileKnown, 'Known'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.smallRadius),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _MnemonicDialog extends StatefulWidget {
  const _MnemonicDialog({required this.initialText, required this.onSave});

  final String initialText;

  /// Returns false if the text was rejected.
  final Future<bool> Function(String text) onSave;

  @override
  State<_MnemonicDialog> createState() => _MnemonicDialogState();
}

class _MnemonicDialogState extends State<_MnemonicDialog> {
  late final _controller = TextEditingController(text: widget.initialText);
  bool _isInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await widget.onSave(_controller.text);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isInvalid = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your mnemonic'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 4,
        minLines: 2,
        decoration: InputDecoration(
          hintText: 'What does this kana look or sound like to you?',
          errorText: _isInvalid ? 'Write something first.' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
