// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActiveMeta = const VerificationMeta(
    'lastActive',
  );
  @override
  late final GeneratedColumn<String> lastActive = GeneratedColumn<String>(
    'last_active',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playerId,
    name,
    createdAt,
    lastActive,
    accountId,
    avatarUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_active')) {
      context.handle(
        _lastActiveMeta,
        lastActive.isAcceptableOrUnknown(data['last_active']!, _lastActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_lastActiveMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      lastActive: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_active'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final String playerId;
  final String name;
  final String createdAt;
  final String lastActive;
  final String? accountId;
  final String? avatarUrl;
  const Player({
    required this.playerId,
    required this.name,
    required this.createdAt,
    required this.lastActive,
    this.accountId,
    this.avatarUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<String>(playerId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<String>(createdAt);
    map['last_active'] = Variable<String>(lastActive);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      playerId: Value(playerId),
      name: Value(name),
      createdAt: Value(createdAt),
      lastActive: Value(lastActive),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      playerId: serializer.fromJson<String>(json['playerId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      lastActive: serializer.fromJson<String>(json['lastActive']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<String>(playerId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String>(createdAt),
      'lastActive': serializer.toJson<String>(lastActive),
      'accountId': serializer.toJson<String?>(accountId),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
    };
  }

  Player copyWith({
    String? playerId,
    String? name,
    String? createdAt,
    String? lastActive,
    Value<String?> accountId = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
  }) => Player(
    playerId: playerId ?? this.playerId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    lastActive: lastActive ?? this.lastActive,
    accountId: accountId.present ? accountId.value : this.accountId,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActive: data.lastActive.present
          ? data.lastActive.value
          : this.lastActive,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('playerId: $playerId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActive: $lastActive, ')
          ..write('accountId: $accountId, ')
          ..write('avatarUrl: $avatarUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(playerId, name, createdAt, lastActive, accountId, avatarUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.playerId == this.playerId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.lastActive == this.lastActive &&
          other.accountId == this.accountId &&
          other.avatarUrl == this.avatarUrl);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<String> playerId;
  final Value<String> name;
  final Value<String> createdAt;
  final Value<String> lastActive;
  final Value<String?> accountId;
  final Value<String?> avatarUrl;
  final Value<int> rowid;
  const PlayersCompanion({
    this.playerId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActive = const Value.absent(),
    this.accountId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String playerId,
    required String name,
    required String createdAt,
    required String lastActive,
    this.accountId = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : playerId = Value(playerId),
       name = Value(name),
       createdAt = Value(createdAt),
       lastActive = Value(lastActive);
  static Insertable<Player> custom({
    Expression<String>? playerId,
    Expression<String>? name,
    Expression<String>? createdAt,
    Expression<String>? lastActive,
    Expression<String>? accountId,
    Expression<String>? avatarUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActive != null) 'last_active': lastActive,
      if (accountId != null) 'account_id': accountId,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? playerId,
    Value<String>? name,
    Value<String>? createdAt,
    Value<String>? lastActive,
    Value<String?>? accountId,
    Value<String?>? avatarUrl,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      accountId: accountId ?? this.accountId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastActive.present) {
      map['last_active'] = Variable<String>(lastActive.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('playerId: $playerId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActive: $lastActive, ')
          ..write('accountId: $accountId, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GamesTable extends Games with TableInfo<$GamesTable, Game> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameTypeMeta = const VerificationMeta(
    'gameType',
  );
  @override
  late final GeneratedColumn<String> gameType = GeneratedColumn<String>(
    'game_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winnerCompetitorIdMeta =
      const VerificationMeta('winnerCompetitorId');
  @override
  late final GeneratedColumn<String> winnerCompetitorId =
      GeneratedColumn<String>(
        'winner_competitor_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<int> isComplete = GeneratedColumn<int>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gameStateJsonMeta = const VerificationMeta(
    'gameStateJson',
  );
  @override
  late final GeneratedColumn<String> gameStateJson = GeneratedColumn<String>(
    'game_state_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameId,
    gameType,
    configJson,
    startTime,
    endTime,
    winnerCompetitorId,
    isComplete,
    gameStateJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<Game> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('game_type')) {
      context.handle(
        _gameTypeMeta,
        gameType.isAcceptableOrUnknown(data['game_type']!, _gameTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gameTypeMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('winner_competitor_id')) {
      context.handle(
        _winnerCompetitorIdMeta,
        winnerCompetitorId.isAcceptableOrUnknown(
          data['winner_competitor_id']!,
          _winnerCompetitorIdMeta,
        ),
      );
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    if (data.containsKey('game_state_json')) {
      context.handle(
        _gameStateJsonMeta,
        gameStateJson.isAcceptableOrUnknown(
          data['game_state_json']!,
          _gameStateJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameId};
  @override
  Game map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Game(
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      gameType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_type'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      winnerCompetitorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}winner_competitor_id'],
      ),
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_complete'],
      )!,
      gameStateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_state_json'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class Game extends DataClass implements Insertable<Game> {
  final String gameId;
  final String gameType;
  final String configJson;
  final String startTime;
  final String? endTime;
  final String? winnerCompetitorId;
  final int isComplete;
  final String? gameStateJson;
  const Game({
    required this.gameId,
    required this.gameType,
    required this.configJson,
    required this.startTime,
    this.endTime,
    this.winnerCompetitorId,
    required this.isComplete,
    this.gameStateJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_id'] = Variable<String>(gameId);
    map['game_type'] = Variable<String>(gameType);
    map['config_json'] = Variable<String>(configJson);
    map['start_time'] = Variable<String>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    if (!nullToAbsent || winnerCompetitorId != null) {
      map['winner_competitor_id'] = Variable<String>(winnerCompetitorId);
    }
    map['is_complete'] = Variable<int>(isComplete);
    if (!nullToAbsent || gameStateJson != null) {
      map['game_state_json'] = Variable<String>(gameStateJson);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      gameId: Value(gameId),
      gameType: Value(gameType),
      configJson: Value(configJson),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      winnerCompetitorId: winnerCompetitorId == null && nullToAbsent
          ? const Value.absent()
          : Value(winnerCompetitorId),
      isComplete: Value(isComplete),
      gameStateJson: gameStateJson == null && nullToAbsent
          ? const Value.absent()
          : Value(gameStateJson),
    );
  }

  factory Game.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Game(
      gameId: serializer.fromJson<String>(json['gameId']),
      gameType: serializer.fromJson<String>(json['gameType']),
      configJson: serializer.fromJson<String>(json['configJson']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      winnerCompetitorId: serializer.fromJson<String?>(
        json['winnerCompetitorId'],
      ),
      isComplete: serializer.fromJson<int>(json['isComplete']),
      gameStateJson: serializer.fromJson<String?>(json['gameStateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameId': serializer.toJson<String>(gameId),
      'gameType': serializer.toJson<String>(gameType),
      'configJson': serializer.toJson<String>(configJson),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'winnerCompetitorId': serializer.toJson<String?>(winnerCompetitorId),
      'isComplete': serializer.toJson<int>(isComplete),
      'gameStateJson': serializer.toJson<String?>(gameStateJson),
    };
  }

  Game copyWith({
    String? gameId,
    String? gameType,
    String? configJson,
    String? startTime,
    Value<String?> endTime = const Value.absent(),
    Value<String?> winnerCompetitorId = const Value.absent(),
    int? isComplete,
    Value<String?> gameStateJson = const Value.absent(),
  }) => Game(
    gameId: gameId ?? this.gameId,
    gameType: gameType ?? this.gameType,
    configJson: configJson ?? this.configJson,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    winnerCompetitorId: winnerCompetitorId.present
        ? winnerCompetitorId.value
        : this.winnerCompetitorId,
    isComplete: isComplete ?? this.isComplete,
    gameStateJson: gameStateJson.present
        ? gameStateJson.value
        : this.gameStateJson,
  );
  Game copyWithCompanion(GamesCompanion data) {
    return Game(
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      gameType: data.gameType.present ? data.gameType.value : this.gameType,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      winnerCompetitorId: data.winnerCompetitorId.present
          ? data.winnerCompetitorId.value
          : this.winnerCompetitorId,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
      gameStateJson: data.gameStateJson.present
          ? data.gameStateJson.value
          : this.gameStateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Game(')
          ..write('gameId: $gameId, ')
          ..write('gameType: $gameType, ')
          ..write('configJson: $configJson, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('winnerCompetitorId: $winnerCompetitorId, ')
          ..write('isComplete: $isComplete, ')
          ..write('gameStateJson: $gameStateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    gameId,
    gameType,
    configJson,
    startTime,
    endTime,
    winnerCompetitorId,
    isComplete,
    gameStateJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Game &&
          other.gameId == this.gameId &&
          other.gameType == this.gameType &&
          other.configJson == this.configJson &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.winnerCompetitorId == this.winnerCompetitorId &&
          other.isComplete == this.isComplete &&
          other.gameStateJson == this.gameStateJson);
}

class GamesCompanion extends UpdateCompanion<Game> {
  final Value<String> gameId;
  final Value<String> gameType;
  final Value<String> configJson;
  final Value<String> startTime;
  final Value<String?> endTime;
  final Value<String?> winnerCompetitorId;
  final Value<int> isComplete;
  final Value<String?> gameStateJson;
  final Value<int> rowid;
  const GamesCompanion({
    this.gameId = const Value.absent(),
    this.gameType = const Value.absent(),
    this.configJson = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.winnerCompetitorId = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.gameStateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GamesCompanion.insert({
    required String gameId,
    required String gameType,
    required String configJson,
    required String startTime,
    this.endTime = const Value.absent(),
    this.winnerCompetitorId = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.gameStateJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : gameId = Value(gameId),
       gameType = Value(gameType),
       configJson = Value(configJson),
       startTime = Value(startTime);
  static Insertable<Game> custom({
    Expression<String>? gameId,
    Expression<String>? gameType,
    Expression<String>? configJson,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? winnerCompetitorId,
    Expression<int>? isComplete,
    Expression<String>? gameStateJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameId != null) 'game_id': gameId,
      if (gameType != null) 'game_type': gameType,
      if (configJson != null) 'config_json': configJson,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (winnerCompetitorId != null)
        'winner_competitor_id': winnerCompetitorId,
      if (isComplete != null) 'is_complete': isComplete,
      if (gameStateJson != null) 'game_state_json': gameStateJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GamesCompanion copyWith({
    Value<String>? gameId,
    Value<String>? gameType,
    Value<String>? configJson,
    Value<String>? startTime,
    Value<String?>? endTime,
    Value<String?>? winnerCompetitorId,
    Value<int>? isComplete,
    Value<String?>? gameStateJson,
    Value<int>? rowid,
  }) {
    return GamesCompanion(
      gameId: gameId ?? this.gameId,
      gameType: gameType ?? this.gameType,
      configJson: configJson ?? this.configJson,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      winnerCompetitorId: winnerCompetitorId ?? this.winnerCompetitorId,
      isComplete: isComplete ?? this.isComplete,
      gameStateJson: gameStateJson ?? this.gameStateJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (gameType.present) {
      map['game_type'] = Variable<String>(gameType.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (winnerCompetitorId.present) {
      map['winner_competitor_id'] = Variable<String>(winnerCompetitorId.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<int>(isComplete.value);
    }
    if (gameStateJson.present) {
      map['game_state_json'] = Variable<String>(gameStateJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('gameId: $gameId, ')
          ..write('gameType: $gameType, ')
          ..write('configJson: $configJson, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('winnerCompetitorId: $winnerCompetitorId, ')
          ..write('isComplete: $isComplete, ')
          ..write('gameStateJson: $gameStateJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompetitorsTable extends Competitors
    with TableInfo<$CompetitorsTable, Competitor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompetitorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _competitorIdMeta = const VerificationMeta(
    'competitorId',
  );
  @override
  late final GeneratedColumn<String> competitorId = GeneratedColumn<String>(
    'competitor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [competitorId, gameId, type, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'competitors';
  @override
  VerificationContext validateIntegrity(
    Insertable<Competitor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('competitor_id')) {
      context.handle(
        _competitorIdMeta,
        competitorId.isAcceptableOrUnknown(
          data['competitor_id']!,
          _competitorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competitorIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {competitorId};
  @override
  Competitor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Competitor(
      competitorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competitor_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $CompetitorsTable createAlias(String alias) {
    return $CompetitorsTable(attachedDatabase, alias);
  }
}

class Competitor extends DataClass implements Insertable<Competitor> {
  final String competitorId;
  final String gameId;
  final String type;
  final String name;
  const Competitor({
    required this.competitorId,
    required this.gameId,
    required this.type,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['competitor_id'] = Variable<String>(competitorId);
    map['game_id'] = Variable<String>(gameId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    return map;
  }

  CompetitorsCompanion toCompanion(bool nullToAbsent) {
    return CompetitorsCompanion(
      competitorId: Value(competitorId),
      gameId: Value(gameId),
      type: Value(type),
      name: Value(name),
    );
  }

  factory Competitor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Competitor(
      competitorId: serializer.fromJson<String>(json['competitorId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'competitorId': serializer.toJson<String>(competitorId),
      'gameId': serializer.toJson<String>(gameId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
    };
  }

  Competitor copyWith({
    String? competitorId,
    String? gameId,
    String? type,
    String? name,
  }) => Competitor(
    competitorId: competitorId ?? this.competitorId,
    gameId: gameId ?? this.gameId,
    type: type ?? this.type,
    name: name ?? this.name,
  );
  Competitor copyWithCompanion(CompetitorsCompanion data) {
    return Competitor(
      competitorId: data.competitorId.present
          ? data.competitorId.value
          : this.competitorId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Competitor(')
          ..write('competitorId: $competitorId, ')
          ..write('gameId: $gameId, ')
          ..write('type: $type, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(competitorId, gameId, type, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Competitor &&
          other.competitorId == this.competitorId &&
          other.gameId == this.gameId &&
          other.type == this.type &&
          other.name == this.name);
}

class CompetitorsCompanion extends UpdateCompanion<Competitor> {
  final Value<String> competitorId;
  final Value<String> gameId;
  final Value<String> type;
  final Value<String> name;
  final Value<int> rowid;
  const CompetitorsCompanion({
    this.competitorId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompetitorsCompanion.insert({
    required String competitorId,
    required String gameId,
    required String type,
    required String name,
    this.rowid = const Value.absent(),
  }) : competitorId = Value(competitorId),
       gameId = Value(gameId),
       type = Value(type),
       name = Value(name);
  static Insertable<Competitor> custom({
    Expression<String>? competitorId,
    Expression<String>? gameId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (competitorId != null) 'competitor_id': competitorId,
      if (gameId != null) 'game_id': gameId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompetitorsCompanion copyWith({
    Value<String>? competitorId,
    Value<String>? gameId,
    Value<String>? type,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return CompetitorsCompanion(
      competitorId: competitorId ?? this.competitorId,
      gameId: gameId ?? this.gameId,
      type: type ?? this.type,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (competitorId.present) {
      map['competitor_id'] = Variable<String>(competitorId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompetitorsCompanion(')
          ..write('competitorId: $competitorId, ')
          ..write('gameId: $gameId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompetitorPlayersTable extends CompetitorPlayers
    with TableInfo<$CompetitorPlayersTable, CompetitorPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompetitorPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _competitorIdMeta = const VerificationMeta(
    'competitorId',
  );
  @override
  late final GeneratedColumn<String> competitorId = GeneratedColumn<String>(
    'competitor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rotationPositionMeta = const VerificationMeta(
    'rotationPosition',
  );
  @override
  late final GeneratedColumn<int> rotationPosition = GeneratedColumn<int>(
    'rotation_position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    competitorId,
    playerId,
    rotationPosition,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'competitor_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompetitorPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('competitor_id')) {
      context.handle(
        _competitorIdMeta,
        competitorId.isAcceptableOrUnknown(
          data['competitor_id']!,
          _competitorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competitorIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('rotation_position')) {
      context.handle(
        _rotationPositionMeta,
        rotationPosition.isAcceptableOrUnknown(
          data['rotation_position']!,
          _rotationPositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rotationPositionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {competitorId, playerId};
  @override
  CompetitorPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompetitorPlayer(
      competitorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competitor_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      rotationPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rotation_position'],
      )!,
    );
  }

  @override
  $CompetitorPlayersTable createAlias(String alias) {
    return $CompetitorPlayersTable(attachedDatabase, alias);
  }
}

class CompetitorPlayer extends DataClass
    implements Insertable<CompetitorPlayer> {
  final String competitorId;
  final String playerId;
  final int rotationPosition;
  const CompetitorPlayer({
    required this.competitorId,
    required this.playerId,
    required this.rotationPosition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['competitor_id'] = Variable<String>(competitorId);
    map['player_id'] = Variable<String>(playerId);
    map['rotation_position'] = Variable<int>(rotationPosition);
    return map;
  }

  CompetitorPlayersCompanion toCompanion(bool nullToAbsent) {
    return CompetitorPlayersCompanion(
      competitorId: Value(competitorId),
      playerId: Value(playerId),
      rotationPosition: Value(rotationPosition),
    );
  }

  factory CompetitorPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompetitorPlayer(
      competitorId: serializer.fromJson<String>(json['competitorId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      rotationPosition: serializer.fromJson<int>(json['rotationPosition']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'competitorId': serializer.toJson<String>(competitorId),
      'playerId': serializer.toJson<String>(playerId),
      'rotationPosition': serializer.toJson<int>(rotationPosition),
    };
  }

  CompetitorPlayer copyWith({
    String? competitorId,
    String? playerId,
    int? rotationPosition,
  }) => CompetitorPlayer(
    competitorId: competitorId ?? this.competitorId,
    playerId: playerId ?? this.playerId,
    rotationPosition: rotationPosition ?? this.rotationPosition,
  );
  CompetitorPlayer copyWithCompanion(CompetitorPlayersCompanion data) {
    return CompetitorPlayer(
      competitorId: data.competitorId.present
          ? data.competitorId.value
          : this.competitorId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      rotationPosition: data.rotationPosition.present
          ? data.rotationPosition.value
          : this.rotationPosition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompetitorPlayer(')
          ..write('competitorId: $competitorId, ')
          ..write('playerId: $playerId, ')
          ..write('rotationPosition: $rotationPosition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(competitorId, playerId, rotationPosition);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompetitorPlayer &&
          other.competitorId == this.competitorId &&
          other.playerId == this.playerId &&
          other.rotationPosition == this.rotationPosition);
}

class CompetitorPlayersCompanion extends UpdateCompanion<CompetitorPlayer> {
  final Value<String> competitorId;
  final Value<String> playerId;
  final Value<int> rotationPosition;
  final Value<int> rowid;
  const CompetitorPlayersCompanion({
    this.competitorId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.rotationPosition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompetitorPlayersCompanion.insert({
    required String competitorId,
    required String playerId,
    required int rotationPosition,
    this.rowid = const Value.absent(),
  }) : competitorId = Value(competitorId),
       playerId = Value(playerId),
       rotationPosition = Value(rotationPosition);
  static Insertable<CompetitorPlayer> custom({
    Expression<String>? competitorId,
    Expression<String>? playerId,
    Expression<int>? rotationPosition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (competitorId != null) 'competitor_id': competitorId,
      if (playerId != null) 'player_id': playerId,
      if (rotationPosition != null) 'rotation_position': rotationPosition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompetitorPlayersCompanion copyWith({
    Value<String>? competitorId,
    Value<String>? playerId,
    Value<int>? rotationPosition,
    Value<int>? rowid,
  }) {
    return CompetitorPlayersCompanion(
      competitorId: competitorId ?? this.competitorId,
      playerId: playerId ?? this.playerId,
      rotationPosition: rotationPosition ?? this.rotationPosition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (competitorId.present) {
      map['competitor_id'] = Variable<String>(competitorId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (rotationPosition.present) {
      map['rotation_position'] = Variable<int>(rotationPosition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompetitorPlayersCompanion(')
          ..write('competitorId: $competitorId, ')
          ..write('playerId: $playerId, ')
          ..write('rotationPosition: $rotationPosition, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DartThrowsTable extends DartThrows
    with TableInfo<$DartThrowsTable, DartThrow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DartThrowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dartIdMeta = const VerificationMeta('dartId');
  @override
  late final GeneratedColumn<String> dartId = GeneratedColumn<String>(
    'dart_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _competitorIdMeta = const VerificationMeta(
    'competitorId',
  );
  @override
  late final GeneratedColumn<String> competitorId = GeneratedColumn<String>(
    'competitor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnNumberMeta = const VerificationMeta(
    'turnNumber',
  );
  @override
  late final GeneratedColumn<int> turnNumber = GeneratedColumn<int>(
    'turn_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dartNumberMeta = const VerificationMeta(
    'dartNumber',
  );
  @override
  late final GeneratedColumn<int> dartNumber = GeneratedColumn<int>(
    'dart_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<String> segment = GeneratedColumn<String>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dartId,
    gameId,
    competitorId,
    playerId,
    turnNumber,
    dartNumber,
    segment,
    score,
    x,
    y,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dart_throws';
  @override
  VerificationContext validateIntegrity(
    Insertable<DartThrow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dart_id')) {
      context.handle(
        _dartIdMeta,
        dartId.isAcceptableOrUnknown(data['dart_id']!, _dartIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dartIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('competitor_id')) {
      context.handle(
        _competitorIdMeta,
        competitorId.isAcceptableOrUnknown(
          data['competitor_id']!,
          _competitorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_competitorIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('turn_number')) {
      context.handle(
        _turnNumberMeta,
        turnNumber.isAcceptableOrUnknown(data['turn_number']!, _turnNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_turnNumberMeta);
    }
    if (data.containsKey('dart_number')) {
      context.handle(
        _dartNumberMeta,
        dartNumber.isAcceptableOrUnknown(data['dart_number']!, _dartNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dartNumberMeta);
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dartId};
  @override
  DartThrow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DartThrow(
      dartId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dart_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      competitorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}competitor_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      turnNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}turn_number'],
      )!,
      dartNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dart_number'],
      )!,
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      ),
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      ),
    );
  }

  @override
  $DartThrowsTable createAlias(String alias) {
    return $DartThrowsTable(attachedDatabase, alias);
  }
}

class DartThrow extends DataClass implements Insertable<DartThrow> {
  final String dartId;
  final String gameId;
  final String competitorId;
  final String playerId;
  final int turnNumber;
  final int dartNumber;
  final String segment;
  final int score;
  final double? x;
  final double? y;
  const DartThrow({
    required this.dartId,
    required this.gameId,
    required this.competitorId,
    required this.playerId,
    required this.turnNumber,
    required this.dartNumber,
    required this.segment,
    required this.score,
    this.x,
    this.y,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dart_id'] = Variable<String>(dartId);
    map['game_id'] = Variable<String>(gameId);
    map['competitor_id'] = Variable<String>(competitorId);
    map['player_id'] = Variable<String>(playerId);
    map['turn_number'] = Variable<int>(turnNumber);
    map['dart_number'] = Variable<int>(dartNumber);
    map['segment'] = Variable<String>(segment);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    return map;
  }

  DartThrowsCompanion toCompanion(bool nullToAbsent) {
    return DartThrowsCompanion(
      dartId: Value(dartId),
      gameId: Value(gameId),
      competitorId: Value(competitorId),
      playerId: Value(playerId),
      turnNumber: Value(turnNumber),
      dartNumber: Value(dartNumber),
      segment: Value(segment),
      score: Value(score),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
    );
  }

  factory DartThrow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DartThrow(
      dartId: serializer.fromJson<String>(json['dartId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      competitorId: serializer.fromJson<String>(json['competitorId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      turnNumber: serializer.fromJson<int>(json['turnNumber']),
      dartNumber: serializer.fromJson<int>(json['dartNumber']),
      segment: serializer.fromJson<String>(json['segment']),
      score: serializer.fromJson<int>(json['score']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dartId': serializer.toJson<String>(dartId),
      'gameId': serializer.toJson<String>(gameId),
      'competitorId': serializer.toJson<String>(competitorId),
      'playerId': serializer.toJson<String>(playerId),
      'turnNumber': serializer.toJson<int>(turnNumber),
      'dartNumber': serializer.toJson<int>(dartNumber),
      'segment': serializer.toJson<String>(segment),
      'score': serializer.toJson<int>(score),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
    };
  }

  DartThrow copyWith({
    String? dartId,
    String? gameId,
    String? competitorId,
    String? playerId,
    int? turnNumber,
    int? dartNumber,
    String? segment,
    int? score,
    Value<double?> x = const Value.absent(),
    Value<double?> y = const Value.absent(),
  }) => DartThrow(
    dartId: dartId ?? this.dartId,
    gameId: gameId ?? this.gameId,
    competitorId: competitorId ?? this.competitorId,
    playerId: playerId ?? this.playerId,
    turnNumber: turnNumber ?? this.turnNumber,
    dartNumber: dartNumber ?? this.dartNumber,
    segment: segment ?? this.segment,
    score: score ?? this.score,
    x: x.present ? x.value : this.x,
    y: y.present ? y.value : this.y,
  );
  DartThrow copyWithCompanion(DartThrowsCompanion data) {
    return DartThrow(
      dartId: data.dartId.present ? data.dartId.value : this.dartId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      competitorId: data.competitorId.present
          ? data.competitorId.value
          : this.competitorId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      turnNumber: data.turnNumber.present
          ? data.turnNumber.value
          : this.turnNumber,
      dartNumber: data.dartNumber.present
          ? data.dartNumber.value
          : this.dartNumber,
      segment: data.segment.present ? data.segment.value : this.segment,
      score: data.score.present ? data.score.value : this.score,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DartThrow(')
          ..write('dartId: $dartId, ')
          ..write('gameId: $gameId, ')
          ..write('competitorId: $competitorId, ')
          ..write('playerId: $playerId, ')
          ..write('turnNumber: $turnNumber, ')
          ..write('dartNumber: $dartNumber, ')
          ..write('segment: $segment, ')
          ..write('score: $score, ')
          ..write('x: $x, ')
          ..write('y: $y')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dartId,
    gameId,
    competitorId,
    playerId,
    turnNumber,
    dartNumber,
    segment,
    score,
    x,
    y,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DartThrow &&
          other.dartId == this.dartId &&
          other.gameId == this.gameId &&
          other.competitorId == this.competitorId &&
          other.playerId == this.playerId &&
          other.turnNumber == this.turnNumber &&
          other.dartNumber == this.dartNumber &&
          other.segment == this.segment &&
          other.score == this.score &&
          other.x == this.x &&
          other.y == this.y);
}

class DartThrowsCompanion extends UpdateCompanion<DartThrow> {
  final Value<String> dartId;
  final Value<String> gameId;
  final Value<String> competitorId;
  final Value<String> playerId;
  final Value<int> turnNumber;
  final Value<int> dartNumber;
  final Value<String> segment;
  final Value<int> score;
  final Value<double?> x;
  final Value<double?> y;
  final Value<int> rowid;
  const DartThrowsCompanion({
    this.dartId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.competitorId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.turnNumber = const Value.absent(),
    this.dartNumber = const Value.absent(),
    this.segment = const Value.absent(),
    this.score = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DartThrowsCompanion.insert({
    required String dartId,
    required String gameId,
    required String competitorId,
    required String playerId,
    required int turnNumber,
    required int dartNumber,
    required String segment,
    required int score,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dartId = Value(dartId),
       gameId = Value(gameId),
       competitorId = Value(competitorId),
       playerId = Value(playerId),
       turnNumber = Value(turnNumber),
       dartNumber = Value(dartNumber),
       segment = Value(segment),
       score = Value(score);
  static Insertable<DartThrow> custom({
    Expression<String>? dartId,
    Expression<String>? gameId,
    Expression<String>? competitorId,
    Expression<String>? playerId,
    Expression<int>? turnNumber,
    Expression<int>? dartNumber,
    Expression<String>? segment,
    Expression<int>? score,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dartId != null) 'dart_id': dartId,
      if (gameId != null) 'game_id': gameId,
      if (competitorId != null) 'competitor_id': competitorId,
      if (playerId != null) 'player_id': playerId,
      if (turnNumber != null) 'turn_number': turnNumber,
      if (dartNumber != null) 'dart_number': dartNumber,
      if (segment != null) 'segment': segment,
      if (score != null) 'score': score,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DartThrowsCompanion copyWith({
    Value<String>? dartId,
    Value<String>? gameId,
    Value<String>? competitorId,
    Value<String>? playerId,
    Value<int>? turnNumber,
    Value<int>? dartNumber,
    Value<String>? segment,
    Value<int>? score,
    Value<double?>? x,
    Value<double?>? y,
    Value<int>? rowid,
  }) {
    return DartThrowsCompanion(
      dartId: dartId ?? this.dartId,
      gameId: gameId ?? this.gameId,
      competitorId: competitorId ?? this.competitorId,
      playerId: playerId ?? this.playerId,
      turnNumber: turnNumber ?? this.turnNumber,
      dartNumber: dartNumber ?? this.dartNumber,
      segment: segment ?? this.segment,
      score: score ?? this.score,
      x: x ?? this.x,
      y: y ?? this.y,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dartId.present) {
      map['dart_id'] = Variable<String>(dartId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (competitorId.present) {
      map['competitor_id'] = Variable<String>(competitorId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (turnNumber.present) {
      map['turn_number'] = Variable<int>(turnNumber.value);
    }
    if (dartNumber.present) {
      map['dart_number'] = Variable<int>(dartNumber.value);
    }
    if (segment.present) {
      map['segment'] = Variable<String>(segment.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DartThrowsCompanion(')
          ..write('dartId: $dartId, ')
          ..write('gameId: $gameId, ')
          ..write('competitorId: $competitorId, ')
          ..write('playerId: $playerId, ')
          ..write('turnNumber: $turnNumber, ')
          ..write('dartNumber: $dartNumber, ')
          ..write('segment: $segment, ')
          ..write('score: $score, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameEventsTable extends GameEvents
    with TableInfo<$GameEventsTable, GameEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSequenceMeta = const VerificationMeta(
    'localSequence',
  );
  @override
  late final GeneratedColumn<int> localSequence = GeneratedColumn<int>(
    'local_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<String> occurredAt = GeneratedColumn<String>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<int> synced = GeneratedColumn<int>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalSequenceMeta = const VerificationMeta(
    'globalSequence',
  );
  @override
  late final GeneratedColumn<int> globalSequence = GeneratedColumn<int>(
    'global_sequence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<int> source = GeneratedColumn<int>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    gameId,
    eventType,
    localSequence,
    occurredAt,
    payloadJson,
    synced,
    actorId,
    globalSequence,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('local_sequence')) {
      context.handle(
        _localSequenceMeta,
        localSequence.isAcceptableOrUnknown(
          data['local_sequence']!,
          _localSequenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localSequenceMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actorIdMeta);
    }
    if (data.containsKey('global_sequence')) {
      context.handle(
        _globalSequenceMeta,
        globalSequence.isAcceptableOrUnknown(
          data['global_sequence']!,
          _globalSequenceMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {gameId, localSequence},
  ];
  @override
  GameEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      localSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_sequence'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_at'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      )!,
      globalSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}global_sequence'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $GameEventsTable createAlias(String alias) {
    return $GameEventsTable(attachedDatabase, alias);
  }
}

class GameEvent extends DataClass implements Insertable<GameEvent> {
  final String eventId;
  final String gameId;
  final String eventType;
  final int localSequence;
  final String occurredAt;
  final String payloadJson;
  final int synced;
  final String actorId;
  final int? globalSequence;
  final int source;
  const GameEvent({
    required this.eventId,
    required this.gameId,
    required this.eventType,
    required this.localSequence,
    required this.occurredAt,
    required this.payloadJson,
    required this.synced,
    required this.actorId,
    this.globalSequence,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['game_id'] = Variable<String>(gameId);
    map['event_type'] = Variable<String>(eventType);
    map['local_sequence'] = Variable<int>(localSequence);
    map['occurred_at'] = Variable<String>(occurredAt);
    map['payload_json'] = Variable<String>(payloadJson);
    map['synced'] = Variable<int>(synced);
    map['actor_id'] = Variable<String>(actorId);
    if (!nullToAbsent || globalSequence != null) {
      map['global_sequence'] = Variable<int>(globalSequence);
    }
    map['source'] = Variable<int>(source);
    return map;
  }

  GameEventsCompanion toCompanion(bool nullToAbsent) {
    return GameEventsCompanion(
      eventId: Value(eventId),
      gameId: Value(gameId),
      eventType: Value(eventType),
      localSequence: Value(localSequence),
      occurredAt: Value(occurredAt),
      payloadJson: Value(payloadJson),
      synced: Value(synced),
      actorId: Value(actorId),
      globalSequence: globalSequence == null && nullToAbsent
          ? const Value.absent()
          : Value(globalSequence),
      source: Value(source),
    );
  }

  factory GameEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      localSequence: serializer.fromJson<int>(json['localSequence']),
      occurredAt: serializer.fromJson<String>(json['occurredAt']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      synced: serializer.fromJson<int>(json['synced']),
      actorId: serializer.fromJson<String>(json['actorId']),
      globalSequence: serializer.fromJson<int?>(json['globalSequence']),
      source: serializer.fromJson<int>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'gameId': serializer.toJson<String>(gameId),
      'eventType': serializer.toJson<String>(eventType),
      'localSequence': serializer.toJson<int>(localSequence),
      'occurredAt': serializer.toJson<String>(occurredAt),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'synced': serializer.toJson<int>(synced),
      'actorId': serializer.toJson<String>(actorId),
      'globalSequence': serializer.toJson<int?>(globalSequence),
      'source': serializer.toJson<int>(source),
    };
  }

  GameEvent copyWith({
    String? eventId,
    String? gameId,
    String? eventType,
    int? localSequence,
    String? occurredAt,
    String? payloadJson,
    int? synced,
    String? actorId,
    Value<int?> globalSequence = const Value.absent(),
    int? source,
  }) => GameEvent(
    eventId: eventId ?? this.eventId,
    gameId: gameId ?? this.gameId,
    eventType: eventType ?? this.eventType,
    localSequence: localSequence ?? this.localSequence,
    occurredAt: occurredAt ?? this.occurredAt,
    payloadJson: payloadJson ?? this.payloadJson,
    synced: synced ?? this.synced,
    actorId: actorId ?? this.actorId,
    globalSequence: globalSequence.present
        ? globalSequence.value
        : this.globalSequence,
    source: source ?? this.source,
  );
  GameEvent copyWithCompanion(GameEventsCompanion data) {
    return GameEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      localSequence: data.localSequence.present
          ? data.localSequence.value
          : this.localSequence,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      synced: data.synced.present ? data.synced.value : this.synced,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      globalSequence: data.globalSequence.present
          ? data.globalSequence.value
          : this.globalSequence,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameEvent(')
          ..write('eventId: $eventId, ')
          ..write('gameId: $gameId, ')
          ..write('eventType: $eventType, ')
          ..write('localSequence: $localSequence, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('synced: $synced, ')
          ..write('actorId: $actorId, ')
          ..write('globalSequence: $globalSequence, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    gameId,
    eventType,
    localSequence,
    occurredAt,
    payloadJson,
    synced,
    actorId,
    globalSequence,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameEvent &&
          other.eventId == this.eventId &&
          other.gameId == this.gameId &&
          other.eventType == this.eventType &&
          other.localSequence == this.localSequence &&
          other.occurredAt == this.occurredAt &&
          other.payloadJson == this.payloadJson &&
          other.synced == this.synced &&
          other.actorId == this.actorId &&
          other.globalSequence == this.globalSequence &&
          other.source == this.source);
}

class GameEventsCompanion extends UpdateCompanion<GameEvent> {
  final Value<String> eventId;
  final Value<String> gameId;
  final Value<String> eventType;
  final Value<int> localSequence;
  final Value<String> occurredAt;
  final Value<String> payloadJson;
  final Value<int> synced;
  final Value<String> actorId;
  final Value<int?> globalSequence;
  final Value<int> source;
  final Value<int> rowid;
  const GameEventsCompanion({
    this.eventId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.localSequence = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.synced = const Value.absent(),
    this.actorId = const Value.absent(),
    this.globalSequence = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameEventsCompanion.insert({
    required String eventId,
    required String gameId,
    required String eventType,
    required int localSequence,
    required String occurredAt,
    required String payloadJson,
    this.synced = const Value.absent(),
    required String actorId,
    this.globalSequence = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       gameId = Value(gameId),
       eventType = Value(eventType),
       localSequence = Value(localSequence),
       occurredAt = Value(occurredAt),
       payloadJson = Value(payloadJson),
       actorId = Value(actorId);
  static Insertable<GameEvent> custom({
    Expression<String>? eventId,
    Expression<String>? gameId,
    Expression<String>? eventType,
    Expression<int>? localSequence,
    Expression<String>? occurredAt,
    Expression<String>? payloadJson,
    Expression<int>? synced,
    Expression<String>? actorId,
    Expression<int>? globalSequence,
    Expression<int>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (gameId != null) 'game_id': gameId,
      if (eventType != null) 'event_type': eventType,
      if (localSequence != null) 'local_sequence': localSequence,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (synced != null) 'synced': synced,
      if (actorId != null) 'actor_id': actorId,
      if (globalSequence != null) 'global_sequence': globalSequence,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? gameId,
    Value<String>? eventType,
    Value<int>? localSequence,
    Value<String>? occurredAt,
    Value<String>? payloadJson,
    Value<int>? synced,
    Value<String>? actorId,
    Value<int?>? globalSequence,
    Value<int>? source,
    Value<int>? rowid,
  }) {
    return GameEventsCompanion(
      eventId: eventId ?? this.eventId,
      gameId: gameId ?? this.gameId,
      eventType: eventType ?? this.eventType,
      localSequence: localSequence ?? this.localSequence,
      occurredAt: occurredAt ?? this.occurredAt,
      payloadJson: payloadJson ?? this.payloadJson,
      synced: synced ?? this.synced,
      actorId: actorId ?? this.actorId,
      globalSequence: globalSequence ?? this.globalSequence,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (localSequence.present) {
      map['local_sequence'] = Variable<int>(localSequence.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(occurredAt.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (synced.present) {
      map['synced'] = Variable<int>(synced.value);
    }
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (globalSequence.present) {
      map['global_sequence'] = Variable<int>(globalSequence.value);
    }
    if (source.present) {
      map['source'] = Variable<int>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('gameId: $gameId, ')
          ..write('eventType: $eventType, ')
          ..write('localSequence: $localSequence, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('synced: $synced, ')
          ..write('actorId: $actorId, ')
          ..write('globalSequence: $globalSequence, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refreshTokenMeta = const VerificationMeta(
    'refreshToken',
  );
  @override
  late final GeneratedColumn<String> refreshToken = GeneratedColumn<String>(
    'refresh_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backendUrlMeta = const VerificationMeta(
    'backendUrl',
  );
  @override
  late final GeneratedColumn<String> backendUrl = GeneratedColumn<String>(
    'backend_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<String> lastLoginAt = GeneratedColumn<String>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    email,
    accessToken,
    refreshToken,
    backendUrl,
    createdAt,
    lastLoginAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    }
    if (data.containsKey('refresh_token')) {
      context.handle(
        _refreshTokenMeta,
        refreshToken.isAcceptableOrUnknown(
          data['refresh_token']!,
          _refreshTokenMeta,
        ),
      );
    }
    if (data.containsKey('backend_url')) {
      context.handle(
        _backendUrlMeta,
        backendUrl.isAcceptableOrUnknown(data['backend_url']!, _backendUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_backendUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      ),
      refreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_token'],
      ),
      backendUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend_url'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_login_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String accountId;
  final String email;
  final String? accessToken;
  final String? refreshToken;
  final String backendUrl;
  final String createdAt;
  final String? lastLoginAt;
  const Account({
    required this.accountId,
    required this.email,
    this.accessToken,
    this.refreshToken,
    required this.backendUrl,
    required this.createdAt,
    this.lastLoginAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || accessToken != null) {
      map['access_token'] = Variable<String>(accessToken);
    }
    if (!nullToAbsent || refreshToken != null) {
      map['refresh_token'] = Variable<String>(refreshToken);
    }
    map['backend_url'] = Variable<String>(backendUrl);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<String>(lastLoginAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      accountId: Value(accountId),
      email: Value(email),
      accessToken: accessToken == null && nullToAbsent
          ? const Value.absent()
          : Value(accessToken),
      refreshToken: refreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshToken),
      backendUrl: Value(backendUrl),
      createdAt: Value(createdAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      accountId: serializer.fromJson<String>(json['accountId']),
      email: serializer.fromJson<String>(json['email']),
      accessToken: serializer.fromJson<String?>(json['accessToken']),
      refreshToken: serializer.fromJson<String?>(json['refreshToken']),
      backendUrl: serializer.fromJson<String>(json['backendUrl']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      lastLoginAt: serializer.fromJson<String?>(json['lastLoginAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'email': serializer.toJson<String>(email),
      'accessToken': serializer.toJson<String?>(accessToken),
      'refreshToken': serializer.toJson<String?>(refreshToken),
      'backendUrl': serializer.toJson<String>(backendUrl),
      'createdAt': serializer.toJson<String>(createdAt),
      'lastLoginAt': serializer.toJson<String?>(lastLoginAt),
    };
  }

  Account copyWith({
    String? accountId,
    String? email,
    Value<String?> accessToken = const Value.absent(),
    Value<String?> refreshToken = const Value.absent(),
    String? backendUrl,
    String? createdAt,
    Value<String?> lastLoginAt = const Value.absent(),
  }) => Account(
    accountId: accountId ?? this.accountId,
    email: email ?? this.email,
    accessToken: accessToken.present ? accessToken.value : this.accessToken,
    refreshToken: refreshToken.present ? refreshToken.value : this.refreshToken,
    backendUrl: backendUrl ?? this.backendUrl,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      email: data.email.present ? data.email.value : this.email,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      refreshToken: data.refreshToken.present
          ? data.refreshToken.value
          : this.refreshToken,
      backendUrl: data.backendUrl.present
          ? data.backendUrl.value
          : this.backendUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('backendUrl: $backendUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    email,
    accessToken,
    refreshToken,
    backendUrl,
    createdAt,
    lastLoginAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.accountId == this.accountId &&
          other.email == this.email &&
          other.accessToken == this.accessToken &&
          other.refreshToken == this.refreshToken &&
          other.backendUrl == this.backendUrl &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> accountId;
  final Value<String> email;
  final Value<String?> accessToken;
  final Value<String?> refreshToken;
  final Value<String> backendUrl;
  final Value<String> createdAt;
  final Value<String?> lastLoginAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.accountId = const Value.absent(),
    this.email = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.backendUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String accountId,
    required String email,
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    required String backendUrl,
    required String createdAt,
    this.lastLoginAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       email = Value(email),
       backendUrl = Value(backendUrl),
       createdAt = Value(createdAt);
  static Insertable<Account> custom({
    Expression<String>? accountId,
    Expression<String>? email,
    Expression<String>? accessToken,
    Expression<String>? refreshToken,
    Expression<String>? backendUrl,
    Expression<String>? createdAt,
    Expression<String>? lastLoginAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (email != null) 'email': email,
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (backendUrl != null) 'backend_url': backendUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? email,
    Value<String?>? accessToken,
    Value<String?>? refreshToken,
    Value<String>? backendUrl,
    Value<String>? createdAt,
    Value<String?>? lastLoginAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      backendUrl: backendUrl ?? this.backendUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (refreshToken.present) {
      map['refresh_token'] = Variable<String>(refreshToken.value);
    }
    if (backendUrl.present) {
      map['backend_url'] = Variable<String>(backendUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<String>(lastLoginAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('backendUrl: $backendUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptMeta = const VerificationMeta(
    'lastAttempt',
  );
  @override
  late final GeneratedColumn<String> lastAttempt = GeneratedColumn<String>(
    'last_attempt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    entityType,
    entityId,
    operationType,
    payloadJson,
    status,
    attemptCount,
    createdAt,
    lastAttempt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
        _lastAttemptMeta,
        lastAttempt.isAcceptableOrUnknown(
          data['last_attempt']!,
          _lastAttemptMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_attempt'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String operationId;
  final String entityType;
  final String entityId;
  final String operationType;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final String createdAt;
  final String? lastAttempt;
  final String? errorMessage;
  const SyncQueueData({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttempt,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<String>(lastAttempt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      operationId: Value(operationId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      createdAt: Value(createdAt),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      operationId: serializer.fromJson<String>(json['operationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      lastAttempt: serializer.fromJson<String?>(json['lastAttempt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'createdAt': serializer.toJson<String>(createdAt),
      'lastAttempt': serializer.toJson<String?>(lastAttempt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncQueueData copyWith({
    String? operationId,
    String? entityType,
    String? entityId,
    String? operationType,
    String? payloadJson,
    String? status,
    int? attemptCount,
    String? createdAt,
    Value<String?> lastAttempt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncQueueData(
    operationId: operationId ?? this.operationId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttempt: data.lastAttempt.present
          ? data.lastAttempt.value
          : this.lastAttempt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    entityId,
    operationType,
    payloadJson,
    status,
    attemptCount,
    createdAt,
    lastAttempt,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.operationId == this.operationId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.createdAt == this.createdAt &&
          other.lastAttempt == this.lastAttempt &&
          other.errorMessage == this.errorMessage);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> operationId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<String> createdAt;
  final Value<String?> lastAttempt;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.operationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadJson,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    required String createdAt,
    this.lastAttempt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? operationId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<String>? createdAt,
    Expression<String>? lastAttempt,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? operationId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<String>? createdAt,
    Value<String?>? lastAttempt,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<String>(lastAttempt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('operationId: $operationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameSessionsTable extends GameSessions
    with TableInfo<$GameSessionsTable, GameSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostPlayerIdMeta = const VerificationMeta(
    'hostPlayerId',
  );
  @override
  late final GeneratedColumn<String> hostPlayerId = GeneratedColumn<String>(
    'host_player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentTurnPlayerIdMeta =
      const VerificationMeta('currentTurnPlayerId');
  @override
  late final GeneratedColumn<String> currentTurnPlayerId =
      GeneratedColumn<String>(
        'current_turn_player_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    gameId,
    hostPlayerId,
    status,
    createdAt,
    startedAt,
    completedAt,
    currentTurnPlayerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('host_player_id')) {
      context.handle(
        _hostPlayerIdMeta,
        hostPlayerId.isAcceptableOrUnknown(
          data['host_player_id']!,
          _hostPlayerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hostPlayerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('current_turn_player_id')) {
      context.handle(
        _currentTurnPlayerIdMeta,
        currentTurnPlayerId.isAcceptableOrUnknown(
          data['current_turn_player_id']!,
          _currentTurnPlayerIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  GameSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameSession(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      hostPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host_player_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      currentTurnPlayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_turn_player_id'],
      ),
    );
  }

  @override
  $GameSessionsTable createAlias(String alias) {
    return $GameSessionsTable(attachedDatabase, alias);
  }
}

class GameSession extends DataClass implements Insertable<GameSession> {
  final String sessionId;
  final String gameId;
  final String hostPlayerId;
  final String status;
  final String createdAt;
  final String? startedAt;
  final String? completedAt;
  final String? currentTurnPlayerId;
  const GameSession({
    required this.sessionId,
    required this.gameId,
    required this.hostPlayerId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.currentTurnPlayerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['game_id'] = Variable<String>(gameId);
    map['host_player_id'] = Variable<String>(hostPlayerId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<String>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    if (!nullToAbsent || currentTurnPlayerId != null) {
      map['current_turn_player_id'] = Variable<String>(currentTurnPlayerId);
    }
    return map;
  }

  GameSessionsCompanion toCompanion(bool nullToAbsent) {
    return GameSessionsCompanion(
      sessionId: Value(sessionId),
      gameId: Value(gameId),
      hostPlayerId: Value(hostPlayerId),
      status: Value(status),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      currentTurnPlayerId: currentTurnPlayerId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentTurnPlayerId),
    );
  }

  factory GameSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameSession(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      hostPlayerId: serializer.fromJson<String>(json['hostPlayerId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      startedAt: serializer.fromJson<String?>(json['startedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      currentTurnPlayerId: serializer.fromJson<String?>(
        json['currentTurnPlayerId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'gameId': serializer.toJson<String>(gameId),
      'hostPlayerId': serializer.toJson<String>(hostPlayerId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
      'startedAt': serializer.toJson<String?>(startedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
      'currentTurnPlayerId': serializer.toJson<String?>(currentTurnPlayerId),
    };
  }

  GameSession copyWith({
    String? sessionId,
    String? gameId,
    String? hostPlayerId,
    String? status,
    String? createdAt,
    Value<String?> startedAt = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
    Value<String?> currentTurnPlayerId = const Value.absent(),
  }) => GameSession(
    sessionId: sessionId ?? this.sessionId,
    gameId: gameId ?? this.gameId,
    hostPlayerId: hostPlayerId ?? this.hostPlayerId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    currentTurnPlayerId: currentTurnPlayerId.present
        ? currentTurnPlayerId.value
        : this.currentTurnPlayerId,
  );
  GameSession copyWithCompanion(GameSessionsCompanion data) {
    return GameSession(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      hostPlayerId: data.hostPlayerId.present
          ? data.hostPlayerId.value
          : this.hostPlayerId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      currentTurnPlayerId: data.currentTurnPlayerId.present
          ? data.currentTurnPlayerId.value
          : this.currentTurnPlayerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameSession(')
          ..write('sessionId: $sessionId, ')
          ..write('gameId: $gameId, ')
          ..write('hostPlayerId: $hostPlayerId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('currentTurnPlayerId: $currentTurnPlayerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    gameId,
    hostPlayerId,
    status,
    createdAt,
    startedAt,
    completedAt,
    currentTurnPlayerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameSession &&
          other.sessionId == this.sessionId &&
          other.gameId == this.gameId &&
          other.hostPlayerId == this.hostPlayerId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.currentTurnPlayerId == this.currentTurnPlayerId);
}

class GameSessionsCompanion extends UpdateCompanion<GameSession> {
  final Value<String> sessionId;
  final Value<String> gameId;
  final Value<String> hostPlayerId;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String?> startedAt;
  final Value<String?> completedAt;
  final Value<String?> currentTurnPlayerId;
  final Value<int> rowid;
  const GameSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.hostPlayerId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.currentTurnPlayerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameSessionsCompanion.insert({
    required String sessionId,
    required String gameId,
    required String hostPlayerId,
    required String status,
    required String createdAt,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.currentTurnPlayerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       gameId = Value(gameId),
       hostPlayerId = Value(hostPlayerId),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<GameSession> custom({
    Expression<String>? sessionId,
    Expression<String>? gameId,
    Expression<String>? hostPlayerId,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? startedAt,
    Expression<String>? completedAt,
    Expression<String>? currentTurnPlayerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (gameId != null) 'game_id': gameId,
      if (hostPlayerId != null) 'host_player_id': hostPlayerId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (currentTurnPlayerId != null)
        'current_turn_player_id': currentTurnPlayerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameSessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? gameId,
    Value<String>? hostPlayerId,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String?>? startedAt,
    Value<String?>? completedAt,
    Value<String?>? currentTurnPlayerId,
    Value<int>? rowid,
  }) {
    return GameSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      hostPlayerId: hostPlayerId ?? this.hostPlayerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (hostPlayerId.present) {
      map['host_player_id'] = Variable<String>(hostPlayerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (currentTurnPlayerId.present) {
      map['current_turn_player_id'] = Variable<String>(
        currentTurnPlayerId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('gameId: $gameId, ')
          ..write('hostPlayerId: $hostPlayerId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('currentTurnPlayerId: $currentTurnPlayerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $GamesTable games = $GamesTable(this);
  late final $CompetitorsTable competitors = $CompetitorsTable(this);
  late final $CompetitorPlayersTable competitorPlayers =
      $CompetitorPlayersTable(this);
  late final $DartThrowsTable dartThrows = $DartThrowsTable(this);
  late final $GameEventsTable gameEvents = $GameEventsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $GameSessionsTable gameSessions = $GameSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    games,
    competitors,
    competitorPlayers,
    dartThrows,
    gameEvents,
    accounts,
    syncQueue,
    gameSessions,
  ];
}

typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      required String playerId,
      required String name,
      required String createdAt,
      required String lastActive,
      Value<String?> accountId,
      Value<String?> avatarUrl,
      Value<int> rowid,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> playerId,
      Value<String> name,
      Value<String> createdAt,
      Value<String> lastActive,
      Value<String?> accountId,
      Value<String?> avatarUrl,
      Value<int> rowid,
    });

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastActive => $composableBuilder(
    column: $table.lastActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastActive => $composableBuilder(
    column: $table.lastActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastActive => $composableBuilder(
    column: $table.lastActive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
          Player,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> lastActive = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                playerId: playerId,
                name: name,
                createdAt: createdAt,
                lastActive: lastActive,
                accountId: accountId,
                avatarUrl: avatarUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playerId,
                required String name,
                required String createdAt,
                required String lastActive,
                Value<String?> accountId = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                playerId: playerId,
                name: name,
                createdAt: createdAt,
                lastActive: lastActive,
                accountId: accountId,
                avatarUrl: avatarUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
      Player,
      PrefetchHooks Function()
    >;
typedef $$GamesTableCreateCompanionBuilder =
    GamesCompanion Function({
      required String gameId,
      required String gameType,
      required String configJson,
      required String startTime,
      Value<String?> endTime,
      Value<String?> winnerCompetitorId,
      Value<int> isComplete,
      Value<String?> gameStateJson,
      Value<int> rowid,
    });
typedef $$GamesTableUpdateCompanionBuilder =
    GamesCompanion Function({
      Value<String> gameId,
      Value<String> gameType,
      Value<String> configJson,
      Value<String> startTime,
      Value<String?> endTime,
      Value<String?> winnerCompetitorId,
      Value<int> isComplete,
      Value<String?> gameStateJson,
      Value<int> rowid,
    });

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get winnerCompetitorId => $composableBuilder(
    column: $table.winnerCompetitorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameStateJson => $composableBuilder(
    column: $table.gameStateJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameType => $composableBuilder(
    column: $table.gameType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get winnerCompetitorId => $composableBuilder(
    column: $table.winnerCompetitorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameStateJson => $composableBuilder(
    column: $table.gameStateJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get gameType =>
      $composableBuilder(column: $table.gameType, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get winnerCompetitorId => $composableBuilder(
    column: $table.winnerCompetitorId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gameStateJson => $composableBuilder(
    column: $table.gameStateJson,
    builder: (column) => column,
  );
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          Game,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (Game, BaseReferences<_$AppDatabase, $GamesTable, Game>),
          Game,
          PrefetchHooks Function()
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> gameId = const Value.absent(),
                Value<String> gameType = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String?> winnerCompetitorId = const Value.absent(),
                Value<int> isComplete = const Value.absent(),
                Value<String?> gameStateJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion(
                gameId: gameId,
                gameType: gameType,
                configJson: configJson,
                startTime: startTime,
                endTime: endTime,
                winnerCompetitorId: winnerCompetitorId,
                isComplete: isComplete,
                gameStateJson: gameStateJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gameId,
                required String gameType,
                required String configJson,
                required String startTime,
                Value<String?> endTime = const Value.absent(),
                Value<String?> winnerCompetitorId = const Value.absent(),
                Value<int> isComplete = const Value.absent(),
                Value<String?> gameStateJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GamesCompanion.insert(
                gameId: gameId,
                gameType: gameType,
                configJson: configJson,
                startTime: startTime,
                endTime: endTime,
                winnerCompetitorId: winnerCompetitorId,
                isComplete: isComplete,
                gameStateJson: gameStateJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      Game,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (Game, BaseReferences<_$AppDatabase, $GamesTable, Game>),
      Game,
      PrefetchHooks Function()
    >;
typedef $$CompetitorsTableCreateCompanionBuilder =
    CompetitorsCompanion Function({
      required String competitorId,
      required String gameId,
      required String type,
      required String name,
      Value<int> rowid,
    });
typedef $$CompetitorsTableUpdateCompanionBuilder =
    CompetitorsCompanion Function({
      Value<String> competitorId,
      Value<String> gameId,
      Value<String> type,
      Value<String> name,
      Value<int> rowid,
    });

class $$CompetitorsTableFilterComposer
    extends Composer<_$AppDatabase, $CompetitorsTable> {
  $$CompetitorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompetitorsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompetitorsTable> {
  $$CompetitorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompetitorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompetitorsTable> {
  $$CompetitorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$CompetitorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompetitorsTable,
          Competitor,
          $$CompetitorsTableFilterComposer,
          $$CompetitorsTableOrderingComposer,
          $$CompetitorsTableAnnotationComposer,
          $$CompetitorsTableCreateCompanionBuilder,
          $$CompetitorsTableUpdateCompanionBuilder,
          (
            Competitor,
            BaseReferences<_$AppDatabase, $CompetitorsTable, Competitor>,
          ),
          Competitor,
          PrefetchHooks Function()
        > {
  $$CompetitorsTableTableManager(_$AppDatabase db, $CompetitorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompetitorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompetitorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompetitorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> competitorId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompetitorsCompanion(
                competitorId: competitorId,
                gameId: gameId,
                type: type,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String competitorId,
                required String gameId,
                required String type,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => CompetitorsCompanion.insert(
                competitorId: competitorId,
                gameId: gameId,
                type: type,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompetitorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompetitorsTable,
      Competitor,
      $$CompetitorsTableFilterComposer,
      $$CompetitorsTableOrderingComposer,
      $$CompetitorsTableAnnotationComposer,
      $$CompetitorsTableCreateCompanionBuilder,
      $$CompetitorsTableUpdateCompanionBuilder,
      (
        Competitor,
        BaseReferences<_$AppDatabase, $CompetitorsTable, Competitor>,
      ),
      Competitor,
      PrefetchHooks Function()
    >;
typedef $$CompetitorPlayersTableCreateCompanionBuilder =
    CompetitorPlayersCompanion Function({
      required String competitorId,
      required String playerId,
      required int rotationPosition,
      Value<int> rowid,
    });
typedef $$CompetitorPlayersTableUpdateCompanionBuilder =
    CompetitorPlayersCompanion Function({
      Value<String> competitorId,
      Value<String> playerId,
      Value<int> rotationPosition,
      Value<int> rowid,
    });

class $$CompetitorPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $CompetitorPlayersTable> {
  $$CompetitorPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rotationPosition => $composableBuilder(
    column: $table.rotationPosition,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompetitorPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $CompetitorPlayersTable> {
  $$CompetitorPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationPosition => $composableBuilder(
    column: $table.rotationPosition,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompetitorPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompetitorPlayersTable> {
  $$CompetitorPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get rotationPosition => $composableBuilder(
    column: $table.rotationPosition,
    builder: (column) => column,
  );
}

class $$CompetitorPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompetitorPlayersTable,
          CompetitorPlayer,
          $$CompetitorPlayersTableFilterComposer,
          $$CompetitorPlayersTableOrderingComposer,
          $$CompetitorPlayersTableAnnotationComposer,
          $$CompetitorPlayersTableCreateCompanionBuilder,
          $$CompetitorPlayersTableUpdateCompanionBuilder,
          (
            CompetitorPlayer,
            BaseReferences<
              _$AppDatabase,
              $CompetitorPlayersTable,
              CompetitorPlayer
            >,
          ),
          CompetitorPlayer,
          PrefetchHooks Function()
        > {
  $$CompetitorPlayersTableTableManager(
    _$AppDatabase db,
    $CompetitorPlayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompetitorPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompetitorPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompetitorPlayersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> competitorId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<int> rotationPosition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompetitorPlayersCompanion(
                competitorId: competitorId,
                playerId: playerId,
                rotationPosition: rotationPosition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String competitorId,
                required String playerId,
                required int rotationPosition,
                Value<int> rowid = const Value.absent(),
              }) => CompetitorPlayersCompanion.insert(
                competitorId: competitorId,
                playerId: playerId,
                rotationPosition: rotationPosition,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompetitorPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompetitorPlayersTable,
      CompetitorPlayer,
      $$CompetitorPlayersTableFilterComposer,
      $$CompetitorPlayersTableOrderingComposer,
      $$CompetitorPlayersTableAnnotationComposer,
      $$CompetitorPlayersTableCreateCompanionBuilder,
      $$CompetitorPlayersTableUpdateCompanionBuilder,
      (
        CompetitorPlayer,
        BaseReferences<
          _$AppDatabase,
          $CompetitorPlayersTable,
          CompetitorPlayer
        >,
      ),
      CompetitorPlayer,
      PrefetchHooks Function()
    >;
typedef $$DartThrowsTableCreateCompanionBuilder =
    DartThrowsCompanion Function({
      required String dartId,
      required String gameId,
      required String competitorId,
      required String playerId,
      required int turnNumber,
      required int dartNumber,
      required String segment,
      required int score,
      Value<double?> x,
      Value<double?> y,
      Value<int> rowid,
    });
typedef $$DartThrowsTableUpdateCompanionBuilder =
    DartThrowsCompanion Function({
      Value<String> dartId,
      Value<String> gameId,
      Value<String> competitorId,
      Value<String> playerId,
      Value<int> turnNumber,
      Value<int> dartNumber,
      Value<String> segment,
      Value<int> score,
      Value<double?> x,
      Value<double?> y,
      Value<int> rowid,
    });

class $$DartThrowsTableFilterComposer
    extends Composer<_$AppDatabase, $DartThrowsTable> {
  $$DartThrowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dartId => $composableBuilder(
    column: $table.dartId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get turnNumber => $composableBuilder(
    column: $table.turnNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dartNumber => $composableBuilder(
    column: $table.dartNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DartThrowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DartThrowsTable> {
  $$DartThrowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dartId => $composableBuilder(
    column: $table.dartId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get turnNumber => $composableBuilder(
    column: $table.turnNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dartNumber => $composableBuilder(
    column: $table.dartNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DartThrowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DartThrowsTable> {
  $$DartThrowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dartId =>
      $composableBuilder(column: $table.dartId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get competitorId => $composableBuilder(
    column: $table.competitorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get turnNumber => $composableBuilder(
    column: $table.turnNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dartNumber => $composableBuilder(
    column: $table.dartNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);
}

class $$DartThrowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DartThrowsTable,
          DartThrow,
          $$DartThrowsTableFilterComposer,
          $$DartThrowsTableOrderingComposer,
          $$DartThrowsTableAnnotationComposer,
          $$DartThrowsTableCreateCompanionBuilder,
          $$DartThrowsTableUpdateCompanionBuilder,
          (
            DartThrow,
            BaseReferences<_$AppDatabase, $DartThrowsTable, DartThrow>,
          ),
          DartThrow,
          PrefetchHooks Function()
        > {
  $$DartThrowsTableTableManager(_$AppDatabase db, $DartThrowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DartThrowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DartThrowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DartThrowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dartId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> competitorId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<int> turnNumber = const Value.absent(),
                Value<int> dartNumber = const Value.absent(),
                Value<String> segment = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DartThrowsCompanion(
                dartId: dartId,
                gameId: gameId,
                competitorId: competitorId,
                playerId: playerId,
                turnNumber: turnNumber,
                dartNumber: dartNumber,
                segment: segment,
                score: score,
                x: x,
                y: y,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dartId,
                required String gameId,
                required String competitorId,
                required String playerId,
                required int turnNumber,
                required int dartNumber,
                required String segment,
                required int score,
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DartThrowsCompanion.insert(
                dartId: dartId,
                gameId: gameId,
                competitorId: competitorId,
                playerId: playerId,
                turnNumber: turnNumber,
                dartNumber: dartNumber,
                segment: segment,
                score: score,
                x: x,
                y: y,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DartThrowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DartThrowsTable,
      DartThrow,
      $$DartThrowsTableFilterComposer,
      $$DartThrowsTableOrderingComposer,
      $$DartThrowsTableAnnotationComposer,
      $$DartThrowsTableCreateCompanionBuilder,
      $$DartThrowsTableUpdateCompanionBuilder,
      (DartThrow, BaseReferences<_$AppDatabase, $DartThrowsTable, DartThrow>),
      DartThrow,
      PrefetchHooks Function()
    >;
typedef $$GameEventsTableCreateCompanionBuilder =
    GameEventsCompanion Function({
      required String eventId,
      required String gameId,
      required String eventType,
      required int localSequence,
      required String occurredAt,
      required String payloadJson,
      Value<int> synced,
      required String actorId,
      Value<int?> globalSequence,
      Value<int> source,
      Value<int> rowid,
    });
typedef $$GameEventsTableUpdateCompanionBuilder =
    GameEventsCompanion Function({
      Value<String> eventId,
      Value<String> gameId,
      Value<String> eventType,
      Value<int> localSequence,
      Value<String> occurredAt,
      Value<String> payloadJson,
      Value<int> synced,
      Value<String> actorId,
      Value<int?> globalSequence,
      Value<int> source,
      Value<int> rowid,
    });

class $$GameEventsTableFilterComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get globalSequence => $composableBuilder(
    column: $table.globalSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get globalSequence => $composableBuilder(
    column: $table.globalSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameEventsTable> {
  $$GameEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get localSequence => $composableBuilder(
    column: $table.localSequence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<int> get globalSequence => $composableBuilder(
    column: $table.globalSequence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$GameEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameEventsTable,
          GameEvent,
          $$GameEventsTableFilterComposer,
          $$GameEventsTableOrderingComposer,
          $$GameEventsTableAnnotationComposer,
          $$GameEventsTableCreateCompanionBuilder,
          $$GameEventsTableUpdateCompanionBuilder,
          (
            GameEvent,
            BaseReferences<_$AppDatabase, $GameEventsTable, GameEvent>,
          ),
          GameEvent,
          PrefetchHooks Function()
        > {
  $$GameEventsTableTableManager(_$AppDatabase db, $GameEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int> localSequence = const Value.absent(),
                Value<String> occurredAt = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> synced = const Value.absent(),
                Value<String> actorId = const Value.absent(),
                Value<int?> globalSequence = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameEventsCompanion(
                eventId: eventId,
                gameId: gameId,
                eventType: eventType,
                localSequence: localSequence,
                occurredAt: occurredAt,
                payloadJson: payloadJson,
                synced: synced,
                actorId: actorId,
                globalSequence: globalSequence,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String gameId,
                required String eventType,
                required int localSequence,
                required String occurredAt,
                required String payloadJson,
                Value<int> synced = const Value.absent(),
                required String actorId,
                Value<int?> globalSequence = const Value.absent(),
                Value<int> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameEventsCompanion.insert(
                eventId: eventId,
                gameId: gameId,
                eventType: eventType,
                localSequence: localSequence,
                occurredAt: occurredAt,
                payloadJson: payloadJson,
                synced: synced,
                actorId: actorId,
                globalSequence: globalSequence,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameEventsTable,
      GameEvent,
      $$GameEventsTableFilterComposer,
      $$GameEventsTableOrderingComposer,
      $$GameEventsTableAnnotationComposer,
      $$GameEventsTableCreateCompanionBuilder,
      $$GameEventsTableUpdateCompanionBuilder,
      (GameEvent, BaseReferences<_$AppDatabase, $GameEventsTable, GameEvent>),
      GameEvent,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String accountId,
      required String email,
      Value<String?> accessToken,
      Value<String?> refreshToken,
      required String backendUrl,
      required String createdAt,
      Value<String?> lastLoginAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> accountId,
      Value<String> email,
      Value<String?> accessToken,
      Value<String?> refreshToken,
      Value<String> backendUrl,
      Value<String> createdAt,
      Value<String?> lastLoginAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backendUrl => $composableBuilder(
    column: $table.backendUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backendUrl => $composableBuilder(
    column: $table.backendUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backendUrl => $composableBuilder(
    column: $table.backendUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> accessToken = const Value.absent(),
                Value<String?> refreshToken = const Value.absent(),
                Value<String> backendUrl = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> lastLoginAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                accountId: accountId,
                email: email,
                accessToken: accessToken,
                refreshToken: refreshToken,
                backendUrl: backendUrl,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String email,
                Value<String?> accessToken = const Value.absent(),
                Value<String?> refreshToken = const Value.absent(),
                required String backendUrl,
                required String createdAt,
                Value<String?> lastLoginAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                accountId: accountId,
                email: email,
                accessToken: accessToken,
                refreshToken: refreshToken,
                backendUrl: backendUrl,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String operationId,
      required String entityType,
      required String entityId,
      required String operationType,
      required String payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      required String createdAt,
      Value<String?> lastAttempt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> operationId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attemptCount,
      Value<String> createdAt,
      Value<String?> lastAttempt,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> lastAttempt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                operationId: operationId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttempt: lastAttempt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String entityType,
                required String entityId,
                required String operationType,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                required String createdAt,
                Value<String?> lastAttempt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                operationId: operationId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payloadJson: payloadJson,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttempt: lastAttempt,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$GameSessionsTableCreateCompanionBuilder =
    GameSessionsCompanion Function({
      required String sessionId,
      required String gameId,
      required String hostPlayerId,
      required String status,
      required String createdAt,
      Value<String?> startedAt,
      Value<String?> completedAt,
      Value<String?> currentTurnPlayerId,
      Value<int> rowid,
    });
typedef $$GameSessionsTableUpdateCompanionBuilder =
    GameSessionsCompanion Function({
      Value<String> sessionId,
      Value<String> gameId,
      Value<String> hostPlayerId,
      Value<String> status,
      Value<String> createdAt,
      Value<String?> startedAt,
      Value<String?> completedAt,
      Value<String?> currentTurnPlayerId,
      Value<int> rowid,
    });

class $$GameSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hostPlayerId => $composableBuilder(
    column: $table.hostPlayerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentTurnPlayerId => $composableBuilder(
    column: $table.currentTurnPlayerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GameSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hostPlayerId => $composableBuilder(
    column: $table.hostPlayerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentTurnPlayerId => $composableBuilder(
    column: $table.currentTurnPlayerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GameSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameSessionsTable> {
  $$GameSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get hostPlayerId => $composableBuilder(
    column: $table.hostPlayerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentTurnPlayerId => $composableBuilder(
    column: $table.currentTurnPlayerId,
    builder: (column) => column,
  );
}

class $$GameSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GameSessionsTable,
          GameSession,
          $$GameSessionsTableFilterComposer,
          $$GameSessionsTableOrderingComposer,
          $$GameSessionsTableAnnotationComposer,
          $$GameSessionsTableCreateCompanionBuilder,
          $$GameSessionsTableUpdateCompanionBuilder,
          (
            GameSession,
            BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>,
          ),
          GameSession,
          PrefetchHooks Function()
        > {
  $$GameSessionsTableTableManager(_$AppDatabase db, $GameSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> hostPlayerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> startedAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> currentTurnPlayerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSessionsCompanion(
                sessionId: sessionId,
                gameId: gameId,
                hostPlayerId: hostPlayerId,
                status: status,
                createdAt: createdAt,
                startedAt: startedAt,
                completedAt: completedAt,
                currentTurnPlayerId: currentTurnPlayerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String gameId,
                required String hostPlayerId,
                required String status,
                required String createdAt,
                Value<String?> startedAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> currentTurnPlayerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameSessionsCompanion.insert(
                sessionId: sessionId,
                gameId: gameId,
                hostPlayerId: hostPlayerId,
                status: status,
                createdAt: createdAt,
                startedAt: startedAt,
                completedAt: completedAt,
                currentTurnPlayerId: currentTurnPlayerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GameSessionsTable,
      GameSession,
      $$GameSessionsTableFilterComposer,
      $$GameSessionsTableOrderingComposer,
      $$GameSessionsTableAnnotationComposer,
      $$GameSessionsTableCreateCompanionBuilder,
      $$GameSessionsTableUpdateCompanionBuilder,
      (
        GameSession,
        BaseReferences<_$AppDatabase, $GameSessionsTable, GameSession>,
      ),
      GameSession,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$CompetitorsTableTableManager get competitors =>
      $$CompetitorsTableTableManager(_db, _db.competitors);
  $$CompetitorPlayersTableTableManager get competitorPlayers =>
      $$CompetitorPlayersTableTableManager(_db, _db.competitorPlayers);
  $$DartThrowsTableTableManager get dartThrows =>
      $$DartThrowsTableTableManager(_db, _db.dartThrows);
  $$GameEventsTableTableManager get gameEvents =>
      $$GameEventsTableTableManager(_db, _db.gameEvents);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$GameSessionsTableTableManager get gameSessions =>
      $$GameSessionsTableTableManager(_db, _db.gameSessions);
}
