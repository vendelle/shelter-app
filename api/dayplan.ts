import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders } from './util';
import pool from './connection';

/**
 * GET  /api/dayplan?date=YYYY-MM-DD  → walks for that date grouped by volunteer
 * POST /api/dayplan                  → save/update all walks for a date (same as puszek)
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
	setCorsHeaders(res);
	if (req.method === 'OPTIONS') return res.status(200).end();

	try {
		if (req.method === 'GET') {
			const { date } = req.query;

			if (!date) {
				return res.status(400).json({ error: 'date query parameter is required' });
			}

			const result = await pool.query(
				`SELECT
					w.id,
					w.dog_id,
					d.name AS dog_name,
					d.kennel,
					w.volunteer_id,
					v.first_name || ' ' || v.last_name AS volunteer_name,
					w.notes
				FROM walks w
				LEFT JOIN dogs d ON w.dog_id = d.id
				LEFT JOIN volunteers v ON w.volunteer_id = v.id
				WHERE w.walk_date = $1 AND w.deleted_at IS NULL
				ORDER BY w.volunteer_id, w.id`,
				[date],
			);

			return res.status(200).json(result.rows);
		}

		if (req.method === 'POST') {
			const { walk_date, walks } = req.body;

			if (!walk_date || !Array.isArray(walks)) {
				return res.status(400).json({ error: 'walk_date and walks array are required' });
			}

			if (
				!walks.every(
					({ dog_id, volunteer_id }: { dog_id: unknown; volunteer_id: unknown }) =>
						Number.isInteger(dog_id) &&
						(volunteer_id === null || Number.isInteger(volunteer_id)),
				)
			) {
				return res.status(400).json({ error: 'Invalid walk data' });
			}

			await pool.query('BEGIN');

			try {
				// Existing walks for this date
				const existingRes = await pool.query(
					'SELECT id, dog_id, volunteer_id FROM walks WHERE walk_date = $1 AND deleted_at IS NULL',
					[walk_date],
				);
				const existingWalks = existingRes.rows;
				const existingMap = new Map(
					existingWalks.map((w: { id: number; dog_id: number; volunteer_id: number | null }) => [
						`${w.dog_id}`,
						w,
					]),
				);
				const newMap = new Map(
					walks.map((w: { dog_id: number }) => [`${w.dog_id}`, w]),
				);

				// Insertions
				const inserts = walks.filter(
					(w: { dog_id: number }) => !existingMap.has(`${w.dog_id}`),
				);
				if (inserts.length > 0) {
					const placeholders = inserts
						.map((_: unknown, i: number) => `($${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`)
						.join(',');
					const values = inserts.flatMap(
						(w: { dog_id: number; volunteer_id: number | null }) => [
							w.dog_id,
							w.volunteer_id || null,
							walk_date,
						],
					);
					await pool.query(
						`INSERT INTO walks (dog_id, volunteer_id, walk_date) VALUES ${placeholders}`,
						values,
					);
				}

				// Updates
				for (const { dog_id, volunteer_id } of walks) {
					const existing = existingMap.get(`${dog_id}`) as
						| { id: number; volunteer_id: number | null }
						| undefined;
					if (existing && existing.volunteer_id !== volunteer_id) {
						await pool.query(
							'UPDATE walks SET volunteer_id = $1 WHERE id = $2',
							[volunteer_id || null, existing.id],
						);
					}
				}

				// Deletions (walks that existed but are no longer in the plan)
				const deleteIds = existingWalks
					.filter((w: { dog_id: number }) => !newMap.has(`${w.dog_id}`))
					.map((w: { id: number }) => w.id);
				if (deleteIds.length > 0) {
					await pool.query(
						'UPDATE walks SET deleted_at = NOW() WHERE id = ANY($1)',
						[deleteIds],
					);
				}

				await pool.query('COMMIT');

				// Return updated walks
				const updatedRes = await pool.query(
					'SELECT id, dog_id, volunteer_id FROM walks WHERE walk_date = $1 AND deleted_at IS NULL',
					[walk_date],
				);
				return res.status(200).json(updatedRes.rows);
			} catch (error) {
				await pool.query('ROLLBACK');
				throw error;
			}
		}

		res.setHeader('Allow', ['GET', 'POST']);
		return res.status(405).json({ error: `Method ${req.method} Not Allowed` });
	} catch (error) {
		handleError(error, res);
	}
}
