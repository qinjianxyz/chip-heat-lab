import fs from "node:fs";
import path from "node:path";

export type KbEntry = {
  id: string;
  title: string;
  path: string;
  type: string;
  claim_level: string;
  sources: string[];
  summary: string;
};

export function loadKbIndex(): KbEntry[] {
  const file = path.join(process.cwd(), "public", "kb", "kb_index.json");
  if (!fs.existsSync(file)) {
    return [];
  }
  return JSON.parse(fs.readFileSync(file, "utf8")) as KbEntry[];
}

export function groupKbByType(entries: KbEntry[]): Array<[string, KbEntry[]]> {
  const groups = new Map<string, KbEntry[]>();
  for (const entry of entries) {
    const current = groups.get(entry.type) ?? [];
    current.push(entry);
    groups.set(entry.type, current);
  }
  return Array.from(groups.entries()).sort(([left], [right]) => left.localeCompare(right));
}
