/**
 * Shelter-website data for our dogs, stored in `dog_shelter_profiles`.
 * Served by /api/dogs?shelter=… (kept on that endpoint to stay within the
 * serverless function budget — see DECISIONS.md):
 *
 *   GET  ?shelter=<dogId>      profile (fetched on first view)       volunteer
 *   POST ?shelter=<dogId>      "Odśwież teraz" — at most every 5 min  volunteer
 *   PUT  ?shelter=<dogId>      { action: 'accept' | 'ignore' } the
 *                              website's kennel/region                admin
 *   GET  ?shelter=suggestions  dogs whose website kennel/region
 *                              differs from ours                      volunteer
 *   GET  ?shelter=sync         refresh every active dog (Vercel Cron,
 *                              authenticated with CRON_SECRET)
 *   GET  ?shelter=photos       a few photo URLs of active dogs for the
 *                              sign-in screen                         anyone
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import pool from './connection';
import { requireRole } from './auth';
import { getRegionForKennel } from './kennel-regions';
import { hasRole } from './permissions';
import { buildShelterUrl, parseShelterId } from './shelter-link';
import { fetchShelterAnimals, parseLocation, type ShelterAnimal } from './shelter-site';
import { hasColumn } from './util';

/** "Odśwież teraz" re-fetches a dog at most this often, to spare the website. */
export const REFRESH_COOLDOWN_MINUTES = 5;

/** Photos on the sign-in screen: the 4×4 grid's border. */
export const WELCOME_PHOTO_COUNT = 12;

interface Dog {
	id: number;
	shelterid: string;
	kennel: string;
	region: string | null;
}

interface ProfileRow {
	found: boolean;
	status: string | null;
	photo_url: string | null;
	breed: string | null;
	color: string | null;
	sex: string | null;
	birth_date: string | null;
	weight_kg: number | null;
	neutered: boolean | null;
	arrival_date: string | null;
	arrival_reason: string | null;
	departure_date: string | null;
	location: string | null;
	description: string | null;
	site_modified_at: Date | null;
	fetched_at: Date;
	ignored_location: string | null;
}

// Dates as text so they stay calendar dates (pg would turn them into
// local-midnight timestamps); NUMERIC as float so it isn't a string.
const PROFILE_COLUMNS = `found, status, photo_url, breed, color, sex,
	birth_date::text AS birth_date, weight_kg::float8 AS weight_kg, neutered,
	arrival_date::text AS arrival_date, arrival_reason, departure_date::text AS departure_date,
	location, description, site_modified_at, fetched_at, ignored_location`;

/** Columns for a Dog; `region` is missing on databases older than migration 003. */
async function dogColumns(table = 'dogs'): Promise<string> {
	const region = (await hasColumn('dogs', 'region')) ? `${table}.region` : 'NULL AS region';
	return `${table}.id, ${table}.shelterid, ${table}.kennel, ${region}`;
}

async function loadProfile(dogId: number): Promise<ProfileRow | null> {
	const result = await pool.query(`SELECT ${PROFILE_COLUMNS} FROM dog_shelter_profiles WHERE dog_id = $1`, [dogId]);
	return result.rows[0] ?? null;
}

async function saveProfile(dogId: number, animal: ShelterAnimal | null): Promise<void> {
	const a = animal;
	await pool.query(
		`INSERT INTO dog_shelter_profiles (dog_id, found, status, photo_url, breed, color, sex, birth_date,
		   weight_kg, neutered, arrival_date, arrival_reason, departure_date, location, description,
		   site_modified_at, fetched_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW())
		 ON CONFLICT (dog_id) DO UPDATE SET
		   found = EXCLUDED.found, status = EXCLUDED.status, photo_url = EXCLUDED.photo_url,
		   breed = EXCLUDED.breed, color = EXCLUDED.color, sex = EXCLUDED.sex,
		   birth_date = EXCLUDED.birth_date, weight_kg = EXCLUDED.weight_kg, neutered = EXCLUDED.neutered,
		   arrival_date = EXCLUDED.arrival_date, arrival_reason = EXCLUDED.arrival_reason,
		   departure_date = EXCLUDED.departure_date, location = EXCLUDED.location,
		   description = EXCLUDED.description, site_modified_at = EXCLUDED.site_modified_at,
		   fetched_at = NOW()`,
		[
			dogId,
			a !== null,
			a?.status ?? null,
			a?.photoUrl ?? null,
			a?.breed ?? null,
			a?.color ?? null,
			a?.sex ?? null,
			a?.birthDate ?? null,
			a?.weightKg ?? null,
			a?.neutered ?? null,
			a?.arrivalDate ?? null,
			a?.arrivalReason ?? null,
			a?.departureDate ?? null,
			a?.location ?? null,
			a?.description ?? null,
			a?.siteModifiedAt ?? null,
		],
	);
}

/** Fetches [dogs] from the website and stores what it says. Returns how many it found. */
export async function refreshDogs(dogs: Dog[]): Promise<number> {
	const slugByDog = new Map<number, string>();
	for (const dog of dogs) {
		const parsed = parseShelterId(dog.shelterid);
		if (parsed) slugByDog.set(dog.id, parsed.slug);
	}
	const animals = await fetchShelterAnimals([...new Set(slugByDog.values())]);

	let found = 0;
	for (const dog of dogs) {
		const slug = slugByDog.get(dog.id);
		const animal = slug ? (animals.get(slug) ?? null) : null;
		if (animal) found++;
		await saveProfile(dog.id, animal);
	}
	return found;
}

/**
 * The website's kennel/region when it differs from ours and an admin hasn't
 * ignored it; null otherwise. Only numbered kennels count — "szpital" is
 * shown on the profile but never suggested.
 */
export function locationSuggestion(
	dog: Pick<Dog, 'kennel' | 'region'>,
	profile: Pick<ProfileRow, 'location' | 'ignored_location'> | null,
): { kennel: string; region: string | null } | null {
	if (!profile?.location || profile.location === profile.ignored_location) return null;
	const site = parseLocation(profile.location);
	if (!site) return null;

	const ourRegion = dog.region || getRegionForKennel(dog.kennel);
	const kennelDiffers = site.kennel !== dog.kennel.trim();
	const regionDiffers = site.region !== null && site.region !== ourRegion;
	return kennelDiffers || regionDiffers ? site : null;
}

function profileJson(dog: Dog, row: ProfileRow | null) {
	return {
		dog_id: dog.id,
		// Our current kennel/region, so the app shows an accepted suggestion
		// without reloading the dog.
		kennel: dog.kennel,
		region: dog.region || getRegionForKennel(dog.kennel),
		url: buildShelterUrl(dog.shelterid),
		found: row?.found ?? false,
		status: row?.status ?? null,
		photo_url: row?.photo_url ?? null,
		breed: row?.breed ?? null,
		color: row?.color ?? null,
		sex: row?.sex ?? null,
		birth_date: row?.birth_date ?? null,
		weight_kg: row?.weight_kg ?? null,
		neutered: row?.neutered ?? null,
		arrival_date: row?.arrival_date ?? null,
		arrival_reason: row?.arrival_reason ?? null,
		departure_date: row?.departure_date ?? null,
		location: row?.location ?? null,
		description: row?.description ?? null,
		site_modified_at: row?.site_modified_at ?? null,
		fetched_at: row?.fetched_at ?? null,
		location_suggestion: locationSuggestion(dog, row),
	};
}

function isWithinCooldown(row: ProfileRow): boolean {
	return Date.now() - new Date(row.fetched_at).getTime() < REFRESH_COOLDOWN_MINUTES * 60_000;
}

export async function handleShelterProfiles(req: VercelRequest, res: VercelResponse) {
	const target = String(req.query.shelter);

	if (target === 'sync') {
		const secret = process.env.CRON_SECRET;
		if (!secret || req.headers?.authorization !== `Bearer ${secret}`) {
			return res.status(401).json({ error: 'Cron secret required' });
		}
		const dogs = await pool.query(`SELECT ${await dogColumns()} FROM dogs WHERE archived IS NOT TRUE`);
		const found = await refreshDogs(dogs.rows);
		return res.status(200).json({ dogs: dogs.rows.length, found });
	}

	// Public: the sign-in screen shows these before anyone signs in. Only the
	// image URLs — no names or ids — and the photos are on the shelter's
	// public website anyway. Cached by Vercel's CDN, so visitors don't hit
	// the database.
	if (target === 'photos') {
		if (req.method !== 'GET') return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
		const result = await pool.query(
			`SELECT p.photo_url
			 FROM dogs d JOIN dog_shelter_profiles p ON p.dog_id = d.id
			 WHERE d.archived IS NOT TRUE AND p.photo_url IS NOT NULL
			 ORDER BY random()
			 LIMIT $1`,
			[WELCOME_PHOTO_COUNT],
		);
		res.setHeader('Cache-Control', 'public, s-maxage=3600, stale-while-revalidate=86400');
		return res.status(200).json(result.rows.map((row) => row.photo_url));
	}

	const user = await requireRole(req, res, 'volunteer');
	if (!user) return;

	// Photos of all active dogs, for the small pictures next to a dog's name
	// in lists. Read from what's stored — never contacts the website.
	if (target === 'thumbs') {
		if (req.method !== 'GET') return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
		const result = await pool.query(
			`SELECT d.id AS dog_id, p.photo_url
			 FROM dogs d JOIN dog_shelter_profiles p ON p.dog_id = d.id
			 WHERE d.archived IS NOT TRUE AND p.photo_url IS NOT NULL`,
		);
		return res.status(200).json(result.rows);
	}

	if (target === 'suggestions') {
		if (req.method !== 'GET') return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
		const result = await pool.query(
			`SELECT ${await dogColumns('d')}, p.location, p.ignored_location
			 FROM dogs d JOIN dog_shelter_profiles p ON p.dog_id = d.id
			 WHERE d.archived IS NOT TRUE`,
		);
		const suggestions = result.rows.flatMap((row) => {
			const suggestion = locationSuggestion(row, row);
			return suggestion ? [{ dog_id: row.id, location: row.location, location_suggestion: suggestion }] : [];
		});
		return res.status(200).json(suggestions);
	}

	const dogId = Number(target);
	if (!Number.isInteger(dogId)) return res.status(400).json({ error: 'shelter must be a dog id, "suggestions" or "sync"' });
	const dogResult = await pool.query(`SELECT ${await dogColumns()} FROM dogs WHERE id = $1`, [dogId]);
	const dog: Dog | undefined = dogResult.rows[0];
	if (!dog) return res.status(404).json({ error: 'Dog not found' });

	if (req.method === 'GET' || req.method === 'POST') {
		let row = await loadProfile(dogId);
		const shouldFetch = req.method === 'GET' ? row === null : row === null || !isWithinCooldown(row);
		if (shouldFetch) {
			try {
				await refreshDogs([dog]);
			} catch (error) {
				// Website down: show what we stored before, if anything.
				if (row === null) throw error;
				console.error('[shelter] refresh failed:', error);
				return res.status(200).json({ ...profileJson(dog, row), refresh_failed: true });
			}
			row = await loadProfile(dogId);
		}
		return res.status(200).json(profileJson(dog, row));
	}

	if (req.method === 'PUT') {
		if (!hasRole(user, 'admin')) return res.status(403).json({ error: 'Insufficient permissions' });
		const row = await loadProfile(dogId);
		const suggestion = locationSuggestion(dog, row);
		if (!row || !suggestion) return res.status(409).json({ error: 'No kennel suggestion for this dog' });

		if (req.body?.action === 'ignore') {
			await pool.query('UPDATE dog_shelter_profiles SET ignored_location = location WHERE dog_id = $1', [dogId]);
		} else if (req.body?.action === 'accept') {
			// Store a region override only where the kennel map wouldn't give
			// the website's region anyway; keep ours if the website has none.
			const updates = ['kennel = $1'];
			const values: unknown[] = [suggestion.kennel];
			if (suggestion.region && (await hasColumn('dogs', 'region'))) {
				values.push(suggestion.region === getRegionForKennel(suggestion.kennel) ? null : suggestion.region);
				updates.push(`region = $${values.length}`);
			}
			values.push(dogId);
			await pool.query(`UPDATE dogs SET ${updates.join(', ')} WHERE id = $${values.length}`, values);
		} else {
			return res.status(400).json({ error: "action must be 'accept' or 'ignore'" });
		}

		const updatedDog = (await pool.query(`SELECT ${await dogColumns()} FROM dogs WHERE id = $1`, [dogId])).rows[0];
		return res.status(200).json(profileJson(updatedDog, await loadProfile(dogId)));
	}

	res.setHeader('Allow', ['GET', 'POST', 'PUT']);
	return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
}
