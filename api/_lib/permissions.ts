/**
 * Role hierarchy and edit rules — the single place that decides who may
 * change what. Endpoints call these after authenticating the user.
 *
 * | Role        | Can                                                             |
 * |-------------|-----------------------------------------------------------------|
 * | (anonymous) | View everything                                                 |
 * | pending     | Same as anonymous (signed in, waiting for a role)               |
 * | volunteer   | Edit day plans from PLAN_EDIT_WINDOW_DAYS ago onward, edit      |
 * |             | their own dog familiarity                                       |
 * | admin       | Edit any day plan, dogs, volunteers, dog relationships,         |
 * |             | anyone's familiarity                                            |
 * | super_admin | Everything above + manage user accounts and roles               |
 */

export const ROLES = ['pending', 'volunteer', 'admin', 'super_admin'] as const;
export type Role = (typeof ROLES)[number];

export function isRole(value: unknown): value is Role {
	return typeof value === 'string' && (ROLES as readonly string[]).includes(value);
}

export function hasRole(user: { role: Role } | null, minimum: Role): boolean {
	return user !== null && ROLES.indexOf(user.role) >= ROLES.indexOf(minimum);
}

/** Volunteers may edit walks up to this many days in the past. */
export const PLAN_EDIT_WINDOW_DAYS = 3;

/** Dates are compared in the shelter's timezone, not the server's (UTC). */
const SHELTER_TIME_ZONE = 'Europe/Warsaw';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Today's date in the shelter's timezone, as YYYY-MM-DD. */
export function shelterToday(now: Date = new Date()): string {
	// en-CA formats dates as YYYY-MM-DD.
	return new Intl.DateTimeFormat('en-CA', { timeZone: SHELTER_TIME_ZONE }).format(now);
}

/** The earliest walk date a volunteer may still edit, as YYYY-MM-DD. */
export function earliestEditableDate(now: Date = new Date()): string {
	const today = new Date(`${shelterToday(now)}T00:00:00Z`);
	today.setUTCDate(today.getUTCDate() - PLAN_EDIT_WINDOW_DAYS);
	return today.toISOString().slice(0, 10);
}

/** Whether [user] may create/change/delete walks on [walkDate] (YYYY-MM-DD). */
export function canEditWalkDate(
	user: { role: Role } | null,
	walkDate: string,
	now: Date = new Date(),
): boolean {
	if (hasRole(user, 'admin')) return true;
	if (!hasRole(user, 'volunteer')) return false;
	// ISO dates compare correctly as strings.
	return ISO_DATE.test(walkDate) && walkDate >= earliestEditableDate(now);
}

/** Whether [user] may edit the dog familiarity of volunteer [volunteerId]. */
export function canEditFamiliarity(
	user: { role: Role; volunteerId: number | null } | null,
	volunteerId: number,
): boolean {
	if (hasRole(user, 'admin')) return true;
	return hasRole(user, 'volunteer') && user!.volunteerId === volunteerId;
}
