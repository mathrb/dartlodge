/// A 2D point in board / image space.
///
/// Coordinates are normalised 0–1 within the detection frame (#377 §6). The
/// scoring math is scale-invariant, so any consistent unit works; normalised
/// coords are what the detector emits.
typedef BoardPoint = ({double x, double y});
