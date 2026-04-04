/// Returns an error message if [name] is invalid, null if valid.
/// The caller is responsible for trimming before passing.
String? validatePlayerName(String name) {
  if (name.isEmpty) return 'Name cannot be empty';
  if (name.length > 30) return 'Name must be 30 characters or fewer';
  return null;
}
