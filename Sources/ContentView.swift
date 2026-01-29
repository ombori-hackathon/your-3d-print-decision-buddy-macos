import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var apiStatus = "Checking..."
    @State private var selectedPrinterId: Int?

    private let apiClient = PrinterAPIClient()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("3D Printer Decision Buddy")
                    .font(.title.bold())
                Spacer()
                Circle()
                    .fill(apiStatus == "healthy" ? .green : .red)
                    .frame(width: 12, height: 12)
                Text(apiStatus)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.bar)

            Divider()

            // Tab View
            TabView(selection: $selectedTab) {
                PrinterBrowseView()
                    .tabItem {
                        Label("Printer Browse", systemImage: "list.bullet.rectangle")
                    }
                    .tag(0)

                PrinterQuizView()
                    .tabItem {
                        Label("Find My Printer", systemImage: "sparkles")
                    }
                    .tag(1)

                MaterialsBrowseView()
                    .tabItem {
                        Label("Materials", systemImage: "cylinder")
                    }
                    .tag(2)

                TroubleshootingBrowseView()
                    .tabItem {
                        Label("Troubleshooting", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(3)
            }
        }
        .task {
            await checkHealth()
        }
        .sheet(item: $selectedPrinterId) { printerId in
            PrinterDetailView(printerId: printerId)
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

