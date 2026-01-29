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
                AppleCloseButton { dismiss() }
            }
            .padding(AppleSpacing.lg)

            if isLoading {
                AppleLoadingState(message: "Loading material details...")
            } else if let error = errorMessage {
                AppleErrorState(message: error) {
                    Task { await loadMaterial() }
                }
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
                .frame(minWidth: 700, minHeight: 550)
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ material: Material) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleSpacing.xxl) {
                // Hero Section
                heroSection(material)

                AppleDivider()

                // Specifications
                specsSection(material)

                AppleDivider()

                // Pros and Cons
                prosConsSection(material)

                AppleDivider()

                // Best Uses
                bestUsesSection(material)

                // Example Projects
                if !material.exampleProjects.isEmpty {
                    exampleProjectsSection(material)
                }

                // Printing Tips
                if !material.printingTips.isEmpty {
                    AppleDivider()
                    printingTipsSection(material)
                }

                // Post Processing
                if !material.postProcessing.isEmpty {
                    postProcessingSection(material)
                }

                // Properties
                if !material.properties.isEmpty {
                    AppleDivider()
                    propertiesSection(material)
                }

                // Compatible Printers
                if !material.compatiblePrinters.isEmpty {
                    AppleDivider()
                    compatiblePrintersSection(material)
                }
            }
            .padding(AppleSpacing.xxl)
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ material: Material) -> some View {
        HStack(alignment: .top, spacing: AppleSpacing.xxl) {
            // Gradient card with icon
            ZStack {
                materialGradient(for: material)
                    .frame(width: 180, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: AppleRadius.xl))

                VStack(spacing: AppleSpacing.sm) {
                    Image(systemName: material.materialType == "fdm" ? "cylinder" : "drop.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(material.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            // Basic Info
            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                VStack(alignment: .leading, spacing: AppleSpacing.xs) {
                    Text(material.fullName)
                        .font(AppleTypography.largeTitle)

                    if let category = material.category {
                        Text(category.capitalized)
                            .font(AppleTypography.title2)
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
                        color: difficultyColor(for: material.difficultyLevel)
                    )
                }

                if let description = material.description {
                    Text(description)
                        .font(AppleTypography.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppleSpacing.xs)
                }
            }
        }
    }

    // MARK: - Specs Section

    private func specsSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Specifications", icon: "thermometer.medium", iconColor: .appleOrange)

            if material.materialType == "fdm" {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppleSpacing.md) {
                    if let tempRange = material.printTemperatureRange {
                        AppleInfoCard(title: "Print Temp", value: tempRange, icon: "thermometer.high", tint: .appleRed)
                    }
                    if let bedRange = material.bedTemperatureRange {
                        AppleInfoCard(title: "Bed Temp", value: bedRange, icon: "thermometer.low", tint: .appleOrange)
                    }
                    if let minTemp = material.printTempMin {
                        AppleInfoCard(title: "Min Print", value: "\(minTemp)\u{00B0}C", icon: "thermometer.snowflake", tint: .appleCyan)
                    }
                    if let maxTemp = material.printTempMax {
                        AppleInfoCard(title: "Max Print", value: "\(maxTemp)\u{00B0}C", icon: "thermometer.sun.fill", tint: .appleRed)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppleSpacing.md) {
                    if let exposure = material.exposureTimeS {
                        AppleInfoCard(title: "Exposure Time", value: String(format: "%.1f s", exposure), icon: "timer", tint: .applePurple)
                    }
                    if let wavelength = material.uvWavelengthNm {
                        AppleInfoCard(title: "UV Wavelength", value: "\(wavelength) nm", icon: "sun.max.fill", tint: .appleYellow)
                    }
                }
            }
        }
    }

    // MARK: - Pros & Cons Section

    private func prosConsSection(_ material: Material) -> some View {
        HStack(alignment: .top, spacing: AppleSpacing.xxl) {
            // Pros
            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                AppleSectionHeader(title: "Pros", icon: "checkmark.circle.fill", iconColor: .appleGreen)

                VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                    ForEach(material.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: AppleSpacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appleGreen)
                            Text(pro)
                                .font(AppleTypography.callout)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Cons
            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                AppleSectionHeader(title: "Cons", icon: "xmark.circle.fill", iconColor: .appleRed)

                VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                    ForEach(material.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: AppleSpacing.sm) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.appleRed)
                            Text(con)
                                .font(AppleTypography.callout)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Best Uses Section

    private func bestUsesSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Best Uses", icon: "star.fill", iconColor: .appleYellow)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(material.bestUses, id: \.self) { use in
                    AppleTag(text: use, color: .appleBlue)
                }
            }
        }
    }

    // MARK: - Example Projects Section

    private func exampleProjectsSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Example Projects", icon: "lightbulb.fill", iconColor: .appleOrange)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(material.exampleProjects, id: \.self) { project in
                    AppleTag(text: project, color: .appleOrange)
                }
            }
        }
    }

    // MARK: - Printing Tips Section

    private func printingTipsSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Printing Tips", icon: "lightbulb.max.fill", iconColor: .appleYellow)

            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                ForEach(material.printingTips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: AppleSpacing.md) {
                        Text("\(index + 1)")
                            .font(AppleTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.appleYellow)
                            .clipShape(Circle())

                        Text(material.printingTips[index])
                            .font(AppleTypography.callout)
                    }
                }
            }
        }
    }

    // MARK: - Post Processing Section

    private func postProcessingSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Post Processing", icon: "wand.and.stars", iconColor: .applePurple)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(material.postProcessing, id: \.self) { step in
                    AppleTag(text: step, color: .applePurple)
                }
            }
        }
    }

    // MARK: - Properties Section

    private func propertiesSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Material Properties", icon: "chart.bar.fill", iconColor: .appleCyan)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppleSpacing.md) {
                ForEach(Array(material.properties.keys.sorted()), id: \.self) { key in
                    if let value = material.properties[key] {
                        ApplePropertyCard(name: key, value: value)
                    }
                }
            }
        }
    }

    // MARK: - Compatible Printers Section

    private func compatiblePrintersSection(_ material: Material) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            HStack {
                AppleSectionHeader(title: "Compatible Printers", icon: "printer.fill", iconColor: .appleBlue)
                Text("(\(material.compatiblePrinters.count))")
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180))], spacing: AppleSpacing.md) {
                ForEach(material.compatiblePrinters) { printer in
                    AppleCompatiblePrinterCard(printer: printer)
                        .onTapGesture {
                            selectedPrinterId = printer.id
                        }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func materialGradient(for material: Material) -> LinearGradient {
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

    private func difficultyColor(for level: String) -> Color {
        switch level {
        case "beginner": return .appleGreen
        case "intermediate": return .appleOrange
        case "advanced": return .appleRed
        default: return .appleGray1
        }
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

// MARK: - Apple Property Card

struct ApplePropertyCard: View {
    let name: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppleSpacing.xs) {
            Text(name.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(AppleTypography.caption)
                .foregroundStyle(.secondary)

            Text(value.capitalized)
                .font(AppleTypography.headline)
                .foregroundStyle(colorFor(value: value))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppleSpacing.md)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))
    }

    private func colorFor(value: String) -> Color {
        switch value.lowercased() {
        case "very high", "excellent": return .appleGreen
        case "high", "very good", "good": return .appleBlue
        case "medium": return .appleOrange
        case "low": return .appleRed
        case "very low", "none": return .appleGray1
        default: return .primary
        }
    }
}

// MARK: - Apple Compatible Printer Card

struct AppleCompatiblePrinterCard: View {
    let printer: CompatiblePrinter

    var body: some View {
        VStack(spacing: AppleSpacing.sm) {
            AppleAsyncImage(url: printer.imageUrl, fallbackIcon: "printer")
                .frame(height: 70)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: AppleRadius.sm))

            VStack(spacing: 2) {
                Text(printer.name)
                    .font(AppleTypography.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(printer.manufacturer)
                    .font(AppleTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(AppleSpacing.sm)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))
        .appleShadow(AppleShadow.subtle)
        .contentShape(Rectangle())
    }
}

// MARK: - Legacy Components

struct PropertyCard: View {
    let name: String
    let value: String

    var body: some View {
        ApplePropertyCard(name: name, value: value)
    }
}

struct CompatiblePrinterCard: View {
    let printer: CompatiblePrinter

    var body: some View {
        AppleCompatiblePrinterCard(printer: printer)
    }
}
