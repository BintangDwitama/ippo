# Word data

The beginner word list for Ippo: about 1,300 Japanese words with their
reading, written form, meanings and the kana needed to read each one.

| File | What it is |
|---|---|
| `words.json` | The word list. Generated; do not edit. |
| `preview.md` | The same list as a readable document, by row of kana. Generated; do not edit. |
| `overrides.json` | Corrections made by hand. Edit this, then rebuild. |
| `sources/` | The beginner vocabulary list the words are chosen from. |
| `LICENSE` | The licence for everything in this folder. |

`words.json` is bundled in the app as it is: the app teaches these words
and keeps the learner's progress when the list changes. The other files
are not part of the installed app.

## Sources and credit

**JMdict.** Readings, written forms, meanings and parts of speech come
from the [JMdict](https://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project)
dictionary file. JMdict is the property of the
[Electronic Dictionary Research and Development Group](https://www.edrdg.org/)
(EDRDG) and is used in conformance with the Group's
[licence](https://www.edrdg.org/edrdg/licence.html) (CC BY-SA 4.0). The
file is read from the JSON conversion published by
[jmdict-simplified](https://github.com/scriptin/jmdict-simplified). The
date of the dictionary a list was built from is in `words.json`
(`dictionaryDate`) and at the top of `preview.md`.

**JLPT vocabulary lists, N5 and N4.** Which words are included, and their
level, come from the lists compiled by
[Jonathan Waller](http://www.tanos.co.uk/jlpt/) (CC BY), in the copy that
[Stephen Kraus](https://github.com/stephenmk/yomitan-jlpt-vocab) matched
to JMdict entries (CC BY-SA 4.0). See `sources/README.md` for the exact
copy and for how its licence was established.

Everything in this folder is licensed CC BY-SA 4.0; see `LICENSE`.

## What was changed

The list is a selection and rearrangement, not a copy:

- Only words on the N5 and N4 lists are kept, and only if they can be read
  with the kana the app teaches.
- Words the dictionary marks archaic, obsolete, rare, vulgar or derogatory
  are left out.
- Words that share a reading (雨 rain and 飴 candy are both あめ) are kept
  as separate words.
- Each word keeps at most three short meanings. The dictionary's wording
  is used for the meanings the beginner list names; explanations in
  parentheses are dropped.
- Meanings and a few mismatched entries are corrected by hand in
  `overrides.json`. A corrected meaning is this project's wording, not the
  dictionary's.
- Words are ordered by level, then by how early in the kana path they
  become readable.

`preview.md` ends with every word that was left out and why.

## Rebuilding

1. Download `jmdict-eng-<version>.json.zip` from the latest
   [jmdict-simplified release](https://github.com/scriptin/jmdict-simplified/releases/latest)
   and unpack it somewhere outside the repository (the file is over 100 MB).
2. From the repository root:

   ```
   dart run tool/words/build_words.dart --dictionary path/to/jmdict-eng-<version>.json
   flutter test test/words
   ```

The build checks the list before writing anything; if a check fails the
existing files are left as they are.

### Corrections

`overrides.json` maps an id from the beginner list (the first column of
the files in `sources/`) to a correction:

```json
{
  "1258330": {"meanings": ["dog"]},
  "2846389": {"useEntry": "1050390", "note": "The list points at the wrong entry."}
}
```

| Field | Effect |
|---|---|
| `meanings` | Replaces the meanings (at most three, no parentheses). |
| `written` | Replaces the written form; `null` for none. |
| `useEntry` | Builds the word from another JMdict entry. |
| `exclude` | `true` leaves the word out. |
| `note` | A remark for readers; changes nothing. |

A correction whose id no longer matches a word stops the build, so
corrections cannot silently go stale.

## Keeping it current

`.github/workflows/update-words.yml` rebuilds the list from the newest
JMdict on the 5th of every month and opens a pull request when a word or
meaning changes. Nothing is merged automatically. It can also be started
by hand from the repository's Actions tab.
