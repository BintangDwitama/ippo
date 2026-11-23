# sources-credit Specification

## Purpose
The screen that credits where the app's content comes from: the JMdict dictionary and its owners, the vocabulary lists that choose the words, the licence of the app's own word list, and the licences of bundled software and fonts.

## Requirements
### Requirement: About and sources screen
The settings screen SHALL give access to a screen that credits the sources of the app's content. The screen SHALL be available without a network connection.

#### Scenario: Open from settings
- **WHEN** the learner selects "About and sources" in settings
- **THEN** the About and sources screen opens

### Requirement: Dictionary acknowledgement
The About and sources screen SHALL state that the app's words come from the JMdict dictionary file, that the file is the property of the Electronic Dictionary Research and Development Group, and that it is used in conformance with the Group's licence. It SHALL show the address of the JMdict project page and of the Group's licence page, the name of the licence, and the date of the dictionary the bundled word list was built from.

#### Scenario: Acknowledgement shown
- **WHEN** the learner opens the About and sources screen
- **THEN** the JMdict acknowledgement, the two addresses, "CC BY-SA 4.0" and the dictionary date are shown

#### Scenario: Date follows the bundled list
- **WHEN** the app is built with a word list made from a dictionary dated 2026-11-16
- **THEN** the screen shows that date

### Requirement: Credit for the word selection
The About and sources screen SHALL credit the vocabulary lists that decide which words are taught: their compiler, the person who matched them to dictionary entries, their licences and where they were obtained. It SHALL state that the app's word list is a changed selection of those sources and is itself shared under CC BY-SA 4.0, and where it can be found.

#### Scenario: List credit shown
- **WHEN** the learner opens the About and sources screen
- **THEN** the names of the list's compiler and of its matcher, their licences and the address of the app's word data are shown

### Requirement: Software and font licences
The About and sources screen SHALL give access to the licences of the software packages and fonts bundled with the app.

#### Scenario: Open licences
- **WHEN** the learner selects "Licences" on the About and sources screen
- **THEN** the licences of bundled packages and fonts are listed

