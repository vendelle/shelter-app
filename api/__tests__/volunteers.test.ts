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
