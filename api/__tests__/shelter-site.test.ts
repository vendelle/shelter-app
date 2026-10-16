import { fetchShelterAnimals, parseLocation, toShelterAnimal } from '../_lib/shelter-site';

/** Trimmed copy of a real /wp-json/wp/v2/animal entry (Amigo, 0573/26). */
const AMIGO = {
	slug: '0573-26p',
	modified_gmt: '2026-08-05T06:30:42',
	'status-zwierzecia': [28],
	acf: {
		breed: 'MIX OGAR P',
		color: 'czarna podpalana ',
		gender_id: 'Samiec',
		weight: 24.5,
		spayed: true,
		date_of_birth: '20201219',
		data_znalezienia: '20260620',
		miejsce_znalezienia: 'zwrot z adopcji',
		data_wydania: null,
		boks_lokalizacja: '430 R12 (domek)',
		description: 'Amigo to mądry,<br/>wierny przyjaciel &amp; kompan.',
		photos: [{ photo_url: 'https://images.example/1.jpg' }, { photo_url: 'https://images.example/2.jpg' }],
	},
};

describe('toShelterAnimal', () => {
	it('normalises a website entry', () => {
		expect(toShelterAnimal(AMIGO)).toEqual({
			status: 'Do adopcji',
			photoUrl: 'https://images.example/1.jpg',
			breed: 'MIX OGAR P',
			color: 'czarna podpalana',
			sex: 'Samiec',
			birthDate: '2020-12-19',
			weightKg: 24.5,
			neutered: true,
			arrivalDate: '2026-06-20',
			arrivalReason: 'zwrot z adopcji',
			departureDate: null,
			location: '430 R12 (domek)',
			description: 'Amigo to mądry,\nwierny przyjaciel & kompan.',
			siteModifiedAt: '2026-08-05T06:30:42Z',
		});
	});

	it('treats the 0.1 kg placeholder and missing values as unknown', () => {
		const animal = toShelterAnimal({
			slug: 'x',
			acf: { weight: 0.1, date_of_birth: '', photos: null, description: '  ', spayed: undefined },
		});
		expect(animal).toMatchObject({
			weightKg: null,
			birthDate: null,
			photoUrl: null,
			description: null,
			neutered: null,
			status: null,
			siteModifiedAt: null,
		});
	});

	it('maps every status the website uses', () => {
		const status = (id: number) => toShelterAnimal({ slug: 'x', 'status-zwierzecia': [id] }).status;
		expect([27, 28, 29, 30, 31, 32, 33].map(status)).toEqual([
			'Kwarantanna',
			'Do adopcji',
			'Adopcja',
			'Odbiór',
			'Ucieczka',
			'Dom tymczasowy',
			'Zmarł',
		]);
		expect(status(99)).toBeNull();
	});
});

describe('parseLocation', () => {
	it.each([
		['430 R12 (domek)', { kennel: '430', region: 'R12' }],
		['332 r13', { kennel: '332', region: 'R13' }],
		['118', { kennel: '118', region: null }],
	])('parses %j', (location, expected) => {
		expect(parseLocation(location)).toEqual(expected);
	});

	it.each(['szpital', 'szpital kwarantanna', 'Kontener D2', '', null])('ignores %j', (location) => {
		expect(parseLocation(location)).toBeNull();
	});
});

describe('fetchShelterAnimals', () => {
	let fetchMock: jest.Mock;

	beforeEach(() => {
		fetchMock = jest.fn().mockResolvedValue({ ok: true, json: async () => [AMIGO] });
		global.fetch = fetchMock;
	});

	it('looks animals up by slug and keys them by slug', async () => {
		const animals = await fetchShelterAnimals(['0573-26p', '9999-99p']);
		expect([...animals.keys()]).toEqual(['0573-26p']);

		const url = new URL(fetchMock.mock.calls[0][0]);
		expect(url.searchParams.getAll('slug[]')).toEqual(['0573-26p', '9999-99p']);
		expect(url.searchParams.get('per_page')).toBe('100');
	});

	it('asks for at most 100 slugs per request', async () => {
		const slugs = Array.from({ length: 150 }, (_, i) => `${String(i).padStart(4, '0')}-26p`);
		await fetchShelterAnimals(slugs);
		expect(fetchMock).toHaveBeenCalledTimes(2);
		expect(new URL(fetchMock.mock.calls[1][0]).searchParams.getAll('slug[]')).toHaveLength(50);
	});

	it('makes no request for an empty list', async () => {
		expect((await fetchShelterAnimals([])).size).toBe(0);
		expect(fetchMock).not.toHaveBeenCalled();
	});

	it('throws when the website is down, so stored data is kept', async () => {
		fetchMock.mockResolvedValue({ ok: false, status: 503 });
		await expect(fetchShelterAnimals(['0573-26p'])).rejects.toThrow('Shelter website responded 503');
	});
});
