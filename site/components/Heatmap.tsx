import type { Snapshot } from "../lib/snapshots";

export function Heatmap({ snapshot }: { snapshot: Snapshot }) {
  const stride = Math.max(1, Math.floor(snapshot.grid_size / 24));
  const cells = [];
  for (let y = 0; y < snapshot.grid_size; y += stride) {
    for (let x = 0; x < snapshot.grid_size; x += stride) {
      const value = snapshot.temperature_grid[y][x];
      const t = Math.max(0, Math.min(1, (value - snapshot.ambient_c) / (snapshot.peak_c - snapshot.ambient_c || 1)));
      const red = Math.round(22 + 210 * t);
      const green = Math.round(60 + 96 * (1 - Math.abs(t - 0.45)));
      const blue = Math.round(82 * (1 - t));
      cells.push(
        <span
          key={`${x}-${y}`}
          style={{ backgroundColor: `rgb(${red}, ${green}, ${blue})` }}
          title={`${value.toFixed(1)} C`}
        />
      );
    }
  }
  return <div className="heat-preview">{cells}</div>;
}
