import SwiftUI

struct ContentView: View {
    @State private var controls = SimulationControls(
        workloadPhase: .balanced,
        powerScale: 1.0,
        coolingPreset: .airflow,
        floorplanMode: .clusteredSram
    )
    @State private var result: SimulationResult?
    @State private var previousCentroid: Point?
    @State private var errorMessage: String?
    @State private var kbEntries: [KBEntry] = []
    @State private var isRunning = false

    private let runner = RustRunner()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                leftPane
                    .frame(width: 320)
                Divider()
                heatmapPane
                Divider()
                rightPane
                    .frame(width: 340)
            }
        }
        .task {
            loadKB()
            await runSimulation()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chip Heat Lab")
                    .font(.headline)
                Text("Simplified early-design thermal intuition demo")
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
            Button("Run") {
                Task { await runSimulation() }
            }
            .disabled(isRunning)
        }
        .padding(14)
    }

    private var leftPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Controls")
                .font(.title3)
                .bold()

            Picker("Workload", selection: binding(\.workloadPhase)) {
                ForEach(WorkloadPhase.allCases) { phase in
                    Text(phase.label).tag(phase)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading) {
                Text("Power Scale \(controls.powerScale, specifier: "%.2f")")
                    .font(.caption)
                Slider(value: binding(\.powerScale), in: 0...2.2, step: 0.1)
            }

            Picker("Cooling", selection: binding(\.coolingPreset)) {
                ForEach(CoolingPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Picker("Floorplan", selection: binding(\.floorplanMode)) {
                ForEach(FloorplanMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if let result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hotspot")
                        .font(.headline)
                    Text("Cell \(result.peakCell.x), \(result.peakCell.y)")
                    Text("Centroid \(result.hotspotCentroid.x, specifier: "%.1f"), \(result.hotspotCentroid.y, specifier: "%.1f")")
                    Text(movementText(result.hotspotCentroid))
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .padding(16)
        .onChange(of: controls) { _ in
            Task { await runSimulation() }
        }
    }

    private var heatmapPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Floorplan + Heatmap")
                .font(.title3)
                .bold()
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
        VStack(alignment: .leading, spacing: 14) {
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
                .frame(height: 190)
            }

            Text("Explanation")
                .font(.title3)
                .bold()
            explanationPanel
            Spacer()
        }
        .padding(16)
    }

    private var explanationPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Assumptions")
                    .font(.headline)
                Text("Fixed 96x96 grid, stylized AI accelerator blocks, one steady-state 2D equation, demo-unit power density, and three cooling presets.")

                Text("Non-Claims")
                    .font(.headline)
                Text("This is not verification, manufacturing evidence, or a production thermal tool. It is a simplified early-design thermal intuition demo.")

                if !kbEntries.isEmpty {
                    Text("KB")
                        .font(.headline)
                    ForEach(kbEntries.prefix(4)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).bold()
                            Text(entry.summary)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        } catch {
            errorMessage = error.localizedDescription
        }
        isRunning = false
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
                        Text(block.name)
                            .font(.caption2)
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
