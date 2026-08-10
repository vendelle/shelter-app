import { createMockPool, mockRequest, mockResponse, type MockPool, type MockResponse } from './helpers';

// Mock the connection module before importing the handler
let mockPool: MockPool;

jest.mock('../_lib/connection', () => {
	mockPool = createMockPool();
	return {
		__esModule: true,
		default: mockPool,
		getPool: () => mockPool,
	};
});

// Mock hasColumn to always return true (region column exists)
jest.mock('../_lib/util', () => {
	const actual = jest.requireActual('../_lib/util');
	return {
		...actual,
		hasColumn: jest.fn().mockResolvedValue(true),
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
		expect(res._body).toEqual([
			{ ...dogs[0], region: 'R5', region_override: null, arrival_date: null, departure_date: null, shelter_url: null },
			{ ...dogs[1], region: 'R5', region_override: null, arrival_date: null, departure_date: null, shelter_url: null },
		]);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('archived IS NOT TRUE'),
		);
	});

	it('formats arrival/departure dates and builds a shelter_url from shelterid', async () => {
		const dogs = [
			{
				id: 4,
				name: 'Piku',
				shelterid: '573/26',
				kennel: 'A1',
				arrival_date: new Date('2026-01-15'),
				departure_date: null,
			},
		];
		mockPool._setResults([{ rows: dogs }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect(res._body).toEqual([
			{
				...dogs[0],
				region: 'R5',
				region_override: null,
				arrival_date: '2026-01-15',
				departure_date: null,
				shelter_url: 'https://napaluchu.waw.pl/animal/0573-26p/',
			},
		]);
	});

	it('omits shelter_url when shelterid does not match the number/year shape', async () => {
		const dogs = [{ id: 5, name: 'Mystery', shelterid: 'S010', kennel: 'A1' }];
		mockPool._setResults([{ rows: dogs }]);

		await handler(mockRequest({ method: 'GET' }), res);

		expect(res._status).toBe(200);
		expect((res._body as Array<Record<string, unknown>>)[0].shelter_url).toBeNull();
	});

	it('returns only archived dogs when only_archived=true', async () => {
		const dogs = [{ id: 3, name: 'Rex', shelterid: 'S003', kennel: 'B1' }];
		mockPool._setResults([{ rows: dogs }]);

		await handler(mockRequest({ method: 'GET', query: { only_archived: 'true' } }), res);

		expect(res._status).toBe(200);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('archived = TRUE'),
		);
	});

	it('returns all dogs when include_archived=true', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(mockRequest({ method: 'GET', query: { include_archived: 'true' } }), res);

		expect(res._status).toBe(200);
		const query = mockPool.query.mock.calls[0][0] as string;
		expect(query).not.toContain('WHERE');
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

	it('rejects non-supported methods with 405', async () => {
		await handler(mockRequest({ method: 'HEAD' }), res);

		expect(res._status).toBe(405);
		expect(res._body).toEqual({
			error: 'Method HEAD Not Allowed',
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

describe('POST /api/dogs', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('creates a dog and returns 201', async () => {
		const newDog = { id: 10, name: 'Rex', shelterid: 'S010', kennel: 'C3', archived: false };
		mockPool._setResults([{ rows: [newDog] }]);

		await handler(
			mockRequest({ method: 'POST', body: { name: 'Rex', shelterid: 'S010', kennel: 'C3' } }),
			res,
		);

		expect(res._status).toBe(201);
		expect(res._body).toEqual({
			...newDog,
			region: 'R5',
			region_override: null,
			arrival_date: null,
			departure_date: null,
			shelter_url: null,
		});
	});

	it('passes arrival_date and departure_date through on create', async () => {
		const newDog = {
			id: 11,
			name: 'Fido',
			shelterid: '2222/26',
			kennel: 'C4',
			archived: false,
			arrival_date: new Date('2026-02-01'),
			departure_date: null,
		};
		mockPool._setResults([{ rows: [newDog] }]);

		await handler(
			mockRequest({
				method: 'POST',
				body: {
					name: 'Fido',
					shelterid: '2222/26',
					kennel: 'C4',
					arrival_date: '2026-02-01',
				},
			}),
			res,
		);

		expect(res._status).toBe(201);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('arrival_date'),
			expect.arrayContaining(['2026-02-01']),
		);
		expect((res._body as Record<string, unknown>).arrival_date).toBe('2026-02-01');
		expect((res._body as Record<string, unknown>).shelter_url).toBe(
			'https://napaluchu.waw.pl/animal/2222-26p/',
		);
	});

	it('returns 400 when name is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: { shelterid: 'S010', kennel: 'C3' } }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'name, shelterid, and kennel are required' });
	});

	it('returns 400 when shelterid is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: { name: 'Rex', kennel: 'C3' } }),
			res,
		);

		expect(res._status).toBe(400);
	});

	it('returns 400 when kennel is missing', async () => {
		await handler(
			mockRequest({ method: 'POST', body: { name: 'Rex', shelterid: 'S010' } }),
			res,
		);

		expect(res._status).toBe(400);
	});
});

describe('PATCH /api/dogs', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('updates a dog name', async () => {
		const updated = { id: 1, name: 'Burek Jr', shelterid: 'S001', kennel: 'A1', archived: false };
		mockPool._setResults([{ rows: [updated] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1, name: 'Burek Jr' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({
			...updated,
			region: 'R5',
			region_override: null,
			arrival_date: null,
			departure_date: null,
			shelter_url: null,
		});
	});

	it('updates departure_date', async () => {
		const updated = {
			id: 1,
			name: 'Burek',
			shelterid: 'S001',
			kennel: 'A1',
			archived: false,
			arrival_date: null,
			departure_date: new Date('2026-03-01'),
		};
		mockPool._setResults([{ rows: [updated] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1, departure_date: '2026-03-01' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('departure_date'),
			expect.arrayContaining(['2026-03-01', 1]),
		);
		expect((res._body as Record<string, unknown>).departure_date).toBe('2026-03-01');
	});

	it('updates multiple fields', async () => {
		const updated = { id: 1, name: 'Luna', shelterid: 'S099', kennel: 'B2', archived: false };
		mockPool._setResults([{ rows: [updated] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 1, name: 'Luna', shelterid: 'S099', kennel: 'B2' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(mockPool.query).toHaveBeenCalledWith(
			expect.stringContaining('name'),
			expect.arrayContaining(['Luna', 'S099', 'B2', 1]),
		);
	});

	it('returns 400 when id is missing', async () => {
		await handler(
			mockRequest({ method: 'PATCH', body: { name: 'Rex' } }),
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

	it('returns 404 when dog not found', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'PATCH', body: { id: 999, name: 'Ghost' } }),
			res,
		);

		expect(res._status).toBe(404);
		expect(res._body).toEqual({ error: 'Dog not found' });
	});
});

describe('PUT /api/dogs', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
	});

	it('archives a dog', async () => {
		const archived = { id: 1, name: 'Burek', shelterid: 'S001', kennel: 'A1', archived: true };
		mockPool._setResults([{ rows: [archived] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '1', archive: 'true' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({
			...archived,
			region: 'R5',
			region_override: null,
			arrival_date: null,
			departure_date: null,
			shelter_url: null,
		});
	});

	it('unarchives a dog', async () => {
		const unarchived = { id: 1, name: 'Burek', shelterid: 'S001', kennel: 'A1', archived: false };
		mockPool._setResults([{ rows: [unarchived] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '1', archive: 'false' } }),
			res,
		);

		expect(res._status).toBe(200);
		expect(res._body).toEqual({
			...unarchived,
			region: 'R5',
			region_override: null,
			arrival_date: null,
			departure_date: null,
			shelter_url: null,
		});
	});

	it('returns 400 when id query param is missing', async () => {
		await handler(
			mockRequest({ method: 'PUT', query: {} }),
			res,
		);

		expect(res._status).toBe(400);
		expect(res._body).toEqual({ error: 'id query param is required' });
	});

	it('returns 404 when dog not found', async () => {
		mockPool._setResults([{ rows: [] }]);

		await handler(
			mockRequest({ method: 'PUT', query: { id: '999', archive: 'true' } }),
			res,
		);

		expect(res._status).toBe(404);
		expect(res._body).toEqual({ error: 'Dog not found' });
	});
});
