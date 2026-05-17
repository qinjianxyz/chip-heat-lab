import type { Snapshot } from "../lib/snapshots";

const blockLabels: Record<string, string> = {
  "MatMul Array A": "MatMul A",
  "MatMul Array B": "MatMul B",
  "SRAM / KV Cache": "SRAM / KV",
  "NoC Spine": "NoC",
  "SerDes / IO": "SerDes / IO",
  Control: "Control",
};

export function Heatmap({
  snapshot,
  sampleStep = 1,
}: {
  snapshot: Snapshot;
  sampleStep?: number;
}) {
  const cells = [];
  const step = Math.max(1, Math.floor(sampleStep));
  const displayGridSize = Math.ceil(snapshot.grid_size / step);
  for (let y = 0; y < snapshot.grid_size; y += step) {
    for (let x = 0; x < snapshot.grid_size; x += step) {
      const value = snapshot.temperature_grid[y][x];
      const t = Math.max(0, Math.min(1, (value - snapshot.ambient_c) / (snapshot.peak_c - snapshot.ambient_c || 1)));
      const red = Math.round(16 + 224 * t);
      const green = Math.round(54 + 116 * (1 - Math.abs(t - 0.48)));
      const blue = Math.round(96 * (1 - t));
      cells.push(
        <span
          key={`${x}-${y}`}
          style={{ backgroundColor: `rgb(${red}, ${green}, ${blue})` }}
          title={`${value.toFixed(1)} C`}
        />
      );
    }
  }
  return (
    <div className="heatmap-wrap">
      <div
        className="heat-preview"
        style={{ gridTemplateColumns: `repeat(${displayGridSize}, 1fr)` }}
      >
        {cells}
      </div>
      <div className="pdn-mesh" aria-hidden="true" />
      <div className="floorplan-layer" aria-hidden="true">
        {[14, 48, 82].flatMap((y) =>
          [14, 48, 82].map((x) => (
            <div
              className="bump-dot"
              key={`bump-${x}-${y}`}
              style={{
                left: `${((x + 0.5) / snapshot.grid_size) * 100}%`,
                top: `${((y + 0.5) / snapshot.grid_size) * 100}%`,
              }}
            />
          ))
        )}
        {snapshot.floorplan.flatMap((block) =>
          block.rects.map((rect, index) => (
            <div
              className={`floorplan-block ${rect.width <= 8 ? "narrow-block" : ""}`}
              key={`${block.name}-${index}`}
              style={{
                left: `${(rect.x / snapshot.grid_size) * 100}%`,
                top: `${(rect.y / snapshot.grid_size) * 100}%`,
                width: `${(rect.width / snapshot.grid_size) * 100}%`,
                height: `${(rect.height / snapshot.grid_size) * 100}%`,
              }}
            >
              <span>{blockLabels[block.name] ?? block.name}</span>
            </div>
          ))
        )}
        <div
          className="peak-marker"
          style={{
            left: `${((snapshot.peak_cell.x + 0.5) / snapshot.grid_size) * 100}%`,
            top: `${((snapshot.peak_cell.y + 0.5) / snapshot.grid_size) * 100}%`,
          }}
        />
      </div>
      <div className="heatmap-hud" aria-label="Heatmap solver metadata">
        <span>{snapshot.grid_size} x {snapshot.grid_size} grid</span>
        <span>peak cell {snapshot.peak_cell.x},{snapshot.peak_cell.y}</span>
        <span>residual {snapshot.residual.toExponential(1)}</span>
      </div>
      <div className="thermal-scale" aria-hidden="true">
        <span>{snapshot.ambient_c.toFixed(0)} C</span>
        <i />
        <span>{snapshot.peak_c.toFixed(1)} C</span>
      </div>
    </div>
  );
}
