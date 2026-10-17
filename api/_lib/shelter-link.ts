/**
 * Parses a shelterid — stored as free text like "2222/26" (number/arrival
 * year), occasionally without a leading zero on the number (e.g. "573/26")
 * — into the shelter website's URL slug shape: the number padded to 4
 * digits, followed by "p" (for "pies" — every animal here is a dog), e.g.
 * "573/26" -> "0573-26p". That slug is also what identifies the animal in
 * the shelter's WordPress REST API (GET /wp-json/wp/v2/animal?slug=...).
 *
 * Returns null if shelterId doesn't match the expected "number/year" shape.
 */
export function parseShelterId(
	shelterId: string | null | undefined,
): { number: string; year: string; slug: string } | null {
	if (!shelterId) return null;
	const match = /^(\d+)\/(\d+)$/.exec(shelterId.trim());
	if (!match) return null;
	const [, rawNumber, year] = match;
	const number = rawNumber.padStart(4, '0');
	return { number, year, slug: `${number}-${year}p` };
}

/**
 * Builds a link to a dog's profile on the shelter's public website, e.g.
 * https://napaluchu.waw.pl/animal/0573-26p/
 *
 * Returns null if shelterId doesn't match the expected shape — callers
 * should just omit the link rather than show a broken one.
 */
export function buildShelterUrl(shelterId: string | null | undefined): string | null {
	const parsed = parseShelterId(shelterId);
	if (!parsed) return null;
	return `https://napaluchu.waw.pl/animal/${parsed.slug}/`;
}
