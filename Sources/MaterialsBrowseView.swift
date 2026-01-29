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
            // Apple-style Filter Sidebar
            filterSidebar
                .frame(minWidth: 220, maxWidth: 260)

            // Main Content
            mainContent
                .frame(minWidth: 500)
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
            VStack(alignment: .leading, spacing: AppleSpacing.xl) {
                Text("Filters")
                    .font(AppleTypography.title3)
                    .padding(.bottom, AppleSpacing.xs)

                // Material Type
                AppleSidebarSection("Material Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(nil as MaterialType?)
                        ForEach(MaterialType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type as MaterialType?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                AppleDivider()

                // Difficulty Level
                AppleSidebarSection("Difficulty") {
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        Text("All Levels").tag(nil as DifficultyLevel?)
                        ForEach(DifficultyLevel.allCases) { level in
                            Text(level.displayName).tag(level as DifficultyLevel?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Spacer(minLength: AppleSpacing.xl)

                // Action Buttons
                VStack(spacing: AppleSpacing.sm) {
                    ApplePrimaryButton(title: "Apply Filters", icon: "line.3.horizontal.decrease") {
                        Task { await loadMaterials() }
                    }
                    .frame(maxWidth: .infinity)

                    AppleSecondaryButton(title: "Reset", icon: "arrow.counterclockwise") {
                        resetFilters()
                        Task { await loadMaterials() }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(AppleSpacing.lg)
        }
        .appleSidebar()
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Group {
            if let error = errorMessage {
                AppleErrorState(message: error) {
                    Task { await loadMaterials() }
                }
            } else if isLoading {
                AppleLoadingState(message: "Loading materials...")
            } else if materials.isEmpty {
                AppleEmptyState(
                    icon: "cylinder",
                    title: "No materials found",
                    subtitle: "Try adjusting your filters"
                )
            } else {
                materialGrid
            }
        }
    }

    // MARK: - Material Grid

    private var materialGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260, maximum: 320))],
                spacing: AppleSpacing.lg
            ) {
                ForEach(materials) { material in
                    AppleMaterialCard(material: material)
                        .onTapGesture {
                            detailMaterialId = material.id
                        }
                }
            }
            .padding(AppleSpacing.xl)
        }
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

// MARK: - Apple Material Card

struct AppleMaterialCard: View {
    let material: MaterialListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header with icon
            ZStack {
                materialGradient
                    .frame(height: 100)

                VStack(spacing: AppleSpacing.sm) {
                    Image(systemName: material.materialType == "fdm" ? "cylinder" : "drop.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(material.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(material.fullName)
                        .font(AppleTypography.headline)
                        .lineLimit(2)

                    if let category = material.category {
                        Text(category.capitalized)
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Badges
                HStack(spacing: AppleSpacing.sm) {
                    ApplePill(
                        text: material.materialType.uppercased(),
                        color: material.materialType == "fdm" ? .appleBlue : .applePurple
                    )

                    ApplePill(
                        text: material.difficultyLevel.capitalized,
                        color: difficultyColor
                    )

                    Spacer()

                    // Temperature
                    if let tempRange = material.temperatureRange {
                        HStack(spacing: 2) {
                            Image(systemName: "thermometer.medium")
                            Text(tempRange)
                        }
                        .font(AppleTypography.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                // Best uses preview
                if !material.bestUses.isEmpty {
                    Text(material.bestUses.prefix(3).joined(separator: " \u{2022} "))
                        .font(AppleTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Pros preview
                if !material.pros.isEmpty {
                    HStack(alignment: .top, spacing: AppleSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appleGreen)
                        Text(material.pros.first ?? "")
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(AppleSpacing.md)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.card))
        .appleShadow(AppleShadow.card)
        .contentShape(Rectangle())
    }

    private var materialGradient: LinearGradient {
        let colors: [Color]
        switch material.materialType {
        case "fdm":
            switch material.name.lowercased() {
            case "pla": colors = [.appleGreen, .appleMint]
            case "petg": colors = [.appleBlue, .appleCyan]
            case "abs": colors = [.appleOrange, .appleRed]
            case "tpu": colors = [.applePurple, .applePink]
            case "asa": colors = [.appleYellow, .appleOrange]
            case "nylon": colors = [.appleGray1, .appleBlue]
            case "pc": colors = [.appleIndigo, .applePurple]
            default: colors = [.appleGray1, .appleGray2]
            }
        case "resin":
            switch material.name.lowercased() {
            case "standard resin": colors = [.appleCyan, .appleBlue]
            case "abs-like resin": colors = [.appleOrange, .appleYellow]
            case "flexible resin": colors = [.applePink, .applePurple]
            case "castable resin": colors = [.appleYellow, .appleOrange]
            case "dental resin": colors = [.appleMint, .appleTeal]
            default: colors = [.applePurple, .appleIndigo]
            }
        default:
            colors = [.appleGray1, .appleGray2]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var difficultyColor: Color {
        switch material.difficultyLevel {
        case "beginner": return .appleGreen
        case "intermediate": return .appleOrange
        case "advanced": return .appleRed
        default: return .appleGray1
        }
    }
}
