"use client";

import { useEffect, useMemo, useState } from "react";
import { Heatmap } from "./Heatmap";
import type { Snapshot } from "../lib/snapshots";

export type ReplaySnapshot = {
  name: string;
  snapshot: Snapshot;
};

export function ReplayExplorer({
  snapshots,
  initialName,
}: {
  snapshots: ReplaySnapshot[];
  initialName?: string;
}) {
  const initialMatch = snapshots.find((item) => item.name === initialName)?.name;
  const defaultName =
    initialMatch ??
    snapshots.find((item) => item.name === "inference_spread")?.name ??
    snapshots[0]?.name;
  const [selectedName, setSelectedName] = useState(defaultName);
  const selected = useMemo(
    () => snapshots.find((item) => item.name === selectedName) ?? snapshots[0],
    [selectedName, snapshots]
  );

  useEffect(() => {
    const onPopState = () => {
      const name = new URLSearchParams(window.location.search).get("snapshot");
      setSelectedName(
        snapshots.find((item) => item.name === name)?.name ??
          snapshots.find((item) => item.name === "inference_spread")?.name ??
          snapshots[0]?.name
      );
    };
    window.addEventListener("popstate", onPopState);
    return () => window.removeEventListener("popstate", onPopState);
  }, [snapshots]);

  const selectSnapshot = (name: string) => {
    setSelectedName(name);
    const url = new URL(window.location.href);
    url.searchParams.set("snapshot", name);
    window.history.pushState(null, "", url);
  };

  if (!selected) {
    return (
      <div className="card">
        <p>Run `bash scripts/export_snapshots.sh` to create replay snapshots.</p>
      </div>
    );
  }

  return (
    <div className="replay-grid">
      <div className="snapshot-list" role="tablist" aria-label="Rust snapshot scenarios">
        {snapshots.map(({ name, snapshot }) => (
          <button
            key={name}
            className={selected.name === name ? "selected" : ""}
            type="button"
            role="tab"
            aria-selected={selected.name === name}
            onClick={() => selectSnapshot(name)}
          >
            <strong>{name}</strong>
            <span>
              {snapshot.controls.workload_phase} · {snapshot.controls.cooling_preset} ·{" "}
              {snapshot.controls.floorplan_mode}
            </span>
          </button>
        ))}
      </div>
      <div className="demo-shell">
        <div className="demo-head">
          <span>{selected.name}</span>
          <span>exported Rust JSON</span>
        </div>
        <Heatmap snapshot={selected.snapshot} sampleStep={2} />
        <div className="snapshot-meta">
          <div className="metric">
            <strong>{selected.snapshot.peak_c.toFixed(1)}</strong>
            <span>peak C</span>
          </div>
          <div className="metric">
            <strong>
              {selected.snapshot.peak_cell.x},{selected.snapshot.peak_cell.y}
            </strong>
            <span>peak cell</span>
          </div>
          <div className="metric">
            <strong>{selected.snapshot.iterations}</strong>
            <span>iterations</span>
          </div>
        </div>
      </div>
    </div>
  );
}
