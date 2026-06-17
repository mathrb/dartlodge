/// Why a player name failed validation.
///
/// A semantic code rather than a message: the domain stays Flutter-free, and
/// the presentation layer maps each case to a localized string. `duplicate`
/// and `unknown` are produced by the form providers (not [validatePlayerName])
/// but live here so the whole name-error vocabulary is in one place.
enum PlayerNameError { empty, tooLong, duplicate, unknown }

/// Returns the validation error for [name], or null if valid.
/// The caller is responsible for trimming before passing.
PlayerNameError? validatePlayerName(String name) {
  if (name.isEmpty) return PlayerNameError.empty;
  if (name.length > 30) return PlayerNameError.tooLong;
  return null;
}
