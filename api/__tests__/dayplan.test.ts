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

import handler from '../dayplan';

describe('/api/dayplan', () => {
	let res: MockResponse;

	beforeEach(() => {
		res = mockResponse();
		mockPool.query.mockReset();
	});

	// -----------------------------------------------------------------------
	// GET
	// -----------------------------------------------------------------------

	describe('GET', () => {
		it('returns 400 when date is missing', async () => {
			await handler(mockRequest({ method: 'GET', query: {} }), res);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'date query parameter is required' });
		});

		it('returns walks with merged volunteer notes', async () => {
			const walkRows = [
				{
					id: 1,
					dog_id: 10,
					dog_name: 'Burek',
					kennel: 'A1',
					volunteer_id: 100,
					volunteer_name: 'Anna Kowalska',
					dog_note: 'shy',
					group_index: 1,
				},
				{
					id: 2,
					dog_id: 11,
					dog_name: 'Luna',
					kennel: 'A2',
					volunteer_id: 100,
					volunteer_name: 'Anna Kowalska',
					dog_note: null,
					group_index: 1,
				},
			];
			const volNoteRows = [
				{ volunteer_id: 100, note: '10-13 only' },
			];

			mockPool.query
				.mockResolvedValueOnce({ rows: walkRows })   // walks query
				.mockResolvedValueOnce({ rows: volNoteRows }); // volunteer notes query

			await handler(
				mockRequest({ method: 'GET', query: { date: '2026-03-31' } }),
				res,
			);

			expect(res._status).toBe(200);
			const body = res._body as unknown[];
			expect(body).toHaveLength(2);

			// Both walks should have the volunteer note merged
			expect((body[0] as Record<string, unknown>).volunteer_note).toBe('10-13 only');
			expect((body[1] as Record<string, unknown>).volunteer_note).toBe('10-13 only');

			// Dog-level fields should be preserved
			expect((body[0] as Record<string, unknown>).dog_note).toBe('shy');
			expect((body[0] as Record<string, unknown>).group_index).toBe(1);
		});

		it('returns empty array for date with no walks', async () => {
			mockPool.query
				.mockResolvedValueOnce({ rows: [] })
				.mockResolvedValueOnce({ rows: [] });

			await handler(
				mockRequest({ method: 'GET', query: { date: '2026-01-01' } }),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual([]);
		});

		it('returns null for volunteer_note when no note exists', async () => {
			mockPool.query
				.mockResolvedValueOnce({
					rows: [{
						id: 1, dog_id: 10, dog_name: 'Burek', kennel: 'A1',
						volunteer_id: 200, volunteer_name: 'Jan Nowak',
						dog_note: null, group_index: null,
					}],
				})
				.mockResolvedValueOnce({ rows: [] }); // no volunteer notes

			await handler(
				mockRequest({ method: 'GET', query: { date: '2026-03-31' } }),
				res,
			);

			const body = res._body as Record<string, unknown>[];
			expect(body[0].volunteer_note).toBeNull();
		});
	});

	// -----------------------------------------------------------------------
	// POST
	// -----------------------------------------------------------------------

	describe('POST', () => {
		it('returns 400 when walk_date is missing', async () => {
			await handler(
				mockRequest({ method: 'POST', body: { walks: [] } }),
				res,
			);

			expect(res._status).toBe(400);
		});

		it('returns 400 when walks array is missing', async () => {
			await handler(
				mockRequest({ method: 'POST', body: { walk_date: '2026-03-31' } }),
				res,
			);

			expect(res._status).toBe(400);
		});

		it('returns 400 for invalid walk data (non-integer dog_id)', async () => {
			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 'abc', volunteer_id: 1 }],
					},
				}),
				res,
			);

			expect(res._status).toBe(400);
			expect(res._body).toEqual({ error: 'Invalid walk data' });
		});

		it('inserts new walks and commits', async () => {
			// BEGIN, existing query, INSERT, COMMIT
			mockPool.query
				.mockResolvedValueOnce({ rows: [] }) // BEGIN
				.mockResolvedValueOnce({ rows: [] }) // SELECT existing (none)
				.mockResolvedValueOnce({ rows: [] }) // INSERT walk
				.mockResolvedValueOnce({ rows: [] }); // COMMIT

			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 10, volunteer_id: 100, dog_note: 'shy', group_index: 1 }],
					},
				}),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual({ ok: true });

			// Verify BEGIN and COMMIT were called
			const calls = mockPool.query.mock.calls.map((c: unknown[]) => c[0]);
			expect(calls[0]).toBe('BEGIN');
			expect(calls[calls.length - 1]).toBe('COMMIT');
		});

		it('saves volunteer notes', async () => {
			// BEGIN, existing, INSERT walk, DELETE old notes, INSERT note, COMMIT
			mockPool.query.mockResolvedValue({ rows: [] });

			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 10, volunteer_id: 100 }],
						volunteer_notes: [
							{ volunteer_id: 100, note: '10-13' },
						],
					},
				}),
				res,
			);

			expect(res._status).toBe(200);

			// Check that volunteer note insert query was issued
			const insertNoteCalls = mockPool.query.mock.calls.filter(
				(c: unknown[]) => typeof c[0] === 'string' && (c[0] as string).includes('day_plan_volunteer_notes'),
			);
			expect(insertNoteCalls.length).toBeGreaterThanOrEqual(1);
		});

		it('skips empty volunteer notes', async () => {
			mockPool.query.mockResolvedValue({ rows: [] });

			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 10, volunteer_id: 100 }],
						volunteer_notes: [
							{ volunteer_id: 100, note: '' },
							{ volunteer_id: 101, note: '   ' },
						],
					},
				}),
				res,
			);

			expect(res._status).toBe(200);

			// Only the DELETE should reference day_plan_volunteer_notes, no INSERT
			const noteInserts = mockPool.query.mock.calls.filter(
				(c: unknown[]) =>
					typeof c[0] === 'string' &&
					(c[0] as string).includes('INSERT INTO day_plan_volunteer_notes'),
			);
			expect(noteInserts).toHaveLength(0);
		});

		it('rolls back transaction on error', async () => {
			mockPool.query
				.mockResolvedValueOnce({ rows: [] }) // BEGIN
				.mockRejectedValueOnce(new Error('constraint violation')); // SELECT fails

			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 10, volunteer_id: 100 }],
					},
				}),
				res,
			);

			expect(res._status).toBe(500);

			// Verify ROLLBACK was called
			const calls = mockPool.query.mock.calls.map((c: unknown[]) => c[0]);
			expect(calls).toContain('ROLLBACK');
		});

		it('accepts walks with null volunteer_id (unassigned dogs)', async () => {
			mockPool.query.mockResolvedValue({ rows: [] });

			await handler(
				mockRequest({
					method: 'POST',
					body: {
						walk_date: '2026-03-31',
						walks: [{ dog_id: 10, volunteer_id: null }],
					},
				}),
				res,
			);

			expect(res._status).toBe(200);
			expect(res._body).toEqual({ ok: true });
		});
	});

	// -----------------------------------------------------------------------
	// Method handling
	// -----------------------------------------------------------------------

	it('handles OPTIONS preflight', async () => {
		await handler(mockRequest({ method: 'OPTIONS' }), res);

		expect(res._status).toBe(200);
		expect(res.end).toHaveBeenCalled();
	});

	it('rejects unsupported methods with 405', async () => {
		// For non-GET/POST, the handler still does pool queries for CORS etc.
		// But it should eventually return 405
		mockPool.query.mockResolvedValue({ rows: [] });

		await handler(mockRequest({ method: 'DELETE' }), res);

		expect(res._status).toBe(405);
	});
});
