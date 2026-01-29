// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Your3dPrintDecisionBuddyClient",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Your3dPrintDecisionBuddyClient",
            path: "Sources"
        ),
    ]
)
