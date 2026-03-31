import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

let mockPool: MockPool;

jest.mock('../connection', () => {
	mockPool = createMockPool();
	return {
		__esModule: true,
		default: mockPool,
		getPool: () => mockPool,
	};
});

import handler from '../dogs-walks';

describe('GET /api/dogs-walks', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		// Suppress production logging noise ([dogs-walks] Request: GET, etc.)
		jest.spyOn(console, 'log').mockImplementation(() => {});
	});

	it('returns dogs with walk counts', async () => {
		const rows = [
			{ id: 1, name: 'Burek', kennel: 'A1', shelterid: 'S001', this_week_walks: 2, last_week_walks: 3 },
			{ id: 2, name: 'Luna', kennel: 'A2', shelterid: 'S002', this_week_walks: 0, last_week_walks: 1 },
		];
		mockPool._setResults([{ rows }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(rows);
		expect(res._body).toHaveLength(2);
	});

	it('query filters out archived dogs', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('archived IS NOT TRUE'),
		);
	});

	it('query joins walks with deleted_at IS NULL filter', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('deleted_at IS NULL'),
		);
	});

	it('returns empty array for shelter with no dogs', async () => {
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

	it('rejects non-GET methods with 405', async () => {
		await handler(mockRequest({ method: 'PUT' }), res);

		expect(res._status).toBe(405);
	});

	it('returns 500 on database error', async () => {
		jest.spyOn(console, 'error').mockImplementation(() => {});
		jest.spyOn(console, 'log').mockImplementation(() => {});
		mockPool.query.mockRejectedValueOnce(new Error('connection lost'));

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(500);
		expect(res._body).toEqual({ error: 'connection lost' });
	});
});
