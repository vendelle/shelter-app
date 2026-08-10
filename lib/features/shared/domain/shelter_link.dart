/// Builds a link to a dog's profile on the shelter's public website, derived
/// from its shelterId — stored as free text like "2222/26" (number/arrival
/// year), occasionally without a leading zero on the number (e.g.
/// "573/26"). The site's URL pads the number to 4 digits and appends "p"
/// (for "pies" — every animal here is a dog), e.g.
/// https://napaluchu.waw.pl/animal/0573-26p/
///
/// Mirrors api/_lib/shelter-link.ts on the backend, which computes the same
/// thing for API consumers — kept as a small duplicate here rather than
/// threading a shelterUrl field through every screen that only ever had a
/// shelterId to begin with.
///
/// Returns null if shelterId doesn't match the expected shape; callers
/// should just omit the link rather than show a broken one.
String? buildShelterUrl(String? shelterId) {
  if (shelterId == null || shelterId.trim().isEmpty) return null;
  final match = RegExp(r'^(\d+)/(\d+)$').firstMatch(shelterId.trim());
  if (match == null) return null;
  final number = match.group(1)!.padLeft(4, '0');
  final year = match.group(2)!;
  return 'https://napaluchu.waw.pl/animal/$number-${year}p/';
}
