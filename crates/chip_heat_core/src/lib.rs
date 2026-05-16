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

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum PowerBumpPreset {
    Sparse,
    Nominal,
    Dense,
}

impl Default for PowerBumpPreset {
    fn default() -> Self {
        Self::Nominal
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

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct PowerDeliveryProxyInput {
    pub scenario_name: String,
    pub controls: SimulationControls,
    pub bump_preset: PowerBumpPreset,
    pub sheet_conductance: f64,
    pub bump_conductance: f64,
    pub droop_scale_mv: f64,
}

impl Default for PowerDeliveryProxyInput {
    fn default() -> Self {
        Self {
            scenario_name: "power_delivery_proxy_review".to_string(),
            controls: SimulationControls {
                workload_phase: WorkloadPhase::InferenceKv,
                power_scale: 1.0,
                cooling_preset: CoolingPreset::Airflow,
                floorplan_mode: FloorplanMode::ClusteredSram,
            },
            bump_preset: PowerBumpPreset::Nominal,
            sheet_conductance: 0.26,
            bump_conductance: 1.45,
            droop_scale_mv: 0.05,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct PowerDeliveryProxyResult {
    pub scenario_name: String,
    pub grid_size: usize,
    pub controls: SimulationControls,
    pub bump_preset: PowerBumpPreset,
    pub bumps: Vec<Cell>,
    pub floorplan: Vec<BlockLayout>,
    pub droop_grid_mv: Vec<Vec<f64>>,
    pub worst_droop_mv: f64,
    pub worst_cell: Cell,
    pub per_block_worst_droop_mv: BTreeMap<String, f64>,
    pub thermal_peak_cell: Cell,
    pub thermal_peak_c: f64,
    pub hotspot_distance_cells: f64,
    pub overlap_score: f64,
    pub residual: f64,
    pub iterations: usize,
    pub warnings: Vec<String>,
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, JsonSchema, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DesignIntervention {
    Baseline,
    SpreadSram,
    DensePowerBumps,
    AggressiveCooling,
    StaggeredWorkload,
    SpreadSramDenseBumps,
    SpreadSramDenseBumpsStaggered,
}

const DESIGN_REVIEW_CANDIDATES: [DesignIntervention; 6] = [
    DesignIntervention::SpreadSram,
    DesignIntervention::DensePowerBumps,
    DesignIntervention::AggressiveCooling,
    DesignIntervention::StaggeredWorkload,
    DesignIntervention::SpreadSramDenseBumps,
    DesignIntervention::SpreadSramDenseBumpsStaggered,
];

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct DesignReviewInput {
    pub scenario_name: String,
    pub ambient_c: f64,
    pub conductivity: f64,
    pub baseline_controls: SimulationControls,
    pub baseline_bump_preset: PowerBumpPreset,
    pub peak_limit_c: f64,
    pub droop_limit_mv: f64,
    pub thermal_dose_limit_c_s: f64,
    pub overlap_limit: f64,
    pub transient_risk_threshold_c: f64,
    pub thermal_capacitance: f64,
    pub time_step_s: f64,
}

impl Default for DesignReviewInput {
    fn default() -> Self {
        Self {
            scenario_name: "kv_cache_design_review".to_string(),
            ambient_c: 35.0,
            conductivity: 0.62,
            baseline_controls: SimulationControls {
                workload_phase: WorkloadPhase::InferenceKv,
                power_scale: 1.0,
                cooling_preset: CoolingPreset::Airflow,
                floorplan_mode: FloorplanMode::ClusteredSram,
            },
            baseline_bump_preset: PowerBumpPreset::Nominal,
            peak_limit_c: 70.0,
            droop_limit_mv: 55.0,
            thermal_dose_limit_c_s: 5.0,
            overlap_limit: 1.0,
            transient_risk_threshold_c: 70.0,
            thermal_capacitance: 0.45,
            time_step_s: 0.10,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct DesignRiskUtilization {
    pub steady_peak: f64,
    pub thermal_dose: f64,
    pub worst_droop: f64,
    pub overlap: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct DesignCandidateResult {
    pub intervention: DesignIntervention,
    pub label: String,
    pub controls: SimulationControls,
    pub bump_preset: PowerBumpPreset,
    pub steady_peak_c: f64,
    pub transient_max_peak_c: f64,
    pub time_above_threshold_s: f64,
    pub thermal_dose_c_s: f64,
    pub max_gradient_c_per_cell: f64,
    pub hotspot_path_distance_cells: f64,
    pub worst_droop_mv: f64,
    pub thermal_pdn_distance_cells: f64,
    pub overlap_score: f64,
    pub risk_utilization: DesignRiskUtilization,
    pub cost_score: f64,
    pub constraint_violations: Vec<String>,
    pub pass: bool,
    pub rank_score: f64,
    pub reason: String,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct DesignReviewResult {
    pub scenario_name: String,
    pub design_question: String,
    pub baseline: DesignCandidateResult,
    pub ranked_candidates: Vec<DesignCandidateResult>,
    pub recommended_intervention: DesignIntervention,
    pub recommended_label: String,
    pub pareto_frontier: Vec<DesignIntervention>,
    pub constraints: BTreeMap<String, f64>,
    pub warnings: Vec<String>,
    pub non_claim: String,
    pub pass: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct WorkloadSegment {
    pub label: String,
    pub workload_phase: WorkloadPhase,
    pub duration_s: f64,
    pub power_scale: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct TransientScenarioInput {
    pub scenario_name: String,
    pub ambient_c: f64,
    pub conductivity: f64,
    pub cooling_preset: CoolingPreset,
    pub floorplan_mode: FloorplanMode,
    pub thermal_capacitance: f64,
    pub time_step_s: f64,
    pub risk_threshold_c: f64,
    pub sample_interval_s: f64,
    pub segments: Vec<WorkloadSegment>,
}

impl Default for TransientScenarioInput {
    fn default() -> Self {
        Self {
            scenario_name: "transient_ai_accelerator_review".to_string(),
            ambient_c: 35.0,
            conductivity: 0.62,
            cooling_preset: CoolingPreset::Airflow,
            floorplan_mode: FloorplanMode::ClusteredSram,
            thermal_capacitance: 0.45,
            time_step_s: 0.05,
            risk_threshold_c: 70.0,
            sample_interval_s: 1.0,
            segments: default_workload_trace(),
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct TransientFrame {
    pub time_s: f64,
    pub segment_label: String,
    pub controls: SimulationControls,
    pub peak_c: f64,
    pub peak_cell: Cell,
    pub hotspot_centroid: Point,
    pub max_gradient_c_per_cell: f64,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct TransientRiskMetrics {
    pub max_peak_c: f64,
    pub final_peak_c: f64,
    pub peak_time_s: f64,
    pub time_above_threshold_s: f64,
    pub thermal_dose_c_s: f64,
    pub max_gradient_c_per_cell: f64,
    pub hotspot_path_distance_cells: f64,
    pub per_segment_peak_c: BTreeMap<String, f64>,
}

#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema, PartialEq)]
pub struct TransientSimulationResult {
    pub scenario_name: String,
    pub grid_size: usize,
    pub ambient_c: f64,
    pub cooling_preset: CoolingPreset,
    pub floorplan_mode: FloorplanMode,
    pub risk_threshold_c: f64,
    pub time_step_s: f64,
    pub thermal_capacitance: f64,
    pub segments: Vec<WorkloadSegment>,
    pub floorplan: Vec<BlockLayout>,
    pub frames: Vec<TransientFrame>,
    pub final_temperature_grid: Vec<Vec<f64>>,
    pub metrics: TransientRiskMetrics,
    pub warnings: Vec<String>,
}

pub fn flagship_floorplan(
    mode: FloorplanMode,
    phase: WorkloadPhase,
    power_scale: f64,
) -> Vec<BlockLayout> {
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

pub fn default_workload_trace() -> Vec<WorkloadSegment> {
    vec![
        segment("prefill_burst", WorkloadPhase::TrainingMatmul, 8.0, 1.35),
        segment("kv_decode", WorkloadPhase::InferenceKv, 26.0, 1.05),
        segment("io_flush", WorkloadPhase::IoBurst, 4.0, 1.10),
        segment("kv_decode_tail", WorkloadPhase::InferenceKv, 16.0, 0.95),
    ]
}

pub fn staggered_workload_trace() -> Vec<WorkloadSegment> {
    vec![
        segment("prefill_burst_a", WorkloadPhase::TrainingMatmul, 4.0, 1.08),
        segment("kv_decode_a", WorkloadPhase::InferenceKv, 13.0, 0.98),
        segment("prefill_burst_b", WorkloadPhase::TrainingMatmul, 4.0, 1.08),
        segment("kv_decode_b", WorkloadPhase::InferenceKv, 17.0, 0.98),
        segment("io_flush", WorkloadPhase::IoBurst, 4.0, 1.00),
        segment("kv_decode_tail", WorkloadPhase::InferenceKv, 12.0, 0.90),
    ]
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

pub fn solve_design_review(input: &DesignReviewInput) -> DesignReviewResult {
    let baseline = evaluate_design_candidate(input, DesignIntervention::Baseline);
    let mut ranked_candidates = DESIGN_REVIEW_CANDIDATES
        .into_iter()
        .map(|intervention| evaluate_design_candidate(input, intervention))
        .collect::<Vec<_>>();
    ranked_candidates.sort_by(compare_design_candidates);

    let recommended = ranked_candidates
        .iter()
        .find(|candidate| candidate.pass)
        .unwrap_or_else(|| ranked_candidates.first().expect("at least one candidate"));
    let recommended_intervention = recommended.intervention;
    let recommended_label = recommended.label.clone();
    let pass = recommended.pass;
    let pareto_frontier = pareto_frontier(&ranked_candidates);

    let mut constraints = BTreeMap::new();
    constraints.insert("peak_limit_c".to_string(), input.peak_limit_c);
    constraints.insert("droop_limit_mv".to_string(), input.droop_limit_mv);
    constraints.insert(
        "thermal_dose_limit_c_s".to_string(),
        input.thermal_dose_limit_c_s,
    );
    constraints.insert("overlap_limit".to_string(), input.overlap_limit);

    DesignReviewResult {
        scenario_name: input.scenario_name.clone(),
        design_question: "Which lowest-cost intervention makes the KV-cache design review pass the simplified thermal and power-delivery constraints?".to_string(),
        baseline,
        ranked_candidates,
        recommended_intervention,
        recommended_label,
        pareto_frontier,
        constraints,
        warnings: vec![
            "design_review_composes_simplified_demo_models_not_final_verification".to_string(),
            "cost_score_is_a_demo_tradeoff_proxy".to_string(),
        ],
        non_claim: "Early-design ranking for this clean-room demo only; not final verification, manufacturing validation, standards compliance, package airflow analysis, or a physical PDN model.".to_string(),
        pass,
    }
}

pub fn solve_power_delivery_proxy(input: &PowerDeliveryProxyInput) -> PowerDeliveryProxyResult {
    let controls = input.controls.clone();
    let floorplan = flagship_floorplan(
        controls.floorplan_mode,
        controls.workload_phase,
        controls.power_scale,
    );
    let current = power_grid(&floorplan);
    let bumps = power_bumps(input.bump_preset);
    let sheet = input.sheet_conductance.max(0.001);
    let bump = input.bump_conductance.max(0.001);
    let scale = input.droop_scale_mv.max(0.001);
    let (raw_droop, iterations, residual, converged) =
        solve_voltage_droop(&current, &bumps, sheet, bump);
    let droop_grid_mv = to_scaled_grid(&raw_droop, scale);
    let (worst_droop_mv, worst_cell) = peak(&droop_grid_mv);
    let per_block_worst_droop_mv = per_block_max(&floorplan, &droop_grid_mv);
    let thermal = solve(&ScenarioInput {
        scenario_name: format!("{}_thermal_reference", input.scenario_name),
        ambient_c: 35.0,
        conductivity: 0.62,
        controls: controls.clone(),
    });
    let hotspot_distance_cells = cell_distance(worst_cell, thermal.peak_cell);
    let overlap_score = round3((1.0 - hotspot_distance_cells / 80.0).clamp(0.0, 1.0));

    let mut warnings = Vec::new();
    warnings.push("power_delivery_proxy_uses_idealized_bumps_and_demo_units".to_string());
    if controls.power_scale > 2.5 {
        warnings.push("power_scale_is_outside_the_demo_calibration_range".to_string());
    }
    if !converged {
        warnings.push("power_proxy_solver_reached_iteration_limit".to_string());
    }

    PowerDeliveryProxyResult {
        scenario_name: input.scenario_name.clone(),
        grid_size: GRID_SIZE,
        controls,
        bump_preset: input.bump_preset,
        bumps,
        floorplan,
        droop_grid_mv,
        worst_droop_mv,
        worst_cell,
        per_block_worst_droop_mv,
        thermal_peak_cell: thermal.peak_cell,
        thermal_peak_c: thermal.peak_c,
        hotspot_distance_cells: round3(hotspot_distance_cells),
        overlap_score,
        residual,
        iterations,
        warnings,
    }
}

pub fn solve_transient(input: &TransientScenarioInput) -> TransientSimulationResult {
    let conductivity = input.conductivity.max(0.001);
    let g_cool = cooling_coefficient(input.cooling_preset);
    let capacitance = input.thermal_capacitance.max(0.001);
    let dt = input.time_step_s.clamp(0.01, 1.0);
    let sample_interval = input.sample_interval_s.max(dt);
    let mut u = vec![0.0; GRID_SIZE * GRID_SIZE];
    let mut frames = Vec::new();
    let mut warnings = Vec::new();
    let mut time_s = 0.0;
    let mut next_sample_s = 0.0;
    let mut max_peak_c = input.ambient_c;
    let mut final_peak_c = input.ambient_c;
    let mut peak_time_s = 0.0;
    let mut time_above_threshold_s = 0.0;
    let mut thermal_dose_c_s = 0.0;
    let mut max_gradient_c_per_cell = 0.0;
    let mut hotspot_path_distance_cells = 0.0;
    let mut previous_centroid: Option<Point> = None;
    let mut per_segment_peak_c: BTreeMap<String, f64> = BTreeMap::new();

    if input.segments.is_empty() {
        warnings.push("transient_trace_has_no_segments".to_string());
    }

    for segment in &input.segments {
        if segment.duration_s <= 0.0 {
            warnings.push(format!(
                "segment_{}_has_non_positive_duration",
                segment.label
            ));
            continue;
        }

        let floorplan = flagship_floorplan(
            input.floorplan_mode,
            segment.workload_phase,
            segment.power_scale,
        );
        let q = power_grid(&floorplan);
        let steps = (segment.duration_s / dt).ceil() as usize;

        for _ in 0..steps {
            transient_step(&mut u, &q, conductivity, g_cool, capacitance, dt);
            time_s = round3(time_s + dt);
            let temperature_grid = to_temperature_grid(&u, input.ambient_c);
            let (peak_c, peak_cell) = peak(&temperature_grid);
            let centroid = hotspot_centroid(&temperature_grid, input.ambient_c, peak_c);
            let gradient = max_gradient(&temperature_grid);

            if let Some(previous) = previous_centroid {
                hotspot_path_distance_cells +=
                    ((centroid.x - previous.x).powi(2) + (centroid.y - previous.y).powi(2)).sqrt();
            }
            previous_centroid = Some(centroid);

            if peak_c > max_peak_c {
                max_peak_c = peak_c;
                peak_time_s = time_s;
            }
            final_peak_c = peak_c;
            if peak_c > input.risk_threshold_c {
                time_above_threshold_s += dt;
                thermal_dose_c_s += (peak_c - input.risk_threshold_c) * dt;
            }
            max_gradient_c_per_cell = f64::max(max_gradient_c_per_cell, gradient);
            per_segment_peak_c
                .entry(segment.label.clone())
                .and_modify(|value| *value = f64::max(*value, peak_c))
                .or_insert(peak_c);

            if time_s + 1.0e-9 >= next_sample_s {
                frames.push(TransientFrame {
                    time_s,
                    segment_label: segment.label.clone(),
                    controls: SimulationControls {
                        workload_phase: segment.workload_phase,
                        power_scale: segment.power_scale,
                        cooling_preset: input.cooling_preset,
                        floorplan_mode: input.floorplan_mode,
                    },
                    peak_c,
                    peak_cell,
                    hotspot_centroid: centroid,
                    max_gradient_c_per_cell: gradient,
                });
                next_sample_s += sample_interval;
            }
        }
    }

    let final_temperature_grid = to_temperature_grid(&u, input.ambient_c);
    let floorplan = flagship_floorplan(input.floorplan_mode, WorkloadPhase::Balanced, 1.0);

    TransientSimulationResult {
        scenario_name: input.scenario_name.clone(),
        grid_size: GRID_SIZE,
        ambient_c: input.ambient_c,
        cooling_preset: input.cooling_preset,
        floorplan_mode: input.floorplan_mode,
        risk_threshold_c: input.risk_threshold_c,
        time_step_s: dt,
        thermal_capacitance: capacitance,
        segments: input.segments.clone(),
        floorplan,
        frames,
        final_temperature_grid,
        metrics: TransientRiskMetrics {
            max_peak_c: round3(max_peak_c),
            final_peak_c: round3(final_peak_c),
            peak_time_s: round3(peak_time_s),
            time_above_threshold_s: round3(time_above_threshold_s),
            thermal_dose_c_s: round3(thermal_dose_c_s),
            max_gradient_c_per_cell: round3(max_gradient_c_per_cell),
            hotspot_path_distance_cells: round3(hotspot_path_distance_cells),
            per_segment_peak_c: per_segment_peak_c
                .into_iter()
                .map(|(key, value)| (key, round3(value)))
                .collect(),
        },
        warnings,
    }
}

pub fn schema_bundle() -> serde_json::Value {
    serde_json::json!({
        "ScenarioInput": schemars::schema_for!(ScenarioInput),
        "SimulationResult": schemars::schema_for!(SimulationResult),
        "DesignReviewInput": schemars::schema_for!(DesignReviewInput),
        "DesignReviewResult": schemars::schema_for!(DesignReviewResult),
        "PowerDeliveryProxyInput": schemars::schema_for!(PowerDeliveryProxyInput),
        "PowerDeliveryProxyResult": schemars::schema_for!(PowerDeliveryProxyResult),
        "TransientScenarioInput": schemars::schema_for!(TransientScenarioInput),
        "TransientSimulationResult": schemars::schema_for!(TransientSimulationResult)
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

fn segment(
    label: &str,
    workload_phase: WorkloadPhase,
    duration_s: f64,
    power_scale: f64,
) -> WorkloadSegment {
    WorkloadSegment {
        label: label.to_string(),
        workload_phase,
        duration_s,
        power_scale,
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

fn evaluate_design_candidate(
    input: &DesignReviewInput,
    intervention: DesignIntervention,
) -> DesignCandidateResult {
    let controls = intervention_controls(input.baseline_controls.clone(), intervention);
    let bump_preset = intervention_bump_preset(input.baseline_bump_preset, intervention);
    let segments = if intervention_uses_staggered_workload(intervention) {
        staggered_workload_trace()
    } else {
        default_workload_trace()
    };

    let steady = solve(&ScenarioInput {
        scenario_name: format!("{}_steady_{:?}", input.scenario_name, intervention),
        ambient_c: input.ambient_c,
        conductivity: input.conductivity,
        controls: controls.clone(),
    });
    let transient = solve_transient(&TransientScenarioInput {
        scenario_name: format!("{}_transient_{:?}", input.scenario_name, intervention),
        ambient_c: input.ambient_c,
        conductivity: input.conductivity,
        cooling_preset: controls.cooling_preset,
        floorplan_mode: controls.floorplan_mode,
        thermal_capacitance: input.thermal_capacitance,
        time_step_s: input.time_step_s,
        risk_threshold_c: input.transient_risk_threshold_c,
        sample_interval_s: 1.0,
        segments,
    });
    let power = solve_power_delivery_proxy(&PowerDeliveryProxyInput {
        scenario_name: format!("{}_power_{:?}", input.scenario_name, intervention),
        controls: controls.clone(),
        bump_preset,
        ..PowerDeliveryProxyInput::default()
    });

    let mut constraint_violations = Vec::new();
    if steady.peak_c > input.peak_limit_c {
        constraint_violations.push("steady_kv_peak_above_limit".to_string());
    }
    if transient.metrics.thermal_dose_c_s > input.thermal_dose_limit_c_s {
        constraint_violations.push("transient_thermal_dose_above_limit".to_string());
    }
    if power.worst_droop_mv > input.droop_limit_mv {
        constraint_violations.push("power_delivery_droop_above_limit".to_string());
    }
    if power.overlap_score > input.overlap_limit {
        constraint_violations.push("thermal_droop_overlap_above_limit".to_string());
    }

    let risk_utilization = DesignRiskUtilization {
        steady_peak: round3(steady.peak_c / input.peak_limit_c.max(1.0e-9)),
        thermal_dose: round3(
            transient.metrics.thermal_dose_c_s / input.thermal_dose_limit_c_s.max(1.0e-9),
        ),
        worst_droop: round3(power.worst_droop_mv / input.droop_limit_mv.max(1.0e-9)),
        overlap: round3(power.overlap_score / input.overlap_limit.max(1.0e-9)),
    };
    let pass = constraint_violations.is_empty();
    let cost_score = intervention_cost(intervention);
    let rank_score = design_rank_score(
        pass,
        cost_score,
        steady.peak_c,
        transient.metrics.thermal_dose_c_s,
        power.worst_droop_mv,
    );
    let reason = design_candidate_reason(
        intervention,
        pass,
        steady.peak_c,
        transient.metrics.thermal_dose_c_s,
        power.worst_droop_mv,
        &constraint_violations,
    );

    DesignCandidateResult {
        intervention,
        label: intervention_label(intervention).to_string(),
        controls,
        bump_preset,
        steady_peak_c: round3(steady.peak_c),
        transient_max_peak_c: round3(transient.metrics.max_peak_c),
        time_above_threshold_s: round3(transient.metrics.time_above_threshold_s),
        thermal_dose_c_s: round3(transient.metrics.thermal_dose_c_s),
        max_gradient_c_per_cell: round3(transient.metrics.max_gradient_c_per_cell),
        hotspot_path_distance_cells: round3(transient.metrics.hotspot_path_distance_cells),
        worst_droop_mv: round3(power.worst_droop_mv),
        thermal_pdn_distance_cells: round3(power.hotspot_distance_cells),
        overlap_score: round3(power.overlap_score),
        risk_utilization,
        cost_score,
        constraint_violations,
        pass,
        rank_score: round3(rank_score),
        reason,
    }
}

fn intervention_controls(
    mut controls: SimulationControls,
    intervention: DesignIntervention,
) -> SimulationControls {
    match intervention {
        DesignIntervention::SpreadSram
        | DesignIntervention::SpreadSramDenseBumps
        | DesignIntervention::SpreadSramDenseBumpsStaggered => {
            controls.floorplan_mode = FloorplanMode::SpreadSram;
        }
        _ => {}
    }

    if intervention == DesignIntervention::AggressiveCooling {
        controls.cooling_preset = CoolingPreset::Aggressive;
    }
    controls
}

fn intervention_bump_preset(
    baseline: PowerBumpPreset,
    intervention: DesignIntervention,
) -> PowerBumpPreset {
    match intervention {
        DesignIntervention::DensePowerBumps
        | DesignIntervention::SpreadSramDenseBumps
        | DesignIntervention::SpreadSramDenseBumpsStaggered => PowerBumpPreset::Dense,
        _ => baseline,
    }
}

fn intervention_uses_staggered_workload(intervention: DesignIntervention) -> bool {
    matches!(
        intervention,
        DesignIntervention::StaggeredWorkload | DesignIntervention::SpreadSramDenseBumpsStaggered
    )
}

fn intervention_cost(intervention: DesignIntervention) -> f64 {
    match intervention {
        DesignIntervention::Baseline => 0.0,
        DesignIntervention::StaggeredWorkload => 1.2,
        DesignIntervention::SpreadSram => 2.0,
        DesignIntervention::DensePowerBumps => 2.5,
        DesignIntervention::AggressiveCooling => 4.0,
        DesignIntervention::SpreadSramDenseBumps => 4.5,
        DesignIntervention::SpreadSramDenseBumpsStaggered => 5.7,
    }
}

fn intervention_label(intervention: DesignIntervention) -> &'static str {
    match intervention {
        DesignIntervention::Baseline => "Baseline clustered SRAM",
        DesignIntervention::SpreadSram => "Spread SRAM",
        DesignIntervention::DensePowerBumps => "Dense power bumps",
        DesignIntervention::AggressiveCooling => "Aggressive cooling",
        DesignIntervention::StaggeredWorkload => "Stagger workload",
        DesignIntervention::SpreadSramDenseBumps => "Spread SRAM + dense bumps",
        DesignIntervention::SpreadSramDenseBumpsStaggered => {
            "Spread SRAM + dense bumps + stagger workload"
        }
    }
}

fn design_rank_score(
    pass: bool,
    cost_score: f64,
    steady_peak_c: f64,
    thermal_dose_c_s: f64,
    worst_droop_mv: f64,
) -> f64 {
    let violation_penalty = if pass { 0.0 } else { 1_000.0 };
    violation_penalty
        + cost_score * 10.0
        + steady_peak_c
        + thermal_dose_c_s * 0.8
        + worst_droop_mv * 0.35
}

fn design_candidate_reason(
    intervention: DesignIntervention,
    pass: bool,
    steady_peak_c: f64,
    thermal_dose_c_s: f64,
    worst_droop_mv: f64,
    violations: &[String],
) -> String {
    if pass {
        return format!(
            "{} passes the simplified constraints with {:.1} C steady KV peak, {:.1} C-s thermal dose, and {:.1} mV worst droop.",
            intervention_label(intervention),
            steady_peak_c,
            thermal_dose_c_s,
            worst_droop_mv
        );
    }
    format!(
        "{} still violates {} with {:.1} C steady KV peak, {:.1} C-s thermal dose, and {:.1} mV worst droop.",
        intervention_label(intervention),
        violations.join(", "),
        steady_peak_c,
        thermal_dose_c_s,
        worst_droop_mv
    )
}

fn compare_design_candidates(
    left: &DesignCandidateResult,
    right: &DesignCandidateResult,
) -> std::cmp::Ordering {
    left.rank_score
        .total_cmp(&right.rank_score)
        .then_with(|| left.cost_score.total_cmp(&right.cost_score))
        .then_with(|| left.label.cmp(&right.label))
}

fn pareto_frontier(candidates: &[DesignCandidateResult]) -> Vec<DesignIntervention> {
    candidates
        .iter()
        .filter(|candidate| {
            !candidates.iter().any(|other| {
                other.intervention != candidate.intervention && dominates(other, candidate)
            })
        })
        .map(|candidate| candidate.intervention)
        .collect()
}

fn dominates(left: &DesignCandidateResult, right: &DesignCandidateResult) -> bool {
    let dimensions = [
        (left.steady_peak_c, right.steady_peak_c),
        (left.thermal_dose_c_s, right.thermal_dose_c_s),
        (left.worst_droop_mv, right.worst_droop_mv),
        (left.cost_score, right.cost_score),
    ];
    dimensions
        .iter()
        .all(|(left_value, right_value)| left_value <= &(right_value + 1.0e-9))
        && dimensions
            .iter()
            .any(|(left_value, right_value)| left_value < &(right_value - 1.0e-9))
}

fn cooling_coefficient(preset: CoolingPreset) -> f64 {
    match preset {
        CoolingPreset::Passive => 0.018,
        CoolingPreset::Airflow => 0.045,
        CoolingPreset::Aggressive => 0.095,
    }
}

fn power_bumps(preset: PowerBumpPreset) -> Vec<Cell> {
    let coordinates: Vec<usize> = match preset {
        PowerBumpPreset::Sparse => vec![16, 80],
        PowerBumpPreset::Nominal => vec![14, 48, 82],
        PowerBumpPreset::Dense => vec![10, 28, 48, 68, 86],
    };

    coordinates
        .iter()
        .flat_map(|y| coordinates.iter().map(move |x| Cell { x: *x, y: *y }))
        .collect()
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

fn solve_voltage_droop(
    current: &[f64],
    bumps: &[Cell],
    sheet_conductance: f64,
    bump_conductance: f64,
) -> (Vec<f64>, usize, f64, bool) {
    let mut droop = vec![0.0; GRID_SIZE * GRID_SIZE];
    let mut bump_grid = vec![0.0; GRID_SIZE * GRID_SIZE];
    for bump in bumps {
        bump_grid[idx(bump.x, bump.y)] = bump_conductance;
    }

    let tolerance = 1.0e-8;
    let max_iterations = 18_000;
    let relaxation = 1.72;
    let mut iterations = 0;
    let mut converged = false;

    for iter in 1..=max_iterations {
        let mut max_delta = 0.0_f64;
        for y in 0..GRID_SIZE {
            for x in 0..GRID_SIZE {
                let cell = idx(x, y);
                let denom = 4.0 * sheet_conductance + bump_grid[cell];
                let gauss_seidel =
                    (current[cell] + sheet_conductance * neighbor_sum(&droop, x, y)) / denom;
                let next = droop[cell] + relaxation * (gauss_seidel - droop[cell]);
                max_delta = max_delta.max((next - droop[cell]).abs());
                droop[cell] = next;
            }
        }
        iterations = iter;
        if max_delta < tolerance {
            converged = true;
            break;
        }
    }

    let residual = droop_residual(&droop, current, &bump_grid, sheet_conductance);
    (droop, iterations, residual, converged)
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

fn transient_step(u: &mut [f64], q: &[f64], k: f64, g_cool: f64, capacitance: f64, dt: f64) {
    let mut next = vec![0.0; GRID_SIZE * GRID_SIZE];
    for y in 0..GRID_SIZE {
        for x in 0..GRID_SIZE {
            let cell = idx(x, y);
            let diffusion = k * (neighbor_sum(u, x, y) - 4.0 * u[cell]);
            let sink = g_cool * u[cell];
            let derivative = (diffusion - sink + q[cell]) / capacitance;
            next[cell] = (u[cell] + dt * derivative).max(0.0);
        }
    }
    u.copy_from_slice(&next);
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

fn droop_residual(
    droop: &[f64],
    current: &[f64],
    bump_grid: &[f64],
    sheet_conductance: f64,
) -> f64 {
    let mut max_residual = 0.0_f64;
    for y in 0..GRID_SIZE {
        for x in 0..GRID_SIZE {
            let cell = idx(x, y);
            let lhs = (4.0 * sheet_conductance + bump_grid[cell]) * droop[cell]
                - sheet_conductance * neighbor_sum(droop, x, y);
            max_residual = max_residual.max((lhs - current[cell]).abs());
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

fn to_scaled_grid(values: &[f64], scale: f64) -> Vec<Vec<f64>> {
    (0..GRID_SIZE)
        .map(|y| {
            (0..GRID_SIZE)
                .map(|x| round3(values[idx(x, y)] * scale))
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

fn cell_distance(left: Cell, right: Cell) -> f64 {
    ((left.x as f64 - right.x as f64).powi(2) + (left.y as f64 - right.y as f64).powi(2)).sqrt()
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

fn max_gradient(grid: &[Vec<f64>]) -> f64 {
    let mut output = 0.0_f64;
    for y in 0..GRID_SIZE {
        for x in 0..GRID_SIZE {
            let value = grid[y][x];
            if x + 1 < GRID_SIZE {
                output = output.max((value - grid[y][x + 1]).abs());
            }
            if y + 1 < GRID_SIZE {
                output = output.max((value - grid[y + 1][x]).abs());
            }
        }
    }
    round3(output)
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

    fn scenario(
        phase: WorkloadPhase,
        power_scale: f64,
        cooling: CoolingPreset,
        mode: FloorplanMode,
    ) -> ScenarioInput {
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
        assert!(
            distance < 20.0,
            "peak={:?}, center={center:?}",
            result.peak_cell
        );
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
        assert!(schema.get("PowerDeliveryProxyInput").is_some());
        assert!(schema.get("PowerDeliveryProxyResult").is_some());
        assert!(schema.get("TransientScenarioInput").is_some());
        assert!(schema.get("TransientSimulationResult").is_some());
    }

    #[test]
    fn power_proxy_zero_power_returns_zero_droop() {
        let result = solve_power_delivery_proxy(&PowerDeliveryProxyInput {
            controls: SimulationControls {
                power_scale: 0.0,
                ..SimulationControls::default()
            },
            ..PowerDeliveryProxyInput::default()
        });
        assert_eq!(result.worst_droop_mv, 0.0);
        assert!(result
            .droop_grid_mv
            .iter()
            .flatten()
            .all(|value| *value == 0.0));
    }

    #[test]
    fn dense_bumps_reduce_power_proxy_droop() {
        let sparse = solve_power_delivery_proxy(&PowerDeliveryProxyInput {
            bump_preset: PowerBumpPreset::Sparse,
            ..PowerDeliveryProxyInput::default()
        });
        let dense = solve_power_delivery_proxy(&PowerDeliveryProxyInput {
            bump_preset: PowerBumpPreset::Dense,
            ..PowerDeliveryProxyInput::default()
        });
        assert!(dense.worst_droop_mv < sparse.worst_droop_mv);
        assert!(dense.iterations <= sparse.iterations + 2000);
    }

    #[test]
    fn power_proxy_reports_hotspot_overlap() {
        let result = solve_power_delivery_proxy(&PowerDeliveryProxyInput::default());
        assert!(result.worst_droop_mv > 0.0);
        assert!((0.0..=1.0).contains(&result.overlap_score));
        assert!(result.hotspot_distance_cells >= 0.0);
        assert!(result
            .per_block_worst_droop_mv
            .contains_key("SRAM / KV Cache"));
    }

    #[test]
    fn transient_outputs_workload_risk_metrics() {
        let result = solve_transient(&TransientScenarioInput::default());
        assert_eq!(result.grid_size, GRID_SIZE);
        assert!(!result.frames.is_empty());
        assert!(result.metrics.max_peak_c > result.ambient_c);
        assert!(result.metrics.hotspot_path_distance_cells > 0.0);
        assert!(result.metrics.max_gradient_c_per_cell > 0.0);
        assert!(result.metrics.per_segment_peak_c.contains_key("kv_decode"));
    }

    #[test]
    fn transient_aggressive_cooling_reduces_risk() {
        let airflow = solve_transient(&TransientScenarioInput::default());
        let aggressive = solve_transient(&TransientScenarioInput {
            cooling_preset: CoolingPreset::Aggressive,
            ..TransientScenarioInput::default()
        });
        assert!(aggressive.metrics.max_peak_c < airflow.metrics.max_peak_c);
        assert!(aggressive.metrics.thermal_dose_c_s <= airflow.metrics.thermal_dose_c_s);
    }

    #[test]
    fn transient_spread_sram_changes_hotspot_path() {
        let clustered = solve_transient(&TransientScenarioInput::default());
        let spread = solve_transient(&TransientScenarioInput {
            floorplan_mode: FloorplanMode::SpreadSram,
            ..TransientScenarioInput::default()
        });
        assert_ne!(
            clustered.frames.last().unwrap().hotspot_centroid,
            spread.frames.last().unwrap().hotspot_centroid
        );
        assert!(spread.metrics.max_peak_c <= clustered.metrics.max_peak_c + 3.0);
    }

    #[test]
    fn design_review_recommends_lowest_cost_passing_intervention() {
        let review = solve_design_review(&DesignReviewInput::default());
        assert!(!review.baseline.pass);
        assert_eq!(
            review.recommended_intervention,
            DesignIntervention::SpreadSram
        );
        assert_eq!(
            review.ranked_candidates.first().unwrap().intervention,
            DesignIntervention::SpreadSram
        );
        assert!(review.pass);
        assert!(review
            .baseline
            .constraint_violations
            .contains(&"power_delivery_droop_above_limit".to_string()));
        assert!(review
            .ranked_candidates
            .first()
            .unwrap()
            .constraint_violations
            .is_empty());
    }

    #[test]
    fn design_review_schema_roundtrip() {
        let input = DesignReviewInput::default();
        let input_json = serde_json::to_string(&input).unwrap();
        let decoded: DesignReviewInput = serde_json::from_str(&input_json).unwrap();
        assert_eq!(decoded, input);

        let schema = schema_bundle();
        assert!(schema.get("DesignReviewInput").is_some());
        assert!(schema.get("DesignReviewResult").is_some());
    }

    #[test]
    fn design_review_ranking_is_deterministic_and_conservative() {
        let first = solve_design_review(&DesignReviewInput::default());
        let second = solve_design_review(&DesignReviewInput::default());
        let first_order = first
            .ranked_candidates
            .iter()
            .map(|candidate| candidate.intervention)
            .collect::<Vec<_>>();
        let second_order = second
            .ranked_candidates
            .iter()
            .map(|candidate| candidate.intervention)
            .collect::<Vec<_>>();

        assert_eq!(first_order, second_order);
        assert!(first
            .ranked_candidates
            .windows(2)
            .all(|pair| compare_design_candidates(&pair[0], &pair[1]).is_le()));
        assert!(first.non_claim.contains("Early-design ranking"));
        assert!(first.non_claim.contains("not final verification"));
        assert!(!first.non_claim.contains("production verification tool"));
    }
}
