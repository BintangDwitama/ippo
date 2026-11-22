import 'package:flutter/material.dart';
import 'package:ippo/ui/about/about_view_model.dart';
import 'package:ippo/ui/core/spacing.dart';
import 'package:ippo/ui/core/widgets/widgets.dart';
import 'package:provider/provider.dart';

/// Where the app's content comes from, and under which licences.
///
/// The dictionary's licence requires this acknowledgement in any
/// application that uses its data.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String jmdictProject =
      'https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project';
  static const String edrdgLicence =
      'https://www.edrdg.org/edrdg/licence.html';
  static const String wallerLists = 'http://www.tanos.co.uk/jlpt/';
  static const String matchedLists =
      'https://github.com/stephenmk/yomitan-jlpt-vocab';
  static const String wordData =
      'https://github.com/BintangDwitama/ippo/tree/main/data/words';
  static const String shareAlike =
      'https://creativecommons.org/licenses/by-sa/4.0/';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AboutViewModel>().uiState;
    final theme = Theme.of(context);
    final date = state.dictionaryDate;

    return Scaffold(
      appBar: AppBar(title: const Text('About and sources')),
      body: ListView(
        padding: Gaps.pagePadding(context),
        children: [
          Text('Ippo', style: theme.textTheme.headlineSmall),
          Gaps.small,
          Text(
            'An app for learning Japanese from zero, one step at a time. '
            'Everything stays on this phone.',
            style: theme.textTheme.bodyLarge,
          ),
          Gaps.medium,
          _Source(
            title: 'Dictionary',
            children: [
              const _Paragraph(
                'The words in this app, with their readings, written forms '
                'and meanings, come from the JMdict dictionary file. JMdict '
                'is the property of the Electronic Dictionary Research and '
                'Development Group, and is used in conformance with the '
                'Group\'s licence.',
              ),
              const _Fact('Licence', 'CC BY-SA 4.0'),
              if (date != null) _Fact('Dictionary dated', date),
              const _Address('JMdict project', jmdictProject),
              const _Address('The Group\'s licence', edrdgLicence),
            ],
          ),
          Gaps.medium,
          const _Source(
            title: 'Which words are taught',
            children: [
              _Paragraph(
                'The choice of words follows the JLPT vocabulary lists for '
                'levels N5 and N4 compiled by Jonathan Waller (CC BY), in '
                'the copy that Stephen Kraus matched to JMdict entries '
                '(CC BY-SA 4.0). There are no official vocabulary lists '
                'for the exam; these are an informed estimate.',
              ),
              _Address('Jonathan Waller\'s lists', wallerLists),
              _Address('Matched copy', matchedLists),
            ],
          ),
          Gaps.medium,
          _Source(
            title: 'This app\'s word list',
            children: [
              _Paragraph(
                '${state.wordCount == 0 ? 'The' : 'The ${state.wordCount}'} '
                'words in this app are a selection from those sources, '
                'changed for beginners: meanings are shortened, some are '
                'reworded by hand, and words are put in the order their '
                'kana are taught. The list is shared under CC BY-SA 4.0. '
                'You may copy and change it if you credit the sources '
                'above and share your version under the same licence.',
              ),
              const _Address('The word list and how it is built', wordData),
              const _Address('CC BY-SA 4.0', shareAlike),
            ],
          ),
          Gaps.medium,
          IppoCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Licences'),
              subtitle: const Text('Software and fonts used by the app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Ippo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IppoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Gaps.small,
          ...children,
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// A web address shown as text that can be selected and copied. The app
/// is offline and opens no links itself.
class _Address extends StatelessWidget {
  const _Address(this.label, this.address);

  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SelectableText(
            address,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
