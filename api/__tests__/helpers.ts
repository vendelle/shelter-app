/**
 * Shared mock utilities for API endpoint tests.
 *
 * Provides:
 * - A mock pg Pool with chainable query results
 * - Mock VercelRequest / VercelResponse builders
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';

// ---------------------------------------------------------------------------
// Mock Pool
// ---------------------------------------------------------------------------

export interface MockPool {
	query: jest.Mock;
	_setResults: (results: Array<{ rows: unknown[] }>) => void;
}

export function createMockPool(): MockPool {
	const queryResults: Array<{ rows: unknown[] }> = [];
	let callIndex = 0;

	const query = jest.fn().mockImplementation(() => {
		const result = queryResults[callIndex] ?? { rows: [] };
		callIndex++;
		return Promise.resolve(result);
	});

	return {
		query,
		_setResults(results) {
			queryResults.length = 0;
			queryResults.push(...results);
			callIndex = 0;
		},
	};
}

// ---------------------------------------------------------------------------
// Mock Request
// ---------------------------------------------------------------------------

export function mockRequest(
	overrides: Partial<{
		method: string;
		query: Record<string, string | string[]>;
		body: unknown;
	}> = {},
): VercelRequest {
	return {
		method: overrides.method ?? 'GET',
		query: overrides.query ?? {},
		body: overrides.body ?? {},
	} as unknown as VercelRequest;
}

// ---------------------------------------------------------------------------
// Mock Response
// ---------------------------------------------------------------------------

export interface MockResponse extends VercelResponse {
	_status: number;
	_body: unknown;
	_headers: Record<string, string | string[]>;
}

export function mockResponse(): MockResponse {
	const res: Partial<MockResponse> = {
		_status: 200,
		_body: undefined,
		_headers: {},
	};

	res.status = jest.fn((code: number) => {
		res._status = code;
		return res as MockResponse;
	});

	res.json = jest.fn((body: unknown) => {
		res._body = body;
		return res as MockResponse;
	});

	res.end = jest.fn(() => res as MockResponse);

	res.setHeader = jest.fn((key: string, value: string | string[]) => {
		res._headers![key] = value;
		return res as MockResponse;
	});

	return res as MockResponse;
}
