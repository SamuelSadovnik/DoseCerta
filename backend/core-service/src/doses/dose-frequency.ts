/**
 * Parses a Portuguese frequency label into the interval in hours
 * between consecutive doses. Falls back to 24h (once a day) for
 * anything unrecognized.
 */
export function parseFrequencyHours(label: string): number {
  const lower = label.toLowerCase().trim();
  const everyXHours = lower.match(/cada\s+(\d+)\s*hora/);
  if (everyXHours) return Number(everyXHours[1]);
  const xPerDay = lower.match(/(\d+)\s*x\s*ao\s*dia/);
  if (xPerDay) {
    const n = Number(xPerDay[1]);
    return n > 0 ? Math.floor(24 / n) : 24;
  }
  return 24;
}

export function calculateDoseCount(frequency: string, durationDays: number): number {
  const hours = parseFrequencyHours(frequency);
  const totalHours = durationDays * 24;
  return Math.floor(totalHours / hours);
}
