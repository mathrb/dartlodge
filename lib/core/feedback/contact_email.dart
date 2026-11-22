/// The project's public contact address.
///
/// Single source of truth for every place the app names an address: the
/// Settings "Contact us" row and the auto-scorer training-data export
/// destination (#744). The address reaches translated copy only through a
/// placeholder, so changing it here causes no translation churn.
///
/// Pure Dart (no Flutter import) so `domain/` layers may depend on it.
const String kDartLodgeContactEmail = 'dartlodge@gmail.com';
