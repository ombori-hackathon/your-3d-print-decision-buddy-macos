import SwiftUI

struct TroubleshootingDetailView: View {
    let issueId: Int
    @State private var issue: PrintIssue?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss
    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Spacer()
                AppleCloseButton { dismiss() }
            }
            .padding(AppleSpacing.lg)

            if isLoading {
                AppleLoadingState(message: "Loading troubleshooting guide...")
            } else if let error = errorMessage {
                AppleErrorState(message: error) {
                    Task { await loadIssue() }
                }
            } else if let issue = issue {
                detailContent(issue)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .task {
            await loadIssue()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ issue: PrintIssue) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleSpacing.xxl) {
                // Hero Section
                heroSection(issue)

                AppleDivider()

                // Symptoms Section
                symptomsSection(issue)

                // Causes Section
                causesSection(issue)

                AppleDivider()

                // Solutions Section
                solutionsSection(issue)

                // Prevention Tips Section
                if !issue.preventionTips.isEmpty {
                    AppleDivider()
                    preventionSection(issue)
                }

                // Related Materials Section
                if !issue.relatedMaterials.isEmpty {
                    AppleDivider()
                    relatedMaterialsSection(issue)
                }
            }
            .padding(AppleSpacing.xxl)
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ issue: PrintIssue) -> some View {
        HStack(alignment: .top, spacing: AppleSpacing.xxl) {
            // Image card
            ZStack {
                cardGradient(for: issue)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppleRadius.xl))

                if let imageUrl = issue.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().scaleEffect(0.6)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: issueIcon(for: issue))
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(.white.opacity(0.9))
                        @unknown default:
                            Image(systemName: issueIcon(for: issue))
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppleRadius.xl))
                } else {
                    Image(systemName: issueIcon(for: issue))
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 120, height: 120)

            // Basic Info
            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                Text(issue.name)
                    .font(AppleTypography.largeTitle)

                // Badges
                HStack(spacing: AppleSpacing.sm) {
                    ApplePill(
                        text: issue.printerType.uppercased(),
                        color: issue.printerType == "fdm" ? .appleBlue : .applePurple
                    )

                    ApplePill(
                        text: issue.difficultyLevel.capitalized,
                        color: difficultyColor(for: issue.difficultyLevel)
                    )

                    if let category = issue.category {
                        ApplePill(text: category.capitalized, color: .appleGray1)
                    }
                }

                Text(issue.description)
                    .font(AppleTypography.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, AppleSpacing.xs)
            }
        }
    }

    // MARK: - Symptoms Section

    private func symptomsSection(_ issue: PrintIssue) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Symptoms", icon: "exclamationmark.triangle.fill", iconColor: .appleOrange)

            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                ForEach(issue.symptoms, id: \.self) { symptom in
                    HStack(alignment: .top, spacing: AppleSpacing.md) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appleOrange)
                        Text(symptom)
                            .font(AppleTypography.callout)
                    }
                }
            }
            .padding(AppleSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appleOrange.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
        }
    }

    // MARK: - Causes Section

    private func causesSection(_ issue: PrintIssue) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Possible Causes", icon: "questionmark.circle.fill", iconColor: .appleRed)

            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                ForEach(issue.causes, id: \.self) { cause in
                    HStack(alignment: .top, spacing: AppleSpacing.md) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appleRed)
                        Text(cause)
                            .font(AppleTypography.callout)
                    }
                }
            }
            .padding(AppleSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appleRed.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
        }
    }

    // MARK: - Solutions Section

    private func solutionsSection(_ issue: PrintIssue) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Step-by-Step Solutions", icon: "wrench.and.screwdriver.fill", iconColor: .appleGreen)

            VStack(spacing: AppleSpacing.md) {
                ForEach(issue.solutions) { step in
                    AppleSolutionStepCard(step: step)
                }
            }
        }
    }

    // MARK: - Prevention Section

    private func preventionSection(_ issue: PrintIssue) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Prevention Tips", icon: "shield.checkered", iconColor: .appleBlue)

            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                ForEach(issue.preventionTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: AppleSpacing.md) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appleBlue)
                        Text(tip)
                            .font(AppleTypography.callout)
                    }
                }
            }
            .padding(AppleSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appleBlue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
        }
    }

    // MARK: - Related Materials Section

    private func relatedMaterialsSection(_ issue: PrintIssue) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Related Materials", icon: "cylinder.fill", iconColor: .applePurple)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(issue.relatedMaterials, id: \.self) { material in
                    AppleTag(text: material, color: .applePurple)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func issueIcon(for issue: PrintIssue) -> String {
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

    private func cardGradient(for issue: PrintIssue) -> LinearGradient {
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

    private func difficultyColor(for level: String) -> Color {
        switch level {
        case "beginner": return .appleGreen
        case "intermediate": return .appleOrange
        case "advanced": return .appleRed
        default: return .appleGray1
        }
    }

    // MARK: - Actions

    private func loadIssue() async {
        isLoading = true
        errorMessage = nil

        do {
            issue = try await apiClient.fetchTroubleshootingIssue(id: issueId)
        } catch {
            errorMessage = "Failed to load troubleshooting guide: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Apple Solution Step Card

struct AppleSolutionStepCard: View {
    let step: SolutionStep

    var body: some View {
        HStack(alignment: .top, spacing: AppleSpacing.lg) {
            // Step number
            Text("\(step.step)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.appleGreen)
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                Text(step.title)
                    .font(AppleTypography.headline)

                Text(step.description)
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)

                if let tip = step.tip {
                    HStack(alignment: .top, spacing: AppleSpacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appleYellow)
                        Text(tip)
                            .font(AppleTypography.callout)
                            .italic()
                    }
                    .padding(AppleSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appleYellow.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppleRadius.sm))
                }
            }
        }
        .padding(AppleSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
    }
}

// MARK: - Legacy Components

struct SolutionStepCard: View {
    let step: SolutionStep

    var body: some View {
        AppleSolutionStepCard(step: step)
    }
}
