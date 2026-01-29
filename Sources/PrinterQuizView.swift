import SwiftUI

struct PrinterQuizView: View {
    enum QuizStep: Int, CaseIterable {
        case skillLevel = 0
        case useCase = 1
        case budget = 2
        case preferences = 3
        case results = 4

        var title: String {
            switch self {
            case .skillLevel: return "Experience Level"
            case .useCase: return "Primary Use"
            case .budget: return "Budget"
            case .preferences: return "Preferences"
            case .results: return "Your Matches"
            }
        }
    }

    @State private var currentStep: QuizStep = .skillLevel
    @State private var selectedSkillLevel: SkillLevel?
    @State private var selectedUseCase: UseCase?
    @State private var budgetMin: Double = 100
    @State private var budgetMax: Double = 1000
    @State private var preferEnclosure: Bool = false
    @State private var preferAutoLeveling: Bool = true
    @State private var recommendations: [RecommendationResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressIndicator
                .padding()
                .background(.bar)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    stepContent
                }
                .padding(32)
            }

            Divider()

            // Navigation
            navigationButtons
                .padding()
                .background(.bar)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(QuizStep.allCases, id: \.rawValue) { step in
                HStack(spacing: 4) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? .blue : .secondary.opacity(0.3))
                        .frame(width: 10, height: 10)

                    if step != .results {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? .blue : .secondary.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .skillLevel:
            skillLevelStep
        case .useCase:
            useCaseStep
        case .budget:
            budgetStep
        case .preferences:
            preferencesStep
        case .results:
            resultsStep
        }
    }

    private var skillLevelStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "What's your 3D printing experience?",
                subtitle: "This helps us recommend printers that match your skill level."
            )

            VStack(spacing: 12) {
                ForEach(SkillLevel.allCases) { level in
                    SelectionCard(
                        title: level.displayName,
                        description: descriptionFor(level),
                        icon: iconFor(level),
                        isSelected: selectedSkillLevel == level
                    ) {
                        selectedSkillLevel = level
                    }
                }
            }
        }
    }

    private var useCaseStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "What will you mainly use the printer for?",
                subtitle: "Different use cases benefit from different printer features."
            )

            VStack(spacing: 12) {
                ForEach(UseCase.allCases) { useCase in
                    SelectionCard(
                        title: useCase.displayName,
                        description: descriptionFor(useCase),
                        icon: iconFor(useCase),
                        isSelected: selectedUseCase == useCase
                    ) {
                        selectedUseCase = useCase
                    }
                }
            }
        }
    }

    private var budgetStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "What's your budget?",
                subtitle: "Set your comfortable price range."
            )

            VStack(spacing: 20) {
                // Budget display
                HStack {
                    VStack {
                        Text("Minimum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(Int(budgetMin))")
                            .font(.title2.bold())
                    }
                    Spacer()
                    VStack {
                        Text("Maximum")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(Int(budgetMax))")
                            .font(.title2.bold())
                    }
                }
                .padding()
                .background(.secondary.opacity(0.1))
                .cornerRadius(12)

                // Sliders
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Minimum: $\(Int(budgetMin))")
                            .font(.caption)
                        Slider(value: $budgetMin, in: 100...5000, step: 50)
                    }

                    VStack(alignment: .leading) {
                        Text("Maximum: $\(Int(budgetMax))")
                            .font(.caption)
                        Slider(value: $budgetMax, in: 200...6000, step: 50)
                    }
                }

                // Quick presets
                HStack(spacing: 12) {
                    budgetPresetButton("Budget", min: 100, max: 400)
                    budgetPresetButton("Mid-Range", min: 400, max: 1000)
                    budgetPresetButton("Premium", min: 1000, max: 3000)
                    budgetPresetButton("Professional", min: 2000, max: 6000)
                }
            }
        }
    }

    private var preferencesStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Any specific preferences?",
                subtitle: "These features can affect your printing experience."
            )

            VStack(spacing: 16) {
                PreferenceToggle(
                    title: "Enclosed Build Chamber",
                    description: "Better temperature control for ABS/ASA, safer around children/pets",
                    icon: "cube.box",
                    isOn: $preferEnclosure
                )

                PreferenceToggle(
                    title: "Automatic Bed Leveling",
                    description: "Makes setup easier, especially recommended for beginners",
                    icon: "level",
                    isOn: $preferAutoLeveling
                )
            }
        }
    }

    private var resultsStep: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView("Finding your perfect printers...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                    Button("Retry") {
                        Task {
                            await fetchRecommendations()
                        }
                    }
                }
            } else if recommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No printers found matching your criteria")
                    Text("Try adjusting your budget or preferences")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                stepHeader(
                    title: "Here are your top matches!",
                    subtitle: "Based on your preferences, these printers are the best fit."
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 350))], spacing: 16) {
                    ForEach(recommendations) { result in
                        RecommendationCard(result: result)
                    }
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if currentStep != .skillLevel {
                Button("Back") {
                    withAnimation {
                        goToPreviousStep()
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if currentStep == .results {
                Button("Start Over") {
                    withAnimation {
                        resetQuiz()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(currentStep == .preferences ? "See Results" : "Continue") {
                    withAnimation {
                        goToNextStep()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
        }
    }

    // MARK: - Helper Views

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }

    private func budgetPresetButton(_ label: String, min: Double, max: Double) -> some View {
        Button(label) {
            budgetMin = min
            budgetMax = max
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    // MARK: - Helper Functions

    private var canProceed: Bool {
        switch currentStep {
        case .skillLevel: return selectedSkillLevel != nil
        case .useCase: return selectedUseCase != nil
        case .budget: return budgetMin < budgetMax
        case .preferences: return true
        case .results: return true
        }
    }

    private func goToNextStep() {
        guard let nextStep = QuizStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep

        if currentStep == .results {
            Task {
                await fetchRecommendations()
            }
        }
    }

    private func goToPreviousStep() {
        guard let prevStep = QuizStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevStep
    }

    private func resetQuiz() {
        currentStep = .skillLevel
        selectedSkillLevel = nil
        selectedUseCase = nil
        budgetMin = 100
        budgetMax = 1000
        preferEnclosure = false
        preferAutoLeveling = true
        recommendations = []
        errorMessage = nil
    }

    private func fetchRecommendations() async {
        guard let skillLevel = selectedSkillLevel,
              let useCase = selectedUseCase else { return }

        isLoading = true
        errorMessage = nil

        let answers = QuizAnswers(
            skillLevel: skillLevel.rawValue,
            useCase: useCase.rawValue,
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            preferEnclosure: preferEnclosure,
            preferAutoLeveling: preferAutoLeveling
        )

        do {
            recommendations = try await apiClient.getRecommendations(answers: answers)
        } catch {
            errorMessage = "Failed to get recommendations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func descriptionFor(_ level: SkillLevel) -> String {
        switch level {
        case .beginner: return "New to 3D printing, looking for easy setup and reliability"
        case .intermediate: return "Some experience, comfortable with basic troubleshooting"
        case .pro: return "Advanced user, wants full control and customization"
        }
    }

    private func iconFor(_ level: SkillLevel) -> String {
        switch level {
        case .beginner: return "star"
        case .intermediate: return "star.leadinghalf.filled"
        case .pro: return "star.fill"
        }
    }

    private func descriptionFor(_ useCase: UseCase) -> String {
        switch useCase {
        case .hobby: return "Personal projects, learning, casual printing"
        case .engineering: return "Functional prototypes, mechanical parts, precision"
        case .art: return "Figurines, sculptures, creative projects"
        case .production: return "Small batch manufacturing, business use"
        }
    }

    private func iconFor(_ useCase: UseCase) -> String {
        switch useCase {
        case .hobby: return "house"
        case .engineering: return "gearshape.2"
        case .art: return "paintpalette"
        case .production: return "shippingbox"
        }
    }
}

// MARK: - Selection Card

struct SelectionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? .blue : .blue.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.1) : .secondary.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preference Toggle

struct PreferenceToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let result: RecommendationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with match score badge
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: result.printer.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Rectangle()
                            .fill(.secondary.opacity(0.1))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .background(.secondary.opacity(0.05))
                .clipped()

                // Match Score Badge
                VStack(spacing: 0) {
                    Text("\(result.matchScore)%")
                        .font(.headline.bold())
                    Text("Match")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(scoreColor)
                .cornerRadius(8)
                .padding(8)
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Name and Price
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.printer.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(result.printer.manufacturer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("$\(result.printer.price, specifier: "%.0f")")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }

                // Badges
                HStack(spacing: 6) {
                    // Type badge
                    Text(result.printer.printerType.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(result.printer.printerType == "fdm" ? .blue.opacity(0.2) : .purple.opacity(0.2))
                        .cornerRadius(4)

                    // Motion badge (FDM only)
                    if let motion = result.printer.motionSystem {
                        Text(motion == "corexy" ? "CoreXY" : "Bed Slinger")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(motion == "corexy" ? .green.opacity(0.2) : .orange.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Feature icons
                    HStack(spacing: 4) {
                        if result.printer.enclosure {
                            Image(systemName: "cube.box.fill")
                                .help("Enclosed")
                        }
                        if result.printer.autoLeveling {
                            Image(systemName: "level.fill")
                                .help("Auto Leveling")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                // Build Volume
                HStack {
                    Image(systemName: "cube")
                        .foregroundStyle(.secondary)
                    Text(result.printer.buildVolumeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Reasons
                if !result.reasons.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.reasons, id: \.self) { reason in
                            Label(reason, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var scoreColor: Color {
        if result.matchScore >= 80 {
            return .green
        } else if result.matchScore >= 60 {
            return .orange
        } else {
            return .secondary
        }
    }
}
