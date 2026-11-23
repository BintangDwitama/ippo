/// What the phone can do about speaking Japanese.
enum JapaneseVoice {
  /// A Japanese voice is downloaded and works without a network.
  ready,

  /// The phone can speak Japanese, but no voice is downloaded: each sound
  /// may be fetched over the network, so it can be late, and absent
  /// without a connection.
  onlineOnly,

  /// The phone has no Japanese voice.
  missing;

  /// Whether anything can be spoken at all.
  bool get canSpeak => this != JapaneseVoice.missing;

  /// Whether the learner would gain from downloading a voice.
  bool get needsDownload => this != JapaneseVoice.ready;
}
