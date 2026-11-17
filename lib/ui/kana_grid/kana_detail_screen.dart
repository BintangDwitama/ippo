import 'package:flutter/material.dart';
import 'package:ippo/domain/models/kana_status.dart';
import 'package:ippo/ui/core/app_theme.dart';
import 'package:ippo/ui/core/widgets.dart';
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
        padding: const EdgeInsets.all(Gaps.page),
        children: [
          KanaText(kana.character, size: 180),
          Text(
            kana.romaji,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          Gaps.small,
          Center(
            child: Chip(
              label: Text(
                switch (state.status) {
                  KanaStatus.notStarted => 'Not started',
                  KanaStatus.learning => 'Learning',
                  KanaStatus.known => 'Known',
                },
              ),
            ),
          ),
          Gaps.small,
          Center(child: AudioButton(onPressed: viewModel.playSound)),
          Gaps.large,
          Text(
            mnemonic.isEdited ? 'Your mnemonic' : 'Mnemonic',
            style: theme.textTheme.titleMedium,
          ),
          Gaps.small,
          MnemonicNote(mnemonic.text),
          Gaps.small,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
          border: const OutlineInputBorder(),
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
