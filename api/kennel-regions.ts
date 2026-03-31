// Temporary kennel → region mapping.
// Replace with the real mapping once the shelter provides it.
// Kennels are 3-digit numbers, regions are R1–R14.

const kennelToRegion: Record<string, string> = {
	// This is a placeholder mapping — update when the shelter provides the real one.
	// Format: 'kennel_number': 'R#'
};

export function getRegionForKennel(kennel: string | null | undefined): string | null {
	if (!kennel) return null;
	return kennelToRegion[kennel] ?? null;
}
