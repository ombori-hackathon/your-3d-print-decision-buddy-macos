import SwiftUI

struct TroubleshootingBrowseView: View {
    @State private var issues: [PrintIssueListItem] = []
    @State private var detailIssueId: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Filters
    @State private var selectedType: MaterialType?
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var searchText: String = ""

    private let apiClient = PrinterAPIClient()

    var body: some View {
        HSplitView {
            // Filter Sidebar
            filterSidebar
                .frame(minWidth: 200, maxWidth: 250)

            // Main Content
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search problems...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task {
                                await loadIssues()
                            }
                        }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            Task {
                                await loadIssues()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding()

                Divider()

                if let error = errorMessage {
                    errorView(error)
                } else if isLoading {
                    ProgressView("Loading troubleshooting guides...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if issues.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No issues found")
                            .foregroundStyle(.secondary)
                        Text("Try adjusting your filters or search")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    issueGrid
                }
            }
            .frame(minWidth: 400)
        }
        .task {
            await loadIssues()
        }
        .sheet(item: $detailIssueId) { issueId in
            TroubleshootingDetailView(issueId: issueId)
                .frame(minWidth: 700, minHeight: 600)
        }
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Filters")
                    .font(.headline)

                // Printer Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Printer Type")
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
                        await loadIssues()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Filters") {
                    resetFilters()
                    Task {
                        await loadIssues()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(.bar)
    }

    // MARK: - Issue Grid

    private var issueGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 350))], spacing: 16) {
                ForEach(issues) { issue in
                    TroubleshootingCard(issue: issue)
                        .onTapGesture {
                            detailIssueId = issue.id
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
                    await loadIssues()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadIssues() async {
        isLoading = true
        errorMessage = nil

        var filters = TroubleshootingFilters(
            printerType: selectedType,
            difficultyLevel: selectedDifficulty
        )
        filters.search = searchText

        do {
            issues = try await apiClient.fetchTroubleshooting(filters: filters)
        } catch {
            errorMessage = "Failed to load troubleshooting guides: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func resetFilters() {
        selectedType = nil
        selectedDifficulty = nil
        searchText = ""
    }
}

// MARK: - Troubleshooting Card

struct TroubleshootingCard: View {
    let issue: PrintIssueListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image
            ZStack {
                Rectangle()
                    .fill(cardGradient)

                if let imageUrl = issue.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            fallbackIcon
                        @unknown default:
                            fallbackIcon
                        }
                    }
                    .frame(height: 110)
                    .clipped()
                } else {
                    fallbackIcon
                }

                // Overlay with name
                VStack {
                    Spacer()
                    Text(issue.name)
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }
            }
            .frame(height: 110)
            .frame(maxWidth: .infinity)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Description
                Text(issue.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Badges
                HStack(spacing: 6) {
                    // Type badge
                    Text(issue.printerType.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(issue.printerType == "fdm" ? .blue.opacity(0.2) : .purple.opacity(0.2))
                        .cornerRadius(4)

                    // Difficulty badge
                    Text(issue.difficultyLevel.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundStyle(difficultyColor)
                        .cornerRadius(4)

                    Spacer()

                    // Category
                    if let category = issue.category {
                        Text(category.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Symptoms preview
                if !issue.symptoms.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        Text(issue.symptomsPreview)
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

    private var fallbackIcon: some View {
        VStack(spacing: 8) {
            Image(systemName: issueIcon)
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var issueIcon: String {
        guard let category = issue.category?.lowercased() else {
            return "wrench"
        }
        switch category {
        case "extrusion": return "arrow.down.right.and.arrow.up.left"
        case "adhesion": return "square.on.square.dashed"
        case "quality": return "sparkles"
        case "mechanical": return "gearshape.2"
        case "structural": return "building.columns"
        default: return "wrench"
        }
    }

    private var cardGradient: LinearGradient {
        let colors: [Color]
        switch issue.printerType {
        case "fdm":
            switch issue.category?.lowercased() {
            case "extrusion": colors = [.orange, .red]
            case "adhesion": colors = [.blue, .cyan]
            case "quality": colors = [.purple, .pink]
            case "mechanical": colors = [.gray, .blue]
            case "structural": colors = [.green, .teal]
            default: colors = [.blue, .indigo]
            }
        case "resin":
            colors = [.purple, .indigo]
        default:
            colors = [.gray, .gray.opacity(0.7)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var difficultyColor: Color {
        switch issue.difficultyLevel {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}
