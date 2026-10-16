import { createMockPool, mockAuth, mockRequest, mockResponse, TEST_USERS, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return { __esModule: true, default: mockPool };
});
jest.mock('../_lib/auth', () => require('./helpers').authModuleMock);
jest.mock('../_lib/util', () => ({
	...jest.requireActual('../_lib/util'),
	hasColumn: jest.fn().mockResolvedValue(true),
}));
jest.mock('../_lib/shelter-site', () => ({
	...jest.requireActual('../_lib/shelter-site'),
	fetchShelterAnimals: jest.fn(),
}));

import type { VercelRequest } from '@vercel/node';
import handler from '../dogs';
import { locationSuggestion } from '../_lib/shelter-profiles';
import { fetchShelterAnimals, type ShelterAnimal } from '../_lib/shelter-site';

const fetchMock = fetchShelterAnimals as jest.Mock;

const DOG = { id: 12, shelterid: '573/26', kennel: '412', region: null };

const ANIMAL: ShelterAnimal = {
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
	description: 'Amigo to mądry pies.',
	siteModifiedAt: '2026-08-05T06:30:42Z',
};

function profileRow(overrides: Record<string, unknown> = {}) {
	return {
		found: true,
		status: 'Do adopcji',
		photo_url: ANIMAL.photoUrl,
		breed: ANIMAL.breed,
		color: ANIMAL.color,
		sex: ANIMAL.sex,
		birth_date: '2020-12-19',
		weight_kg: 24.5,
		neutered: true,
		arrival_date: '2026-06-20',
		arrival_reason: 'zwrot z adopcji',
		departure_date: null,
		location: '430 R12 (domek)',
		description: ANIMAL.description,
		site_modified_at: new Date('2026-08-05T06:30:42Z'),
		fetched_at: new Date(),
		ignored_location: null,
		...overrides,
	};
}

const minutesAgo = (m: number) => new Date(Date.now() - m * 60_000);
const shelter = (target: string, extra: Partial<{ method: string; body: unknown }> = {}) =>
	mockRequest({ method: 'GET', query: { shelter: target }, ...extra });

describe('/api/dogs?shelter=', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		mockPool._setResults([]);
		mockAuth.user = TEST_USERS.volunteer;
		fetchMock.mockReset();
		fetchMock.mockResolvedValue(new Map([['0573-26p', ANIMAL]]));
	});

	describe('GET <dogId>', () => {
		it('returns the stored profile without contacting the website', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow()] }]);
			await handler(shelter('12'), res);

			expect(res._status).toBe(200);
			expect(fetchMock).not.toHaveBeenCalled();
			expect(res._body).toMatchObject({
				dog_id: 12,
				url: 'https://napaluchu.waw.pl/animal/0573-26p/',
				found: true,
				status: 'Do adopcji',
				birth_date: '2020-12-19',
				weight_kg: 24.5,
				location_suggestion: { kennel: '430', region: 'R12' },
			});
		});

		it('fetches from the website on first view', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [] }, { rows: [] }, { rows: [profileRow()] }]);
			await handler(shelter('12'), res);

			expect(fetchMock).toHaveBeenCalledWith(['0573-26p']);
			const [sql, params] = mockPool.query.mock.calls[2];
			expect(sql).toContain('INSERT INTO dog_shelter_profiles');
			expect(params.slice(0, 4)).toEqual([12, true, 'Do adopcji', 'https://images.example/1.jpg']);
			expect(res._status).toBe(200);
		});

		it('records dogs the website does not have', async () => {
			fetchMock.mockResolvedValue(new Map());
			mockPool._setResults([{ rows: [DOG] }, { rows: [] }, { rows: [] }, { rows: [profileRow({ found: false })] }]);
			await handler(shelter('12'), res);

			expect(mockPool.query.mock.calls[2][1].slice(0, 3)).toEqual([12, false, null]);
			expect(res._body).toMatchObject({ found: false });
		});

		it('records dogs whose shelterid has no website page', async () => {
			mockPool._setResults([{ rows: [{ ...DOG, shelterid: 'S010' }] }, { rows: [] }, { rows: [] }, { rows: [] }]);
			await handler(shelter('12'), res);

			expect(fetchMock).toHaveBeenCalledWith([]);
			expect(res._body).toMatchObject({ url: null, found: false, fetched_at: null });
		});

		it('returns 404 for unknown dogs', async () => {
			await handler(shelter('999'), res);
			expect(res._status).toBe(404);
		});

		it('rejects targets that are not a dog id', async () => {
			await handler(shelter('abc'), res);
			expect(res._status).toBe(400);
		});

		it('is closed to anonymous visitors', async () => {
			mockAuth.user = null;
			await handler(shelter('12'), res);
			expect(res._status).toBe(401);
		});

		it('returns 500 when the website is down and nothing is stored', async () => {
			jest.spyOn(console, 'error').mockImplementation(() => {});
			fetchMock.mockRejectedValue(new Error('Shelter website responded 503'));
			mockPool._setResults([{ rows: [DOG] }, { rows: [] }]);
			await handler(shelter('12'), res);
			expect(res._status).toBe(500);
		});
	});

	describe('POST <dogId> (refresh now)', () => {
		it('re-fetches once the cooldown has passed', async () => {
			mockPool._setResults([
				{ rows: [DOG] },
				{ rows: [profileRow({ fetched_at: minutesAgo(6) })] },
				{ rows: [] },
				{ rows: [profileRow()] },
			]);
			await handler(shelter('12', { method: 'POST' }), res);

			expect(fetchMock).toHaveBeenCalledTimes(1);
			expect(res._status).toBe(200);
		});

		it('keeps the stored profile when the website is down', async () => {
			jest.spyOn(console, 'error').mockImplementation(() => {});
			fetchMock.mockRejectedValue(new Error('Shelter website responded 503'));
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow({ fetched_at: minutesAgo(60) })] }]);
			await handler(shelter('12', { method: 'POST' }), res);

			expect(res._status).toBe(200);
			expect(res._body).toMatchObject({ found: true, status: 'Do adopcji', refresh_failed: true });
		});

		it('returns the stored profile within the 5-minute cooldown', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow({ fetched_at: minutesAgo(2) })] }]);
			await handler(shelter('12', { method: 'POST' }), res);

			expect(fetchMock).not.toHaveBeenCalled();
			expect(res._status).toBe(200);
		});
	});

	describe('PUT <dogId> (kennel suggestion)', () => {
		it('accepts the website kennel, without a region override when the map agrees', async () => {
			// Kennel 430 maps to R12, so the region override is cleared.
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow()] }, { rows: [] }, { rows: [{ ...DOG, kennel: '430' }] }, { rows: [profileRow()] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'accept' } }), res);

			expect(mockPool.query.mock.calls[2]).toEqual(['UPDATE dogs SET kennel = $1, region = $2 WHERE id = $3', ['430', null, 12]]);
			expect(res._status).toBe(200);
			expect(res._body).toMatchObject({ location_suggestion: null });
		});

		it('stores the website region as an override when the map disagrees', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow({ location: '430 R5' })] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'accept' } }), res);

			expect(mockPool.query.mock.calls[2][1]).toEqual(['430', 'R5', 12]);
		});

		it('keeps our region when the website gives none', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow({ location: '430' })] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'accept' } }), res);

			expect(mockPool.query.mock.calls[2]).toEqual(['UPDATE dogs SET kennel = $1 WHERE id = $2', ['430', 12]]);
		});

		it('ignores the current website location', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow()] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'ignore' } }), res);

			expect(mockPool.query.mock.calls[2][0]).toBe('UPDATE dog_shelter_profiles SET ignored_location = location WHERE dog_id = $1');
		});

		it('is admin only', async () => {
			mockPool._setResults([{ rows: [DOG] }]);
			await handler(shelter('12', { method: 'PUT', body: { action: 'ignore' } }), res);
			expect(res._status).toBe(403);
		});

		it('returns 409 when there is nothing to accept', async () => {
			mockPool._setResults([{ rows: [{ ...DOG, kennel: '430' }] }, { rows: [profileRow()] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'accept' } }), res);
			expect(res._status).toBe(409);
		});

		it('rejects unknown actions', async () => {
			mockPool._setResults([{ rows: [DOG] }, { rows: [profileRow()] }]);
			mockAuth.user = TEST_USERS.admin;
			await handler(shelter('12', { method: 'PUT', body: { action: 'delete' } }), res);
			expect(res._status).toBe(400);
		});
	});

	it('returns 405 for other methods', async () => {
		mockPool._setResults([{ rows: [DOG] }]);
		await handler(shelter('12', { method: 'DELETE' }), res);
		expect(res._status).toBe(405);
	});

	describe('GET suggestions', () => {
		it('lists active dogs whose website kennel differs from ours', async () => {
			mockPool._setResults([
				{
					rows: [
						{ ...DOG, location: '430 R12 (domek)', ignored_location: null },
						{ ...DOG, id: 13, kennel: '430', location: '430 R12', ignored_location: null },
						{ ...DOG, id: 14, location: '430 R12', ignored_location: '430 R12' },
					],
				},
			]);
			await handler(shelter('suggestions'), res);

			expect(res._body).toEqual([
				{ dog_id: 12, location: '430 R12 (domek)', location_suggestion: { kennel: '430', region: 'R12' } },
			]);
		});

		it('only supports GET', async () => {
			await handler(shelter('suggestions', { method: 'POST' }), res);
			expect(res._status).toBe(405);
		});
	});

	describe('GET sync (nightly cron)', () => {
		const originalEnv = process.env;
		const cronRequest = (authorization?: string) =>
			({ method: 'GET', query: { shelter: 'sync' }, headers: { authorization } }) as unknown as VercelRequest;

		beforeEach(() => {
			process.env = { ...originalEnv, CRON_SECRET: 'cron-secret' };
			mockAuth.user = null;
		});

		afterAll(() => {
			process.env = originalEnv;
		});

		it('refreshes every active dog', async () => {
			mockPool._setResults([{ rows: [DOG, { ...DOG, id: 13, shelterid: '1/25' }] }]);
			await handler(cronRequest('Bearer cron-secret'), res);

			expect(fetchMock).toHaveBeenCalledWith(['0573-26p', '0001-25p']);
			expect(res._body).toEqual({ dogs: 2, found: 1 });
		});

		it('needs the cron secret', async () => {
			await handler(cronRequest('Bearer wrong'), res);
			expect(res._status).toBe(401);
			expect(mockPool.query).not.toHaveBeenCalled();
		});

		it('is disabled when CRON_SECRET is not set', async () => {
			delete process.env.CRON_SECRET;
			await handler(cronRequest('Bearer '), res);
			expect(res._status).toBe(401);
		});
	});
});

describe('locationSuggestion', () => {
	const dog = { kennel: '412', region: null };

	it('uses our region override when we have one', () => {
		expect(locationSuggestion({ kennel: '430', region: 'R12' }, { location: '430 R12', ignored_location: null })).toBeNull();
		expect(locationSuggestion({ kennel: '430', region: 'R5' }, { location: '430 R12', ignored_location: null })).toEqual({
			kennel: '430',
			region: 'R12',
		});
	});

	it('never suggests places that are not a numbered kennel', () => {
		expect(locationSuggestion(dog, { location: 'szpital', ignored_location: null })).toBeNull();
	});

	it('is null without website data', () => {
		expect(locationSuggestion(dog, null)).toBeNull();
		expect(locationSuggestion(dog, { location: null, ignored_location: null })).toBeNull();
	});
});
