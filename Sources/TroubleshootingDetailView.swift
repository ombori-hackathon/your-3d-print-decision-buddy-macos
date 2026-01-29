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
                ProgressView("Loading troubleshooting guide...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                errorView(error)
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
            VStack(alignment: .leading, spacing: 24) {
                // Hero Section
                HStack(alignment: .top, spacing: 24) {
                    // Image card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardGradient(for: issue))
                            .frame(width: 140, height: 140)

                        if let imageUrl = issue.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: issueIcon(for: issue))
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.9))
                                @unknown default:
                                    Image(systemName: issueIcon(for: issue))
                                        .font(.system(size: 48))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            Image(systemName: issueIcon(for: issue))
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 140, height: 140)

                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(issue.name)
                            .font(.largeTitle.bold())

                        // Badges
                        HStack(spacing: 8) {
                            Badge(
                                text: issue.printerType.uppercased(),
                                color: issue.printerType == "fdm" ? .blue : .purple
                            )

                            Badge(
                                text: issue.difficultyLevel.capitalized,
                                color: difficultyColor(for: issue.difficultyLevel)
                            )

                            if let category = issue.category {
                                Badge(
                                    text: category.capitalized,
                                    color: .gray
                                )
                            }
                        }

                        Text(issue.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }

                Divider()

                // Symptoms Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Symptoms")
                            .font(.title2.bold())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(issue.symptoms, id: \.self) { symptom in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                                    .font(.callout)
                                Text(symptom)
                                    .font(.callout)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.05))
                    .cornerRadius(12)
                }

                // Causes Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Possible Causes")
                            .font(.title2.bold())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(issue.causes, id: \.self) { cause in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.red)
                                    .font(.callout)
                                Text(cause)
                                    .font(.callout)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.red.opacity(0.05))
                    .cornerRadius(12)
                }

                Divider()

                // Solutions Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(.green)
                        Text("Step-by-Step Solutions")
                            .font(.title2.bold())
                    }

                    ForEach(issue.solutions) { step in
                        SolutionStepCard(step: step)
                    }
                }

                // Prevention Tips Section
                if !issue.preventionTips.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.checkered")
                                .foregroundStyle(.blue)
                            Text("Prevention Tips")
                                .font(.title2.bold())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(issue.preventionTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.blue)
                                        .font(.callout)
                                    Text(tip)
                                        .font(.callout)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.blue.opacity(0.05))
                        .cornerRadius(12)
                    }
                }

                // Related Materials Section
                if !issue.relatedMaterials.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cylinder.fill")
                                .foregroundStyle(.purple)
                            Text("Related Materials")
                                .font(.title2.bold())
                        }

                        FlowLayout(spacing: 8) {
                            ForEach(issue.relatedMaterials, id: \.self) { material in
                                Text(material)
                                    .font(.callout)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.purple.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(24)
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
                    await loadIssue()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Solution Step Card

struct SolutionStepCard: View {
    let step: SolutionStep

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 36, height: 36)
                Text("\(step.step)")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.headline)

                Text(step.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if let tip = step.tip {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(tip)
                            .font(.callout)
                            .italic()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}
