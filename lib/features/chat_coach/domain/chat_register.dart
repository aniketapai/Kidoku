/// Politeness register to phrase a message in, mirroring the three levels
/// JLPT learners actually need to navigate day to day: plain form with
/// friends, teineigo with acquaintances/colleagues, and keigo for
/// superiors/clients.
enum ChatRegister {
  casual,
  semiFormal,
  formal;

  String get label => switch (this) {
    ChatRegister.casual => 'Casual',
    ChatRegister.semiFormal => 'Semi-formal',
    ChatRegister.formal => 'Formal',
  };

  String get subtitle => switch (this) {
    ChatRegister.casual => 'Friends — plain form',
    ChatRegister.semiFormal => 'Colleagues — です/ます',
    ChatRegister.formal => 'Polite — keigo',
  };

  /// Fed into the model prompt, not shown in the UI.
  String get promptDescription => switch (this) {
    ChatRegister.casual =>
      'casual/plain form (普通体, タメ口) as used between close friends — '
          'contractions, plain-form verb endings, casual sentence-final '
          'particles are all fine',
    ChatRegister.semiFormal =>
      'semi-formal teineigo (です/ます体) as used with colleagues, '
          'acquaintances, or people you don\'t know well — polite but not '
          'deferential',
    ChatRegister.formal =>
      'formal keigo (敬語, mixing 尊敬語/謙譲語 as appropriate) as used with '
          'superiors, clients, or in business correspondence',
  };
}
