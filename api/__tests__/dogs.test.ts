import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

// Mock the connection module before importing the handler
let mockPool: MockPool;

jest.mock('../connection', () => {
	mockPool = createMockPool();
	return {
		__esModule: true,
		default: mockPool,
		getPool: () => mockPool,
	};
});

import handler from '../dogs';

describe('GET /api/dogs', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns list of non-archived dogs', async () => {
		const dogs = [
			{ id: 1, name: 'Burek', shelterid: 'S001', kennel: 'A1' },
			{ id: 2, name: 'Luna', shelterid: 'S002', kennel: 'A2' },
		];
		mockPool._setResults([{ rows: dogs }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual(dogs);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('archived IS NOT TRUE'),
		);
	});

	it('returns empty array when no dogs exist', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([]);
	});

	it('sets CORS headers', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res.setHeader).toHaveBeenCalledWith(
			'Access-Control-Allow-Origin',
			'*',
		);
	});

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);

		expect(res._status).toBe(200);
		expect(res.end).toHaveBeenCalled();
	});

	it('rejects non-GET methods with 405', async () => {
		await handler(mockRequest({ method: 'DELETE' }), res);

		expect(res._status).toBe(405);
		expect(res._body).toEqual({
			error: 'Method DELETE Not Allowed',
		});
	});

	it('returns 500 on database error', async () => {
		jest.spyOn(console, 'error').mockImplementation(() => {});
		mockPool.query.mockRejectedValueOnce(new Error('Connection refused'));

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(500);
		expect(res._body).toEqual({ error: 'Connection refused' });
	});
});
