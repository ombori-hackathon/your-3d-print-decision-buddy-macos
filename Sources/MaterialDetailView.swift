import SwiftUI

struct MaterialDetailView: View {
    let materialId: Int
    @State private var material: Material?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPrinterId: Int?

    @Environment(\.dismiss) private var dismiss
    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            if isLoading {
                ProgressView("Loading material details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                errorView(error)
            } else if let material = material {
                detailContent(material)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .task {
            await loadMaterial()
        }
        .sheet(item: $selectedPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
                .frame(minWidth: 600, minHeight: 500)
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ material: Material) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Section: Gradient + Basic Info
                HStack(alignment: .top, spacing: 24) {
                    // Gradient card with icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(materialGradient(for: material))
                            .frame(width: 200, height: 160)

                        VStack(spacing: 8) {
                            Image(systemName: material.materialType == "fdm" ? "cylinder" : "drop.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.9))

                            Text(material.name)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                    }

                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(material.fullName)
                                .font(.title.bold())
                            if let category = material.category {
                                Text(category.capitalized)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Badges
                        HStack(spacing: 8) {
                            Badge(
                                text: material.materialType.uppercased(),
                                color: material.materialType == "fdm" ? .blue : .purple
                            )

                            Badge(
                                text: material.difficultyLevel.capitalized,
                                color: difficultyColor(for: material.difficultyLevel)
                            )
                        }

                        if let description = material.description {
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }

                Divider()

                // Temperature/UV Specifications
                Text("Specifications")
                    .font(.title2.bold())

                if material.materialType == "fdm" {
                    fdmSpecsSection(material)
                } else {
                    resinSpecsSection(material)
                }

                Divider()

                // Pros and Cons side by side
                HStack(alignment: .top, spacing: 32) {
                    // Pros
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Pros")
                                .font(.title3.bold())
                        }

                        ForEach(material.pros, id: \.self) { pro in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(pro)
                                    .font(.callout)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Cons
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Cons")
                                .font(.title3.bold())
                        }

                        ForEach(material.cons, id: \.self) { con in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(con)
                                    .font(.callout)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Best Uses
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("Best Uses")
                            .font(.title3.bold())
                    }

                    FlowLayout(spacing: 8) {
                        ForEach(material.bestUses, id: \.self) { use in
                            Text(use)
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                // Example Projects
                if !material.exampleProjects.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.orange)
                            Text("Example Projects")
                                .font(.title3.bold())
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(material.exampleProjects, id: \.self) { project in
                                Text(project)
                                    .font(.callout)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Divider()

                // Printing Tips
                if !material.printingTips.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.max.fill")
                                .foregroundStyle(.yellow)
                            Text("Printing Tips")
                                .font(.title3.bold())
                        }

                        ForEach(material.printingTips.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Text(material.printingTips[index])
                            }
                            .font(.callout)
                        }
                    }
                }

                // Post Processing
                if !material.postProcessing.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.purple)
                            Text("Post Processing")
                                .font(.title3.bold())
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(material.postProcessing, id: \.self) { step in
                                Text(step)
                                    .font(.callout)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.purple.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Properties
                if !material.properties.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.cyan)
                            Text("Material Properties")
                                .font(.title3.bold())
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Array(material.properties.keys.sorted()), id: \.self) { key in
                                if let value = material.properties[key] {
                                    PropertyCard(name: key, value: value)
                                }
                            }
                        }
                    }
                }

                // Compatible Printers
                if !material.compatiblePrinters.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "printer.fill")
                                .foregroundStyle(.blue)
                            Text("Compatible Printers")
                                .font(.title3.bold())
                            Text("(\(material.compatiblePrinters.count))")
                                .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200))], spacing: 12) {
                            ForEach(material.compatiblePrinters) { printer in
                                CompatiblePrinterCard(printer: printer)
                                    .onTapGesture {
                                        selectedPrinterId = printer.id
                                    }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - FDM Specs Section

    private func fdmSpecsSection(_ material: Material) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let tempRange = material.printTemperatureRange {
                SpecCard(title: "Print Temp", value: tempRange, icon: "thermometer.high")
            }

            if let bedRange = material.bedTemperatureRange {
                SpecCard(title: "Bed Temp", value: bedRange, icon: "thermometer.low")
            }

            if let minTemp = material.printTempMin {
                SpecCard(title: "Min Print Temp", value: "\(minTemp)°C", icon: "thermometer.snowflake")
            }

            if let maxTemp = material.printTempMax {
                SpecCard(title: "Max Print Temp", value: "\(maxTemp)°C", icon: "thermometer.sun.fill")
            }
        }
    }

    // MARK: - Resin Specs Section

    private func resinSpecsSection(_ material: Material) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let exposure = material.exposureTimeS {
                SpecCard(title: "Exposure Time", value: String(format: "%.1f s", exposure), icon: "timer")
            }

            if let wavelength = material.uvWavelengthNm {
                SpecCard(title: "UV Wavelength", value: "\(wavelength) nm", icon: "sun.max.fill")
            }
        }
    }

    // MARK: - Helper Methods

    private func materialGradient(for material: Material) -> LinearGradient {
        let colors: [Color]
        switch material.materialType {
        case "fdm":
            switch material.name.lowercased() {
            case "pla": colors = [.green, .green.opacity(0.7)]
            case "petg": colors = [.blue, .cyan]
            case "abs": colors = [.orange, .red]
            case "tpu": colors = [.purple, .pink]
            case "asa": colors = [.yellow, .orange]
            case "nylon": colors = [.gray, .blue]
            case "pc": colors = [.indigo, .purple]
            default: colors = [.gray, .gray.opacity(0.7)]
            }
        case "resin":
            switch material.name.lowercased() {
            case "standard resin": colors = [.cyan, .blue]
            case "abs-like resin": colors = [.orange, .yellow]
            case "flexible resin": colors = [.pink, .purple]
            case "castable resin": colors = [.yellow, .orange]
            case "dental resin": colors = [.mint, .teal]
            default: colors = [.purple, .indigo]
            }
        default:
            colors = [.gray, .gray.opacity(0.7)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func difficultyColor(for level: String) -> Color {
        switch level {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await loadMaterial()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadMaterial() async {
        isLoading = true
        errorMessage = nil

        do {
            material = try await apiClient.fetchMaterial(id: materialId)
        } catch {
            errorMessage = "Failed to load material: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Property Card

struct PropertyCard: View {
    let name: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.capitalized)
                .font(.callout.bold())
                .foregroundStyle(colorFor(value: value))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private func colorFor(value: String) -> Color {
        switch value.lowercased() {
        case "very high", "excellent": return .green
        case "high", "very good", "good": return .blue
        case "medium": return .orange
        case "low": return .red
        case "very low", "none": return .gray
        default: return .primary
        }
    }
}

// MARK: - Compatible Printer Card

struct CompatiblePrinterCard: View {
    let printer: CompatiblePrinter

    var body: some View {
        VStack(spacing: 8) {
            // Image
            AsyncImage(url: URL(string: printer.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.secondary.opacity(0.1))
                        .overlay { ProgressView() }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Rectangle()
                        .fill(.secondary.opacity(0.1))
                        .overlay {
                            Image(systemName: "printer")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(.secondary.opacity(0.05))
            .cornerRadius(8)

            // Info
            VStack(spacing: 2) {
                Text(printer.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(printer.manufacturer)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .contentShape(Rectangle())
    }
}
