import SwiftUI

struct MaterialsBrowseView: View {
    @State private var materials: [MaterialListItem] = []
    @State private var selectedMaterialId: Int?
    @State private var detailMaterialId: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Filters
    @State private var selectedType: MaterialType?
    @State private var selectedDifficulty: DifficultyLevel?

    private let apiClient = PrinterAPIClient()

    var body: some View {
        HSplitView {
            // Filter Sidebar
            filterSidebar
                .frame(minWidth: 200, maxWidth: 250)

            // Main Content
            VStack(spacing: 0) {
                if let error = errorMessage {
                    errorView(error)
                } else if isLoading {
                    ProgressView("Loading materials...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if materials.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cylinder")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No materials found")
                            .foregroundStyle(.secondary)
                        Text("Try adjusting your filters")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    materialGrid
                }
            }
            .frame(minWidth: 400)
        }
        .task {
            await loadMaterials()
        }
        .sheet(item: $detailMaterialId) { materialId in
            MaterialDetailView(materialId: materialId)
                .frame(minWidth: 700, minHeight: 600)
        }
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Filters")
                    .font(.headline)

                // Material Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Material Type")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(nil as MaterialType?)
                        ForEach(MaterialType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type as MaterialType?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                // Difficulty Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Difficulty Level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Difficulty", selection: $selectedDifficulty) {
                        Text("All Levels").tag(nil as DifficultyLevel?)
                        ForEach(DifficultyLevel.allCases) { level in
                            Text(level.displayName).tag(level as DifficultyLevel?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Spacer()

                // Apply Button
                Button("Apply Filters") {
                    Task {
                        await loadMaterials()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Filters") {
                    resetFilters()
                    Task {
                        await loadMaterials()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(.bar)
    }

    // MARK: - Material Grid

    private var materialGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 350))], spacing: 16) {
                ForEach(materials) { material in
                    MaterialCard(material: material)
                        .onTapGesture {
                            detailMaterialId = material.id
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await loadMaterials()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadMaterials() async {
        isLoading = true
        errorMessage = nil

        let filters = MaterialFilters(
            materialType: selectedType,
            difficultyLevel: selectedDifficulty
        )

        do {
            materials = try await apiClient.fetchMaterials(filters: filters)
        } catch {
            errorMessage = "Failed to load materials: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func resetFilters() {
        selectedType = nil
        selectedDifficulty = nil
    }
}

// MARK: - Material Card

struct MaterialCard: View {
    let material: MaterialListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder (materials don't have images yet in seed data)
            ZStack {
                Rectangle()
                    .fill(materialGradient)

                VStack(spacing: 8) {
                    Image(systemName: material.materialType == "fdm" ? "cylinder" : "drop.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))

                    Text(material.name)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Name and Type
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(material.fullName)
                            .font(.headline)
                            .lineLimit(2)
                        if let category = material.category {
                            Text(category.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                // Badges
                HStack(spacing: 6) {
                    // Type badge
                    Text(material.materialType.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(material.materialType == "fdm" ? .blue.opacity(0.2) : .purple.opacity(0.2))
                        .cornerRadius(4)

                    // Difficulty badge
                    Text(material.difficultyLevel.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundStyle(difficultyColor)
                        .cornerRadius(4)

                    Spacer()

                    // Temperature (FDM only)
                    if let tempRange = material.temperatureRange {
                        HStack(spacing: 2) {
                            Image(systemName: "thermometer.medium")
                            Text(tempRange)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                // Best uses preview
                if !material.bestUses.isEmpty {
                    Text(material.bestUses.prefix(3).joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Pros preview
                if !material.pros.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(material.pros.first ?? "")
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .contentShape(Rectangle())
    }

    private var materialGradient: LinearGradient {
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

    private var difficultyColor: Color {
        switch material.difficultyLevel {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}

