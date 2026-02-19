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
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$X01GameConfigToJson(X01GameConfig instance) =>
    <String, dynamic>{
      'startingScore': instance.startingScore,
      'inStrategy': instance.inStrategy,
      'outStrategy': instance.outStrategy,
      'runtimeType': instance.$type,
    };

CricketGameConfig _$CricketGameConfigFromJson(Map<String, dynamic> json) =>
    CricketGameConfig(
      variant: json['variant'] as String,
      numbers: (json['numbers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      pointsToWin: (json['pointsToWin'] as num).toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CricketGameConfigToJson(CricketGameConfig instance) =>
    <String, dynamic>{
      'variant': instance.variant,
      'numbers': instance.numbers,
      'pointsToWin': instance.pointsToWin,
      'runtimeType': instance.$type,
    };

AroundTheClockGameConfig _$AroundTheClockGameConfigFromJson(
  Map<String, dynamic> json,
) => AroundTheClockGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$AroundTheClockGameConfigToJson(
  AroundTheClockGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

KillerGameConfig _$KillerGameConfigFromJson(Map<String, dynamic> json) =>
    KillerGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$KillerGameConfigToJson(KillerGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

BaseballGameConfig _$BaseballGameConfigFromJson(Map<String, dynamic> json) =>
    BaseballGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BaseballGameConfigToJson(BaseballGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

GolfGameConfig _$GolfGameConfigFromJson(Map<String, dynamic> json) =>
    GolfGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$GolfGameConfigToJson(GolfGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

ShanghaiGameConfig _$ShanghaiGameConfigFromJson(Map<String, dynamic> json) =>
    ShanghaiGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$ShanghaiGameConfigToJson(ShanghaiGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

ScramGameConfig _$ScramGameConfigFromJson(Map<String, dynamic> json) =>
    ScramGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$ScramGameConfigToJson(ScramGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

HalveItGameConfig _$HalveItGameConfigFromJson(Map<String, dynamic> json) =>
    HalveItGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$HalveItGameConfigToJson(HalveItGameConfig instance) =>
    <String, dynamic>{'runtimeType': instance.$type};

HighScoreGameConfig _$HighScoreGameConfigFromJson(Map<String, dynamic> json) =>
    HighScoreGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$HighScoreGameConfigToJson(
  HighScoreGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

BlindCricketGameConfig _$BlindCricketGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindCricketGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BlindCricketGameConfigToJson(
  BlindCricketGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

BlindGolfGameConfig _$BlindGolfGameConfigFromJson(Map<String, dynamic> json) =>
    BlindGolfGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BlindGolfGameConfigToJson(
  BlindGolfGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

BlindKillerGameConfig _$BlindKillerGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindKillerGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BlindKillerGameConfigToJson(
  BlindKillerGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

BlindShanghaiGameConfig _$BlindShanghaiGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindShanghaiGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$BlindShanghaiGameConfigToJson(
  BlindShanghaiGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};

ChaseTheDragonGameConfig _$ChaseTheDragonGameConfigFromJson(
  Map<String, dynamic> json,
) => ChaseTheDragonGameConfig($type: json['runtimeType'] as String?);

Map<String, dynamic> _$ChaseTheDragonGameConfigToJson(
  ChaseTheDragonGameConfig instance,
) => <String, dynamic>{'runtimeType': instance.$type};
