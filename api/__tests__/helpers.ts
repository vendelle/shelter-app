/**
 * Shared mock utilities for API endpoint tests.
 *
 * Provides:
 * - A mock pg Pool with chainable query results
 * - Mock VercelRequest / VercelResponse builders
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';
import type { AuthUser } from '../_lib/auth';
import { hasRole, type Role } from '../_lib/permissions';

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

	res.send = jest.fn((body: unknown) => {
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

// ---------------------------------------------------------------------------
// Mock auth — endpoint tests swap `../_lib/auth` for this, then pick who is
// calling via `mockAuth.user`:
//
//   jest.mock('../_lib/auth', () => require('./helpers').authModuleMock);
//   beforeEach(() => { mockAuth.user = TEST_USERS.admin; });
// ---------------------------------------------------------------------------

export const TEST_USERS: Record<Role, AuthUser> = {
	pending: { id: 1, email: 'pending@test.pl', displayName: null, photoUrl: null, volunteerId: null, role: 'pending' },
	volunteer: { id: 2, email: 'volunteer@test.pl', displayName: 'Vol', photoUrl: null, volunteerId: 7, role: 'volunteer' },
	admin: { id: 3, email: 'admin@test.pl', displayName: 'Admin', photoUrl: null, volunteerId: null, role: 'admin' },
	super_admin: { id: 4, email: 'owner@test.pl', displayName: 'Owner', photoUrl: null, volunteerId: null, role: 'super_admin' },
};

export const mockAuth: { user: AuthUser | null } = { user: TEST_USERS.admin };

/** Same contract as the real `requireRole`, minus token verification. */
export const authModuleMock = {
	requireRole: jest.fn(async (_req: VercelRequest, res: VercelResponse, minimum: Role) => {
		const user = mockAuth.user;
		if (!user) {
			res.status(401).json({ error: 'Sign in required' });
			return null;
		}
		if (!hasRole(user, minimum)) {
			res.status(403).json({ error: 'Insufficient permissions' });
			return null;
		}
		return user;
	}),
};

/** The YYYY-MM-DD date [days] before [isoDate]. */
export function daysBefore(isoDate: string, days: number): string {
	const date = new Date(`${isoDate}T00:00:00Z`);
	date.setUTCDate(date.getUTCDate() - days);
	return date.toISOString().slice(0, 10);
}
