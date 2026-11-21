## Why

Two marks are missing from the 208 kana, and a large share of ordinary words cannot be read without them: the small っ, which doubles the consonant that follows (きって), and the katakana long mark ー, which lengthens a vowel (コーヒー). The next stage unlocks words by the kana in them, so until these marks can be learned, those words can never unlock.

## What Changes

- Add three **marks** to the kana set: hiragana っ, katakana ッ and katakana ー. The app then holds 211 kana.
- Add a fourth kana group, **mark**, taught after the combination kana of its script.
- Teach a mark as a rule, not a sound: its lesson shows the mark, explains what it does, and plays a spoken pair that makes the difference audible (きて, then きって).
- A mark has **no review cards and no quiz question**, because it has no reading of its own to be asked. Completing its lesson marks it as learned.
- Marks never appear as wrong options in multiple-choice questions.
- The kana grid gains a fourth section, Marks.
- Goals for voiced and combination kana now also cover that script's marks: 59 hiragana, 60 katakana, 211 in all. **BREAKING** for a goal of that kind that is already active, which grows by one or two kana.
- Not included: drill cards that test hearing doubled or long sounds, hiragana long vowels (which are written with ordinary kana), and the words that use the marks.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `kana-content`: the seeded set grows to 211 with a mark group; the grid gains a section; marks are taught as rules with a spoken example and are never answer options.
- `kana-lessons`: marks follow the combination kana of their script, are not quizzed, and get no review cards.
- `learning-goals`: the voiced-and-combination target sets and the all-kana set include the marks.

## Impact

- **Code**: `KanaGroup` and `KanaPayload` (a new group and an optional spoken sample), the payload mapper and seed parser, `CompleteLesson`, `GetKanaStatus`, `BuildChoiceOptions`, the lesson ViewModel and screen, the kana grid ViewModel and screen, and the three places that speak a kana.
- **Assets**: three entries added to `assets/seed/kana.json`.
- **Data**: no schema change. Three items are added by seeding on the next launch.
- **Existing learners**: nothing changes for a basic-kana goal. Lessons offer っ after the hiragana combination kana and ッ and ー after the katakana ones.
- **Backups**: the format is unchanged. A backup that records a mark as learned is refused by an older app as not matching its version.
- **Manual verification**: the three spoken pairs have to be judged by ear on the phone.
