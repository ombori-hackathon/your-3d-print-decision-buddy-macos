import SwiftUI

struct PrinterDetailView: View {
    let printerId: Int
    @State private var printer: Printer?
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
                AppleLoadingState(message: "Loading printer details...")
            } else if let error = errorMessage {
                AppleErrorState(message: error) {
                    Task { await loadPrinter() }
                }
            } else if let printer = printer {
                detailContent(printer)
            }
        }
        .frame(minWidth: 700, minHeight: 550)
        .task {
            await loadPrinter()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ printer: Printer) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleSpacing.xxl) {
                // Hero Section
                heroSection(printer)

                AppleDivider()

                // Specifications
                specsSection(printer)

                AppleDivider()

                // Materials
                materialsSection(printer)

                AppleDivider()

                // Connectivity
                connectivitySection(printer)

                AppleDivider()

                // Skill Levels & Use Cases
                HStack(alignment: .top, spacing: AppleSpacing.section) {
                    skillLevelsSection(printer)
                    useCasesSection(printer)
                }

                // Action Button
                if let url = printer.productUrl, let productURL = URL(string: url) {
                    AppleDivider()

                    Link(destination: productURL) {
                        HStack(spacing: AppleSpacing.sm) {
                            Image(systemName: "safari")
                                .font(.system(size: 14, weight: .semibold))
                            Text("View Product Page")
                                .font(AppleTypography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppleSpacing.md)
                        .background(Color.appleBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.button))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppleSpacing.xxl)
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ printer: Printer) -> some View {
        HStack(alignment: .top, spacing: AppleSpacing.xxl) {
            // Image
            AppleAsyncImage(url: printer.imageUrl, fallbackIcon: "printer")
                .frame(width: 240, height: 180)
                .background(Color.primary.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: AppleRadius.lg))

            // Basic Info
            VStack(alignment: .leading, spacing: AppleSpacing.md) {
                VStack(alignment: .leading, spacing: AppleSpacing.xs) {
                    Text(printer.name)
                        .font(AppleTypography.largeTitle)

                    Text(printer.manufacturer)
                        .font(AppleTypography.title2)
                        .foregroundStyle(.secondary)
                }

                ApplePrice(amount: printer.price, size: .large)

                // Badges
                AppleFlowLayout(spacing: AppleSpacing.sm) {
                    ApplePill(
                        text: printer.printerType.uppercased(),
                        color: printer.printerType == "fdm" ? .appleBlue : .applePurple
                    )

                    if let motion = printer.motionSystem {
                        ApplePill(
                            text: motion == "corexy" ? "CoreXY" : "Bed Slinger",
                            color: motion == "corexy" ? .appleGreen : .appleOrange
                        )
                    }

                    if printer.enclosure {
                        ApplePill(text: "Enclosed", color: .appleTeal)
                    }

                    if printer.autoLeveling {
                        ApplePill(text: "Auto Leveling", color: .appleIndigo)
                    }
                }

                if let description = printer.description {
                    Text(description)
                        .font(AppleTypography.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppleSpacing.xs)
                }
            }
        }
    }

    // MARK: - Specifications Section

    private func specsSection(_ printer: Printer) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Specifications", icon: "slider.horizontal.3", iconColor: .appleBlue)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppleSpacing.md) {
                AppleInfoCard(title: "Build Volume", value: printer.buildVolumeDescription, icon: "cube", tint: .appleBlue)

                if let maxSpeed = printer.maxSpeed {
                    AppleInfoCard(title: "Max Speed", value: "\(maxSpeed) mm/s", icon: "speedometer", tint: .appleGreen)
                }

                if let resolution = printer.layerResolution {
                    AppleInfoCard(title: "Min Layer", value: String(format: "%.3f mm", resolution), icon: "square.stack.3d.up", tint: .applePurple)
                }

                if let noiseLevel = printer.noiseLevel {
                    AppleInfoCard(title: "Noise Level", value: noiseLevel.capitalized, icon: "speaker.wave.2", tint: .appleOrange)
                }

                AppleInfoCard(title: "Enclosure", value: printer.enclosure ? "Yes" : "No", icon: "cube.box", tint: .appleTeal)

                AppleInfoCard(title: "Auto Leveling", value: printer.autoLeveling ? "Yes" : "No", icon: "level", tint: .appleIndigo)
            }
        }
    }

    // MARK: - Materials Section

    private func materialsSection(_ printer: Printer) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Supported Materials", icon: "cylinder.split.1x2", iconColor: .appleBlue)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(printer.materials, id: \.self) { material in
                    AppleTag(text: material, color: .appleBlue)
                }
            }
        }
    }

    // MARK: - Connectivity Section

    private func connectivitySection(_ printer: Printer) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.lg) {
            AppleSectionHeader(title: "Connectivity", icon: "antenna.radiowaves.left.and.right", iconColor: .appleGreen)

            AppleFlowLayout(spacing: AppleSpacing.sm) {
                ForEach(printer.connectivity, id: \.self) { conn in
                    AppleTag(text: conn, icon: iconFor(connectivity: conn), color: .appleGreen)
                }
            }
        }
    }

    // MARK: - Skill Levels Section

    private func skillLevelsSection(_ printer: Printer) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.md) {
            AppleSectionHeader(title: "Skill Levels", icon: "star.fill", iconColor: .appleYellow)

            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                ForEach(printer.skillLevels, id: \.self) { level in
                    HStack(spacing: AppleSpacing.sm) {
                        Image(systemName: iconFor(skillLevel: level))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(level.capitalized)
                            .font(AppleTypography.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Use Cases Section

    private func useCasesSection(_ printer: Printer) -> some View {
        VStack(alignment: .leading, spacing: AppleSpacing.md) {
            AppleSectionHeader(title: "Use Cases", icon: "briefcase.fill", iconColor: .applePurple)

            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                ForEach(printer.useCases, id: \.self) { useCase in
                    HStack(spacing: AppleSpacing.sm) {
                        Image(systemName: iconFor(useCase: useCase))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(useCase.capitalized)
                            .font(AppleTypography.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Methods

    private func iconFor(connectivity: String) -> String {
        switch connectivity.lowercased() {
        case "wifi": return "wifi"
        case "usb": return "cable.connector"
        case "ethernet": return "network"
        case "sd card": return "sdcard"
        default: return "antenna.radiowaves.left.and.right"
        }
    }

    private func iconFor(skillLevel: String) -> String {
        switch skillLevel.lowercased() {
        case "beginner": return "star"
        case "intermediate": return "star.leadinghalf.filled"
        case "pro": return "star.fill"
        default: return "person"
        }
    }

    private func iconFor(useCase: String) -> String {
        switch useCase.lowercased() {
        case "hobby": return "house"
        case "engineering": return "gearshape.2"
        case "art": return "paintpalette"
        case "production": return "shippingbox"
        default: return "checkmark.circle"
        }
    }

    // MARK: - Actions

    private func loadPrinter() async {
        isLoading = true
        errorMessage = nil

        do {
            printer = try await apiClient.fetchPrinter(id: printerId)
        } catch {
            errorMessage = "Failed to load printer: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Legacy Components (keeping for backward compatibility)

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        ApplePill(text: text, color: color)
    }
}

struct SpecCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        AppleInfoCard(title: title, value: value, icon: icon, tint: .appleBlue)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = AppleSpacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
