import Foundation

enum WorkloadPhase: String, CaseIterable, Identifiable, Codable {
    case balanced
    case trainingMatmul = "training_matmul"
    case inferenceKv = "inference_kv"
    case ioBurst = "io_burst"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .balanced: return "Balanced"
        case .trainingMatmul: return "Training"
        case .inferenceKv: return "KV Inference"
        case .ioBurst: return "IO Burst"
        }
    }
}

enum CoolingPreset: String, CaseIterable, Identifiable, Codable {
    case passive
    case airflow
    case aggressive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .passive: return "Passive"
        case .airflow: return "Airflow"
        case .aggressive: return "Aggressive"
        }
    }
}

enum FloorplanMode: String, CaseIterable, Identifiable, Codable {
    case clusteredSram = "clustered_sram"
    case spreadSram = "spread_sram"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clusteredSram: return "Clustered SRAM"
        case .spreadSram: return "Spread SRAM"
        }
    }
}

enum PowerBumpPreset: String, Codable {
    case sparse
    case nominal
    case dense
}

enum DesignIntervention: String, Codable {
    case baseline
    case spreadSram = "spread_sram"
    case densePowerBumps = "dense_power_bumps"
    case aggressiveCooling = "aggressive_cooling"
    case staggeredWorkload = "staggered_workload"
    case spreadSramDenseBumps = "spread_sram_dense_bumps"
    case spreadSramDenseBumpsStaggered = "spread_sram_dense_bumps_staggered"
}

struct SimulationControls: Codable, Equatable {
    var workloadPhase: WorkloadPhase
    var powerScale: Double
    var coolingPreset: CoolingPreset
    var floorplanMode: FloorplanMode

    enum CodingKeys: String, CodingKey {
        case workloadPhase = "workload_phase"
        case powerScale = "power_scale"
        case coolingPreset = "cooling_preset"
        case floorplanMode = "floorplan_mode"
    }
}

struct ScenarioInput: Codable {
    var scenarioName: String
    var ambientC: Double
    var conductivity: Double
    var controls: SimulationControls

    enum CodingKeys: String, CodingKey {
        case scenarioName = "scenario_name"
        case ambientC = "ambient_c"
        case conductivity
        case controls
    }
}

struct Cell: Codable, Equatable {
    var x: Int
    var y: Int
}

struct Point: Codable, Equatable {
    var x: Double
    var y: Double
}

struct Rect: Codable, Equatable {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
}

struct BlockLayout: Codable, Identifiable, Equatable {
    var id: String { name }
    var name: String
    var rects: [Rect]
    var powerDensity: Double

    enum CodingKeys: String, CodingKey {
        case name
        case rects
        case powerDensity = "power_density"
    }
}

struct SimulationResult: Codable, Equatable {
    var scenarioName: String
    var gridSize: Int
    var ambientC: Double
    var controls: SimulationControls
    var floorplan: [BlockLayout]
    var temperatureGrid: [[Double]]
    var peakC: Double
    var peakCell: Cell
    var hotspotCentroid: Point
    var perBlockMax: [String: Double]
    var residual: Double
    var iterations: Int
    var warnings: [String]

    enum CodingKeys: String, CodingKey {
        case scenarioName = "scenario_name"
        case gridSize = "grid_size"
        case ambientC = "ambient_c"
        case controls
        case floorplan
        case temperatureGrid = "temperature_grid"
        case peakC = "peak_c"
        case peakCell = "peak_cell"
        case hotspotCentroid = "hotspot_centroid"
        case perBlockMax = "per_block_max"
        case residual
        case iterations
        case warnings
    }
}

struct KBEntry: Codable, Identifiable {
    var id: String
    var title: String
    var path: String
    var type: String
    var claimLevel: String
    var sources: [String]
    var summary: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case path
        case type
        case claimLevel = "claim_level"
        case sources
        case summary
    }
}

struct DesignCandidateResult: Codable, Identifiable, Equatable {
    var id: String { intervention.rawValue }
    var intervention: DesignIntervention
    var label: String
    var controls: SimulationControls
    var bumpPreset: PowerBumpPreset
    var steadyPeakC: Double
    var transientMaxPeakC: Double
    var timeAboveThresholdS: Double
    var thermalDoseCS: Double
    var maxGradientCPerCell: Double
    var hotspotPathDistanceCells: Double
    var worstDroopMv: Double
    var thermalPdnDistanceCells: Double
    var overlapScore: Double
    var riskUtilization: DesignRiskUtilization
    var costScore: Double
    var constraintViolations: [String]
    var pass: Bool
    var rankScore: Double
    var reason: String

    enum CodingKeys: String, CodingKey {
        case intervention
        case label
        case controls
        case bumpPreset = "bump_preset"
        case steadyPeakC = "steady_peak_c"
        case transientMaxPeakC = "transient_max_peak_c"
        case timeAboveThresholdS = "time_above_threshold_s"
        case thermalDoseCS = "thermal_dose_c_s"
        case maxGradientCPerCell = "max_gradient_c_per_cell"
        case hotspotPathDistanceCells = "hotspot_path_distance_cells"
        case worstDroopMv = "worst_droop_mv"
        case thermalPdnDistanceCells = "thermal_pdn_distance_cells"
        case overlapScore = "overlap_score"
        case riskUtilization = "risk_utilization"
        case costScore = "cost_score"
        case constraintViolations = "constraint_violations"
        case pass
        case rankScore = "rank_score"
        case reason
    }
}

struct DesignRiskUtilization: Codable, Equatable {
    var steadyPeak: Double
    var thermalDose: Double
    var worstDroop: Double
    var overlap: Double

    enum CodingKeys: String, CodingKey {
        case steadyPeak = "steady_peak"
        case thermalDose = "thermal_dose"
        case worstDroop = "worst_droop"
        case overlap
    }
}

struct DesignReviewResult: Codable, Equatable {
    var scenarioName: String
    var designQuestion: String
    var baseline: DesignCandidateResult
    var rankedCandidates: [DesignCandidateResult]
    var recommendedIntervention: DesignIntervention
    var recommendedLabel: String
    var paretoFrontier: [DesignIntervention]
    var constraints: [String: Double]
    var warnings: [String]
    var nonClaim: String
    var pass: Bool

    enum CodingKeys: String, CodingKey {
        case scenarioName = "scenario_name"
        case designQuestion = "design_question"
        case baseline
        case rankedCandidates = "ranked_candidates"
        case recommendedIntervention = "recommended_intervention"
        case recommendedLabel = "recommended_label"
        case paretoFrontier = "pareto_frontier"
        case constraints
        case warnings
        case nonClaim = "non_claim"
        case pass
    }
}
