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
            case .skillLevel: return "Experience"
            case .useCase: return "Purpose"
            case .budget: return "Budget"
            case .preferences: return "Features"
            case .results: return "Results"
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
    @State private var detailPrinterId: Int?

    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Apple-style Progress Indicator
            progressBar
                .padding(.horizontal, AppleSpacing.section)
                .padding(.vertical, AppleSpacing.lg)
                .background(.ultraThinMaterial)

            AppleDivider()

            // Content
            ScrollView {
                VStack(spacing: AppleSpacing.xxl) {
                    stepContent
                }
                .padding(AppleSpacing.section)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }

            AppleDivider()

            // Navigation
            navigationBar
                .padding(AppleSpacing.lg)
                .background(.ultraThinMaterial)
        }
        .sheet(item: $detailPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
                .frame(minWidth: 700, minHeight: 550)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 0) {
            ForEach(QuizStep.allCases, id: \.rawValue) { step in
                HStack(spacing: 0) {
                    // Step indicator
                    VStack(spacing: AppleSpacing.xs) {
                        ZStack {
                            Circle()
                                .fill(stepColor(for: step))
                                .frame(width: 28, height: 28)

                            if step.rawValue < currentStep.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(step.rawValue + 1)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(step.rawValue <= currentStep.rawValue ? .white : .secondary)
                            }
                        }

                        Text(step.title)
                            .font(AppleTypography.caption)
                            .foregroundStyle(step.rawValue <= currentStep.rawValue ? .primary : .tertiary)
                    }

                    // Connector line
                    if step != .results {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.appleBlue : Color.primary.opacity(0.1))
                            .frame(height: 2)
                            .padding(.horizontal, AppleSpacing.sm)
                            .padding(.bottom, AppleSpacing.lg)
                    }
                }
            }
        }
    }

    private func stepColor(for step: QuizStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return .appleGreen
        } else if step.rawValue == currentStep.rawValue {
            return .appleBlue
        } else {
            return Color.primary.opacity(0.1)
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
        VStack(spacing: AppleSpacing.xxl) {
            stepHeader(
                title: "What's your experience level?",
                subtitle: "We'll recommend printers that match your skills."
            )

            VStack(spacing: AppleSpacing.md) {
                ForEach(SkillLevel.allCases) { level in
                    AppleSelectionCard(
                        title: level.displayName,
                        description: descriptionFor(level),
                        icon: iconFor(level),
                        isSelected: selectedSkillLevel == level
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSkillLevel = level
                        }
                    }
                }
            }
        }
    }

    private var useCaseStep: some View {
        VStack(spacing: AppleSpacing.xxl) {
            stepHeader(
                title: "What will you create?",
                subtitle: "Different uses benefit from different features."
            )

            VStack(spacing: AppleSpacing.md) {
                ForEach(UseCase.allCases) { useCase in
                    AppleSelectionCard(
                        title: useCase.displayName,
                        description: descriptionFor(useCase),
                        icon: iconFor(useCase),
                        isSelected: selectedUseCase == useCase
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedUseCase = useCase
                        }
                    }
                }
            }
        }
    }

    private var budgetStep: some View {
        VStack(spacing: AppleSpacing.xxl) {
            stepHeader(
                title: "What's your budget?",
                subtitle: "Set a comfortable price range."
            )

            VStack(spacing: AppleSpacing.xl) {
                // Budget display card
                HStack(spacing: AppleSpacing.xxxl) {
                    VStack(spacing: AppleSpacing.xs) {
                        Text("From")
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(Int(budgetMin))")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }

                    Rectangle()
                        .fill(Color.appleSeparator)
                        .frame(width: 1, height: 40)

                    VStack(spacing: AppleSpacing.xs) {
                        Text("To")
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(Int(budgetMax))")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(AppleSpacing.xl)
                .background(Color.primary.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))

                // Sliders
                VStack(spacing: AppleSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                        Text("Minimum")
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $budgetMin, in: 100...5000, step: 50)
                            .tint(Color.appleBlue)
                    }

                    VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                        Text("Maximum")
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $budgetMax, in: 200...6000, step: 50)
                            .tint(Color.appleBlue)
                    }
                }

                // Quick presets
                HStack(spacing: AppleSpacing.sm) {
                    budgetPresetButton("Budget", min: 100, max: 400)
                    budgetPresetButton("Mid-Range", min: 400, max: 1000)
                    budgetPresetButton("Premium", min: 1000, max: 3000)
                    budgetPresetButton("Pro", min: 2000, max: 6000)
                }
            }
        }
    }

    private var preferencesStep: some View {
        VStack(spacing: AppleSpacing.xxl) {
            stepHeader(
                title: "Any specific features?",
                subtitle: "Optional preferences to refine your results."
            )

            VStack(spacing: AppleSpacing.md) {
                ApplePreferenceToggle(
                    title: "Enclosed Chamber",
                    description: "Better for ABS/ASA, safer around children and pets",
                    icon: "cube.box",
                    isOn: $preferEnclosure
                )

                ApplePreferenceToggle(
                    title: "Auto Bed Leveling",
                    description: "Easier setup, especially recommended for beginners",
                    icon: "level",
                    isOn: $preferAutoLeveling
                )
            }
        }
    }

    private var resultsStep: some View {
        VStack(spacing: AppleSpacing.xxl) {
            if isLoading {
                AppleLoadingState(message: "Finding your perfect printers...")
            } else if let error = errorMessage {
                AppleErrorState(message: error) {
                    Task { await fetchRecommendations() }
                }
            } else if recommendations.isEmpty {
                AppleEmptyState(
                    icon: "magnifyingglass",
                    title: "No matches found",
                    subtitle: "Try adjusting your budget or preferences"
                )
            } else {
                stepHeader(
                    title: "Your Top Matches",
                    subtitle: "Based on your preferences"
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 320))], spacing: AppleSpacing.lg) {
                    ForEach(recommendations) { result in
                        AppleRecommendationCard(result: result)
                            .onTapGesture {
                                detailPrinterId = result.printer.id
                            }
                    }
                }
            }
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            if currentStep != .skillLevel {
                AppleSecondaryButton(title: "Back", icon: "chevron.left") {
                    withAnimation(.spring(response: 0.3)) {
                        goToPreviousStep()
                    }
                }
            }

            Spacer()

            if currentStep == .results {
                ApplePrimaryButton(title: "Start Over", icon: "arrow.counterclockwise") {
                    withAnimation(.spring(response: 0.3)) {
                        resetQuiz()
                    }
                }
            } else {
                ApplePrimaryButton(
                    title: currentStep == .preferences ? "See Results" : "Continue",
                    icon: currentStep == .preferences ? "sparkles" : "chevron.right"
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        goToNextStep()
                    }
                }
                .opacity(canProceed ? 1.0 : 0.5)
                .disabled(!canProceed)
            }
        }
    }

    // MARK: - Helper Views

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(spacing: AppleSpacing.sm) {
            Text(title)
                .font(AppleTypography.title1)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(AppleTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func budgetPresetButton(_ label: String, min: Double, max: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                budgetMin = min
                budgetMax = max
            }
        } label: {
            Text(label)
                .font(AppleTypography.caption)
                .fontWeight(.medium)
                .padding(.horizontal, AppleSpacing.md)
                .padding(.vertical, AppleSpacing.sm)
                .background(
                    budgetMin == min && budgetMax == max
                        ? Color.appleBlue
                        : Color.primary.opacity(0.06)
                )
                .foregroundStyle(
                    budgetMin == min && budgetMax == max
                        ? .white
                        : .primary
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
            Task { await fetchRecommendations() }
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
        case .beginner: return "New to 3D printing, want easy setup"
        case .intermediate: return "Some experience, comfortable troubleshooting"
        case .pro: return "Advanced user, want full control"
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
        case .hobby: return "Personal projects, learning, casual prints"
        case .engineering: return "Functional prototypes, mechanical parts"
        case .art: return "Figurines, sculptures, creative work"
        case .production: return "Small batch manufacturing, business"
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

// MARK: - Apple Selection Card

struct AppleSelectionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppleSpacing.lg) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.appleBlue)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.appleBlue : Color.appleBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppleTypography.headline)

                    Text(description)
                        .font(AppleTypography.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.appleBlue)
                }
            }
            .padding(AppleSpacing.lg)
            .background(
                isSelected
                    ? Color.appleBlue.opacity(0.08)
                    : Color.primary.opacity(0.03)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: AppleRadius.lg)
                    .stroke(isSelected ? Color.appleBlue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Apple Preference Toggle

struct ApplePreferenceToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppleSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.appleBlue)
                .frame(width: 44, height: 44)
                .background(Color.appleBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppleTypography.headline)

                Text(description)
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color.appleBlue)
        }
        .padding(AppleSpacing.lg)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))
    }
}

// MARK: - Apple Recommendation Card

struct AppleRecommendationCard: View {
    let result: RecommendationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with match badge
            ZStack(alignment: .topTrailing) {
                AppleAsyncImage(url: result.printer.imageUrl, fallbackIcon: "printer")
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.02))
                    .clipped()

                AppleMatchBadge(score: result.matchScore)
                    .padding(AppleSpacing.sm)
            }

            // Content
            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.printer.name)
                            .font(AppleTypography.headline)
                            .lineLimit(1)

                        Text(result.printer.manufacturer)
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ApplePrice(amount: result.printer.price, size: .medium)
                }

                // Badges
                HStack(spacing: AppleSpacing.sm) {
                    ApplePill(
                        text: result.printer.printerType.uppercased(),
                        color: result.printer.printerType == "fdm" ? .appleBlue : .applePurple
                    )

                    if let motion = result.printer.motionSystem {
                        ApplePill(
                            text: motion == "corexy" ? "CoreXY" : "Bed Slinger",
                            color: motion == "corexy" ? .appleGreen : .appleOrange
                        )
                    }

                    Spacer()

                    HStack(spacing: AppleSpacing.xs) {
                        if result.printer.enclosure {
                            Image(systemName: "cube.box.fill")
                        }
                        if result.printer.autoLeveling {
                            Image(systemName: "level.fill")
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }

                // Reasons
                if !result.reasons.isEmpty {
                    AppleDivider()
                        .padding(.vertical, AppleSpacing.xs)

                    VStack(alignment: .leading, spacing: AppleSpacing.xs) {
                        ForEach(result.reasons.prefix(2), id: \.self) { reason in
                            HStack(spacing: AppleSpacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.appleGreen)
                                Text(reason)
                                    .font(AppleTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(AppleSpacing.md)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.card))
        .appleShadow(AppleShadow.card)
    }
}
