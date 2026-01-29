import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var textIndex = 0

    private let loadingMessages = [
        "Heating up the nozzle...",
        "Leveling the bed...",
        "Loading filament...",
        "Calibrating extruder...",
        "Preparing first layer...",
        "Almost ready to print..."
    ]

    private let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.appleBlue.opacity(0.1),
                    Color.applePurple.opacity(0.05),
                    Color.appleBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppleSpacing.xxxl) {
                Spacer()

                // App Icon Animation
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appleBlue, Color.applePurple, Color.applePink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)

                    // Inner icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)

                        Image(systemName: "cube.transparent")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appleBlue, Color.applePurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    }

                    // Orbiting dot (like filament)
                    Circle()
                        .fill(Color.appleGreen)
                        .frame(width: 10, height: 10)
                        .offset(x: 60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                }

                // App Name
                VStack(spacing: AppleSpacing.md) {
                    Text("3D Printer Buddy")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Motto
                    Text("The app that helps you turn questions into clean prints.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppleSpacing.xxl)
                }

                Spacer()

                // Loading indicator
                VStack(spacing: AppleSpacing.lg) {
                    // Progress dots
                    HStack(spacing: AppleSpacing.sm) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.appleBlue)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }

                    // Loading text
                    Text(loadingMessages[textIndex])
                        .font(AppleTypography.callout)
                        .foregroundStyle(.tertiary)
                        .contentTransition(.numericText())
                }
                .padding(.bottom, AppleSpacing.section)
            }
            .padding(AppleSpacing.xxl)
        }
        .onAppear {
            isAnimating = true
        }
        .onReceive(timer) { _ in
            withAnimation {
                textIndex = (textIndex + 1) % loadingMessages.count
            }
        }
    }
}

// MARK: - Main App Container with Splash

struct AppContainerView: View {
    @State private var showSplash = true
    @State private var splashOpacity = 1.0

    var body: some View {
        ZStack {
            // Main content (always present but hidden initially)
            ContentView()
                .opacity(showSplash ? 0 : 1)

            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .opacity(splashOpacity)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Show splash for 2.5 seconds then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    splashOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSplash = false
                }
            }
        }
    }
}
