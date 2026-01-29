import SwiftUI

struct PrinterBrowseView: View {
    @State private var printers: [PrinterListItem] = []
    @State private var selectedPrinterId: Int?
    @State private var detailPrinterId: Int?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Filters
    @State private var priceMin: Double = 0
    @State private var priceMax: Double = 6000
    @State private var selectedType: PrinterType?
    @State private var selectedMotionSystem: MotionSystem?
    @State private var selectedSkillLevel: SkillLevel?
    @State private var selectedUseCase: UseCase?
    @State private var filterEnclosure: Bool = false
    @State private var filterMultiColor: Bool = false

    private let apiClient = PrinterAPIClient()

    var body: some View {
        HSplitView {
            // Filter Sidebar
            filterSidebar
                .frame(minWidth: 200, maxWidth: 250)

            // Main Content
            VStack(spacing: 0) {
                if let error = errorMessage {
                    errorView(error)
                } else if isLoading {
                    ProgressView("Loading printers...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if printers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "printer")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No printers found")
                            .foregroundStyle(.secondary)
                        Text("Try adjusting your filters")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    printerList
                }
            }
            .frame(minWidth: 400)
        }
        .task {
            await loadPrinters()
        }
        .sheet(item: $detailPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
                .frame(minWidth: 600, minHeight: 500)
        }
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Filters")
                    .font(.headline)

                // Price Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price Range")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("$\(Int(priceMin))")
                            .monospacedDigit()
                        Spacer()
                        Text("$\(Int(priceMax))")
                            .monospacedDigit()
                    }
                    .font(.caption)

                    HStack {
                        Slider(value: $priceMin, in: 0...5000, step: 50)
                        Slider(value: $priceMax, in: 100...6000, step: 50)
                    }
                }

                Divider()

                // Printer Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Printer Type")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(nil as PrinterType?)
                        ForEach(PrinterType.allCases) { type in
                            Text(type.displayName).tag(type as PrinterType?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                // Motion System (FDM only)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Motion System")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Motion", selection: $selectedMotionSystem) {
                        Text("All Systems").tag(nil as MotionSystem?)
                        ForEach(MotionSystem.allCases) { system in
                            Text(system.displayName).tag(system as MotionSystem?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                // Skill Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Level")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Skill", selection: $selectedSkillLevel) {
                        Text("All Levels").tag(nil as SkillLevel?)
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.displayName).tag(level as SkillLevel?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                // Use Case
                VStack(alignment: .leading, spacing: 8) {
                    Text("Use Case")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Use Case", selection: $selectedUseCase) {
                        Text("All Use Cases").tag(nil as UseCase?)
                        ForEach(UseCase.allCases) { useCase in
                            Text(useCase.displayName).tag(useCase as UseCase?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Divider()

                // Enclosure Toggle
                Toggle("Enclosed Only", isOn: $filterEnclosure)

                // Multi Color Toggle
                Toggle("Multi Color Support", isOn: $filterMultiColor)

                Spacer()

                // Apply Button
                Button("Apply Filters") {
                    Task {
                        await loadPrinters()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Reset Filters") {
                    resetFilters()
                    Task {
                        await loadPrinters()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(.bar)
    }

    // MARK: - Printer List (Grid with images)

    private var printerList: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 350))], spacing: 16) {
                ForEach(printers) { printer in
                    PrinterCard(printer: printer)
                        .onTapGesture {
                            detailPrinterId = printer.id
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
                    await loadPrinters()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadPrinters() async {
        isLoading = true
        errorMessage = nil

        let filters = PrinterAPIClient.PrinterFilters(
            priceMin: priceMin > 0 ? priceMin : nil,
            priceMax: priceMax < 6000 ? priceMax : nil,
            skillLevel: selectedSkillLevel?.rawValue,
            useCase: selectedUseCase?.rawValue,
            printerType: selectedType?.rawValue,
            motionSystem: selectedMotionSystem?.rawValue,
            hasEnclosure: filterEnclosure ? true : nil,
            hasMultiColor: filterMultiColor ? true : nil
        )

        do {
            printers = try await apiClient.fetchPrinters(filters: filters)
        } catch {
            errorMessage = "Failed to load printers: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func resetFilters() {
        priceMin = 0
        priceMax = 6000
        selectedType = nil
        selectedMotionSystem = nil
        selectedSkillLevel = nil
        selectedUseCase = nil
        filterEnclosure = false
        filterMultiColor = false
    }
}

// MARK: - Printer Card

struct PrinterCard: View {
    let printer: PrinterListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AsyncImage(url: URL(string: printer.imageUrl ?? "")) { phase in
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

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Name and Price
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(printer.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(printer.manufacturer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("$\(printer.price, specifier: "%.0f")")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }

                // Badges
                HStack(spacing: 6) {
                    // Type badge
                    Text(printer.printerType.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(printer.printerType == "fdm" ? .blue.opacity(0.2) : .purple.opacity(0.2))
                        .cornerRadius(4)

                    // Motion badge (FDM only)
                    if let motion = printer.motionSystem {
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
                        if printer.enclosure {
                            Image(systemName: "cube.box.fill")
                                .help("Enclosed")
                        }
                        if printer.autoLeveling {
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
                    Text(printer.buildVolumeDescription)
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
}
