/// Reads (segment, multiplier) from a DartThrown event payload.
/// Handles both numeric payloads (production: segment=20, multiplier=3)
/// and string payloads (legacy/test: segment='T20').
/// Returns (0, 1) for miss or unparseable data.
({int segment, int multiplier}) readSegmentFromPayload(
    Map<String, dynamic> payload) {
  final raw = payload['segment'];
  if (raw is num) {
    final mult = (payload['multiplier'] as num?)?.toInt() ?? 1;
    return (segment: raw.toInt(), multiplier: mult);
  }
  if (raw is String) {
    if (raw == 'MISS') return (segment: 0, multiplier: 1);
    if (raw == 'DB') return (segment: 25, multiplier: 2);
    if (raw == 'SB') return (segment: 25, multiplier: 1);
    int mult = 1;
    String stripped = raw;
    if (raw.startsWith('T')) {
      mult = 3;
      stripped = raw.substring(1);
    } else if (raw.startsWith('D')) {
      mult = 2;
      stripped = raw.substring(1);
    }
    final n = int.tryParse(stripped);
    return (segment: n ?? 0, multiplier: mult);
  }
  return (segment: 0, multiplier: 1);
}
