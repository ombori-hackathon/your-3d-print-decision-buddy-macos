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
                ProgressView("Loading printer details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                errorView(error)
            } else if let printer = printer {
                detailContent(printer)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .task {
            await loadPrinter()
        }
    }

    // MARK: - Detail Content

    private func detailContent(_ printer: Printer) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Section: Image + Basic Info
                HStack(alignment: .top, spacing: 24) {
                    // Image
                    AsyncImage(url: URL(string: printer.imageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.secondary.opacity(0.1))
                                .overlay { ProgressView() }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Rectangle()
                                .fill(.secondary.opacity(0.1))
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 250, height: 200)
                    .background(.secondary.opacity(0.05))
                    .cornerRadius(12)

                    // Basic Info
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(printer.name)
                                .font(.title.bold())
                            Text(printer.manufacturer)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }

                        Text("$\(printer.price, specifier: "%.0f")")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.green)

                        // Badges
                        HStack(spacing: 8) {
                            Badge(text: printer.printerType.uppercased(), color: printer.printerType == "fdm" ? .blue : .purple)

                            if let motion = printer.motionSystem {
                                Badge(text: motion == "corexy" ? "CoreXY" : "Bed Slinger", color: motion == "corexy" ? .green : .orange)
                            }

                            if printer.enclosure {
                                Badge(text: "Enclosed", color: .teal)
                            }

                            if printer.autoLeveling {
                                Badge(text: "Auto Leveling", color: .indigo)
                            }
                        }

                        if let description = printer.description {
                            Text(description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }

                Divider()

                // Specifications
                Text("Specifications")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    SpecCard(title: "Build Volume", value: printer.buildVolumeDescription, icon: "cube")

                    if let maxSpeed = printer.maxSpeed {
                        SpecCard(title: "Max Speed", value: "\(maxSpeed) mm/s", icon: "speedometer")
                    }

                    if let resolution = printer.layerResolution {
                        SpecCard(title: "Min Layer", value: String(format: "%.3f mm", resolution), icon: "square.stack.3d.up")
                    }

                    if let noiseLevel = printer.noiseLevel {
                        SpecCard(title: "Noise Level", value: noiseLevel.capitalized, icon: "speaker.wave.2")
                    }

                    SpecCard(title: "Enclosure", value: printer.enclosure ? "Yes" : "No", icon: "cube.box")
                    SpecCard(title: "Auto Leveling", value: printer.autoLeveling ? "Yes" : "No", icon: "level")
                }

                Divider()

                // Materials
                VStack(alignment: .leading, spacing: 12) {
                    Text("Supported Materials")
                        .font(.title3.bold())

                    FlowLayout(spacing: 8) {
                        ForEach(printer.materials, id: \.self) { material in
                            Text(material)
                                .font(.callout)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }

                Divider()

                // Connectivity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connectivity")
                        .font(.title3.bold())

                    FlowLayout(spacing: 8) {
                        ForEach(printer.connectivity, id: \.self) { conn in
                            HStack(spacing: 6) {
                                Image(systemName: iconFor(connectivity: conn))
                                Text(conn)
                            }
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }

                Divider()

                // Skill Levels & Use Cases
                HStack(alignment: .top, spacing: 48) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Skill Levels")
                            .font(.title3.bold())
                        ForEach(printer.skillLevels, id: \.self) { level in
                            Label(level.capitalized, systemImage: iconFor(skillLevel: level))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Use Cases")
                            .font(.title3.bold())
                        ForEach(printer.useCases, id: \.self) { useCase in
                            Label(useCase.capitalized, systemImage: iconFor(useCase: useCase))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Action Button
                if let url = printer.productUrl, let productURL = URL(string: url) {
                    Link(destination: productURL) {
                        HStack {
                            Image(systemName: "safari")
                            Text("View Product Page")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
    }

    // MARK: - Helper Views

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

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task {
                    await loadPrinter()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Badge

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(6)
    }
}

// MARK: - Spec Card

struct SpecCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.secondary.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

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
