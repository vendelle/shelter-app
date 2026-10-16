/**
 * Role hierarchy and edit rules — the single place that decides who may
 * change what. Endpoints call these after authenticating the user.
 *
 * | Role        | Can                                                             |
 * |-------------|-----------------------------------------------------------------|
 * | (anonymous) | Nothing — every endpoint except sign-in needs a volunteer       |
 * | pending     | Nothing (signed in, waiting for a super_admin to grant a role)  |
 * | volunteer   | View everything; edit day plans inside the edit window (see     |
 * |             | editableDateRange) and their own dog familiarity                |
 * | admin       | + dogs, volunteers, dog relationships, anyone's familiarity     |
 * | super_admin | + day plans on any date (history fixes), user accounts & roles  |
 */

export const ROLES = ['pending', 'volunteer', 'admin', 'super_admin'] as const;
export type Role = (typeof ROLES)[number];

export function isRole(value: unknown): value is Role {
	return typeof value === 'string' && (ROLES as readonly string[]).includes(value);
}

export function hasRole(user: { role: Role } | null, minimum: Role): boolean {
	return user !== null && ROLES.indexOf(user.role) >= ROLES.indexOf(minimum);
}

/** Day plans are editable from this many days ago… */
export const PLAN_EDIT_DAYS_BACK = 2;
/** …to this many days ahead. Outside that, only a super_admin can edit. */
export const PLAN_EDIT_DAYS_AHEAD = 2;

/** Dates are compared in the shelter's timezone, not the server's (UTC). */
const SHELTER_TIME_ZONE = 'Europe/Warsaw';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** Today's date in the shelter's timezone, as YYYY-MM-DD. */
export function shelterToday(now: Date = new Date()): string {
	// en-CA formats dates as YYYY-MM-DD.
	return new Intl.DateTimeFormat('en-CA', { timeZone: SHELTER_TIME_ZONE }).format(now);
}

function shiftDays(isoDate: string, days: number): string {
	const date = new Date(`${isoDate}T00:00:00Z`);
	date.setUTCDate(date.getUTCDate() + days);
	return date.toISOString().slice(0, 10);
}

/** First and last walk date (YYYY-MM-DD, inclusive) open for editing. */
export function editableDateRange(now: Date = new Date()): { from: string; to: string } {
	const today = shelterToday(now);
	return { from: shiftDays(today, -PLAN_EDIT_DAYS_BACK), to: shiftDays(today, PLAN_EDIT_DAYS_AHEAD) };
}

/** Whether [user] may create/change/delete walks on [walkDate] (YYYY-MM-DD). */
export function canEditWalkDate(
	user: { role: Role } | null,
	walkDate: string,
	now: Date = new Date(),
): boolean {
	if (hasRole(user, 'super_admin')) return true;
	if (!hasRole(user, 'volunteer')) return false;
	const { from, to } = editableDateRange(now);
	// ISO dates compare correctly as strings.
	return ISO_DATE.test(walkDate) && walkDate >= from && walkDate <= to;
}

/** Whether [user] may edit the dog familiarity of volunteer [volunteerId]. */
export function canEditFamiliarity(
	user: { role: Role; volunteerId: number | null } | null,
	volunteerId: number,
): boolean {
	if (hasRole(user, 'admin')) return true;
	return hasRole(user, 'volunteer') && user!.volunteerId === volunteerId;
}

/** API error for a day plan change outside the edit window. */
export const DAY_LOCKED = `Only days from ${PLAN_EDIT_DAYS_BACK} days ago to ${PLAN_EDIT_DAYS_AHEAD} days ahead can be edited — ask the app owner`;
