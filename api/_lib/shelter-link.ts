/**
 * Builds a link to a dog's profile on the shelter's public website, derived
 * from its shelterid — stored as free text like "2222/26" (number/arrival
 * year), occasionally without a leading zero on the number (e.g. "573/26").
 * The site's URL pads the number to 4 digits and appends "p" (for "pies" —
 * all animals here are dogs), e.g. https://napaluchu.waw.pl/animal/0573-26p/
 *
 * Returns null if shelterid doesn't match the expected "number/year" shape
 * — callers should just omit the link rather than show a broken one.
 */
export function buildShelterUrl(shelterId: string | null | undefined): string | null {
	if (!shelterId) return null;
	const match = /^(\d+)\/(\d+)$/.exec(shelterId.trim());
	if (!match) return null;
	const [, number, year] = match;
	return `https://napaluchu.waw.pl/animal/${number.padStart(4, '0')}-${year}p/`;
}
