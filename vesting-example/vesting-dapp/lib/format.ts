export function lovelaceToAda(lovelace: string | number | bigint): number {
  const value =
    typeof lovelace === "bigint"
      ? Number(lovelace)
      : typeof lovelace === "string"
        ? Number(lovelace)
        : lovelace;
  return value / 1_000_000;
}

export function formatAda(lovelace: string): string {
  return `${lovelaceToAda(lovelace).toLocaleString(undefined, {
    maximumFractionDigits: 2,
    minimumFractionDigits: 2,
  })} ₳`;
}

export function formatTimestamp(ms?: number | null): string {
  if (!ms) return "—";
  const date = new Date(ms);
  return `${date.toLocaleDateString()} ${date.toLocaleTimeString()}`;
}

export function formatRelative(ms?: number | null): string {
  if (!ms) return "—";
  const diff = ms - Date.now();
  const abs = Math.abs(diff);
  const minutes = Math.round(abs / 60000);
  if (minutes < 1) return diff < 0 ? "just unlocked" : "less than 1 min";
  const hours = Math.floor(minutes / 60);
  if (hours < 1) {
    return diff < 0 ? `${minutes} min ago` : `in ${minutes} min`;
  }
  const days = Math.floor(hours / 24);
  if (days < 1) {
    return diff < 0 ? `${hours} h ago` : `in ${hours} h`;
  }
  return diff < 0 ? `${days} d ago` : `in ${days} d`;
}

