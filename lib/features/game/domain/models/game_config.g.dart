// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

X01GameConfig _$X01GameConfigFromJson(Map<String, dynamic> json) =>
    X01GameConfig(
      startingScore: (json['startingScore'] as num).toInt(),
      inStrategy: json['inStrategy'] as String,
      outStrategy: json['outStrategy'] as String,
      legsToWin: (json['legsToWin'] as num?)?.toInt() ?? 1,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? null,
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      handicaps:
          (json['handicaps'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$X01GameConfigToJson(X01GameConfig instance) =>
    <String, dynamic>{
      'startingScore': instance.startingScore,
      'inStrategy': instance.inStrategy,
      'outStrategy': instance.outStrategy,
      'legsToWin': instance.legsToWin,
      'totalRounds': instance.totalRounds,
      'startingPlayerId': instance.startingPlayerId,
      'handicaps': instance.handicaps,
      'runtimeType': instance.$type,
    };

CricketGameConfig _$CricketGameConfigFromJson(
  Map<String, dynamic> json,
) => CricketGameConfig(
  scoring: _readCricketScoring(json, 'scoring') as String? ?? 'standard',
  targetMode: _readCricketTargetMode(json, 'targetMode') as String? ?? 'fixed',
  numbers:
      (json['numbers'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>['15', '16', '17', '18', '19', '20', 'bull'],
  legsToWin: (json['legsToWin'] as num?)?.toInt() ?? 1,
  totalRounds: (json['totalRounds'] as num?)?.toInt() ?? null,
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$CricketGameConfigToJson(CricketGameConfig instance) =>
    <String, dynamic>{
      'scoring': instance.scoring,
      'targetMode': instance.targetMode,
      'numbers': instance.numbers,
      'legsToWin': instance.legsToWin,
      'totalRounds': instance.totalRounds,
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

AroundTheClockGameConfig _$AroundTheClockGameConfigFromJson(
  Map<String, dynamic> json,
) => AroundTheClockGameConfig(
  variant: json['variant'] as String? ?? 'standard',
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$AroundTheClockGameConfigToJson(
  AroundTheClockGameConfig instance,
) => <String, dynamic>{
  'variant': instance.variant,
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

ShanghaiGameConfig _$ShanghaiGameConfigFromJson(Map<String, dynamic> json) =>
    ShanghaiGameConfig(
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 7,
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ShanghaiGameConfigToJson(ShanghaiGameConfig instance) =>
    <String, dynamic>{
      'totalRounds': instance.totalRounds,
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

Catch40GameConfig _$Catch40GameConfigFromJson(Map<String, dynamic> json) =>
    Catch40GameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$Catch40GameConfigToJson(Catch40GameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

Bobs27GameConfig _$Bobs27GameConfigFromJson(Map<String, dynamic> json) =>
    Bobs27GameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$Bobs27GameConfigToJson(Bobs27GameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

CheckoutPracticeGameConfig _$CheckoutPracticeGameConfigFromJson(
  Map<String, dynamic> json,
) => CheckoutPracticeGameConfig(
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  randomOrder: json['randomOrder'] as bool? ?? false,
  targetSuccesses: (json['targetSuccesses'] as num?)?.toInt() ?? null,
  targetMode: _readCheckoutTargetMode(json, 'targetMode') as String? ?? 'fixed',
  fixedTarget: (json['fixedTarget'] as num?)?.toInt() ?? 170,
  minTarget: (json['minTarget'] as num?)?.toInt() ?? 40,
  maxTarget: (json['maxTarget'] as num?)?.toInt() ?? 170,
  progressionStep: (json['progressionStep'] as num?)?.toInt() ?? 10,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$CheckoutPracticeGameConfigToJson(
  CheckoutPracticeGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'randomOrder': instance.randomOrder,
  'targetSuccesses': instance.targetSuccesses,
  'targetMode': instance.targetMode,
  'fixedTarget': instance.fixedTarget,
  'minTarget': instance.minTarget,
  'maxTarget': instance.maxTarget,
  'progressionStep': instance.progressionStep,
  'runtimeType': instance.$type,
};

CountUpGameConfig _$CountUpGameConfigFromJson(Map<String, dynamic> json) =>
    CountUpGameConfig(
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 8,
      handicaps:
          (json['handicaps'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CountUpGameConfigToJson(CountUpGameConfig instance) =>
    <String, dynamic>{
      'totalRounds': instance.totalRounds,
      'handicaps': instance.handicaps,
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };
