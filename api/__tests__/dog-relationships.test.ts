import { createMockPool, mockRequest, mockResponse, MockResponse } from './helpers';
import { mockAuth, TEST_USERS } from './helpers';

jest.mock('../_lib/auth', () => require('./helpers').authModuleMock);

// Callers are admins unless a test says otherwise.
beforeEach(() => {
	mockAuth.user = TEST_USERS.admin;
});

// Mock pool before importing handler
const mockPool = createMockPool();
jest.mock('../_lib/connection', () => mockPool);

import handler from '../dog-relationships';

describe('GET /api/dog-relationships', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns relationships for a specific dog', async () => {
		const rows = [
			{ id: 1, dog_id_1: 1, dog_id_2: 2, level: 'yard', notes: null, dog_name_1: 'Burek', dog_name_2: 'Luna' },
		];
		mockPool._setResults([{ rows }]);

		await handler(mockRequest({ method: 'GET', query: { dog_id: '1' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(rows);
	});

	it('returns all relationships when no dog_id', async () => {
		const rows = [
			{ id: 1, dog_id_1: 1, dog_id_2: 2, level: 'yard', notes: null, dog_name_1: 'Burek', dog_name_2: 'Luna' },
		];
		mockPool._setResults([{ rows }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(rows);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('ORDER BY d1.name'),
		);
	});
});

describe('PUT /api/dog-relationships', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('upserts a relationship', async () => {
		const row = { id: 1, dog_id_1: 1, dog_id_2: 2, level: 'contact_good', notes: 'walks well' };
		mockPool._setResults([{ rows: [row] }]);

		await handler(
			mockRequest({ method: 'PUT', body: { dog_id_1: 1, dog_id_2: 2, level: 'contact_good', notes: 'walks well' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(row);
	});

	it('canonically orders dog IDs', async () => {
		const row = { id: 1, dog_id_1: 2, dog_id_2: 5, level: 'yard', notes: null };
		mockPool._setResults([{ rows: [row] }]);

		await handler(
			mockRequest({ method: 'PUT', body: { dog_id_1: 5, dog_id_2: 2, level: 'yard' } }),
			res,
		);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('INSERT INTO dog_relationships'),
			[2, 5, 'yard', null],
		);
	});

	it('returns 400 when fields are missing', async () => {
		await handler(
			mockRequest({ method: 'PUT', body: { dog_id_1: 1 } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id_1, dog_id_2, and level are required' });
	});

	it('returns 400 when dog IDs are the same', async () => {
		await handler(
			mockRequest({ method: 'PUT', body: { dog_id_1: 1, dog_id_2: 1, level: 'yard' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'dog_id_1 and dog_id_2 must be different' });
	});

	it('returns 400 for invalid level', async () => {
		await handler(
			mockRequest({ method: 'PUT', body: { dog_id_1: 1, dog_id_2: 2, level: 'best_friends' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({
			error: 'level must be one of: yard, contact_good, contact_caution, parallel_good, parallel_caution, incompatible',
		});
	});
});

describe('DELETE /api/dog-relationships', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('deletes a relationship', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'DELETE', query: { dog_id_1: '1', dog_id_2: '3' } }),
			res,
		);

		expect(res._status).toBe(204);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('DELETE FROM dog_relationships'),
			[1, 3],
		);
	});

	it('canonically orders IDs on delete', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'DELETE', query: { dog_id_1: '5', dog_id_2: '2' } }),
			res,
		);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('DELETE FROM dog_relationships'),
			[2, 5],
		);
	});

	it('returns 400 when params are missing', async () => {
		await handler(
			mockRequest({ method: 'DELETE', query: { dog_id_1: '1' } }),
			res,
		);

		expect(res._status).toBe(400);
	});
});

describe('Unsupported methods', () => {
	it('returns 405 for POST', async () => {
		const res = mockResponse();
		await handler(mockRequest({ method: 'POST' }), res);
		expect(res._status).toBe(405);
	});
});

describe('/api/dog-relationships permissions', () => {
	it('rejects anonymous changes with 401', async () => {
		mockAuth.user = null;
		const res = mockResponse();
		await handler(mockRequest({ method: 'PUT', query: { id: '1' } }), res);
		expect(res._status).toBe(401);
	});

	it('rejects volunteers with 403 — changes need an admin', async () => {
		mockAuth.user = TEST_USERS.volunteer;
		const res = mockResponse();
		await handler(mockRequest({ method: 'PUT', query: { id: '1' } }), res);
		expect(res._status).toBe(403);
	});
});
