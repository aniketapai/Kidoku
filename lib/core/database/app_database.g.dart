// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DictionaryEntriesTable extends DictionaryEntries
    with TableInfo<$DictionaryEntriesTable, DictionaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dictionaryFormMeta = const VerificationMeta(
    'dictionaryForm',
  );
  @override
  late final GeneratedColumn<String> dictionaryForm = GeneratedColumn<String>(
    'dictionary_form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningsMeta = const VerificationMeta(
    'meanings',
  );
  @override
  late final GeneratedColumn<String> meanings = GeneratedColumn<String>(
    'meanings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jlptLevelMeta = const VerificationMeta(
    'jlptLevel',
  );
  @override
  late final GeneratedColumn<String> jlptLevel = GeneratedColumn<String>(
    'jlpt_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dictionaryForm,
    reading,
    meanings,
    partOfSpeech,
    jlptLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dictionary_form')) {
      context.handle(
        _dictionaryFormMeta,
        dictionaryForm.isAcceptableOrUnknown(
          data['dictionary_form']!,
          _dictionaryFormMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryFormMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('meanings')) {
      context.handle(
        _meaningsMeta,
        meanings.isAcceptableOrUnknown(data['meanings']!, _meaningsMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningsMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partOfSpeechMeta);
    }
    if (data.containsKey('jlpt_level')) {
      context.handle(
        _jlptLevelMeta,
        jlptLevel.isAcceptableOrUnknown(data['jlpt_level']!, _jlptLevelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dictionaryForm};
  @override
  DictionaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryEntry(
      dictionaryForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_form'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      meanings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meanings'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      )!,
      jlptLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jlpt_level'],
      ),
    );
  }

  @override
  $DictionaryEntriesTable createAlias(String alias) {
    return $DictionaryEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryEntry extends DataClass implements Insertable<DictionaryEntry> {
  final String dictionaryForm;
  final String reading;

  /// JSON-encoded list of strings.
  final String meanings;
  final String partOfSpeech;
  final String? jlptLevel;
  const DictionaryEntry({
    required this.dictionaryForm,
    required this.reading,
    required this.meanings,
    required this.partOfSpeech,
    this.jlptLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dictionary_form'] = Variable<String>(dictionaryForm);
    map['reading'] = Variable<String>(reading);
    map['meanings'] = Variable<String>(meanings);
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    if (!nullToAbsent || jlptLevel != null) {
      map['jlpt_level'] = Variable<String>(jlptLevel);
    }
    return map;
  }

  DictionaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryEntriesCompanion(
      dictionaryForm: Value(dictionaryForm),
      reading: Value(reading),
      meanings: Value(meanings),
      partOfSpeech: Value(partOfSpeech),
      jlptLevel: jlptLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(jlptLevel),
    );
  }

  factory DictionaryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryEntry(
      dictionaryForm: serializer.fromJson<String>(json['dictionaryForm']),
      reading: serializer.fromJson<String>(json['reading']),
      meanings: serializer.fromJson<String>(json['meanings']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      jlptLevel: serializer.fromJson<String?>(json['jlptLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dictionaryForm': serializer.toJson<String>(dictionaryForm),
      'reading': serializer.toJson<String>(reading),
      'meanings': serializer.toJson<String>(meanings),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'jlptLevel': serializer.toJson<String?>(jlptLevel),
    };
  }

  DictionaryEntry copyWith({
    String? dictionaryForm,
    String? reading,
    String? meanings,
    String? partOfSpeech,
    Value<String?> jlptLevel = const Value.absent(),
  }) => DictionaryEntry(
    dictionaryForm: dictionaryForm ?? this.dictionaryForm,
    reading: reading ?? this.reading,
    meanings: meanings ?? this.meanings,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    jlptLevel: jlptLevel.present ? jlptLevel.value : this.jlptLevel,
  );
  DictionaryEntry copyWithCompanion(DictionaryEntriesCompanion data) {
    return DictionaryEntry(
      dictionaryForm: data.dictionaryForm.present
          ? data.dictionaryForm.value
          : this.dictionaryForm,
      reading: data.reading.present ? data.reading.value : this.reading,
      meanings: data.meanings.present ? data.meanings.value : this.meanings,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      jlptLevel: data.jlptLevel.present ? data.jlptLevel.value : this.jlptLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntry(')
          ..write('dictionaryForm: $dictionaryForm, ')
          ..write('reading: $reading, ')
          ..write('meanings: $meanings, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('jlptLevel: $jlptLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dictionaryForm, reading, meanings, partOfSpeech, jlptLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryEntry &&
          other.dictionaryForm == this.dictionaryForm &&
          other.reading == this.reading &&
          other.meanings == this.meanings &&
          other.partOfSpeech == this.partOfSpeech &&
          other.jlptLevel == this.jlptLevel);
}

class DictionaryEntriesCompanion extends UpdateCompanion<DictionaryEntry> {
  final Value<String> dictionaryForm;
  final Value<String> reading;
  final Value<String> meanings;
  final Value<String> partOfSpeech;
  final Value<String?> jlptLevel;
  final Value<int> rowid;
  const DictionaryEntriesCompanion({
    this.dictionaryForm = const Value.absent(),
    this.reading = const Value.absent(),
    this.meanings = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.jlptLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionaryEntriesCompanion.insert({
    required String dictionaryForm,
    required String reading,
    required String meanings,
    required String partOfSpeech,
    this.jlptLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dictionaryForm = Value(dictionaryForm),
       reading = Value(reading),
       meanings = Value(meanings),
       partOfSpeech = Value(partOfSpeech);
  static Insertable<DictionaryEntry> custom({
    Expression<String>? dictionaryForm,
    Expression<String>? reading,
    Expression<String>? meanings,
    Expression<String>? partOfSpeech,
    Expression<String>? jlptLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dictionaryForm != null) 'dictionary_form': dictionaryForm,
      if (reading != null) 'reading': reading,
      if (meanings != null) 'meanings': meanings,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (jlptLevel != null) 'jlpt_level': jlptLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionaryEntriesCompanion copyWith({
    Value<String>? dictionaryForm,
    Value<String>? reading,
    Value<String>? meanings,
    Value<String>? partOfSpeech,
    Value<String?>? jlptLevel,
    Value<int>? rowid,
  }) {
    return DictionaryEntriesCompanion(
      dictionaryForm: dictionaryForm ?? this.dictionaryForm,
      reading: reading ?? this.reading,
      meanings: meanings ?? this.meanings,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dictionaryForm.present) {
      map['dictionary_form'] = Variable<String>(dictionaryForm.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meanings.present) {
      map['meanings'] = Variable<String>(meanings.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (jlptLevel.present) {
      map['jlpt_level'] = Variable<String>(jlptLevel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntriesCompanion(')
          ..write('dictionaryForm: $dictionaryForm, ')
          ..write('reading: $reading, ')
          ..write('meanings: $meanings, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('jlptLevel: $jlptLevel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserWordsTable extends UserWords
    with TableInfo<$UserWordsTable, UserWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dictionaryFormMeta = const VerificationMeta(
    'dictionaryForm',
  );
  @override
  late final GeneratedColumn<String> dictionaryForm = GeneratedColumn<String>(
    'dictionary_form',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WordStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WordStatus>($UserWordsTable.$converterstatus);
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenMeta = const VerificationMeta(
    'lastSeen',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
    'last_seen',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _srsDueAtMeta = const VerificationMeta(
    'srsDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> srsDueAt = GeneratedColumn<DateTime>(
    'srs_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _srsIntervalMeta = const VerificationMeta(
    'srsInterval',
  );
  @override
  late final GeneratedColumn<int> srsInterval = GeneratedColumn<int>(
    'srs_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    dictionaryForm,
    status,
    savedAt,
    lastSeen,
    srsDueAt,
    srsInterval,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dictionary_form')) {
      context.handle(
        _dictionaryFormMeta,
        dictionaryForm.isAcceptableOrUnknown(
          data['dictionary_form']!,
          _dictionaryFormMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dictionaryFormMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    }
    if (data.containsKey('last_seen')) {
      context.handle(
        _lastSeenMeta,
        lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('srs_due_at')) {
      context.handle(
        _srsDueAtMeta,
        srsDueAt.isAcceptableOrUnknown(data['srs_due_at']!, _srsDueAtMeta),
      );
    }
    if (data.containsKey('srs_interval')) {
      context.handle(
        _srsIntervalMeta,
        srsInterval.isAcceptableOrUnknown(
          data['srs_interval']!,
          _srsIntervalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dictionaryForm};
  @override
  UserWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWord(
      dictionaryForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dictionary_form'],
      )!,
      status: $UserWordsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      ),
      lastSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen'],
      )!,
      srsDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}srs_due_at'],
      ),
      srsInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}srs_interval'],
      )!,
    );
  }

  @override
  $UserWordsTable createAlias(String alias) {
    return $UserWordsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WordStatus, String, String> $converterstatus =
      const EnumNameConverter<WordStatus>(WordStatus.values);
}

class UserWord extends DataClass implements Insertable<UserWord> {
  final String dictionaryForm;
  final WordStatus status;
  final DateTime? savedAt;
  final DateTime lastSeen;
  final DateTime? srsDueAt;
  final int srsInterval;
  const UserWord({
    required this.dictionaryForm,
    required this.status,
    this.savedAt,
    required this.lastSeen,
    this.srsDueAt,
    required this.srsInterval,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dictionary_form'] = Variable<String>(dictionaryForm);
    {
      map['status'] = Variable<String>(
        $UserWordsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || savedAt != null) {
      map['saved_at'] = Variable<DateTime>(savedAt);
    }
    map['last_seen'] = Variable<DateTime>(lastSeen);
    if (!nullToAbsent || srsDueAt != null) {
      map['srs_due_at'] = Variable<DateTime>(srsDueAt);
    }
    map['srs_interval'] = Variable<int>(srsInterval);
    return map;
  }

  UserWordsCompanion toCompanion(bool nullToAbsent) {
    return UserWordsCompanion(
      dictionaryForm: Value(dictionaryForm),
      status: Value(status),
      savedAt: savedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(savedAt),
      lastSeen: Value(lastSeen),
      srsDueAt: srsDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(srsDueAt),
      srsInterval: Value(srsInterval),
    );
  }

  factory UserWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWord(
      dictionaryForm: serializer.fromJson<String>(json['dictionaryForm']),
      status: $UserWordsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      savedAt: serializer.fromJson<DateTime?>(json['savedAt']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      srsDueAt: serializer.fromJson<DateTime?>(json['srsDueAt']),
      srsInterval: serializer.fromJson<int>(json['srsInterval']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dictionaryForm': serializer.toJson<String>(dictionaryForm),
      'status': serializer.toJson<String>(
        $UserWordsTable.$converterstatus.toJson(status),
      ),
      'savedAt': serializer.toJson<DateTime?>(savedAt),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'srsDueAt': serializer.toJson<DateTime?>(srsDueAt),
      'srsInterval': serializer.toJson<int>(srsInterval),
    };
  }

  UserWord copyWith({
    String? dictionaryForm,
    WordStatus? status,
    Value<DateTime?> savedAt = const Value.absent(),
    DateTime? lastSeen,
    Value<DateTime?> srsDueAt = const Value.absent(),
    int? srsInterval,
  }) => UserWord(
    dictionaryForm: dictionaryForm ?? this.dictionaryForm,
    status: status ?? this.status,
    savedAt: savedAt.present ? savedAt.value : this.savedAt,
    lastSeen: lastSeen ?? this.lastSeen,
    srsDueAt: srsDueAt.present ? srsDueAt.value : this.srsDueAt,
    srsInterval: srsInterval ?? this.srsInterval,
  );
  UserWord copyWithCompanion(UserWordsCompanion data) {
    return UserWord(
      dictionaryForm: data.dictionaryForm.present
          ? data.dictionaryForm.value
          : this.dictionaryForm,
      status: data.status.present ? data.status.value : this.status,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      srsDueAt: data.srsDueAt.present ? data.srsDueAt.value : this.srsDueAt,
      srsInterval: data.srsInterval.present
          ? data.srsInterval.value
          : this.srsInterval,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWord(')
          ..write('dictionaryForm: $dictionaryForm, ')
          ..write('status: $status, ')
          ..write('savedAt: $savedAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('srsDueAt: $srsDueAt, ')
          ..write('srsInterval: $srsInterval')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dictionaryForm,
    status,
    savedAt,
    lastSeen,
    srsDueAt,
    srsInterval,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWord &&
          other.dictionaryForm == this.dictionaryForm &&
          other.status == this.status &&
          other.savedAt == this.savedAt &&
          other.lastSeen == this.lastSeen &&
          other.srsDueAt == this.srsDueAt &&
          other.srsInterval == this.srsInterval);
}

class UserWordsCompanion extends UpdateCompanion<UserWord> {
  final Value<String> dictionaryForm;
  final Value<WordStatus> status;
  final Value<DateTime?> savedAt;
  final Value<DateTime> lastSeen;
  final Value<DateTime?> srsDueAt;
  final Value<int> srsInterval;
  final Value<int> rowid;
  const UserWordsCompanion({
    this.dictionaryForm = const Value.absent(),
    this.status = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.srsDueAt = const Value.absent(),
    this.srsInterval = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordsCompanion.insert({
    required String dictionaryForm,
    required WordStatus status,
    this.savedAt = const Value.absent(),
    required DateTime lastSeen,
    this.srsDueAt = const Value.absent(),
    this.srsInterval = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dictionaryForm = Value(dictionaryForm),
       status = Value(status),
       lastSeen = Value(lastSeen);
  static Insertable<UserWord> custom({
    Expression<String>? dictionaryForm,
    Expression<String>? status,
    Expression<DateTime>? savedAt,
    Expression<DateTime>? lastSeen,
    Expression<DateTime>? srsDueAt,
    Expression<int>? srsInterval,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dictionaryForm != null) 'dictionary_form': dictionaryForm,
      if (status != null) 'status': status,
      if (savedAt != null) 'saved_at': savedAt,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (srsDueAt != null) 'srs_due_at': srsDueAt,
      if (srsInterval != null) 'srs_interval': srsInterval,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordsCompanion copyWith({
    Value<String>? dictionaryForm,
    Value<WordStatus>? status,
    Value<DateTime?>? savedAt,
    Value<DateTime>? lastSeen,
    Value<DateTime?>? srsDueAt,
    Value<int>? srsInterval,
    Value<int>? rowid,
  }) {
    return UserWordsCompanion(
      dictionaryForm: dictionaryForm ?? this.dictionaryForm,
      status: status ?? this.status,
      savedAt: savedAt ?? this.savedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      srsDueAt: srsDueAt ?? this.srsDueAt,
      srsInterval: srsInterval ?? this.srsInterval,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dictionaryForm.present) {
      map['dictionary_form'] = Variable<String>(dictionaryForm.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $UserWordsTable.$converterstatus.toSql(status.value),
      );
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (srsDueAt.present) {
      map['srs_due_at'] = Variable<DateTime>(srsDueAt.value);
    }
    if (srsInterval.present) {
      map['srs_interval'] = Variable<int>(srsInterval.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordsCompanion(')
          ..write('dictionaryForm: $dictionaryForm, ')
          ..write('status: $status, ')
          ..write('savedAt: $savedAt, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('srsDueAt: $srsDueAt, ')
          ..write('srsInterval: $srsInterval, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeedMetaTable extends SeedMeta
    with TableInfo<$SeedMetaTable, SeedMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeedMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seededVersionMeta = const VerificationMeta(
    'seededVersion',
  );
  @override
  late final GeneratedColumn<int> seededVersion = GeneratedColumn<int>(
    'seeded_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, seededVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seed_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeedMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('seeded_version')) {
      context.handle(
        _seededVersionMeta,
        seededVersion.isAcceptableOrUnknown(
          data['seeded_version']!,
          _seededVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seededVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SeedMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeedMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seededVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seeded_version'],
      )!,
    );
  }

  @override
  $SeedMetaTable createAlias(String alias) {
    return $SeedMetaTable(attachedDatabase, alias);
  }
}

class SeedMetaData extends DataClass implements Insertable<SeedMetaData> {
  final int id;
  final int seededVersion;
  const SeedMetaData({required this.id, required this.seededVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['seeded_version'] = Variable<int>(seededVersion);
    return map;
  }

  SeedMetaCompanion toCompanion(bool nullToAbsent) {
    return SeedMetaCompanion(
      id: Value(id),
      seededVersion: Value(seededVersion),
    );
  }

  factory SeedMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeedMetaData(
      id: serializer.fromJson<int>(json['id']),
      seededVersion: serializer.fromJson<int>(json['seededVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seededVersion': serializer.toJson<int>(seededVersion),
    };
  }

  SeedMetaData copyWith({int? id, int? seededVersion}) => SeedMetaData(
    id: id ?? this.id,
    seededVersion: seededVersion ?? this.seededVersion,
  );
  SeedMetaData copyWithCompanion(SeedMetaCompanion data) {
    return SeedMetaData(
      id: data.id.present ? data.id.value : this.id,
      seededVersion: data.seededVersion.present
          ? data.seededVersion.value
          : this.seededVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeedMetaData(')
          ..write('id: $id, ')
          ..write('seededVersion: $seededVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, seededVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeedMetaData &&
          other.id == this.id &&
          other.seededVersion == this.seededVersion);
}

class SeedMetaCompanion extends UpdateCompanion<SeedMetaData> {
  final Value<int> id;
  final Value<int> seededVersion;
  const SeedMetaCompanion({
    this.id = const Value.absent(),
    this.seededVersion = const Value.absent(),
  });
  SeedMetaCompanion.insert({
    this.id = const Value.absent(),
    required int seededVersion,
  }) : seededVersion = Value(seededVersion);
  static Insertable<SeedMetaData> custom({
    Expression<int>? id,
    Expression<int>? seededVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seededVersion != null) 'seeded_version': seededVersion,
    });
  }

  SeedMetaCompanion copyWith({Value<int>? id, Value<int>? seededVersion}) {
    return SeedMetaCompanion(
      id: id ?? this.id,
      seededVersion: seededVersion ?? this.seededVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seededVersion.present) {
      map['seeded_version'] = Variable<int>(seededVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeedMetaCompanion(')
          ..write('id: $id, ')
          ..write('seededVersion: $seededVersion')
          ..write(')'))
        .toString();
  }
}

class $DeckCardsTable extends DeckCards
    with TableInfo<$DeckCardsTable, DeckCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeckCardType, String> cardType =
      GeneratedColumn<String>(
        'card_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DeckCardType>($DeckCardsTable.$convertercardType);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expressionMeta = const VerificationMeta(
    'expression',
  );
  @override
  late final GeneratedColumn<String> expression = GeneratedColumn<String>(
    'expression',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingMeta = const VerificationMeta(
    'reading',
  );
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
    'reading',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    level,
    cardType,
    category,
    expression,
    reading,
    meaning,
    extra,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('expression')) {
      context.handle(
        _expressionMeta,
        expression.isAcceptableOrUnknown(data['expression']!, _expressionMeta),
      );
    } else if (isInserting) {
      context.missing(_expressionMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(
        _readingMeta,
        reading.isAcceptableOrUnknown(data['reading']!, _readingMeta),
      );
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeckCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      cardType: $DeckCardsTable.$convertercardType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}card_type'],
        )!,
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      expression: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expression'],
      )!,
      reading: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reading'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DeckCardsTable createAlias(String alias) {
    return $DeckCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeckCardType, String, String> $convertercardType =
      const EnumNameConverter<DeckCardType>(DeckCardType.values);
}

class DeckCard extends DataClass implements Insertable<DeckCard> {
  final String id;
  final String deckId;
  final String level;
  final DeckCardType cardType;
  final String? category;
  final String expression;
  final String reading;
  final String meaning;

  /// JSON-encoded map of remaining raw Anki fields (romaji; onyomi/kunyomi/
  /// examples/note for kanji) not promoted to their own column, kept for
  /// full fidelity per the "add it as it is" import requirement.
  final String? extra;
  final int sortOrder;
  const DeckCard({
    required this.id,
    required this.deckId,
    required this.level,
    required this.cardType,
    this.category,
    required this.expression,
    required this.reading,
    required this.meaning,
    this.extra,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['level'] = Variable<String>(level);
    {
      map['card_type'] = Variable<String>(
        $DeckCardsTable.$convertercardType.toSql(cardType),
      );
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['expression'] = Variable<String>(expression);
    map['reading'] = Variable<String>(reading);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String>(extra);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DeckCardsCompanion toCompanion(bool nullToAbsent) {
    return DeckCardsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      level: Value(level),
      cardType: Value(cardType),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      expression: Value(expression),
      reading: Value(reading),
      meaning: Value(meaning),
      extra: extra == null && nullToAbsent
          ? const Value.absent()
          : Value(extra),
      sortOrder: Value(sortOrder),
    );
  }

  factory DeckCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckCard(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      level: serializer.fromJson<String>(json['level']),
      cardType: $DeckCardsTable.$convertercardType.fromJson(
        serializer.fromJson<String>(json['cardType']),
      ),
      category: serializer.fromJson<String?>(json['category']),
      expression: serializer.fromJson<String>(json['expression']),
      reading: serializer.fromJson<String>(json['reading']),
      meaning: serializer.fromJson<String>(json['meaning']),
      extra: serializer.fromJson<String?>(json['extra']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'level': serializer.toJson<String>(level),
      'cardType': serializer.toJson<String>(
        $DeckCardsTable.$convertercardType.toJson(cardType),
      ),
      'category': serializer.toJson<String?>(category),
      'expression': serializer.toJson<String>(expression),
      'reading': serializer.toJson<String>(reading),
      'meaning': serializer.toJson<String>(meaning),
      'extra': serializer.toJson<String?>(extra),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DeckCard copyWith({
    String? id,
    String? deckId,
    String? level,
    DeckCardType? cardType,
    Value<String?> category = const Value.absent(),
    String? expression,
    String? reading,
    String? meaning,
    Value<String?> extra = const Value.absent(),
    int? sortOrder,
  }) => DeckCard(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    level: level ?? this.level,
    cardType: cardType ?? this.cardType,
    category: category.present ? category.value : this.category,
    expression: expression ?? this.expression,
    reading: reading ?? this.reading,
    meaning: meaning ?? this.meaning,
    extra: extra.present ? extra.value : this.extra,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DeckCard copyWithCompanion(DeckCardsCompanion data) {
    return DeckCard(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      level: data.level.present ? data.level.value : this.level,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      category: data.category.present ? data.category.value : this.category,
      expression: data.expression.present
          ? data.expression.value
          : this.expression,
      reading: data.reading.present ? data.reading.value : this.reading,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      extra: data.extra.present ? data.extra.value : this.extra,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckCard(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('level: $level, ')
          ..write('cardType: $cardType, ')
          ..write('category: $category, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning, ')
          ..write('extra: $extra, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    level,
    cardType,
    category,
    expression,
    reading,
    meaning,
    extra,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckCard &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.level == this.level &&
          other.cardType == this.cardType &&
          other.category == this.category &&
          other.expression == this.expression &&
          other.reading == this.reading &&
          other.meaning == this.meaning &&
          other.extra == this.extra &&
          other.sortOrder == this.sortOrder);
}

class DeckCardsCompanion extends UpdateCompanion<DeckCard> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> level;
  final Value<DeckCardType> cardType;
  final Value<String?> category;
  final Value<String> expression;
  final Value<String> reading;
  final Value<String> meaning;
  final Value<String?> extra;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DeckCardsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.level = const Value.absent(),
    this.cardType = const Value.absent(),
    this.category = const Value.absent(),
    this.expression = const Value.absent(),
    this.reading = const Value.absent(),
    this.meaning = const Value.absent(),
    this.extra = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeckCardsCompanion.insert({
    required String id,
    required String deckId,
    required String level,
    required DeckCardType cardType,
    this.category = const Value.absent(),
    required String expression,
    required String reading,
    required String meaning,
    this.extra = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       level = Value(level),
       cardType = Value(cardType),
       expression = Value(expression),
       reading = Value(reading),
       meaning = Value(meaning),
       sortOrder = Value(sortOrder);
  static Insertable<DeckCard> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? level,
    Expression<String>? cardType,
    Expression<String>? category,
    Expression<String>? expression,
    Expression<String>? reading,
    Expression<String>? meaning,
    Expression<String>? extra,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (level != null) 'level': level,
      if (cardType != null) 'card_type': cardType,
      if (category != null) 'category': category,
      if (expression != null) 'expression': expression,
      if (reading != null) 'reading': reading,
      if (meaning != null) 'meaning': meaning,
      if (extra != null) 'extra': extra,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeckCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? level,
    Value<DeckCardType>? cardType,
    Value<String?>? category,
    Value<String>? expression,
    Value<String>? reading,
    Value<String>? meaning,
    Value<String?>? extra,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DeckCardsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      level: level ?? this.level,
      cardType: cardType ?? this.cardType,
      category: category ?? this.category,
      expression: expression ?? this.expression,
      reading: reading ?? this.reading,
      meaning: meaning ?? this.meaning,
      extra: extra ?? this.extra,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(
        $DeckCardsTable.$convertercardType.toSql(cardType.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (expression.present) {
      map['expression'] = Variable<String>(expression.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckCardsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('level: $level, ')
          ..write('cardType: $cardType, ')
          ..write('category: $category, ')
          ..write('expression: $expression, ')
          ..write('reading: $reading, ')
          ..write('meaning: $meaning, ')
          ..write('extra: $extra, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeckCardProgressTable extends DeckCardProgress
    with TableInfo<$DeckCardProgressTable, DeckCardProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckCardProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewDirection, String>
  direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ReviewDirection>($DeckCardProgressTable.$converterdirection);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalIndexMeta = const VerificationMeta(
    'intervalIndex',
  );
  @override
  late final GeneratedColumn<int> intervalIndex = GeneratedColumn<int>(
    'interval_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _introducedAtMeta = const VerificationMeta(
    'introducedAt',
  );
  @override
  late final GeneratedColumn<DateTime> introducedAt = GeneratedColumn<DateTime>(
    'introduced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewedMeta = const VerificationMeta(
    'lastReviewed',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
    'last_reviewed',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    direction,
    dueAt,
    intervalIndex,
    introducedAt,
    lastReviewed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_card_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckCardProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('interval_index')) {
      context.handle(
        _intervalIndexMeta,
        intervalIndex.isAcceptableOrUnknown(
          data['interval_index']!,
          _intervalIndexMeta,
        ),
      );
    }
    if (data.containsKey('introduced_at')) {
      context.handle(
        _introducedAtMeta,
        introducedAt.isAcceptableOrUnknown(
          data['introduced_at']!,
          _introducedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
        _lastReviewedMeta,
        lastReviewed.isAcceptableOrUnknown(
          data['last_reviewed']!,
          _lastReviewedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId, direction};
  @override
  DeckCardProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckCardProgressData(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      direction: $DeckCardProgressTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      intervalIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_index'],
      )!,
      introducedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}introduced_at'],
      ),
      lastReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed'],
      ),
    );
  }

  @override
  $DeckCardProgressTable createAlias(String alias) {
    return $DeckCardProgressTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReviewDirection, String, String>
  $converterdirection = const EnumNameConverter<ReviewDirection>(
    ReviewDirection.values,
  );
}

class DeckCardProgressData extends DataClass
    implements Insertable<DeckCardProgressData> {
  final String cardId;
  final ReviewDirection direction;
  final DateTime? dueAt;
  final int intervalIndex;

  /// When this card was first introduced into the direction's rotation —
  /// used to enforce SrsConfig.kNewDeckCardsPerDayPerDirection.
  final DateTime? introducedAt;
  final DateTime? lastReviewed;
  const DeckCardProgressData({
    required this.cardId,
    required this.direction,
    this.dueAt,
    required this.intervalIndex,
    this.introducedAt,
    this.lastReviewed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    {
      map['direction'] = Variable<String>(
        $DeckCardProgressTable.$converterdirection.toSql(direction),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['interval_index'] = Variable<int>(intervalIndex);
    if (!nullToAbsent || introducedAt != null) {
      map['introduced_at'] = Variable<DateTime>(introducedAt);
    }
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    return map;
  }

  DeckCardProgressCompanion toCompanion(bool nullToAbsent) {
    return DeckCardProgressCompanion(
      cardId: Value(cardId),
      direction: Value(direction),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      intervalIndex: Value(intervalIndex),
      introducedAt: introducedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(introducedAt),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
    );
  }

  factory DeckCardProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckCardProgressData(
      cardId: serializer.fromJson<String>(json['cardId']),
      direction: $DeckCardProgressTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      intervalIndex: serializer.fromJson<int>(json['intervalIndex']),
      introducedAt: serializer.fromJson<DateTime?>(json['introducedAt']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'direction': serializer.toJson<String>(
        $DeckCardProgressTable.$converterdirection.toJson(direction),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'intervalIndex': serializer.toJson<int>(intervalIndex),
      'introducedAt': serializer.toJson<DateTime?>(introducedAt),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
    };
  }

  DeckCardProgressData copyWith({
    String? cardId,
    ReviewDirection? direction,
    Value<DateTime?> dueAt = const Value.absent(),
    int? intervalIndex,
    Value<DateTime?> introducedAt = const Value.absent(),
    Value<DateTime?> lastReviewed = const Value.absent(),
  }) => DeckCardProgressData(
    cardId: cardId ?? this.cardId,
    direction: direction ?? this.direction,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    intervalIndex: intervalIndex ?? this.intervalIndex,
    introducedAt: introducedAt.present ? introducedAt.value : this.introducedAt,
    lastReviewed: lastReviewed.present ? lastReviewed.value : this.lastReviewed,
  );
  DeckCardProgressData copyWithCompanion(DeckCardProgressCompanion data) {
    return DeckCardProgressData(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      direction: data.direction.present ? data.direction.value : this.direction,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalIndex: data.intervalIndex.present
          ? data.intervalIndex.value
          : this.intervalIndex,
      introducedAt: data.introducedAt.present
          ? data.introducedAt.value
          : this.introducedAt,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckCardProgressData(')
          ..write('cardId: $cardId, ')
          ..write('direction: $direction, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalIndex: $intervalIndex, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('lastReviewed: $lastReviewed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    direction,
    dueAt,
    intervalIndex,
    introducedAt,
    lastReviewed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckCardProgressData &&
          other.cardId == this.cardId &&
          other.direction == this.direction &&
          other.dueAt == this.dueAt &&
          other.intervalIndex == this.intervalIndex &&
          other.introducedAt == this.introducedAt &&
          other.lastReviewed == this.lastReviewed);
}

class DeckCardProgressCompanion extends UpdateCompanion<DeckCardProgressData> {
  final Value<String> cardId;
  final Value<ReviewDirection> direction;
  final Value<DateTime?> dueAt;
  final Value<int> intervalIndex;
  final Value<DateTime?> introducedAt;
  final Value<DateTime?> lastReviewed;
  final Value<int> rowid;
  const DeckCardProgressCompanion({
    this.cardId = const Value.absent(),
    this.direction = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalIndex = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeckCardProgressCompanion.insert({
    required String cardId,
    required ReviewDirection direction,
    this.dueAt = const Value.absent(),
    this.intervalIndex = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       direction = Value(direction);
  static Insertable<DeckCardProgressData> custom({
    Expression<String>? cardId,
    Expression<String>? direction,
    Expression<DateTime>? dueAt,
    Expression<int>? intervalIndex,
    Expression<DateTime>? introducedAt,
    Expression<DateTime>? lastReviewed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (direction != null) 'direction': direction,
      if (dueAt != null) 'due_at': dueAt,
      if (intervalIndex != null) 'interval_index': intervalIndex,
      if (introducedAt != null) 'introduced_at': introducedAt,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeckCardProgressCompanion copyWith({
    Value<String>? cardId,
    Value<ReviewDirection>? direction,
    Value<DateTime?>? dueAt,
    Value<int>? intervalIndex,
    Value<DateTime?>? introducedAt,
    Value<DateTime?>? lastReviewed,
    Value<int>? rowid,
  }) {
    return DeckCardProgressCompanion(
      cardId: cardId ?? this.cardId,
      direction: direction ?? this.direction,
      dueAt: dueAt ?? this.dueAt,
      intervalIndex: intervalIndex ?? this.intervalIndex,
      introducedAt: introducedAt ?? this.introducedAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $DeckCardProgressTable.$converterdirection.toSql(direction.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (intervalIndex.present) {
      map['interval_index'] = Variable<int>(intervalIndex.value);
    }
    if (introducedAt.present) {
      map['introduced_at'] = Variable<DateTime>(introducedAt.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckCardProgressCompanion(')
          ..write('cardId: $cardId, ')
          ..write('direction: $direction, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalIndex: $intervalIndex, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, occurredAt, correct];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }
}

class ReviewEvent extends DataClass implements Insertable<ReviewEvent> {
  final int id;
  final DateTime occurredAt;
  final bool correct;
  const ReviewEvent({
    required this.id,
    required this.occurredAt,
    required this.correct,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['correct'] = Variable<bool>(correct);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      occurredAt: Value(occurredAt),
      correct: Value(correct),
    );
  }

  factory ReviewEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEvent(
      id: serializer.fromJson<int>(json['id']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      correct: serializer.fromJson<bool>(json['correct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'correct': serializer.toJson<bool>(correct),
    };
  }

  ReviewEvent copyWith({int? id, DateTime? occurredAt, bool? correct}) =>
      ReviewEvent(
        id: id ?? this.id,
        occurredAt: occurredAt ?? this.occurredAt,
        correct: correct ?? this.correct,
      );
  ReviewEvent copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEvent(
      id: data.id.present ? data.id.value : this.id,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      correct: data.correct.present ? data.correct.value : this.correct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEvent(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('correct: $correct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, occurredAt, correct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEvent &&
          other.id == this.id &&
          other.occurredAt == this.occurredAt &&
          other.correct == this.correct);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEvent> {
  final Value<int> id;
  final Value<DateTime> occurredAt;
  final Value<bool> correct;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.correct = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime occurredAt,
    required bool correct,
  }) : occurredAt = Value(occurredAt),
       correct = Value(correct);
  static Insertable<ReviewEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? occurredAt,
    Expression<bool>? correct,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (correct != null) 'correct': correct,
    });
  }

  ReviewEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? occurredAt,
    Value<bool>? correct,
  }) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      correct: correct ?? this.correct,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('correct: $correct')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CertificateType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CertificateType>($AchievementsTable.$convertertype);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    level,
    earnedAt,
    note,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: $AchievementsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}earned_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CertificateType, String, String> $convertertype =
      const EnumNameConverter<CertificateType>(CertificateType.values);
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final int id;
  final CertificateType type;
  final String level;
  final DateTime earnedAt;
  final String? note;

  /// Path to a photo of the physical certificate, copied into app storage
  /// (see AddAchievementDialog) so it survives past the picker's temp file.
  final String? imagePath;
  const Achievement({
    required this.id,
    required this.type,
    required this.level,
    required this.earnedAt,
    this.note,
    this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['type'] = Variable<String>(
        $AchievementsTable.$convertertype.toSql(type),
      );
    }
    map['level'] = Variable<String>(level);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      type: Value(type),
      level: Value(level),
      earnedAt: Value(earnedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<int>(json['id']),
      type: $AchievementsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      level: serializer.fromJson<String>(json['level']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
      note: serializer.fromJson<String?>(json['note']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(
        $AchievementsTable.$convertertype.toJson(type),
      ),
      'level': serializer.toJson<String>(level),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
      'note': serializer.toJson<String?>(note),
      'imagePath': serializer.toJson<String?>(imagePath),
    };
  }

  Achievement copyWith({
    int? id,
    CertificateType? type,
    String? level,
    DateTime? earnedAt,
    Value<String?> note = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
  }) => Achievement(
    id: id ?? this.id,
    type: type ?? this.type,
    level: level ?? this.level,
    earnedAt: earnedAt ?? this.earnedAt,
    note: note.present ? note.value : this.note,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      level: data.level.present ? data.level.value : this.level,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
      note: data.note.present ? data.note.value : this.note,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('level: $level, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, level, earnedAt, note, imagePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.type == this.type &&
          other.level == this.level &&
          other.earnedAt == this.earnedAt &&
          other.note == this.note &&
          other.imagePath == this.imagePath);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<int> id;
  final Value<CertificateType> type;
  final Value<String> level;
  final Value<DateTime> earnedAt;
  final Value<String?> note;
  final Value<String?> imagePath;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.level = const Value.absent(),
    this.earnedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
  });
  AchievementsCompanion.insert({
    this.id = const Value.absent(),
    required CertificateType type,
    required String level,
    required DateTime earnedAt,
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
  }) : type = Value(type),
       level = Value(level),
       earnedAt = Value(earnedAt);
  static Insertable<Achievement> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? level,
    Expression<DateTime>? earnedAt,
    Expression<String>? note,
    Expression<String>? imagePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (level != null) 'level': level,
      if (earnedAt != null) 'earned_at': earnedAt,
      if (note != null) 'note': note,
      if (imagePath != null) 'image_path': imagePath,
    });
  }

  AchievementsCompanion copyWith({
    Value<int>? id,
    Value<CertificateType>? type,
    Value<String>? level,
    Value<DateTime>? earnedAt,
    Value<String?>? note,
    Value<String?>? imagePath,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      level: level ?? this.level,
      earnedAt: earnedAt ?? this.earnedAt,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AchievementsTable.$convertertype.toSql(type.value),
      );
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('level: $level, ')
          ..write('earnedAt: $earnedAt, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newDeckCardsPerDayPerDirectionMeta =
      const VerificationMeta('newDeckCardsPerDayPerDirection');
  @override
  late final GeneratedColumn<int> newDeckCardsPerDayPerDirection =
      GeneratedColumn<int>(
        'new_deck_cards_per_day_per_direction',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _readerFontScaleMeta = const VerificationMeta(
    'readerFontScale',
  );
  @override
  late final GeneratedColumn<double> readerFontScale = GeneratedColumn<double>(
    'reader_font_scale',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    newDeckCardsPerDayPerDirection,
    readerFontScale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('new_deck_cards_per_day_per_direction')) {
      context.handle(
        _newDeckCardsPerDayPerDirectionMeta,
        newDeckCardsPerDayPerDirection.isAcceptableOrUnknown(
          data['new_deck_cards_per_day_per_direction']!,
          _newDeckCardsPerDayPerDirectionMeta,
        ),
      );
    }
    if (data.containsKey('reader_font_scale')) {
      context.handle(
        _readerFontScaleMeta,
        readerFontScale.isAcceptableOrUnknown(
          data['reader_font_scale']!,
          _readerFontScaleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      newDeckCardsPerDayPerDirection: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_deck_cards_per_day_per_direction'],
      ),
      readerFontScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reader_font_scale'],
      ),
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;

  /// User-facing override for [SrsConfig.kNewDeckCardsPerDayPerDirection].
  /// Null until the user changes it from the default in the Decks review UI.
  final int? newDeckCardsPerDayPerDirection;

  /// Multiplier applied to the story reader's base font size. Null until the
  /// user changes it from the default (1.0) in the reader's text-size
  /// control — kept separate from furigana visibility, which is a
  /// per-session toggle rather than a persisted preference.
  final double? readerFontScale;
  const UserSetting({
    required this.id,
    this.newDeckCardsPerDayPerDirection,
    this.readerFontScale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || newDeckCardsPerDayPerDirection != null) {
      map['new_deck_cards_per_day_per_direction'] = Variable<int>(
        newDeckCardsPerDayPerDirection,
      );
    }
    if (!nullToAbsent || readerFontScale != null) {
      map['reader_font_scale'] = Variable<double>(readerFontScale);
    }
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      newDeckCardsPerDayPerDirection:
          newDeckCardsPerDayPerDirection == null && nullToAbsent
          ? const Value.absent()
          : Value(newDeckCardsPerDayPerDirection),
      readerFontScale: readerFontScale == null && nullToAbsent
          ? const Value.absent()
          : Value(readerFontScale),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      newDeckCardsPerDayPerDirection: serializer.fromJson<int?>(
        json['newDeckCardsPerDayPerDirection'],
      ),
      readerFontScale: serializer.fromJson<double?>(json['readerFontScale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'newDeckCardsPerDayPerDirection': serializer.toJson<int?>(
        newDeckCardsPerDayPerDirection,
      ),
      'readerFontScale': serializer.toJson<double?>(readerFontScale),
    };
  }

  UserSetting copyWith({
    int? id,
    Value<int?> newDeckCardsPerDayPerDirection = const Value.absent(),
    Value<double?> readerFontScale = const Value.absent(),
  }) => UserSetting(
    id: id ?? this.id,
    newDeckCardsPerDayPerDirection: newDeckCardsPerDayPerDirection.present
        ? newDeckCardsPerDayPerDirection.value
        : this.newDeckCardsPerDayPerDirection,
    readerFontScale: readerFontScale.present
        ? readerFontScale.value
        : this.readerFontScale,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      newDeckCardsPerDayPerDirection:
          data.newDeckCardsPerDayPerDirection.present
          ? data.newDeckCardsPerDayPerDirection.value
          : this.newDeckCardsPerDayPerDirection,
      readerFontScale: data.readerFontScale.present
          ? data.readerFontScale.value
          : this.readerFontScale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write(
            'newDeckCardsPerDayPerDirection: $newDeckCardsPerDayPerDirection, ',
          )
          ..write('readerFontScale: $readerFontScale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, newDeckCardsPerDayPerDirection, readerFontScale);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.newDeckCardsPerDayPerDirection ==
              this.newDeckCardsPerDayPerDirection &&
          other.readerFontScale == this.readerFontScale);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<int?> newDeckCardsPerDayPerDirection;
  final Value<double?> readerFontScale;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.newDeckCardsPerDayPerDirection = const Value.absent(),
    this.readerFontScale = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.newDeckCardsPerDayPerDirection = const Value.absent(),
    this.readerFontScale = const Value.absent(),
  });
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<int>? newDeckCardsPerDayPerDirection,
    Expression<double>? readerFontScale,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (newDeckCardsPerDayPerDirection != null)
        'new_deck_cards_per_day_per_direction': newDeckCardsPerDayPerDirection,
      if (readerFontScale != null) 'reader_font_scale': readerFontScale,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<int?>? newDeckCardsPerDayPerDirection,
    Value<double?>? readerFontScale,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      newDeckCardsPerDayPerDirection:
          newDeckCardsPerDayPerDirection ?? this.newDeckCardsPerDayPerDirection,
      readerFontScale: readerFontScale ?? this.readerFontScale,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (newDeckCardsPerDayPerDirection.present) {
      map['new_deck_cards_per_day_per_direction'] = Variable<int>(
        newDeckCardsPerDayPerDirection.value,
      );
    }
    if (readerFontScale.present) {
      map['reader_font_scale'] = Variable<double>(readerFontScale.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write(
            'newDeckCardsPerDayPerDirection: $newDeckCardsPerDayPerDirection, ',
          )
          ..write('readerFontScale: $readerFontScale')
          ..write(')'))
        .toString();
  }
}

class $StoryProgressTable extends StoryProgress
    with TableInfo<$StoryProgressTable, StoryProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoryProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPageIndexMeta = const VerificationMeta(
    'lastPageIndex',
  );
  @override
  late final GeneratedColumn<int> lastPageIndex = GeneratedColumn<int>(
    'last_page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    storyId,
    lastPageIndex,
    completed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'story_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('last_page_index')) {
      context.handle(
        _lastPageIndexMeta,
        lastPageIndex.isAcceptableOrUnknown(
          data['last_page_index']!,
          _lastPageIndexMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {storyId};
  @override
  StoryProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryProgressData(
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story_id'],
      )!,
      lastPageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page_index'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StoryProgressTable createAlias(String alias) {
    return $StoryProgressTable(attachedDatabase, alias);
  }
}

class StoryProgressData extends DataClass
    implements Insertable<StoryProgressData> {
  final String storyId;
  final int lastPageIndex;
  final bool completed;
  final DateTime updatedAt;
  const StoryProgressData({
    required this.storyId,
    required this.lastPageIndex,
    required this.completed,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['story_id'] = Variable<String>(storyId);
    map['last_page_index'] = Variable<int>(lastPageIndex);
    map['completed'] = Variable<bool>(completed);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StoryProgressCompanion toCompanion(bool nullToAbsent) {
    return StoryProgressCompanion(
      storyId: Value(storyId),
      lastPageIndex: Value(lastPageIndex),
      completed: Value(completed),
      updatedAt: Value(updatedAt),
    );
  }

  factory StoryProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryProgressData(
      storyId: serializer.fromJson<String>(json['storyId']),
      lastPageIndex: serializer.fromJson<int>(json['lastPageIndex']),
      completed: serializer.fromJson<bool>(json['completed']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'storyId': serializer.toJson<String>(storyId),
      'lastPageIndex': serializer.toJson<int>(lastPageIndex),
      'completed': serializer.toJson<bool>(completed),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StoryProgressData copyWith({
    String? storyId,
    int? lastPageIndex,
    bool? completed,
    DateTime? updatedAt,
  }) => StoryProgressData(
    storyId: storyId ?? this.storyId,
    lastPageIndex: lastPageIndex ?? this.lastPageIndex,
    completed: completed ?? this.completed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StoryProgressData copyWithCompanion(StoryProgressCompanion data) {
    return StoryProgressData(
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      lastPageIndex: data.lastPageIndex.present
          ? data.lastPageIndex.value
          : this.lastPageIndex,
      completed: data.completed.present ? data.completed.value : this.completed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryProgressData(')
          ..write('storyId: $storyId, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(storyId, lastPageIndex, completed, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryProgressData &&
          other.storyId == this.storyId &&
          other.lastPageIndex == this.lastPageIndex &&
          other.completed == this.completed &&
          other.updatedAt == this.updatedAt);
}

class StoryProgressCompanion extends UpdateCompanion<StoryProgressData> {
  final Value<String> storyId;
  final Value<int> lastPageIndex;
  final Value<bool> completed;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StoryProgressCompanion({
    this.storyId = const Value.absent(),
    this.lastPageIndex = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoryProgressCompanion.insert({
    required String storyId,
    this.lastPageIndex = const Value.absent(),
    this.completed = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : storyId = Value(storyId),
       updatedAt = Value(updatedAt);
  static Insertable<StoryProgressData> custom({
    Expression<String>? storyId,
    Expression<int>? lastPageIndex,
    Expression<bool>? completed,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (storyId != null) 'story_id': storyId,
      if (lastPageIndex != null) 'last_page_index': lastPageIndex,
      if (completed != null) 'completed': completed,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoryProgressCompanion copyWith({
    Value<String>? storyId,
    Value<int>? lastPageIndex,
    Value<bool>? completed,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoryProgressCompanion(
      storyId: storyId ?? this.storyId,
      lastPageIndex: lastPageIndex ?? this.lastPageIndex,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (lastPageIndex.present) {
      map['last_page_index'] = Variable<int>(lastPageIndex.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoryProgressCompanion(')
          ..write('storyId: $storyId, ')
          ..write('lastPageIndex: $lastPageIndex, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DictionaryEntriesTable dictionaryEntries =
      $DictionaryEntriesTable(this);
  late final $UserWordsTable userWords = $UserWordsTable(this);
  late final $SeedMetaTable seedMeta = $SeedMetaTable(this);
  late final $DeckCardsTable deckCards = $DeckCardsTable(this);
  late final $DeckCardProgressTable deckCardProgress = $DeckCardProgressTable(
    this,
  );
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $StoryProgressTable storyProgress = $StoryProgressTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dictionaryEntries,
    userWords,
    seedMeta,
    deckCards,
    deckCardProgress,
    reviewEvents,
    achievements,
    userSettings,
    storyProgress,
  ];
}

typedef $$DictionaryEntriesTableCreateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      required String dictionaryForm,
      required String reading,
      required String meanings,
      required String partOfSpeech,
      Value<String?> jlptLevel,
      Value<int> rowid,
    });
typedef $$DictionaryEntriesTableUpdateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      Value<String> dictionaryForm,
      Value<String> reading,
      Value<String> meanings,
      Value<String> partOfSpeech,
      Value<String?> jlptLevel,
      Value<int> rowid,
    });

class $$DictionaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meanings => $composableBuilder(
    column: $table.meanings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jlptLevel => $composableBuilder(
    column: $table.jlptLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get meanings =>
      $composableBuilder(column: $table.meanings, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jlptLevel =>
      $composableBuilder(column: $table.jlptLevel, builder: (column) => column);
}

class $$DictionaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryEntriesTable,
          DictionaryEntry,
          $$DictionaryEntriesTableFilterComposer,
          $$DictionaryEntriesTableOrderingComposer,
          $$DictionaryEntriesTableAnnotationComposer,
          $$DictionaryEntriesTableCreateCompanionBuilder,
          $$DictionaryEntriesTableUpdateCompanionBuilder,
          (
            DictionaryEntry,
            BaseReferences<
              _$AppDatabase,
              $DictionaryEntriesTable,
              DictionaryEntry
            >,
          ),
          DictionaryEntry,
          PrefetchHooks Function()
        > {
  $$DictionaryEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> dictionaryForm = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> meanings = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String?> jlptLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryEntriesCompanion(
                dictionaryForm: dictionaryForm,
                reading: reading,
                meanings: meanings,
                partOfSpeech: partOfSpeech,
                jlptLevel: jlptLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dictionaryForm,
                required String reading,
                required String meanings,
                required String partOfSpeech,
                Value<String?> jlptLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryEntriesCompanion.insert(
                dictionaryForm: dictionaryForm,
                reading: reading,
                meanings: meanings,
                partOfSpeech: partOfSpeech,
                jlptLevel: jlptLevel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryEntriesTable,
      DictionaryEntry,
      $$DictionaryEntriesTableFilterComposer,
      $$DictionaryEntriesTableOrderingComposer,
      $$DictionaryEntriesTableAnnotationComposer,
      $$DictionaryEntriesTableCreateCompanionBuilder,
      $$DictionaryEntriesTableUpdateCompanionBuilder,
      (
        DictionaryEntry,
        BaseReferences<_$AppDatabase, $DictionaryEntriesTable, DictionaryEntry>,
      ),
      DictionaryEntry,
      PrefetchHooks Function()
    >;
typedef $$UserWordsTableCreateCompanionBuilder =
    UserWordsCompanion Function({
      required String dictionaryForm,
      required WordStatus status,
      Value<DateTime?> savedAt,
      required DateTime lastSeen,
      Value<DateTime?> srsDueAt,
      Value<int> srsInterval,
      Value<int> rowid,
    });
typedef $$UserWordsTableUpdateCompanionBuilder =
    UserWordsCompanion Function({
      Value<String> dictionaryForm,
      Value<WordStatus> status,
      Value<DateTime?> savedAt,
      Value<DateTime> lastSeen,
      Value<DateTime?> srsDueAt,
      Value<int> srsInterval,
      Value<int> rowid,
    });

class $$UserWordsTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WordStatus, WordStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get srsDueAt => $composableBuilder(
    column: $table.srsDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get srsInterval => $composableBuilder(
    column: $table.srsInterval,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
    column: $table.lastSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get srsDueAt => $composableBuilder(
    column: $table.srsDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get srsInterval => $composableBuilder(
    column: $table.srsInterval,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordsTable> {
  $$UserWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dictionaryForm => $composableBuilder(
    column: $table.dictionaryForm,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WordStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get srsDueAt =>
      $composableBuilder(column: $table.srsDueAt, builder: (column) => column);

  GeneratedColumn<int> get srsInterval => $composableBuilder(
    column: $table.srsInterval,
    builder: (column) => column,
  );
}

class $$UserWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserWordsTable,
          UserWord,
          $$UserWordsTableFilterComposer,
          $$UserWordsTableOrderingComposer,
          $$UserWordsTableAnnotationComposer,
          $$UserWordsTableCreateCompanionBuilder,
          $$UserWordsTableUpdateCompanionBuilder,
          (UserWord, BaseReferences<_$AppDatabase, $UserWordsTable, UserWord>),
          UserWord,
          PrefetchHooks Function()
        > {
  $$UserWordsTableTableManager(_$AppDatabase db, $UserWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dictionaryForm = const Value.absent(),
                Value<WordStatus> status = const Value.absent(),
                Value<DateTime?> savedAt = const Value.absent(),
                Value<DateTime> lastSeen = const Value.absent(),
                Value<DateTime?> srsDueAt = const Value.absent(),
                Value<int> srsInterval = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion(
                dictionaryForm: dictionaryForm,
                status: status,
                savedAt: savedAt,
                lastSeen: lastSeen,
                srsDueAt: srsDueAt,
                srsInterval: srsInterval,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dictionaryForm,
                required WordStatus status,
                Value<DateTime?> savedAt = const Value.absent(),
                required DateTime lastSeen,
                Value<DateTime?> srsDueAt = const Value.absent(),
                Value<int> srsInterval = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserWordsCompanion.insert(
                dictionaryForm: dictionaryForm,
                status: status,
                savedAt: savedAt,
                lastSeen: lastSeen,
                srsDueAt: srsDueAt,
                srsInterval: srsInterval,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserWordsTable,
      UserWord,
      $$UserWordsTableFilterComposer,
      $$UserWordsTableOrderingComposer,
      $$UserWordsTableAnnotationComposer,
      $$UserWordsTableCreateCompanionBuilder,
      $$UserWordsTableUpdateCompanionBuilder,
      (UserWord, BaseReferences<_$AppDatabase, $UserWordsTable, UserWord>),
      UserWord,
      PrefetchHooks Function()
    >;
typedef $$SeedMetaTableCreateCompanionBuilder =
    SeedMetaCompanion Function({Value<int> id, required int seededVersion});
typedef $$SeedMetaTableUpdateCompanionBuilder =
    SeedMetaCompanion Function({Value<int> id, Value<int> seededVersion});

class $$SeedMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SeedMetaTable> {
  $$SeedMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seededVersion => $composableBuilder(
    column: $table.seededVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeedMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SeedMetaTable> {
  $$SeedMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seededVersion => $composableBuilder(
    column: $table.seededVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeedMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeedMetaTable> {
  $$SeedMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seededVersion => $composableBuilder(
    column: $table.seededVersion,
    builder: (column) => column,
  );
}

class $$SeedMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeedMetaTable,
          SeedMetaData,
          $$SeedMetaTableFilterComposer,
          $$SeedMetaTableOrderingComposer,
          $$SeedMetaTableAnnotationComposer,
          $$SeedMetaTableCreateCompanionBuilder,
          $$SeedMetaTableUpdateCompanionBuilder,
          (
            SeedMetaData,
            BaseReferences<_$AppDatabase, $SeedMetaTable, SeedMetaData>,
          ),
          SeedMetaData,
          PrefetchHooks Function()
        > {
  $$SeedMetaTableTableManager(_$AppDatabase db, $SeedMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeedMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeedMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeedMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seededVersion = const Value.absent(),
              }) => SeedMetaCompanion(id: id, seededVersion: seededVersion),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seededVersion,
              }) => SeedMetaCompanion.insert(
                id: id,
                seededVersion: seededVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeedMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeedMetaTable,
      SeedMetaData,
      $$SeedMetaTableFilterComposer,
      $$SeedMetaTableOrderingComposer,
      $$SeedMetaTableAnnotationComposer,
      $$SeedMetaTableCreateCompanionBuilder,
      $$SeedMetaTableUpdateCompanionBuilder,
      (
        SeedMetaData,
        BaseReferences<_$AppDatabase, $SeedMetaTable, SeedMetaData>,
      ),
      SeedMetaData,
      PrefetchHooks Function()
    >;
typedef $$DeckCardsTableCreateCompanionBuilder =
    DeckCardsCompanion Function({
      required String id,
      required String deckId,
      required String level,
      required DeckCardType cardType,
      Value<String?> category,
      required String expression,
      required String reading,
      required String meaning,
      Value<String?> extra,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$DeckCardsTableUpdateCompanionBuilder =
    DeckCardsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> level,
      Value<DeckCardType> cardType,
      Value<String?> category,
      Value<String> expression,
      Value<String> reading,
      Value<String> meaning,
      Value<String?> extra,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$DeckCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DeckCardsTable> {
  $$DeckCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeckCardType, DeckCardType, String>
  get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeckCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeckCardsTable> {
  $$DeckCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reading => $composableBuilder(
    column: $table.reading,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeckCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeckCardsTable> {
  $$DeckCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeckCardType, String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get expression => $composableBuilder(
    column: $table.expression,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$DeckCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeckCardsTable,
          DeckCard,
          $$DeckCardsTableFilterComposer,
          $$DeckCardsTableOrderingComposer,
          $$DeckCardsTableAnnotationComposer,
          $$DeckCardsTableCreateCompanionBuilder,
          $$DeckCardsTableUpdateCompanionBuilder,
          (DeckCard, BaseReferences<_$AppDatabase, $DeckCardsTable, DeckCard>),
          DeckCard,
          PrefetchHooks Function()
        > {
  $$DeckCardsTableTableManager(_$AppDatabase db, $DeckCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeckCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeckCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeckCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<DeckCardType> cardType = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> expression = const Value.absent(),
                Value<String> reading = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeckCardsCompanion(
                id: id,
                deckId: deckId,
                level: level,
                cardType: cardType,
                category: category,
                expression: expression,
                reading: reading,
                meaning: meaning,
                extra: extra,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String level,
                required DeckCardType cardType,
                Value<String?> category = const Value.absent(),
                required String expression,
                required String reading,
                required String meaning,
                Value<String?> extra = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => DeckCardsCompanion.insert(
                id: id,
                deckId: deckId,
                level: level,
                cardType: cardType,
                category: category,
                expression: expression,
                reading: reading,
                meaning: meaning,
                extra: extra,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeckCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeckCardsTable,
      DeckCard,
      $$DeckCardsTableFilterComposer,
      $$DeckCardsTableOrderingComposer,
      $$DeckCardsTableAnnotationComposer,
      $$DeckCardsTableCreateCompanionBuilder,
      $$DeckCardsTableUpdateCompanionBuilder,
      (DeckCard, BaseReferences<_$AppDatabase, $DeckCardsTable, DeckCard>),
      DeckCard,
      PrefetchHooks Function()
    >;
typedef $$DeckCardProgressTableCreateCompanionBuilder =
    DeckCardProgressCompanion Function({
      required String cardId,
      required ReviewDirection direction,
      Value<DateTime?> dueAt,
      Value<int> intervalIndex,
      Value<DateTime?> introducedAt,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });
typedef $$DeckCardProgressTableUpdateCompanionBuilder =
    DeckCardProgressCompanion Function({
      Value<String> cardId,
      Value<ReviewDirection> direction,
      Value<DateTime?> dueAt,
      Value<int> intervalIndex,
      Value<DateTime?> introducedAt,
      Value<DateTime?> lastReviewed,
      Value<int> rowid,
    });

class $$DeckCardProgressTableFilterComposer
    extends Composer<_$AppDatabase, $DeckCardProgressTable> {
  $$DeckCardProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewDirection, ReviewDirection, String>
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeckCardProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $DeckCardProgressTable> {
  $$DeckCardProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeckCardProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeckCardProgressTable> {
  $$DeckCardProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReviewDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
    column: $table.lastReviewed,
    builder: (column) => column,
  );
}

class $$DeckCardProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeckCardProgressTable,
          DeckCardProgressData,
          $$DeckCardProgressTableFilterComposer,
          $$DeckCardProgressTableOrderingComposer,
          $$DeckCardProgressTableAnnotationComposer,
          $$DeckCardProgressTableCreateCompanionBuilder,
          $$DeckCardProgressTableUpdateCompanionBuilder,
          (
            DeckCardProgressData,
            BaseReferences<
              _$AppDatabase,
              $DeckCardProgressTable,
              DeckCardProgressData
            >,
          ),
          DeckCardProgressData,
          PrefetchHooks Function()
        > {
  $$DeckCardProgressTableTableManager(
    _$AppDatabase db,
    $DeckCardProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeckCardProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeckCardProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeckCardProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<ReviewDirection> direction = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> intervalIndex = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeckCardProgressCompanion(
                cardId: cardId,
                direction: direction,
                dueAt: dueAt,
                intervalIndex: intervalIndex,
                introducedAt: introducedAt,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cardId,
                required ReviewDirection direction,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> intervalIndex = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<DateTime?> lastReviewed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeckCardProgressCompanion.insert(
                cardId: cardId,
                direction: direction,
                dueAt: dueAt,
                intervalIndex: intervalIndex,
                introducedAt: introducedAt,
                lastReviewed: lastReviewed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeckCardProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeckCardProgressTable,
      DeckCardProgressData,
      $$DeckCardProgressTableFilterComposer,
      $$DeckCardProgressTableOrderingComposer,
      $$DeckCardProgressTableAnnotationComposer,
      $$DeckCardProgressTableCreateCompanionBuilder,
      $$DeckCardProgressTableUpdateCompanionBuilder,
      (
        DeckCardProgressData,
        BaseReferences<
          _$AppDatabase,
          $DeckCardProgressTable,
          DeckCardProgressData
        >,
      ),
      DeckCardProgressData,
      PrefetchHooks Function()
    >;
typedef $$ReviewEventsTableCreateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      required DateTime occurredAt,
      required bool correct,
    });
typedef $$ReviewEventsTableUpdateCompanionBuilder =
    ReviewEventsCompanion Function({
      Value<int> id,
      Value<DateTime> occurredAt,
      Value<bool> correct,
    });

class $$ReviewEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);
}

class $$ReviewEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewEventsTable,
          ReviewEvent,
          $$ReviewEventsTableFilterComposer,
          $$ReviewEventsTableOrderingComposer,
          $$ReviewEventsTableAnnotationComposer,
          $$ReviewEventsTableCreateCompanionBuilder,
          $$ReviewEventsTableUpdateCompanionBuilder,
          (
            ReviewEvent,
            BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent>,
          ),
          ReviewEvent,
          PrefetchHooks Function()
        > {
  $$ReviewEventsTableTableManager(_$AppDatabase db, $ReviewEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<bool> correct = const Value.absent(),
              }) => ReviewEventsCompanion(
                id: id,
                occurredAt: occurredAt,
                correct: correct,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime occurredAt,
                required bool correct,
              }) => ReviewEventsCompanion.insert(
                id: id,
                occurredAt: occurredAt,
                correct: correct,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewEventsTable,
      ReviewEvent,
      $$ReviewEventsTableFilterComposer,
      $$ReviewEventsTableOrderingComposer,
      $$ReviewEventsTableAnnotationComposer,
      $$ReviewEventsTableCreateCompanionBuilder,
      $$ReviewEventsTableUpdateCompanionBuilder,
      (
        ReviewEvent,
        BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent>,
      ),
      ReviewEvent,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      Value<int> id,
      required CertificateType type,
      required String level,
      required DateTime earnedAt,
      Value<String?> note,
      Value<String?> imagePath,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<int> id,
      Value<CertificateType> type,
      Value<String> level,
      Value<DateTime> earnedAt,
      Value<String?> note,
      Value<String?> imagePath,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CertificateType, CertificateType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CertificateType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<CertificateType> type = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                type: type,
                level: level,
                earnedAt: earnedAt,
                note: note,
                imagePath: imagePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required CertificateType type,
                required String level,
                required DateTime earnedAt,
                Value<String?> note = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                type: type,
                level: level,
                earnedAt: earnedAt,
                note: note,
                imagePath: imagePath,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int?> newDeckCardsPerDayPerDirection,
      Value<double?> readerFontScale,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<int?> newDeckCardsPerDayPerDirection,
      Value<double?> readerFontScale,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newDeckCardsPerDayPerDirection => $composableBuilder(
    column: $table.newDeckCardsPerDayPerDirection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readerFontScale => $composableBuilder(
    column: $table.readerFontScale,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newDeckCardsPerDayPerDirection => $composableBuilder(
    column: $table.newDeckCardsPerDayPerDirection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readerFontScale => $composableBuilder(
    column: $table.readerFontScale,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get newDeckCardsPerDayPerDirection => $composableBuilder(
    column: $table.newDeckCardsPerDayPerDirection,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readerFontScale => $composableBuilder(
    column: $table.readerFontScale,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> newDeckCardsPerDayPerDirection =
                    const Value.absent(),
                Value<double?> readerFontScale = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                newDeckCardsPerDayPerDirection: newDeckCardsPerDayPerDirection,
                readerFontScale: readerFontScale,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> newDeckCardsPerDayPerDirection =
                    const Value.absent(),
                Value<double?> readerFontScale = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                id: id,
                newDeckCardsPerDayPerDirection: newDeckCardsPerDayPerDirection,
                readerFontScale: readerFontScale,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$StoryProgressTableCreateCompanionBuilder =
    StoryProgressCompanion Function({
      required String storyId,
      Value<int> lastPageIndex,
      Value<bool> completed,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StoryProgressTableUpdateCompanionBuilder =
    StoryProgressCompanion Function({
      Value<String> storyId,
      Value<int> lastPageIndex,
      Value<bool> completed,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StoryProgressTableFilterComposer
    extends Composer<_$AppDatabase, $StoryProgressTable> {
  $$StoryProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPageIndex => $composableBuilder(
    column: $table.lastPageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoryProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $StoryProgressTable> {
  $$StoryProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get storyId => $composableBuilder(
    column: $table.storyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPageIndex => $composableBuilder(
    column: $table.lastPageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoryProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoryProgressTable> {
  $$StoryProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<int> get lastPageIndex => $composableBuilder(
    column: $table.lastPageIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StoryProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoryProgressTable,
          StoryProgressData,
          $$StoryProgressTableFilterComposer,
          $$StoryProgressTableOrderingComposer,
          $$StoryProgressTableAnnotationComposer,
          $$StoryProgressTableCreateCompanionBuilder,
          $$StoryProgressTableUpdateCompanionBuilder,
          (
            StoryProgressData,
            BaseReferences<
              _$AppDatabase,
              $StoryProgressTable,
              StoryProgressData
            >,
          ),
          StoryProgressData,
          PrefetchHooks Function()
        > {
  $$StoryProgressTableTableManager(_$AppDatabase db, $StoryProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoryProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoryProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoryProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> storyId = const Value.absent(),
                Value<int> lastPageIndex = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoryProgressCompanion(
                storyId: storyId,
                lastPageIndex: lastPageIndex,
                completed: completed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String storyId,
                Value<int> lastPageIndex = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StoryProgressCompanion.insert(
                storyId: storyId,
                lastPageIndex: lastPageIndex,
                completed: completed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoryProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoryProgressTable,
      StoryProgressData,
      $$StoryProgressTableFilterComposer,
      $$StoryProgressTableOrderingComposer,
      $$StoryProgressTableAnnotationComposer,
      $$StoryProgressTableCreateCompanionBuilder,
      $$StoryProgressTableUpdateCompanionBuilder,
      (
        StoryProgressData,
        BaseReferences<_$AppDatabase, $StoryProgressTable, StoryProgressData>,
      ),
      StoryProgressData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DictionaryEntriesTableTableManager get dictionaryEntries =>
      $$DictionaryEntriesTableTableManager(_db, _db.dictionaryEntries);
  $$UserWordsTableTableManager get userWords =>
      $$UserWordsTableTableManager(_db, _db.userWords);
  $$SeedMetaTableTableManager get seedMeta =>
      $$SeedMetaTableTableManager(_db, _db.seedMeta);
  $$DeckCardsTableTableManager get deckCards =>
      $$DeckCardsTableTableManager(_db, _db.deckCards);
  $$DeckCardProgressTableTableManager get deckCardProgress =>
      $$DeckCardProgressTableTableManager(_db, _db.deckCardProgress);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$StoryProgressTableTableManager get storyProgress =>
      $$StoryProgressTableTableManager(_db, _db.storyProgress);
}
