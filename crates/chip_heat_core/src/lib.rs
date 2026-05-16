use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

pub const GRID_SIZE: usize = 96;

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum WorkloadPhase {
    Balanced,
    TrainingMatmul,
    InferenceKv,
    IoBurst,
}

impl Default for WorkloadPhase {
    fn default() -> Self {
        Self::Balanced
    }
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum CoolingPreset {
    Passive,
    Airflow,
    Aggressive,
}

impl Default for CoolingPreset {
    fn default() -> Self {
        Self::Airflow
    }
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum FloorplanMode {
    ClusteredSram,
    SpreadSram,
}

impl Default for FloorplanMode {
    fn default() -> Self {
        Self::ClusteredSram
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct SimulationControls {
    pub workload_phase: WorkloadPhase,
    pub power_scale: f64,
    pub cooling_preset: CoolingPreset,
    pub floorplan_mode: FloorplanMode,
}

impl Default for SimulationControls {
    fn default() -> Self {
        Self {
            workload_phase: WorkloadPhase::Balanced,
            power_scale: 1.0,
            cooling_preset: CoolingPreset::Airflow,
            floorplan_mode: FloorplanMode::ClusteredSram,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct ScenarioInput {
    pub scenario_name: String,
    pub ambient_c: f64,
    pub conductivity: f64,
    pub controls: SimulationControls,
}

impl Default for ScenarioInput {
    fn default() -> Self {
        Self {
            scenario_name: "flagship_ai_accelerator".to_string(),
            ambient_c: 35.0,
            conductivity: 0.62,
            controls: SimulationControls::default(),
        }
    }
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
pub struct Cell {
    pub x: usize,
    pub y: usize,
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
pub struct Rect {
    pub x: usize,
    pub y: usize,
    pub width: usize,
    pub height: usize,
}

impl Rect {
    fn contains(&self, x: usize, y: usize) -> bool {
        x >= self.x && x < self.x + self.width && y >= self.y && y < self.y + self.height
    }

    pub fn center(&self) -> Point {
        Point {
            x: self.x as f64 + self.width as f64 / 2.0,
            y: self.y as f64 + self.height as f64 / 2.0,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct BlockLayout {
    pub name: String,
    pub rects: Vec<Rect>,
    pub power_density: f64,
}

impl BlockLayout {
    fn contains(&self, x: usize, y: usize) -> bool {
        self.rects.iter().any(|rect| rect.contains(x, y))
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct SimulationResult {
    pub scenario_name: String,
    pub grid_size: usize,
    pub ambient_c: f64,
    pub controls: SimulationControls,
    pub floorplan: Vec<BlockLayout>,
    pub temperature_grid: Vec<Vec<f64>>,
    pub peak_c: f64,
    pub peak_cell: Cell,
    pub hotspot_centroid: Point,
    pub per_block_max: BTreeMap<String, f64>,
    pub residual: f64,
    pub iterations: usize,
    pub warnings: Vec<String>,
}

pub fn flagship_floorplan(mode: FloorplanMode, phase: WorkloadPhase, power_scale: f64) -> Vec<BlockLayout> {
    let mut blocks = vec![
        block("MatMul Array A", vec![rect(12, 12, 30, 28)], 1.48),
        block("MatMul Array B", vec![rect(54, 12, 30, 28)], 1.36),
        block("NoC Spine", vec![rect(45, 6, 6, 84)], 0.58),
        block("SerDes / IO", vec![rect(0, 82, 96, 8)], 0.50),
        block("Control", vec![rect(70, 44, 18, 20)], 0.28),
    ];

    let sram_rects = match mode {
        FloorplanMode::ClusteredSram => vec![rect(14, 50, 38, 26)],
        FloorplanMode::SpreadSram => vec![rect(8, 54, 28, 20), rect(60, 54, 28, 20)],
    };
    blocks.push(block("SRAM / KV Cache", sram_rects, 0.92));

    for block in &mut blocks {
        block.power_density *= phase_multiplier(phase, &block.name) * power_scale.max(0.0);
    }
    blocks
}

pub fn solve(input: &ScenarioInput) -> SimulationResult {
    let controls = input.controls.clone();
    let floorplan = flagship_floorplan(
        controls.floorplan_mode,
        controls.workload_phase,
        controls.power_scale,
    );
    let q = power_grid(&floorplan);
    let g_cool = cooling_coefficient(controls.cooling_preset);
    let conductivity = input.conductivity.max(0.001);
    let (rise, iterations, residual, converged) = solve_temperature_rise(&q, conductivity, g_cool);
    let temperature_grid = to_temperature_grid(&rise, input.ambient_c);
    let (peak_c, peak_cell) = peak(&temperature_grid);
    let hotspot_centroid = hotspot_centroid(&temperature_grid, input.ambient_c, peak_c);
    let per_block_max = per_block_max(&floorplan, &temperature_grid);

    let mut warnings = Vec::new();
    if controls.power_scale > 2.5 {
        warnings.push("power_scale_is_outside_the_demo_calibration_range".to_string());
    }
    if !converged {
        warnings.push("solver_reached_iteration_limit".to_string());
    }

    SimulationResult {
        scenario_name: input.scenario_name.clone(),
        grid_size: GRID_SIZE,
        ambient_c: input.ambient_c,
        controls,
        floorplan,
        temperature_grid,
        peak_c,
        peak_cell,
        hotspot_centroid,
        per_block_max,
        residual,
        iterations,
        warnings,
    }
}

pub fn schema_bundle() -> serde_json::Value {
    serde_json::json!({
        "ScenarioInput": schemars::schema_for!(ScenarioInput),
        "SimulationResult": schemars::schema_for!(SimulationResult)
    })
}

fn block(name: &str, rects: Vec<Rect>, power_density: f64) -> BlockLayout {
    BlockLayout {
        name: name.to_string(),
        rects,
        power_density,
    }
}

fn rect(x: usize, y: usize, width: usize, height: usize) -> Rect {
    Rect {
        x,
        y,
        width,
        height,
    }
}

fn phase_multiplier(phase: WorkloadPhase, block_name: &str) -> f64 {
    match phase {
        WorkloadPhase::Balanced => match block_name {
            "MatMul Array A" => 1.00,
            "MatMul Array B" => 0.95,
            "SRAM / KV Cache" => 0.72,
            "NoC Spine" => 0.70,
            "SerDes / IO" => 0.62,
            "Control" => 0.50,
            _ => 1.0,
        },
        WorkloadPhase::TrainingMatmul => match block_name {
            "MatMul Array A" => 1.55,
            "MatMul Array B" => 1.45,
            "SRAM / KV Cache" => 0.75,
            "NoC Spine" => 0.82,
            "SerDes / IO" => 0.50,
            "Control" => 0.45,
            _ => 1.0,
        },
        WorkloadPhase::InferenceKv => match block_name {
            "MatMul Array A" => 0.62,
            "MatMul Array B" => 0.58,
            "SRAM / KV Cache" => 1.70,
            "NoC Spine" => 0.88,
            "SerDes / IO" => 0.52,
            "Control" => 0.45,
            _ => 1.0,
        },
        WorkloadPhase::IoBurst => match block_name {
            "MatMul Array A" => 0.55,
            "MatMul Array B" => 0.52,
            "SRAM / KV Cache" => 0.65,
            "NoC Spine" => 1.20,
            "SerDes / IO" => 1.85,
            "Control" => 0.48,
            _ => 1.0,
        },
    }
}

fn cooling_coefficient(preset: CoolingPreset) -> f64 {
    match preset {
        CoolingPreset::Passive => 0.018,
        CoolingPreset::Airflow => 0.045,
        CoolingPreset::Aggressive => 0.095,
    }
}

fn power_grid(floorplan: &[BlockLayout]) -> Vec<f64> {
    let mut q = vec![0.0; GRID_SIZE * GRID_SIZE];
    for block in floorplan {
        for rect in &block.rects {
            for y in rect.y..(rect.y + rect.height).min(GRID_SIZE) {
                for x in rect.x..(rect.x + rect.width).min(GRID_SIZE) {
                    q[idx(x, y)] += block.power_density;
                }
            }
        }
    }
    q
}

fn solve_temperature_rise(q: &[f64], k: f64, g_cool: f64) -> (Vec<f64>, usize, f64, bool) {
    let mut u = vec![0.0; GRID_SIZE * GRID_SIZE];
    let denom = 4.0 * k + g_cool;
    let tolerance = 1.0e-8;
    let max_iterations = 18_000;
    let mut iterations = 0;
    let mut converged = false;

    for iter in 1..=max_iterations {
        let mut max_delta = 0.0_f64;
        for y in 0..GRID_SIZE {
            for x in 0..GRID_SIZE {
                let neighbor_sum = neighbor_sum(&u, x, y);
                let next = (q[idx(x, y)] + k * neighbor_sum) / denom;
                let cell = idx(x, y);
                max_delta = max_delta.max((next - u[cell]).abs());
                u[cell] = next;
            }
        }
        iterations = iter;
        if max_delta < tolerance {
            converged = true;
            break;
        }
    }

    let residual = residual(&u, q, k, g_cool);
    (u, iterations, residual, converged)
}

fn neighbor_sum(values: &[f64], x: usize, y: usize) -> f64 {
    let mut sum = 0.0;
    if x > 0 {
        sum += values[idx(x - 1, y)];
    }
    if x + 1 < GRID_SIZE {
        sum += values[idx(x + 1, y)];
    }
    if y > 0 {
        sum += values[idx(x, y - 1)];
    }
    if y + 1 < GRID_SIZE {
        sum += values[idx(x, y + 1)];
    }
    sum
}

fn residual(u: &[f64], q: &[f64], k: f64, g_cool: f64) -> f64 {
    let mut max_residual = 0.0_f64;
    let denom = 4.0 * k + g_cool;
    for y in 0..GRID_SIZE {
        for x in 0..GRID_SIZE {
            let cell = idx(x, y);
            let lhs = denom * u[cell] - k * neighbor_sum(u, x, y);
            max_residual = max_residual.max((lhs - q[cell]).abs());
        }
    }
    max_residual
}

fn to_temperature_grid(rise: &[f64], ambient_c: f64) -> Vec<Vec<f64>> {
    (0..GRID_SIZE)
        .map(|y| {
            (0..GRID_SIZE)
                .map(|x| round3(ambient_c + rise[idx(x, y)]))
                .collect()
        })
        .collect()
}

fn peak(grid: &[Vec<f64>]) -> (f64, Cell) {
    let mut peak_c = f64::NEG_INFINITY;
    let mut peak_cell = Cell { x: 0, y: 0 };
    for (y, row) in grid.iter().enumerate() {
        for (x, value) in row.iter().copied().enumerate() {
            if value > peak_c {
                peak_c = value;
                peak_cell = Cell { x, y };
            }
        }
    }
    (peak_c, peak_cell)
}

fn hotspot_centroid(grid: &[Vec<f64>], ambient_c: f64, peak_c: f64) -> Point {
    let rise = peak_c - ambient_c;
    if rise <= 1.0e-9 {
        return Point { x: 0.0, y: 0.0 };
    }

    let threshold = peak_c - (0.06 * rise).max(0.2);
    let mut weight_sum = 0.0;
    let mut x_sum = 0.0;
    let mut y_sum = 0.0;
    for (y, row) in grid.iter().enumerate() {
        for (x, value) in row.iter().copied().enumerate() {
            if value >= threshold {
                let weight = (value - ambient_c).max(0.0);
                weight_sum += weight;
                x_sum += weight * x as f64;
                y_sum += weight * y as f64;
            }
        }
    }

    if weight_sum <= f64::EPSILON {
        Point { x: 0.0, y: 0.0 }
    } else {
        Point {
            x: round3(x_sum / weight_sum),
            y: round3(y_sum / weight_sum),
        }
    }
}

fn per_block_max(floorplan: &[BlockLayout], grid: &[Vec<f64>]) -> BTreeMap<String, f64> {
    let mut output = BTreeMap::new();
    for block in floorplan {
        let mut block_peak = f64::NEG_INFINITY;
        for y in 0..GRID_SIZE {
            for x in 0..GRID_SIZE {
                if block.contains(x, y) {
                    block_peak = block_peak.max(grid[y][x]);
                }
            }
        }
        output.insert(block.name.clone(), round3(block_peak));
    }
    output
}

fn idx(x: usize, y: usize) -> usize {
    y * GRID_SIZE + x
}

fn round3(value: f64) -> f64 {
    (value * 1000.0).round() / 1000.0
}

#[cfg(test)]
mod tests {
    use super::*;

    fn scenario(phase: WorkloadPhase, power_scale: f64, cooling: CoolingPreset, mode: FloorplanMode) -> ScenarioInput {
        ScenarioInput {
            scenario_name: "test".to_string(),
            controls: SimulationControls {
                workload_phase: phase,
                power_scale,
                cooling_preset: cooling,
                floorplan_mode: mode,
            },
            ..ScenarioInput::default()
        }
    }

    #[test]
    fn zero_power_returns_ambient() {
        let result = solve(&scenario(
            WorkloadPhase::Balanced,
            0.0,
            CoolingPreset::Airflow,
            FloorplanMode::ClusteredSram,
        ));
        assert_eq!(result.peak_c, result.ambient_c);
        assert!(result
            .temperature_grid
            .iter()
            .flatten()
            .all(|value| (*value - result.ambient_c).abs() < 1.0e-12));
    }

    #[test]
    fn stronger_cooling_lowers_peak() {
        let passive = solve(&scenario(
            WorkloadPhase::TrainingMatmul,
            1.0,
            CoolingPreset::Passive,
            FloorplanMode::ClusteredSram,
        ));
        let aggressive = solve(&scenario(
            WorkloadPhase::TrainingMatmul,
            1.0,
            CoolingPreset::Aggressive,
            FloorplanMode::ClusteredSram,
        ));
        assert!(aggressive.peak_c < passive.peak_c);
    }

    #[test]
    fn doubling_power_roughly_doubles_temperature_rise() {
        let base = solve(&scenario(
            WorkloadPhase::Balanced,
            1.0,
            CoolingPreset::Airflow,
            FloorplanMode::ClusteredSram,
        ));
        let doubled = solve(&scenario(
            WorkloadPhase::Balanced,
            2.0,
            CoolingPreset::Airflow,
            FloorplanMode::ClusteredSram,
        ));
        let base_rise = base.peak_c - base.ambient_c;
        let doubled_rise = doubled.peak_c - doubled.ambient_c;
        let ratio = doubled_rise / base_rise;
        assert!((ratio - 2.0).abs() < 0.03, "ratio={ratio}");
    }

    #[test]
    fn hotspot_appears_near_high_power_block() {
        let result = solve(&scenario(
            WorkloadPhase::TrainingMatmul,
            1.0,
            CoolingPreset::Airflow,
            FloorplanMode::ClusteredSram,
        ));
        let matmul_a = result
            .floorplan
            .iter()
            .find(|block| block.name == "MatMul Array A")
            .unwrap();
        let center = matmul_a.rects[0].center();
        let distance = ((result.peak_cell.x as f64 - center.x).powi(2)
            + (result.peak_cell.y as f64 - center.y).powi(2))
        .sqrt();
        assert!(distance < 20.0, "peak={:?}, center={center:?}", result.peak_cell);
    }

    #[test]
    fn spread_sram_changes_or_lowers_peak_vs_clustered() {
        let clustered = solve(&scenario(
            WorkloadPhase::InferenceKv,
            1.0,
            CoolingPreset::Airflow,
            FloorplanMode::ClusteredSram,
        ));
        let spread = solve(&scenario(
            WorkloadPhase::InferenceKv,
            1.0,
            CoolingPreset::Airflow,
            FloorplanMode::SpreadSram,
        ));
        let moved = clustered.peak_cell != spread.peak_cell;
        let lowered = spread.peak_c <= clustered.peak_c;
        assert!(moved || lowered);
    }

    #[test]
    fn deterministic_golden_snapshot() {
        let result = solve(&ScenarioInput::default());
        let summary = serde_json::json!({
            "grid_size": result.grid_size,
            "peak_c": result.peak_c,
            "peak_cell": result.peak_cell,
            "hotspot_centroid": result.hotspot_centroid,
            "per_block_max": result.per_block_max,
            "iterations": result.iterations,
            "residual_rounded": round3(result.residual),
        });
        let expected: serde_json::Value =
            serde_json::from_str(include_str!("../tests/golden/flagship_summary.json")).unwrap();
        assert_eq!(summary, expected);
    }

    #[test]
    fn json_schema_roundtrip() {
        let input = ScenarioInput::default();
        let input_json = serde_json::to_string(&input).unwrap();
        let decoded: ScenarioInput = serde_json::from_str(&input_json).unwrap();
        assert_eq!(decoded, input);

        let result = solve(&input);
        let result_json = serde_json::to_string(&result).unwrap();
        let decoded_result: SimulationResult = serde_json::from_str(&result_json).unwrap();
        assert_eq!(decoded_result.peak_cell, result.peak_cell);

        let schema = schema_bundle();
        assert!(schema.get("ScenarioInput").is_some());
        assert!(schema.get("SimulationResult").is_some());
    }
}
