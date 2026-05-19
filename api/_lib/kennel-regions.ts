// Kennel → region mapping using the shelter's actual layout.
// Returns "R{number}" or "?" for unmapped kennels.

export function getRegionForKennel(kennel: string | null | undefined): string | null {
	if (!kennel) return null;
	const num = parseInt(kennel.replace(/\D/g, ''), 10);
	if (isNaN(num)) return null;
	const region = getRegionNumberForKennel(num);
	return region !== null ? `R${region}` : '?';
}


export function getRegionNumberForKennel(kennelNumber: number): number | null {
	if (!Number.isInteger(kennelNumber) || kennelNumber <= 0) {
		return null;
	}

	const inRange = (start: number, end: number) =>
		kennelNumber >= start && kennelNumber <= end;

	// Region 5 - red quarantine
	if (inRange(1, 48)) {
		return 5;
	}

	// Region 4 - green
	// Top green pavilions:
	// - VIII top row: 49-63
	// - VII top row: 64-72
	// - VII/VIII bottom rows: 91-114
	if (
		inRange(49, 72) ||
		inRange(91, 114)
	) {
		return 4;
	}

	// Region 3 - orange
	// - Pawilon VI: 73-90
	// - Pawilon IV: 130-159
	if (
		inRange(73, 90) ||
		inRange(130, 159)
	) {
		return 3;
	}

	// Region 2 - cyan
	// - Pawilon V top row: 115-129
	// - Pawilon V bottom row: 160-174
	// - Pawilon III top row: 175-183
	// - Pawilon III bottom row: 238-240
	if (
		inRange(115, 129) ||
		inRange(160, 183) ||
		inRange(238, 240)
	) {
		return 2;
	}

	// Region 1 - lime
	// - Pawilon II top row: 184-192
	// - Pawilon I top row: 193-207
	// - Pawilon I/II bottom rows: 208-231
	// - Small middle lime block: 241-248
	if (
		inRange(184, 231) ||
		inRange(241, 248)
	) {
		return 1;
	}

	// Region 12 - brown
	// Includes proper vertical runs:
	// - inner vertical: 405-422
	// - outer vertical: 425-441
	// - small lower brown block: 590-596
	// - top horizontal brown block: 607-620
	// - inner upper brown strip: 700-708
	if (
		inRange(405, 422) ||
		inRange(425, 441) ||
		inRange(590, 596) ||
		inRange(607, 620) ||
		inRange(700, 708)
	) {
		return 12;
	}

	// Region 13 - magenta
	// - upper/right magenta area: 320-344
	// - lower horizontal magenta strip: 451-456
	// - upper inner magenta group: 623-631
	// - small magenta strip near blue top row: 709-714
	// - single lower magenta kennel: 732
	if (
		inRange(320, 344) ||
		inRange(451, 456) ||
		inRange(623, 631) ||
		inRange(709, 732)
	) {
		return 13;
	}

	// Region 11 - dark blue
	if (inRange(457, 522) || inRange(811, 819)) {
		return 11;
	}

	// Region 9 - teal
	if (inRange(523, 585)) {
		return 9;
	}

	// Region 8 - purple
	// Includes:
	// - left purple vertical/diagonal block
	// - lower purple curved rows
	// - bottom isolated purple kennels
	if (
		inRange(801, 810) ||
		inRange(822, 862) ||
		inRange(901, 927)
	) {
		return 8;
	}

	return null;
}