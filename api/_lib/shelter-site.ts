/**
 * Reads dogs from the shelter's public website (napaluchu.waw.pl), via its
 * WordPress REST API — the `animal` post type, keyed by the same slug as the
 * page URL (see shelter-link.ts).
 */

const ANIMALS_API = 'https://napaluchu.waw.pl/wp-json/wp/v2/animal';
const FETCH_TIMEOUT_MS = 10_000;
/** WordPress's max page size — also the most slugs we send per request. */
const BATCH_SIZE = 100;

/** The site's `status-zwierzecia` taxonomy (GET /wp-json/wp/v2/status-zwierzecia). */
const STATUS_NAMES: Record<number, string> = {
	27: 'Kwarantanna',
	28: 'Do adopcji',
	29: 'Adopcja',
	30: 'Odbiór',
	31: 'Ucieczka',
	32: 'Dom tymczasowy',
	33: 'Zmarł',
};

const FIELDS = [
	'slug',
	'modified_gmt',
	'status-zwierzecia',
	...[
		'breed',
		'color',
		'gender_id',
		'weight',
		'spayed',
		'date_of_birth',
		'data_znalezienia',
		'miejsce_znalezienia',
		'data_wydania',
		'boks_lokalizacja',
		'description',
		'photos',
	].map((f) => `acf.${f}`),
].join(',');

interface WpAnimal {
	slug: string;
	modified_gmt?: string;
	'status-zwierzecia'?: number[];
	acf?: {
		breed?: string;
		color?: string;
		gender_id?: string;
		weight?: number | string;
		spayed?: boolean;
		date_of_birth?: string;
		data_znalezienia?: string;
		miejsce_znalezienia?: string;
		data_wydania?: string | null;
		boks_lokalizacja?: string;
		description?: string;
		photos?: Array<{ photo_url?: string }> | null;
	};
}

/** A dog as the website describes it, normalised for our database. */
export interface ShelterAnimal {
	status: string | null;
	photoUrl: string | null;
	breed: string | null;
	color: string | null;
	sex: string | null;
	birthDate: string | null;
	weightKg: number | null;
	neutered: boolean | null;
	arrivalDate: string | null;
	arrivalReason: string | null;
	departureDate: string | null;
	location: string | null;
	description: string | null;
	siteModifiedAt: string | null;
}

function text(value: unknown): string | null {
	return typeof value === 'string' && value.trim() ? value.trim() : null;
}

/** "20260620" -> "2026-06-20"; anything else -> null. */
function acfDate(value: unknown): string | null {
	const match = typeof value === 'string' ? /^(\d{4})(\d{2})(\d{2})$/.exec(value) : null;
	return match ? `${match[1]}-${match[2]}-${match[3]}` : null;
}

/** Descriptions are plain text but occasionally carry HTML. */
function plainText(value: unknown): string | null {
	const raw = text(value);
	if (!raw) return null;
	return (
		raw
			.replace(/<br\s*\/?>/gi, '\n')
			.replace(/<[^>]+>/g, '')
			.replace(/&nbsp;/g, ' ')
			.replace(/&amp;/g, '&')
			.trim() || null
	);
}

export function toShelterAnimal(wp: WpAnimal): ShelterAnimal {
	const acf = wp.acf ?? {};
	const weight = Number(acf.weight);
	const statusId = wp['status-zwierzecia']?.[0];
	return {
		status: statusId !== undefined ? (STATUS_NAMES[statusId] ?? null) : null,
		// The site's own page shows the first gallery photo; `main_photo`
		// points at files that no longer exist.
		photoUrl: text(acf.photos?.[0]?.photo_url),
		breed: text(acf.breed),
		color: text(acf.color),
		sex: text(acf.gender_id),
		birthDate: acfDate(acf.date_of_birth),
		// 0.1 kg is what the site shows for dogs that were never weighed.
		weightKg: Number.isFinite(weight) && weight > 0.1 ? weight : null,
		neutered: typeof acf.spayed === 'boolean' ? acf.spayed : null,
		arrivalDate: acfDate(acf.data_znalezienia),
		arrivalReason: text(acf.miejsce_znalezienia),
		departureDate: acfDate(acf.data_wydania),
		location: text(acf.boks_lokalizacja),
		description: plainText(acf.description),
		siteModifiedAt: wp.modified_gmt ? `${wp.modified_gmt}Z` : null,
	};
}

async function fetchBatch(slugs: string[]): Promise<WpAnimal[]> {
	const params = new URLSearchParams({ per_page: String(BATCH_SIZE), _fields: FIELDS });
	for (const slug of slugs) params.append('slug[]', slug);

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
	try {
		const res = await fetch(`${ANIMALS_API}?${params}`, { signal: controller.signal });
		if (!res.ok) throw new Error(`Shelter website responded ${res.status}`);
		return (await res.json()) as WpAnimal[];
	} finally {
		clearTimeout(timeout);
	}
}

/**
 * Looks up animals by slug, a page of up to 100 per request. Slugs the site
 * doesn't know are simply absent from the result. Throws if the site is
 * unreachable, so callers can keep their previous data.
 */
export async function fetchShelterAnimals(slugs: string[]): Promise<Map<string, ShelterAnimal>> {
	const animals = new Map<string, ShelterAnimal>();
	for (let i = 0; i < slugs.length; i += BATCH_SIZE) {
		for (const wp of await fetchBatch(slugs.slice(i, i + BATCH_SIZE))) {
			animals.set(wp.slug, toShelterAnimal(wp));
		}
	}
	return animals;
}

/**
 * Splits the website's location into kennel and region, e.g.
 * "430 R12 (domek)" -> { kennel: "430", region: "R12" }. Null for places
 * that aren't a numbered kennel ("szpital", "szpital kwarantanna").
 */
export function parseLocation(location: string | null): { kennel: string; region: string | null } | null {
	const match = location ? /^(\d+)\s*(R\d+)?/i.exec(location.trim()) : null;
	if (!match) return null;
	return { kennel: match[1], region: match[2]?.toUpperCase() ?? null };
}
