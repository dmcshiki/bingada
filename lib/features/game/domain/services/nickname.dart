/// Nickname shown in a room. Short and only common characters: letters
/// (accents included), digits, space, dot, dash and underscore. The same
/// rule is enforced by firestore.rules (`nicknameOk`).
abstract final class Nickname {
  static const minLength = 2;
  static const maxLength = 20;

  static final _allowed = RegExp(r'^[\p{L}\p{N} ._-]+$', unicode: true);
  static final _bad = RegExp(r'[^\p{L}\p{N} ._-]', unicode: true);

  /// Trims and collapses inner spaces.
  static String normalize(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Error message for the UI, or null when [raw] is a valid nickname.
  static String? validate(String raw) {
    final n = normalize(raw);
    if (n.length < minLength) return 'Use pelo menos $minLength caracteres.';
    if (n.length > maxLength) return 'Use no máximo $maxLength caracteres.';
    if (!_allowed.hasMatch(n)) {
      return 'Use só letras, números, espaço, ponto, hífen ou _.';
    }
    return null;
  }

  /// A valid default from an account name (first name, cleaned and cut).
  static String fromName(String name) {
    final first = normalize(name).split(' ').first.replaceAll(_bad, '');
    final cut = first.length > maxLength
        ? first.substring(0, maxLength)
        : first;
    return cut.length >= minLength ? cut : 'Jogador';
  }
}
