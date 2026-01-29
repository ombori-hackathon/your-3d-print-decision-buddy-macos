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
            // Apple-style Filter Sidebar
            filterSidebar
                .frame(minWidth: 220, maxWidth: 260)

            // Main Content
            mainContent
                .frame(minWidth: 500)
        }
        .task {
            await loadPrinters()
        }
        .sheet(item: $detailPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
                .frame(minWidth: 700, minHeight: 550)
        }
    }

    // MARK: - Filter Sidebar

    private var filterSidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppleSpacing.xl) {
                // Header
                Text("Filters")
                    .font(AppleTypography.title3)
                    .padding(.bottom, AppleSpacing.xs)

                // Price Range
                AppleSidebarSection("Price Range") {
                    VStack(spacing: AppleSpacing.md) {
                        HStack {
                            Text("$\(Int(priceMin))")
                                .font(AppleTypography.mono)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(Int(priceMax))")
                                .font(AppleTypography.mono)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: AppleSpacing.sm) {
                            Slider(value: $priceMin, in: 0...5000, step: 50)
                                .tint(Color.appleBlue)
                            Slider(value: $priceMax, in: 100...6000, step: 50)
                                .tint(Color.appleBlue)
                        }
                    }
                }

                AppleDivider()

                // Printer Type
                AppleSidebarSection("Printer Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("All Types").tag(nil as PrinterType?)
                        ForEach(PrinterType.allCases) { type in
                            Text(type.displayName).tag(type as PrinterType?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                // Motion System
                AppleSidebarSection("Motion System") {
                    Picker("Motion", selection: $selectedMotionSystem) {
                        Text("All Systems").tag(nil as MotionSystem?)
                        ForEach(MotionSystem.allCases) { system in
                            Text(system.displayName).tag(system as MotionSystem?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                // Skill Level
                AppleSidebarSection("Skill Level") {
                    Picker("Skill", selection: $selectedSkillLevel) {
                        Text("All Levels").tag(nil as SkillLevel?)
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.displayName).tag(level as SkillLevel?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                // Use Case
                AppleSidebarSection("Use Case") {
                    Picker("Use Case", selection: $selectedUseCase) {
                        Text("All Use Cases").tag(nil as UseCase?)
                        ForEach(UseCase.allCases) { useCase in
                            Text(useCase.displayName).tag(useCase as UseCase?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                AppleDivider()

                // Feature Toggles
                VStack(alignment: .leading, spacing: AppleSpacing.md) {
                    Toggle(isOn: $filterEnclosure) {
                        Label("Enclosed Only", systemImage: "cube.box")
                            .font(AppleTypography.callout)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.appleBlue)

                    Toggle(isOn: $filterMultiColor) {
                        Label("Multi-Color", systemImage: "paintpalette")
                            .font(AppleTypography.callout)
                    }
                    .toggleStyle(.switch)
                    .tint(Color.appleBlue)
                }

                Spacer(minLength: AppleSpacing.xl)

                // Action Buttons
                VStack(spacing: AppleSpacing.sm) {
                    ApplePrimaryButton(title: "Apply Filters", icon: "line.3.horizontal.decrease") {
                        Task { await loadPrinters() }
                    }
                    .frame(maxWidth: .infinity)

                    AppleSecondaryButton(title: "Reset", icon: "arrow.counterclockwise") {
                        resetFilters()
                        Task { await loadPrinters() }
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
                    Task { await loadPrinters() }
                }
            } else if isLoading {
                AppleLoadingState(message: "Loading printers...")
            } else if printers.isEmpty {
                AppleEmptyState(
                    icon: "printer",
                    title: "No printers found",
                    subtitle: "Try adjusting your filters"
                )
            } else {
                printerGrid
            }
        }
    }

    // MARK: - Printer Grid

    private var printerGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 260, maximum: 320))],
                spacing: AppleSpacing.lg
            ) {
                ForEach(printers) { printer in
                    ApplePrinterCard(printer: printer)
                        .onTapGesture {
                            detailPrinterId = printer.id
                        }
                }
            }
            .padding(AppleSpacing.xl)
        }
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

// MARK: - Apple-Style Printer Card

struct ApplePrinterCard: View {
    let printer: PrinterListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            AppleAsyncImage(url: printer.imageUrl, fallbackIcon: "printer")
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.02))
                .clipped()

            // Content
            VStack(alignment: .leading, spacing: AppleSpacing.sm) {
                // Header: Name + Price
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(printer.name)
                            .font(AppleTypography.headline)
                            .lineLimit(1)

                        Text(printer.manufacturer)
                            .font(AppleTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ApplePrice(amount: printer.price, size: .medium)
                }

                // Badges
                HStack(spacing: AppleSpacing.sm) {
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

                    Spacer()

                    // Feature icons
                    HStack(spacing: AppleSpacing.xs) {
                        if printer.enclosure {
                            Image(systemName: "cube.box.fill")
                                .help("Enclosed")
                        }
                        if printer.autoLeveling {
                            Image(systemName: "level.fill")
                                .help("Auto Leveling")
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                }

                // Build Volume
                HStack(spacing: AppleSpacing.xs) {
                    Image(systemName: "cube")
                        .font(.system(size: 10))
                    Text(printer.buildVolumeDescription)
                        .font(AppleTypography.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding(AppleSpacing.md)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.card))
        .appleShadow(AppleShadow.card)
        .contentShape(Rectangle())
    }
}
