import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return {
		__esModule: true,
		default: mockPool,
		getPool: () => mockPool,
	};
});

import handler from '../volunteers';

describe('GET /api/volunteers', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns list of volunteers', async () => {
		const volunteers = [
			{ id: 1, first_name: 'Anna', last_name: 'Kowalska' },
			{ id: 2, first_name: 'Jan', last_name: 'Nowak' },
		];
		mockPool._setResults([{ rows: volunteers }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(volunteers);
	});

	it('returns only archived volunteers when only_archived=true', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { only_archived: 'true' } }), res);

		expect(res._status).toBe(200);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('archived = TRUE'),
		);
	});

	it('returns all volunteers when include_archived=true', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { include_archived: 'true' } }), res);

		expect(res._status).toBe(200);
		const query = mockPool.query.mock.calls[0][0] as string;
		expect(query).not.toContain('WHERE');
	});

	it('returns empty array when no volunteers exist', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([]);
	});

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);

		expect(res._status).toBe(200);
		expect(res.end).toHaveBeenCalled();
	});

	it('rejects DELETE with 405', async () => {
		await handler(mockRequest({ method: 'DELETE' }), res);

		expect(res._status).toBe(405);
	});

	it('returns 500 on database error', async () => {
		jest.spyOn(console, 'error').mockImplementation(() => {});
		mockPool.query.mockRejectedValueOnce(new Error('timeout'));

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(500);
		expect(res._body).toEqual({ error: 'timeout' });
	});
});

describe('GET /api/volunteers?id=X (profile)', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns volunteer, visits, and dogs', async () => {
		const volunteer = { id: 1, first_name: 'Anna', last_name: 'Kowalska', archived: false, role: 'senior' };
		const visits = [
			{ walk_date: '2026-08-04', walk_count: 2 },
			{ walk_date: '2026-08-01', walk_count: 2 },
		];
		const dogs = [
			{ dog_id: 1, dog_name: 'Rex', walk_count: 12 },
			{ dog_id: 2, dog_name: 'Cody', walk_count: 0 },
		];
		mockPool._setResults([{ rows: [volunteer] }, { rows: visits }, { rows: dogs }]);

		await handler(mockRequest({ method: 'GET', query: { id: '1' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({ volunteer, visits, dogs });
	});

	it('returns 404 when volunteer does not exist', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { id: '999' } }), res);

		expect(res._status).toBe(404);
		expect(res._body).toEqual({ error: 'Volunteer not found' });
	});

	it('returns empty visits and dogs when the volunteer has no walks', async () => {
		const volunteer = { id: 2, first_name: 'Jan', last_name: 'Nowak', archived: false, role: 'new' };
		mockPool._setResults([{ rows: [volunteer] }, { rows: [] }, { rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { id: '2' } }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({ volunteer, visits: [], dogs: [] });
	});
});

describe('POST /api/volunteers', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('creates a volunteer and returns 201', async () => {
		const newVol = { id: 10, first_name: 'Anna', last_name: 'K', archived: false, role: 'supporter' };
		mockPool._setResults([{ rows: [newVol] }]);

		await handler(
			mockRequest({ method: 'POST', body: { first_name: 'Anna', last_name: 'K', role: 'supporter' } }),
			res,
		);

		expect(res._status).toBe(201);
		expect(res._body).toEqual(newVol);
	});

	it('defaults role to new when not provided', async () => {
		const newVol = { id: 11, first_name: 'Jan', last_name: 'N', archived: false, role: 'new' };
		mockPool._setResults([{ rows: [newVol] }]);

		await handler(
			mockRequest({ method: 'POST', body: { first_name: 'Jan', last_name: 'N' } }),
			res,
		);

		expect(res._status).toBe(201);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.any(String),
			['Jan', 'N', 'new'],
		);
	});

	it('returns 400 when first_name is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: { last_name: 'K' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'first_name and last_name are required' });
	});

	it('returns 400 when last_name is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: { first_name: 'Anna' } }),
			res,
		);

		expect(res._status).toBe(400);
	});
});

describe('PATCH /api/volunteers', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('updates volunteer name', async () => {
		const updated = { id: 1, first_name: 'Anna Maria', last_name: 'K', archived: false, role: 'new' };
		mockPool._setResults([{ rows: [updated] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1, first_name: 'Anna Maria' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(updated);
	});

	it('updates multiple fields including role', async () => {
		const updated = { id: 1, first_name: 'Anna', last_name: 'Nowak', archived: false, role: 'senior' };
		mockPool._setResults([{ rows: [updated] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1, first_name: 'Anna', last_name: 'Nowak', role: 'senior' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('first_name'),
			expect.arrayContaining(['Anna', 'Nowak', 'senior', 1]),
		);
	});

	it('returns 400 when id is missing', async () => {
		await handler(
			mockRequest({ method: 'PATCH', body: { first_name: 'Anna' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'id is required' });
	});

	it('returns 400 when no fields to update', async () => {
		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1 } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'No fields to update' });
	});

	it('returns 404 when volunteer not found', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 999, first_name: 'Ghost' } }),
			res,
		);

		expect(res._status).toBe(404);
		expect(res._body).toEqual({ error: 'Volunteer not found' });
	});
});

describe('PUT /api/volunteers', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('archives a volunteer', async () => {
		const archived = { id: 1, first_name: 'Anna', last_name: 'K', archived: true, role: 'new' };
		mockPool._setResults([{ rows: [archived] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '1', archive: 'true' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(archived);
	});

	it('unarchives a volunteer', async () => {
		const unarchived = { id: 1, first_name: 'Anna', last_name: 'K', archived: false, role: 'new' };
		mockPool._setResults([{ rows: [unarchived] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '1', archive: 'false' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(unarchived);
	});

	it('returns 400 when id query param is missing', async () => {
		await handler(
			mockRequest({ method: 'PUT', query: {} }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'id query param is required' });
	});

	it('returns 404 when volunteer not found', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '999', archive: 'true' } }),
			res,
		);

		expect(res._status).toBe(404);
		expect(res._body).toEqual({ error: 'Volunteer not found' });
	});
});
