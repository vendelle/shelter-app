// Temporary kennel → region mapping.
// Replace with the real mapping once the shelter provides it.
// Distributes kennels evenly across R1–R13 based on kennel number.

export function getRegionForKennel(kennel: string | null | undefined): string | null {
	if (!kennel) return null;
	// Parse digits from kennel string, hash to R1–R13
	const num = parseInt(kennel.replace(/\D/g, ''), 10);
	if (isNaN(num)) return null;
	return `R${(num % 13) + 1}`;
}
