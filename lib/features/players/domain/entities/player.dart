// Player Entity
// Represents a player in the darts application

import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
abstract class Player with _$Player {
  const factory Player({
    
    @JsonKey(name: 'player_id') required String playerId,
   
    @JsonKey(name: 'name') required String name,
  
    @JsonKey(name: 'created_at') required DateTime createdAt,
 
    @JsonKey(name: 'last_active') required DateTime lastActive,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
