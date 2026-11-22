## ADDED Requirements

### Requirement: Word list for beginners
The project SHALL maintain a list of Japanese words for learners, drawn from an open dictionary and limited to the vocabulary of the first two beginner exam levels. A word SHALL be in the list only if its reading can be written entirely with kana the app teaches. Words the dictionary marks as archaic, obsolete, rare, vulgar or derogatory SHALL NOT be in the list.

#### Scenario: A beginner word is included
- **WHEN** the list is built and the beginner vocabulary contains あか (red)
- **THEN** the list contains あか

#### Scenario: A word needing an untaught kana is left out
- **WHEN** a beginner word's reading contains a kana the app does not teach
- **THEN** the word is not in the list

#### Scenario: A word using a mark is included
- **WHEN** a beginner word's reading contains the small っ or the long mark ー
- **THEN** the word is in the list

#### Scenario: A word above the two levels is left out
- **WHEN** a common dictionary word is not in the vocabulary of the first two beginner levels
- **THEN** the word is not in the list

### Requirement: What is recorded for a word
Each word in the list SHALL have: an identifier that stays the same when the list is rebuilt; its reading in kana; its usual written form, or none when it is normally written in kana; between one and three short meanings in English with no parenthesised explanations; a part of speech; its level; and its position in the learning order.

#### Scenario: A word written with kanji
- **WHEN** the list contains あか
- **THEN** its record has the reading あか, the written form 赤, the meaning "red", the part of speech noun and a level

#### Scenario: A word written in kana
- **WHEN** a word is normally written in kana
- **THEN** its record has no written form

#### Scenario: Identifier survives a rebuild
- **WHEN** the list is rebuilt from a newer dictionary that still contains a word
- **THEN** the word keeps the same identifier

### Requirement: Kana needed to read a word
Each word SHALL record which of the app's kana are needed to read it, using the kana's stable keys. A combination kana SHALL be recorded as the combination, not as its two characters.

#### Scenario: Plain kana
- **WHEN** the list contains あか
- **THEN** it records that あ and か are needed

#### Scenario: Combination kana
- **WHEN** a word's reading contains きゃ
- **THEN** it records that the combination きゃ is needed, and does not record や on its account

#### Scenario: Repeated kana
- **WHEN** a word's reading uses the same kana twice
- **THEN** that kana is recorded once

### Requirement: One word per reading
The list SHALL NOT contain two words with the same reading. Where several beginner words share a reading, the list SHALL keep the one from the lower level, and SHALL report the others as set aside.

#### Scenario: Shared reading
- **WHEN** two beginner words are both read はし
- **THEN** the list contains exactly one word read はし
- **AND** the other is named in the preview as set aside

### Requirement: Learning order
The list SHALL order its words so that the first level comes before the second and, within a level, words readable with earlier-taught kana come before words that need later ones. Rebuilding from the same inputs SHALL produce the same order.

#### Scenario: Earlier kana first
- **WHEN** two words of the same level need kana from the あ and か rows only, and from the ま row, respectively
- **THEN** the first comes earlier in the order

#### Scenario: Stable result
- **WHEN** the list is built twice from the same dictionary, beginner vocabulary and corrections
- **THEN** the two results are identical

### Requirement: Corrections by hand
The project SHALL keep a file of corrections, separate from the generated list, through which a word can be left out, its meanings or written form replaced, or a list entry matched to the wrong dictionary entry pointed at the right one. Rebuilding SHALL apply the corrections. A correction that refers to a word that is no longer a candidate SHALL make the build fail with a message naming it.

#### Scenario: Replacing a meaning
- **WHEN** a correction gives new meanings for a word and the list is rebuilt
- **THEN** the word has those meanings

#### Scenario: Pointing at the right entry
- **WHEN** a correction names another dictionary entry for a list entry and the list is rebuilt
- **THEN** the word is built from that entry

#### Scenario: Leaving a word out
- **WHEN** a correction excludes a word and the list is rebuilt
- **THEN** the word is not in the list

#### Scenario: Stale correction
- **WHEN** a correction names a word that is not among the candidates
- **THEN** the build fails and names that correction

### Requirement: Preview for review
Building the list SHALL also produce a readable preview that shows, for each row of kana in teaching order, the words that become readable once that row has been learned, and the running total. The preview SHALL list the words set aside for sharing a reading and the beginner vocabulary entries that could not be matched to the dictionary.

#### Scenario: Words by row
- **WHEN** the preview is generated
- **THEN** under the か row it lists the words readable with the あ and か rows that were not readable with the あ row alone

#### Scenario: Every word appears once
- **WHEN** the preview is generated
- **THEN** each word of the list appears in it exactly once

### Requirement: Sources are credited
Wherever the word list is published, the project SHALL name the dictionary and the beginner vocabulary it was built from, their authors or publishers, and their licences, and SHALL state the date of the dictionary data used. The word list SHALL be published under the licence the dictionary requires for derived files.

#### Scenario: Notices beside the data
- **WHEN** someone opens the folder that holds the word list in the repository
- **THEN** they find the names and licences of both sources, the dictionary date, and the licence of the word list

### Requirement: The list is kept current
The project SHALL rebuild the word list from the latest published dictionary at least once a month without anyone having to start it, and SHALL present any resulting change for review before it becomes the published list.

#### Scenario: Dictionary changed
- **WHEN** the monthly rebuild produces a word list that differs from the published one
- **THEN** the change is proposed for review, showing what differs

#### Scenario: Nothing changed
- **WHEN** the monthly rebuild produces the same words, differing at most in the dictionary date
- **THEN** nothing is proposed

### Requirement: Invalid lists are never published
A build SHALL verify its result before writing it: identifiers and readings are unique, every recorded kana is one the app teaches, every word has a meaning, and the order has no gaps. If a check fails, the build SHALL stop and leave the existing list unchanged.

#### Scenario: A failed check
- **WHEN** a build would produce two words with the same reading
- **THEN** the build fails with a message and the existing word list is not modified
