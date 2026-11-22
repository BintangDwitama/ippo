import 'package:flutter/material.dart';
import 'package:ippo/ui/backup/backup_ui_state.dart';
import 'package:ippo/ui/backup/backup_view_model.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:provider/provider.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BackupViewModel>();
    final state = viewModel.uiState;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup and restore')),
      body: SafeArea(
        child: switch (state) {
          BackupLoading() => const Center(child: CircularProgressIndicator()),
          BackupWorking() => _Working(work: state.work),
          BackupIdle() => _Idle(state: state, viewModel: viewModel),
          BackupConfirming() => _Confirming(state: state, viewModel: viewModel),
        },
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.work});

  final BackupWork work;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          Gaps.medium,
          Text(switch (work) {
            BackupWork.exporting => 'Preparing your backup',
            BackupWork.reading => 'Reading the file',
            BackupWork.restoring => 'Restoring your data',
          }, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.state, required this.viewModel});

  final BackupIdle state;
  final BackupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final notice = state.notice;
    final lastExportAt = state.lastExportAt;

    final actions = ListView(
      padding: const EdgeInsets.all(Gaps.page),
      children: [
        IppoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Export', style: theme.textTheme.titleLarge),
              Gaps.small,
              Text(
                'Save all your progress as one file: the kana you have '
                'learned, your reviews, your goals and your own mnemonics. '
                'Keep it somewhere other than this phone.',
                style: theme.textTheme.bodyLarge,
              ),
              Gaps.small,
              Text(
                lastExportAt == null
                    ? 'No export made yet.'
                    : 'Last export: ${formatDateTime(lastExportAt)}',
                style: muted,
              ),
              Gaps.medium,
              PrimaryButton(
                label: 'Export backup',
                onPressed: viewModel.export,
              ),
            ],
          ),
        ),
        Gaps.medium,
        IppoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Import', style: theme.textTheme.titleLarge),
              Gaps.small,
              Text(
                'Bring back a backup file. It replaces everything on this '
                'phone; you will see what the file holds before anything '
                'changes.',
                style: theme.textTheme.bodyLarge,
              ),
              Gaps.medium,
              SecondaryButton(
                label: 'Import backup',
                onPressed: viewModel.pickImportFile,
              ),
            ],
          ),
        ),
        Gaps.medium,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Your phone also backs up Ippo automatically when backup is '
            'turned on in the phone\'s settings. That copy comes back when '
            'the app is installed again.',
            style: muted,
          ),
        ),
      ],
    );

    if (notice == null) return actions;
    // The notice stays above the list, so the outcome of an action is
    // seen wherever the list happens to be scrolled.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Gaps.page,
            Gaps.page,
            Gaps.page,
            0,
          ),
          child: _NoticeBanner(
            notice: notice,
            onDismiss: viewModel.dismissNotice,
          ),
        ),
        Expanded(child: actions),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.notice, required this.onDismiss});

  final BackupNotice notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final (label, detail) = switch (notice) {
      BackupNotice.exported => (
        'Backup saved',
        'Your progress is in the file you just saved.',
      ),
      BackupNotice.restored => (
        'Data restored',
        'This phone now has the data from the backup.',
      ),
      BackupNotice.exportFailed => (
        'The backup could not be saved',
        'Nothing was changed. Try another location.',
      ),
      BackupNotice.restoreFailed => (
        'The backup could not be restored',
        'Your data is as it was before.',
      ),
      BackupNotice.notABackup => (
        'Not an Ippo backup',
        'That file was not made by Ippo. Nothing was changed.',
      ),
      BackupNotice.newerVersion => (
        'This backup needs a newer version of Ippo',
        'Update the app, then import it again. Nothing was changed.',
      ),
      BackupNotice.corrupt => (
        'This backup is damaged',
        'Part of the file is missing or unreadable. Nothing was changed.',
      ),
      BackupNotice.unknownItems => (
        'This backup does not match this version of Ippo',
        'It has kana this version does not know. Update the app, then '
            'import it again. Nothing was changed.',
      ),
      BackupNotice.fileTooLarge => (
        'That file is too large to be a backup',
        'Nothing was changed.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FeedbackBanner(
          isCorrect: !notice.isError,
          label: label,
          detail: detail,
        ),
        TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
      ],
    );
  }
}

/// The file's contents next to the phone's, before anything is replaced.
class _Confirming extends StatelessWidget {
  const _Confirming({required this.state, required this.viewModel});

  final BackupConfirming state;
  final BackupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(Gaps.page),
      children: [
        Text('Replace your data?', style: theme.textTheme.headlineSmall),
        Gaps.small,
        Text(
          'The backup was exported on '
          '${formatDateTime(state.inFile.exportedAt)}.',
          style: theme.textTheme.bodyLarge,
        ),
        Gaps.medium,
        IppoCard(
          child: Column(
            children: [
              const _SummaryRow(
                label: '',
                inFile: 'In the file',
                onPhone: 'On this phone',
                isHeader: true,
              ),
              const Divider(),
              _SummaryRow(
                label: 'Kana learned',
                inFile: '${state.inFile.introducedCount}',
                onPhone: '${state.onPhone.introducedCount}',
              ),
              _SummaryRow(
                label: 'Words learned',
                inFile: '${state.inFile.wordCount}',
                onPhone: '${state.onPhone.wordCount}',
              ),
              _SummaryRow(
                label: 'Cards',
                inFile: '${state.inFile.cardCount}',
                onPhone: '${state.onPhone.cardCount}',
              ),
              _SummaryRow(
                label: 'Reviews',
                inFile: '${state.inFile.reviewCount}',
                onPhone: '${state.onPhone.reviewCount}',
              ),
            ],
          ),
        ),
        if (state.skippedWords > 0) ...[
          Gaps.medium,
          Text(
            state.skippedWords == 1
                ? '1 word in the file is not in this version of Ippo '
                    'and will be left out.'
                : '${state.skippedWords} words in the file are not in '
                    'this version of Ippo and will be left out.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
        Gaps.medium,
        Text(
          'Everything on this phone will be replaced by the file. This '
          'cannot be undone. To keep what is on this phone, cancel and '
          'export it first.',
          style: theme.textTheme.bodyLarge,
        ),
        Gaps.large,
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: viewModel.confirmImport,
          child: const Text('Replace data on this phone'),
        ),
        Gaps.small,
        SecondaryButton(label: 'Cancel', onPressed: viewModel.cancelImport),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.inFile,
    required this.onPhone,
    this.isHeader = false,
  });

  final String label;
  final String inFile;
  final String onPhone;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = isHeader
        ? theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          Expanded(
            flex: 3,
            child: Text(inFile, textAlign: TextAlign.end, style: valueStyle),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(onPhone, textAlign: TextAlign.end, style: valueStyle),
          ),
        ],
      ),
    );
  }
}
