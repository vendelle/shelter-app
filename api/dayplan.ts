import type { VercelRequest, VercelResponse } from '@vercel/node';
import { handleError, setCorsHeaders, hasColumn } from './_lib/util';
import pool from './_lib/connection';
import { getRegionForKennel } from './_lib/kennel-regions';
import { requireAuth } from './_lib/auth-middleware';

/**
 * GET  /api/dayplan?date=YYYY-MM-DD  → walks + volunteer notes for that date
 * POST /api/dayplan                  → save/update all walks + notes for a date
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

			const hasRegionCol = await hasColumn('dogs', 'region');
			const regionSelect = hasRegionCol ? 'd.region AS db_region,' : '';

			// Walks with dog info
			const walksRes = await pool.query(
				`SELECT
					w.id,
					w.dog_id,
					d.name AS dog_name,
					d.kennel,
					d.shelterid,
					${regionSelect}
					w.volunteer_id,
					v.first_name || ' ' || v.last_name AS volunteer_name,
					w.notes AS dog_note,
					w.group_index
				FROM walks w
				LEFT JOIN dogs d ON w.dog_id = d.id
				LEFT JOIN volunteers v ON w.volunteer_id = v.id
				WHERE w.walk_date = $1 AND w.deleted_at IS NULL
				ORDER BY w.volunteer_id, w.id`,
				[date],
			);

			// Volunteer notes for this date
			const volNotesRes = await pool.query(
				`SELECT volunteer_id, note
				FROM day_plan_volunteer_notes
				WHERE plan_date = $1`,
				[date],
			);
			const volNotes = new Map(
				volNotesRes.rows.map((r: { volunteer_id: number; note: string }) => [
					r.volunteer_id,
					r.note,
				]),
			);

			// Attach volunteer_note and computed region to each walk row
			const rows = walksRes.rows.map(
				(r: { volunteer_id: number; [key: string]: unknown }) => ({
					...r,
					region: (r.db_region as string) || getRegionForKennel(r.kennel as string),
					db_region: undefined,
					volunteer_note: volNotes.get(r.volunteer_id) || null,
				}),
			);

			return res.status(200).json(rows);
		}

		if (req.method === 'POST') {
			const user = await requireAuth(req, res);
			if (!user) return;

			const { walk_date, walks, volunteer_notes } = req.body;

			if (!walk_date || !Array.isArray(walks)) {
				return res.status(400).json({ error: 'walk_date and walks array are required' });
			}

			if (
				!walks.every(
					({
						dog_id,
						volunteer_id,
					}: {
						dog_id: unknown;
						volunteer_id: unknown;
					}) =>
						Number.isInteger(dog_id) &&
						(volunteer_id === null || Number.isInteger(volunteer_id)),
				)
			) {
				return res.status(400).json({ error: 'Invalid walk data' });
			}

			await pool.query('BEGIN');

			try {
				// --- Walks (insert/update/delete) ---

				const existingRes = await pool.query(
					'SELECT id, dog_id, volunteer_id, notes, group_index FROM walks WHERE walk_date = $1 AND deleted_at IS NULL',
					[walk_date],
				);
				const existingWalks = existingRes.rows;
				const existingMap = new Map(
					existingWalks.map(
						(w: {
							id: number;
							dog_id: number;
							volunteer_id: number | null;
							notes: string | null;
							group_index: number | null;
						}) => [`${w.dog_id}`, w],
					),
				);
				const newMap = new Map(
					walks.map((w: { dog_id: number }) => [`${w.dog_id}`, w]),
				);

				// Insertions
				const inserts = walks.filter(
					(w: { dog_id: number }) => !existingMap.has(`${w.dog_id}`),
				);
				for (const w of inserts) {
					await pool.query(
						`INSERT INTO walks (dog_id, volunteer_id, walk_date, notes, group_index)
						 VALUES ($1, $2, $3, $4, $5)`,
						[
							w.dog_id,
							w.volunteer_id || null,
							walk_date,
							w.dog_note || null,
							w.group_index ?? null,
						],
					);
				}

				// Updates
				for (const w of walks) {
					const existing = existingMap.get(`${w.dog_id}`) as
						| {
								id: number;
								volunteer_id: number | null;
								notes: string | null;
								group_index: number | null;
						  }
						| undefined;
					if (existing) {
						const needsUpdate =
							existing.volunteer_id !== (w.volunteer_id || null) ||
							existing.notes !== (w.dog_note || null) ||
							existing.group_index !== (w.group_index ?? null);

						if (needsUpdate) {
							await pool.query(
								'UPDATE walks SET volunteer_id = $1, notes = $2, group_index = $3 WHERE id = $4',
								[
									w.volunteer_id || null,
									w.dog_note || null,
									w.group_index ?? null,
									existing.id,
								],
							);
						}
					}
				}

				// Deletions
				const deleteIds = existingWalks
					.filter((w: { dog_id: number }) => !newMap.has(`${w.dog_id}`))
					.map((w: { id: number }) => w.id);
				if (deleteIds.length > 0) {
					await pool.query(
						'UPDATE walks SET deleted_at = NOW() WHERE id = ANY($1)',
						[deleteIds],
					);
				}

				// --- Volunteer notes (upsert/delete) ---

				if (Array.isArray(volunteer_notes)) {
					// Delete existing notes for this date
					await pool.query(
						'DELETE FROM day_plan_volunteer_notes WHERE plan_date = $1',
						[walk_date],
					);

					// Insert new notes (only non-empty)
					const notesToInsert = volunteer_notes.filter(
						(n: { note?: string }) => n.note && n.note.trim(),
					);
					for (const n of notesToInsert) {
						await pool.query(
							`INSERT INTO day_plan_volunteer_notes (plan_date, volunteer_id, note)
							 VALUES ($1, $2, $3)`,
							[walk_date, n.volunteer_id, n.note],
						);
					}
				}

				await pool.query('COMMIT');

				return res.status(200).json({ ok: true });
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
