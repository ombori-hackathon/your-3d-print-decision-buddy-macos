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
            // Apple-style Filter Sidebar
            filterSidebar
                .frame(minWidth: 220, maxWidth: 260)

            // Main Content
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(AppleSpacing.lg)

                AppleDivider()

                mainContent
            }
            .frame(minWidth: 500)
        }
        .task {
            await loadIssues()
        }
        .sheet(item: $detailIssueId) { issueId in
            TroubleshootingDetailView(issueId: issueId)
                .frame(minWidth: 700, minHeight: 600)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppleSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search issues...", text: $searchText)
                .font(AppleTypography.body)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await loadIssues() }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    Task { await loadIssues() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppleSpacing.md)
        .padding(.vertical, AppleSpacing.sm + 2)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleSpacing.xl) {
                Text("Filters")
                    .font(AppleTypography.title3)
                    .padding(.bottom, AppleSpacing.xs)

                // Printer Type
                AppleSidebarSection("Printer Type") {
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
                        Task { await loadIssues() }
                    }
                    .frame(maxWidth: .infinity)

                    AppleSecondaryButton(title: "Reset", icon: "arrow.counterclockwise") {
                        resetFilters()
                        Task { await loadIssues() }
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
                    Task { await loadIssues() }
                }
            } else if isLoading {
                AppleLoadingState(message: "Loading troubleshooting guides...")
            } else if issues.isEmpty {
                AppleEmptyState(
                    icon: "wrench.and.screwdriver",
                    title: "No issues found",
                    subtitle: "Try adjusting your filters or search"
                )
            } else {
                issueGrid
            }
        }
    }

    // MARK: - Issue Grid

    private var issueGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260, maximum: 320))],
                spacing: AppleSpacing.lg
            ) {
                ForEach(issues) { issue in
                    AppleTroubleshootingCard(issue: issue)
                        .onTapGesture {
                            detailIssueId = issue.id
                        }
                }
            }
            .padding(AppleSpacing.xl)
        }
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

// MARK: - Apple Troubleshooting Card

struct AppleTroubleshootingCard: View {
    let issue: PrintIssueListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with image
            ZStack {
                cardGradient
                    .frame(height: 100)

                if let imageUrl = issue.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.6)
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
                    .frame(height: 100)
                    .clipped()
                } else {
                    fallbackIcon
                }

                // Title overlay
                VStack {
                    Spacer()
                    Text(issue.name)
                        .font(AppleTypography.headline)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, AppleSpacing.sm)
                        .padding(.bottom, AppleSpacing.sm)
                }
            }
            .frame(height: 100)

            // Content
            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                // Description
                Text(issue.description)
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Badges
                HStack(spacing: AppleSpacing.sm) {
                    ApplePill(
                        text: issue.printerType.uppercased(),
                        color: issue.printerType == "fdm" ? .appleBlue : .applePurple
                    )

                    ApplePill(
                        text: issue.difficultyLevel.capitalized,
                        color: difficultyColor
                    )

                    Spacer()

                    if let category = issue.category {
                        Text(category.capitalized)
                            .font(AppleTypography.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Symptoms preview
                if !issue.symptoms.isEmpty {
                    HStack(alignment: .top, spacing: AppleSpacing.xs) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appleOrange)
                        Text(issue.symptomsPreview)
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

    private var fallbackIcon: some View {
        Image(systemName: issueIcon)
            .font(.system(size: 32, weight: .light))
            .foregroundStyle(.white.opacity(0.9))
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
            case "extrusion": colors = [.appleOrange, .appleRed]
            case "adhesion": colors = [.appleBlue, .appleCyan]
            case "quality": colors = [.applePurple, .applePink]
            case "mechanical": colors = [.appleGray1, .appleBlue]
            case "structural": colors = [.appleGreen, .appleTeal]
            default: colors = [.appleBlue, .appleIndigo]
            }
        case "resin":
            colors = [.applePurple, .appleIndigo]
        default:
            colors = [.appleGray1, .appleGray2]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var difficultyColor: Color {
        switch issue.difficultyLevel {
        case "beginner": return .appleGreen
        case "intermediate": return .appleOrange
        case "advanced": return .appleRed
        default: return .appleGray1
        }
    }
}
