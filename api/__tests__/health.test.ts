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

import handler from '../health';

describe('GET /api/health', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('returns 200 with diagnostic info when DB is healthy', async () => {
		mockPool.query.mockResolvedValueOnce({
			rows: [{ now: '2026-03-31T12:00:00Z', db: 'shelter_dev' }],
		});

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		const body = res._body as Record<string, unknown>;
		expect(body.status).toBe('ok');
		expect(body.db_connected).toBe(true);
		expect(body.db_name).toBe('shelter_dev');
		expect(body.node_version).toBeDefined();
		expect(body.timestamp).toBeDefined();
	});

	it('returns 500 when DB connection fails', async () => {
		mockPool.query.mockRejectedValueOnce(new Error('ECONNREFUSED'));

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(500);
		const body = res._body as Record<string, unknown>;
		expect(body.status).toBe('error');
		expect(body.db_connected).toBe(false);
		expect(body.error).toBe('ECONNREFUSED');
	});
});
