import type { VercelRequest, VercelResponse } from '@vercel/node';
import pool, { getPool } from './connection';

/**
 * GET /api/health — diagnostic endpoint to verify:
 * 1. Function runs at all
 * 2. Env vars are set
 * 3. Database connection works
 */
export default async function handler(_req: VercelRequest, res: VercelResponse) {
	const checks: Record<string, unknown> = {
		status: 'ok',
		timestamp: new Date().toISOString(),
		node_version: process.version,
		env_DATABASE_URL_UNPOOLED: !!process.env.DATABASE_URL_UNPOOLED,
		env_DATABASE_URL: !!process.env.DATABASE_URL,
		env_DEV_DATABASE_URL_UNPOOLED: !!process.env.DEV_DATABASE_URL_UNPOOLED,
		env_DEV_DATABASE_URL: !!process.env.DEV_DATABASE_URL,
	};

	try {
		getPool(); // force init with logging
		checks.pool_created = true;

		const result = await pool.query('SELECT NOW() AS now, current_database() AS db');
		checks.db_connected = true;
		checks.db_time = result.rows[0].now;
		checks.db_name = result.rows[0].db;
	} catch (error) {
		checks.status = 'error';
		checks.db_connected = false;
		checks.error = error instanceof Error ? error.message : String(error);
		checks.error_stack = error instanceof Error ? error.stack : undefined;
	}

	const statusCode = checks.status === 'ok' ? 200 : 500;
	return res.status(statusCode).json(checks);
}
