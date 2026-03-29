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
      'runtimeType': instance.$type,
    };

CricketGameConfig _$CricketGameConfigFromJson(Map<String, dynamic> json) =>
    CricketGameConfig(
      variant: json['variant'] as String,
      numbers: (json['numbers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      legsToWin: (json['legsToWin'] as num?)?.toInt() ?? 1,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? null,
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$CricketGameConfigToJson(CricketGameConfig instance) =>
    <String, dynamic>{
      'variant': instance.variant,
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

KillerGameConfig _$KillerGameConfigFromJson(Map<String, dynamic> json) =>
    KillerGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$KillerGameConfigToJson(KillerGameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

BaseballGameConfig _$BaseballGameConfigFromJson(Map<String, dynamic> json) =>
    BaseballGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$BaseballGameConfigToJson(BaseballGameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

GolfGameConfig _$GolfGameConfigFromJson(Map<String, dynamic> json) =>
    GolfGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$GolfGameConfigToJson(GolfGameConfig instance) =>
    <String, dynamic>{
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

ScramGameConfig _$ScramGameConfigFromJson(Map<String, dynamic> json) =>
    ScramGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ScramGameConfigToJson(ScramGameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

HalveItGameConfig _$HalveItGameConfigFromJson(Map<String, dynamic> json) =>
    HalveItGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$HalveItGameConfigToJson(HalveItGameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'runtimeType': instance.$type,
    };

HighScoreGameConfig _$HighScoreGameConfigFromJson(Map<String, dynamic> json) =>
    HighScoreGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$HighScoreGameConfigToJson(
  HighScoreGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

BlindCricketGameConfig _$BlindCricketGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindCricketGameConfig(
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BlindCricketGameConfigToJson(
  BlindCricketGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

BlindGolfGameConfig _$BlindGolfGameConfigFromJson(Map<String, dynamic> json) =>
    BlindGolfGameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$BlindGolfGameConfigToJson(
  BlindGolfGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

BlindKillerGameConfig _$BlindKillerGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindKillerGameConfig(
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BlindKillerGameConfigToJson(
  BlindKillerGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

BlindShanghaiGameConfig _$BlindShanghaiGameConfigFromJson(
  Map<String, dynamic> json,
) => BlindShanghaiGameConfig(
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$BlindShanghaiGameConfigToJson(
  BlindShanghaiGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

ChaseTheDragonGameConfig _$ChaseTheDragonGameConfigFromJson(
  Map<String, dynamic> json,
) => ChaseTheDragonGameConfig(
  startingPlayerId: json['startingPlayerId'] as String? ?? null,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ChaseTheDragonGameConfigToJson(
  ChaseTheDragonGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'runtimeType': instance.$type,
};

Catch40GameConfig _$Catch40GameConfigFromJson(Map<String, dynamic> json) =>
    Catch40GameConfig(
      startingPlayerId: json['startingPlayerId'] as String? ?? null,
      totalRounds: (json['totalRounds'] as num?)?.toInt() ?? 8,
      roundTargets:
          (json['roundTargets'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [10, 15, 20, 25, 30, 35, 40, 45],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$Catch40GameConfigToJson(Catch40GameConfig instance) =>
    <String, dynamic>{
      'startingPlayerId': instance.startingPlayerId,
      'totalRounds': instance.totalRounds,
      'roundTargets': instance.roundTargets,
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
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$CheckoutPracticeGameConfigToJson(
  CheckoutPracticeGameConfig instance,
) => <String, dynamic>{
  'startingPlayerId': instance.startingPlayerId,
  'randomOrder': instance.randomOrder,
  'runtimeType': instance.$type,
};
