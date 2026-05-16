import SwiftUI

struct ContentView: View {
    @State private var controls = SimulationControls(
        workloadPhase: .inferenceKv,
        powerScale: 1.0,
        coolingPreset: .airflow,
        floorplanMode: .spreadSram
    )
    @State private var result: SimulationResult?
    @State private var previousCentroid: Point?
    @State private var designComparison: DesignComparison?
    @State private var designReview: DesignReviewResult?
    @State private var errorMessage: String?
    @State private var kbEntries: [KBEntry] = []
    @State private var isRunning = false
    @State private var isRunningReview = false

    private let runner = RustRunner()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                leftPane
                    .frame(width: 340)
                Divider()
                heatmapPane
                Divider()
                rightPane
                    .frame(width: 460)
            }
        }
        .task {
            loadKB()
            await runSimulation()
            await runDesignReview()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chip Heat Lab")
                    .font(.headline)
                Text("Native design-review cockpit: Rust thermal, transient, and power-delivery proxy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let result {
                Text("Peak \(result.peakC, specifier: "%.1f") C")
                    .font(.title3.monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
            }
            if let designReview {
                Text("Review: \(designReview.recommendedLabel)")
                    .font(.callout)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
            }
            Button("Run") {
                Task { await runSimulation() }
            }
            .disabled(isRunning)
            Button("Review") {
                Task { await runDesignReview() }
            }
            .disabled(isRunningReview)
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
        .padding(14)
    }

    private var leftPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Live Scenario Controls")
                    .font(.title3)
                    .bold()
                Text("The app opens on the recommended KV-cache spread-SRAM case. Toggle back to clustered SRAM to show the hotter baseline behind the review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Workload")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: binding(\.workloadPhase)) {
                        ForEach(WorkloadPhase.allCases) { phase in
                            Text(phase.label).tag(phase)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Power Scale \(controls.powerScale, specifier: "%.2f")")
                        .font(.caption)
                    Slider(value: binding(\.powerScale), in: 0...2.2, step: 0.1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Cooling")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: binding(\.coolingPreset)) {
                        ForEach(CoolingPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Floorplan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: binding(\.floorplanMode)) {
                        ForEach(FloorplanMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                if let result {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Hotspot")
                            .font(.headline)
                        Text("Cell \(result.peakCell.x), \(result.peakCell.y)")
                        Text("Centroid \(result.hotspotCentroid.x, specifier: "%.1f"), \(result.hotspotCentroid.y, specifier: "%.1f")")
                        Text(movementText(result.hotspotCentroid))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.callout)
                    .padding(10)
                    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .onChange(of: controls) { _ in
            Task { await runSimulation() }
        }
    }

    private var heatmapPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Floorplan + Heatmap")
                .font(.title3)
                .bold()
            if let result {
                HStack(spacing: 8) {
                    ReviewStatusPill(text: result.controls.workloadPhase.label.uppercased(), color: .blue)
                    ReviewStatusPill(text: result.controls.floorplanMode.label.uppercased(), color: .green)
                    ReviewStatusPill(text: "\(result.iterations) SOLVER ITERS", color: .gray)
                    Spacer()
                    Text("residual \(result.residual, format: .number.precision(.significantDigits(2)))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            GeometryReader { geometry in
                if let result {
                    ZStack {
                        HeatmapView(result: result)
                        FloorplanOverlay(blocks: result.floorplan)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(16)
    }

    private var rightPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                designReviewPanel
                blockMaxPanel
                designValuePanel
                explanationPanel
            }
            .padding(16)
        }
    }

    private var designValuePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question")
                .font(.headline)
            Text("For a KV-cache-heavy workload, does spreading SRAM reduce the hotspot before changing the cooling budget?")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let comparison = designComparison {
                HStack(spacing: 10) {
                    MetricTile(label: "clustered", value: comparison.clusteredPeak)
                    MetricTile(label: "spread", value: comparison.spreadPeak)
                    MetricTile(label: "drop", value: comparison.deltaC)
                }
                Text(comparison.recommendation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Run the simulation to compute the layout comparison.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private var designReviewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Design Review")
                        .font(.title3)
                        .bold()
                    Text("Rust CLI composes steady thermal, transient dose, and power-delivery proxy checks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if isRunningReview {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if let designReview {
                let recommended = recommendedCandidate(in: designReview)
                let baseline = designReview.baseline

                Text(designReview.designQuestion)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    ReviewStatusPill(text: baseline.pass ? "BASELINE PASS" : "BASELINE RISK", color: baseline.pass ? .green : .orange)
                    ReviewStatusPill(text: designReview.pass ? "REVIEW HAS PASSING FIX" : "NO PASSING FIX", color: designReview.pass ? .green : .red)
                    Spacer(minLength: 0)
                }

                if let recommended {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended First Change")
                            .font(.headline)
                        Text(recommended.label)
                            .font(.title3)
                            .bold()
                        Text(recommended.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            MetricTile(label: "steady", value: recommended.steadyPeakC, unit: "C", tint: .orange)
                            MetricTile(label: "dose", value: recommended.thermalDoseCS, unit: "C-s", tint: .red)
                            MetricTile(label: "droop", value: recommended.worstDroopMv, unit: "mV", tint: .blue)
                            MetricTile(label: "cost", value: recommended.costScore, unit: "", tint: .green)
                        }
                    }
                    .padding(10)
                    .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }

                constraintPanel(designReview)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ranked Interventions")
                            .font(.headline)
                        Spacer()
                        Text("lowest passing score first")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(designReview.rankedCandidates.prefix(6).enumerated()), id: \.element.id) { index, candidate in
                        CandidateReviewRow(rank: index + 1, candidate: candidate)
                    }
                }

                if !designReview.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model Warnings")
                            .font(.headline)
                        ForEach(designReview.warnings, id: \.self) { warning in
                            Text(warning.replacingOccurrences(of: "_", with: " "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text(designReview.nonClaim)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
                    .background(.gray.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("Runs the Rust CLI design-review mode: steady thermal, transient dose, power-delivery proxy, constraints, and ranked intervention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }

    private var blockMaxPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Per-Block Max")
                .font(.title3)
                .bold()
            if let result {
                Table(blockRows(result), columns: {
                    TableColumn("Block", value: \.name)
                    TableColumn("Max C") { row in
                        Text(row.value, format: .number.precision(.fractionLength(1)))
                            .monospacedDigit()
                    }
                })
                .frame(height: 170)
            } else {
                Text("Waiting for the interactive heatmap run.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var explanationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GBrain-Ready Knowledge")
                .font(.title3)
                .bold()
            Text("The app keeps assumptions and claim boundaries visible from the same KB index used by the repo and site.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Assumptions")
                    .font(.headline)
                Text("Fixed 96x96 grid, stylized AI accelerator blocks, simplified thermal equations, demo-unit power density, and proxy power-delivery checks.")

                Text("Non-Claims")
                    .font(.headline)
                Text("This is not verification, manufacturing evidence, standards compliance, package airflow analysis, or a production chip-design tool.")

                if !kbEntries.isEmpty {
                    Divider()
                    ForEach(kbEntries.prefix(5)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).bold()
                            Text(entry.summary)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .font(.callout)
        }
    }

    private func constraintPanel(_ designReview: DesignReviewResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Constraint Checks")
                .font(.headline)
            ForEach(constraintKeys(in: designReview), id: \.self) { key in
                ConstraintCheckRow(
                    name: constraintLabel(key),
                    limit: constraintLimitText(key, value: designReview.constraints[key] ?? 0),
                    baselineValue: candidateValueText(designReview.baseline, key: key),
                    recommendedValue: recommendedCandidate(in: designReview).map { candidateValueText($0, key: key) } ?? "-",
                    baselinePass: !violates(designReview.baseline, key: key),
                    recommendedPass: recommendedCandidate(in: designReview).map { !violates($0, key: key) } ?? false
                )
            }
        }
        .padding(10)
        .background(.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func recommendedCandidate(in designReview: DesignReviewResult) -> DesignCandidateResult? {
        designReview.rankedCandidates.first { $0.intervention == designReview.recommendedIntervention }
            ?? designReview.rankedCandidates.first
    }

    private func constraintKeys(in designReview: DesignReviewResult) -> [String] {
        let preferred = ["peak_limit_c", "thermal_dose_limit_c_s", "droop_limit_mv", "overlap_limit"]
        let present = Set(designReview.constraints.keys)
        let ordered = preferred.filter { present.contains($0) }
        return ordered + designReview.constraints.keys.filter { !preferred.contains($0) }.sorted()
    }

    private func constraintLabel(_ key: String) -> String {
        switch key {
        case "peak_limit_c": return "Steady peak"
        case "thermal_dose_limit_c_s": return "Thermal dose"
        case "droop_limit_mv": return "Worst droop"
        case "overlap_limit": return "Thermal/PDN overlap"
        default: return key.replacingOccurrences(of: "_", with: " ")
        }
    }

    private func constraintLimitText(_ key: String, value: Double) -> String {
        switch key {
        case "peak_limit_c": return String(format: "<= %.0f C", value)
        case "thermal_dose_limit_c_s": return String(format: "<= %.1f C-s", value)
        case "droop_limit_mv": return String(format: "<= %.0f mV", value)
        case "overlap_limit": return String(format: "<= %.2f", value)
        default: return String(format: "<= %.2f", value)
        }
    }

    private func candidateValueText(_ candidate: DesignCandidateResult, key: String) -> String {
        switch key {
        case "peak_limit_c": return String(format: "%.1f C", candidate.steadyPeakC)
        case "thermal_dose_limit_c_s": return String(format: "%.1f C-s", candidate.thermalDoseCS)
        case "droop_limit_mv": return String(format: "%.1f mV", candidate.worstDroopMv)
        case "overlap_limit": return String(format: "%.2f", candidate.overlapScore)
        default: return "-"
        }
    }

    private func violates(_ candidate: DesignCandidateResult, key: String) -> Bool {
        let fragments: [String]
        switch key {
        case "peak_limit_c": fragments = ["peak"]
        case "thermal_dose_limit_c_s": fragments = ["thermal_dose"]
        case "droop_limit_mv": fragments = ["droop"]
        case "overlap_limit": fragments = ["overlap"]
        default: fragments = [key]
        }
        return candidate.constraintViolations.contains { violation in
            fragments.contains { violation.contains($0) }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<SimulationControls, Value>) -> Binding<Value> {
        Binding(
            get: { controls[keyPath: keyPath] },
            set: { controls[keyPath: keyPath] = $0 }
        )
    }

    private func runSimulation() async {
        isRunning = true
        errorMessage = nil
        let input = ScenarioInput(
            scenarioName: "flagship_ai_accelerator",
            ambientC: 35.0,
            conductivity: 0.62,
            controls: controls
        )
        do {
            let next = try await runner.run(input)
            previousCentroid = result?.hotspotCentroid
            result = next
            designComparison = try? await runDesignComparison()
        } catch {
            errorMessage = error.localizedDescription
        }
        isRunning = false
    }

    private func runDesignComparison() async throws -> DesignComparison {
        let clustered = try await runner.run(
            comparisonInput(floorplanMode: .clusteredSram)
        )
        let spread = try await runner.run(
            comparisonInput(floorplanMode: .spreadSram)
        )
        return DesignComparison(clustered: clustered, spread: spread)
    }

    private func runDesignReview() async {
        isRunningReview = true
        do {
            designReview = try await runner.runDesignReview()
        } catch {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
        isRunningReview = false
    }

    private func comparisonInput(floorplanMode: FloorplanMode) -> ScenarioInput {
        ScenarioInput(
            scenarioName: "kv_cache_floorplan_comparison",
            ambientC: 35.0,
            conductivity: 0.62,
            controls: SimulationControls(
                workloadPhase: .inferenceKv,
                powerScale: 1.0,
                coolingPreset: .airflow,
                floorplanMode: floorplanMode
            )
        )
    }

    private func loadKB() {
        guard let url = ResourceLocator.url(named: "kb_index", extension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([KBEntry].self, from: data)
        else {
            return
        }
        kbEntries = entries
    }

    private func movementText(_ centroid: Point) -> String {
        guard let previousCentroid else {
            return "Run another control change to show hotspot movement."
        }
        let dx = centroid.x - previousCentroid.x
        let dy = centroid.y - previousCentroid.y
        return String(format: "Movement arrow: dx %.1f, dy %.1f", dx, dy)
    }

    private func blockRows(_ result: SimulationResult) -> [BlockRow] {
        result.perBlockMax
            .map { BlockRow(name: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }

}

struct BlockRow: Identifiable {
    var id: String { name }
    var name: String
    var value: Double
}

struct DesignComparison {
    var clusteredPeak: Double
    var spreadPeak: Double
    var deltaC: Double
    var clusteredCentroid: Point
    var spreadCentroid: Point

    init(clustered: SimulationResult, spread: SimulationResult) {
        clusteredPeak = clustered.peakC
        spreadPeak = spread.peakC
        deltaC = clustered.peakC - spread.peakC
        clusteredCentroid = clustered.hotspotCentroid
        spreadCentroid = spread.hotspotCentroid
    }

    var recommendation: String {
        if deltaC > 1.0 {
            return String(format: "In this simplified model, spreading SRAM lowers the KV-cache peak by %.1f C and moves the centroid from %.1f, %.1f to %.1f, %.1f.", deltaC, clusteredCentroid.x, clusteredCentroid.y, spreadCentroid.x, spreadCentroid.y)
        }
        return "In this simplified model, layout has a smaller effect than cooling or workload phase for this comparison."
    }
}

struct ReviewStatusPill: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct MetricTile: View {
    var label: String
    var value: Double
    var unit = ""
    var tint = Color.blue

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.headline.monospacedDigit())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct ConstraintCheckRow: View {
    var name: String
    var limit: String
    var baselineValue: String
    var recommendedValue: String
    var baselinePass: Bool
    var recommendedPass: Bool

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 4) {
            GridRow {
                Text(name)
                    .font(.caption.bold())
                Text("base")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("rec")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(limit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            GridRow {
                Text("")
                valueText(baselineValue, pass: baselinePass)
                valueText(recommendedValue, pass: recommendedPass)
                Text("")
            }
        }
        .padding(.vertical, 3)
    }

    private func valueText(_ text: String, pass: Bool) -> some View {
        Text(text)
            .font(.caption.monospacedDigit())
            .foregroundStyle(pass ? .green : .orange)
    }
}

struct CandidateReviewRow: View {
    var rank: Int
    var candidate: DesignCandidateResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("#\(rank)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
                ReviewStatusPill(
                    text: candidate.pass ? "PASS" : "\(candidate.constraintViolations.count) RISK",
                    color: candidate.pass ? .green : .orange
                )
                Text(candidate.label)
                    .font(.callout.bold())
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(String(format: "%.1f cost", candidate.costScore))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                MiniMetric(label: "steady", value: String(format: "%.1f C", candidate.steadyPeakC))
                MiniMetric(label: "dose", value: String(format: "%.1f C-s", candidate.thermalDoseCS))
                MiniMetric(label: "droop", value: String(format: "%.1f mV", candidate.worstDroopMv))
                MiniMetric(label: "overlap", value: String(format: "%.2f", candidate.overlapScore))
            }

            Text(candidate.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(candidate.pass ? Color.green.opacity(0.06) : Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MiniMetric: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.caption.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HeatmapView: View {
    var result: SimulationResult

    var body: some View {
        Canvas { context, size in
            let grid = result.temperatureGrid
            let minT = result.ambientC
            let maxT = max(result.peakC, minT + 1)
            let cellW = size.width / CGFloat(result.gridSize)
            let cellH = size.height / CGFloat(result.gridSize)
            for y in 0..<result.gridSize {
                for x in 0..<result.gridSize {
                    let value = grid[y][x]
                    let t = min(max((value - minT) / (maxT - minT), 0), 1)
                    let color = Color(
                        red: 0.08 + 0.90 * t,
                        green: 0.18 + 0.42 * (1 - abs(t - 0.45)),
                        blue: 0.35 * (1 - t)
                    )
                    let rect = CGRect(x: CGFloat(x) * cellW, y: CGFloat(y) * cellH, width: cellW + 0.5, height: cellH + 0.5)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .background(Color.black.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private func chipBlockDisplayName(_ name: String) -> String {
    switch name {
    case "MatMul Array A": return "MatMul A"
    case "MatMul Array B": return "MatMul B"
    case "SRAM / KV Cache": return "SRAM / KV"
    case "NoC Spine": return "NoC"
    default: return name
    }
}

struct FloorplanOverlay: View {
    var blocks: [BlockLayout]

    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 96
            let scaleY = geometry.size.height / 96
            ZStack(alignment: .topLeading) {
                ForEach(blocks) { block in
                    ForEach(block.rects.indices, id: \.self) { index in
                        let rect = block.rects[index]
                        Rectangle()
                            .stroke(.white.opacity(0.85), lineWidth: 1.2)
                            .background(Color.white.opacity(0.05))
                            .frame(width: CGFloat(rect.width) * scaleX, height: CGFloat(rect.height) * scaleY)
                            .offset(x: CGFloat(rect.x) * scaleX, y: CGFloat(rect.y) * scaleY)
                        Text(chipBlockDisplayName(block.name))
                            .font(rect.width <= 8 ? .system(size: 9, weight: .bold) : .caption2)
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 4))
                            .offset(x: CGFloat(rect.x) * scaleX + 4, y: CGFloat(rect.y) * scaleY + 4)
                    }
                }
            }
        }
    }
}
