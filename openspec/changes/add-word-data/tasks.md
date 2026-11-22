## 1. Sources

- [x] 1.1 Download the latest English JMdict file from jmdict-simplified; record in design.md its file name, size, version field and dictionary date
- [x] 1.2 Confirm from the file whether word ids are JMdict sequence numbers; record the result and switch to the fallback key if they are not
- [x] 1.3 Read the file's tag table and record the exact tags for archaic, obsolete, rare, vulgar, derogatory and "usually written in kana"
- [x] 1.4 Choose the copy of the beginner list to vendor, read the licence statement that accompanies it, and record both; check the licence of the published mapping to JMdict ids and decide whether to use it or match by form and reading
- [x] 1.5 Vendor the beginner list for levels 5 and 4 under `data/words/sources/` with its attribution notice

## 2. Build logic

- [x] 2.1 Create `tool/words/` with the entry point and argument handling (dictionary path, output folder)
- [x] 2.2 Implement splitting a reading into the app's kana from `assets/seed/kana.json`
- [x] 2.3 Implement reading the dictionary file, with a check on its version field
- [x] 2.4 Implement matching beginner list entries to dictionary entries, collecting the unmatched
- [x] 2.5 Implement the word record: reading, written form, meanings, part of speech, level, kana
- [x] 2.6 Implement the selection rules, overrides and the rule for words that share a reading, collecting the words set aside
- [x] 2.7 Implement ordering and the output writer with stable formatting
- [x] 2.8 Implement the self-checks that stop the build before writing
- [x] 2.9 Implement the preview

## 3. Tests

- [x] 3.1 Fixtures: a small dictionary file and beginner list covering every rule
- [x] 3.2 Tests for splitting readings: plain, combination, small っ, long mark, an untaught character
- [x] 3.3 Tests for matching, each selection rule, words that share a reading
- [x] 3.4 Tests for meanings, part of speech, written form and overrides, including a stale override
- [x] 3.5 Tests for order, for identical output from identical input, and for a failed self-check leaving the existing file unchanged
- [x] 3.6 Tests on the committed word file and preview

## 4. Generate and review

- [x] 4.1 Run the build; commit `data/words/words.json`, `preview.md` and `overrides.json`
- [x] 4.2 Record in design.md the number of words kept, set aside and unmatched, and how many are readable after each of the first ten rows of kana
- [x] 4.3 Read every word the preview flags and add overrides for meanings that are wrong, misleading or awkward
- [ ] 4.4 The owner reads the preview and reports words or meanings that look wrong; add overrides and rebuild

## 5. Notices

- [x] 5.1 Write `data/words/README.md`: both sources, authors, licences, the EDRDG project links, the dictionary date, how the beginner list's licence was established, and how to rebuild
- [x] 5.2 Add `data/words/LICENSE` for the files in the folder
- [x] 5.3 Add a short section to the main README pointing to the word data and its sources

## 6. Monthly rebuild

- [x] 6.1 Add `.github/workflows/update-words.yml`: monthly and on request; install Flutter; run the build and the word tests; on a change push a branch and open a pull request
- [x] 6.2 Run the workflow once by hand and confirm it completes and proposes nothing when the data is current
- [ ] 6.3 The owner allows workflows to create pull requests in the repository's settings, or accepts opening them by hand

## 7. Checks

- [x] 7.1 Run `flutter analyze` and `flutter test`; fix all issues
- [x] 7.2 Confirm the release APK does not contain the word file
