import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var apiStatus = "Checking..."
    @State private var selectedPrinterId: Int?

    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Apple-style unified toolbar header
            headerView
                .background(.ultraThinMaterial)

            AppleDivider()

            // Tab View with refined styling
            TabView(selection: $selectedTab) {
                PrinterBrowseView()
                    .tabItem {
                        Label("Printer Browse", systemImage: "square.grid.2x2")
                    }
                    .tag(0)

                PrinterQuizView()
                    .tabItem {
                        Label("Find Printer", systemImage: "sparkle.magnifyingglass")
                    }
                    .tag(1)

                MaterialsBrowseView()
                    .tabItem {
                        Label("Materials", systemImage: "cylinder.split.1x2")
                    }
                    .tag(2)

                TroubleshootingBrowseView()
                    .tabItem {
                        Label("Troubleshoot", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(3)
            }
        }
        .background(Color.appleBackground)
        .task {
            await checkHealth()
        }
        .sheet(item: $selectedPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: AppleSpacing.lg) {
            // App title with icon
            HStack(spacing: AppleSpacing.sm) {
                Image(systemName: "cube.transparent")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.appleBlue)

                Text("3D Printer Buddy")
                    .font(AppleTypography.title2)
            }

            Spacer()

            // Status indicator
            HStack(spacing: AppleSpacing.sm) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppleSpacing.md)
            .padding(.vertical, AppleSpacing.sm)
            .background(Color.primary.opacity(0.04))
            .clipShape(Capsule())
        }
        .padding(.horizontal, AppleSpacing.xl)
        .padding(.vertical, AppleSpacing.md)
    }

    private var statusColor: Color {
        switch apiStatus {
        case "healthy": return .appleGreen
        case "offline": return .appleRed
        default: return .appleOrange
        }
    }

    private var statusText: String {
        switch apiStatus {
        case "healthy": return "Connected"
        case "offline": return "Offline"
        default: return "Connecting..."
        }
    }

    private func checkHealth() async {
        do {
            apiStatus = try await apiClient.checkHealth()
        } catch {
            apiStatus = "offline"
        }
    }
}

// MARK: - Int extension for Identifiable (for sheet)

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
