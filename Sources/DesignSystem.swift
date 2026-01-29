import SwiftUI

// MARK: - Apple-Inspired Design System
// Following Apple Human Interface Guidelines for macOS

// MARK: - Color Palette

extension Color {
    // Semantic colors following Apple's design language
    static let appleBackground = Color(NSColor.windowBackgroundColor)
    static let appleSidebarBackground = Color(NSColor.controlBackgroundColor)
    static let appleCardBackground = Color(NSColor.controlBackgroundColor)

    // Accent colors - refined, muted tones
    static let appleBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let appleGreen = Color(red: 0.196, green: 0.843, blue: 0.294)
    static let appleOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let applePurple = Color(red: 0.686, green: 0.322, blue: 0.871)
    static let applePink = Color(red: 1.0, green: 0.176, blue: 0.333)
    static let appleRed = Color(red: 1.0, green: 0.231, blue: 0.188)
    static let appleTeal = Color(red: 0.353, green: 0.784, blue: 0.980)
    static let appleIndigo = Color(red: 0.345, green: 0.337, blue: 0.839)
    static let appleMint = Color(red: 0.0, green: 0.78, blue: 0.745)
    static let appleCyan = Color(red: 0.196, green: 0.678, blue: 0.902)
    static let appleYellow = Color(red: 1.0, green: 0.8, blue: 0.0)

    // Neutral palette
    static let appleGray1 = Color(NSColor.systemGray)
    static let appleGray2 = Color(NSColor.secondaryLabelColor)
    static let appleGray3 = Color(NSColor.tertiaryLabelColor)
    static let appleGray4 = Color(NSColor.quaternaryLabelColor)
    static let appleSeparator = Color(NSColor.separatorColor)
}

// MARK: - Typography Scale

struct AppleTypography {
    // Large Title - App headers
    static let largeTitle = Font.system(size: 26, weight: .bold, design: .default)

    // Title 1 - Section headers
    static let title1 = Font.system(size: 22, weight: .bold, design: .default)

    // Title 2 - Card headers
    static let title2 = Font.system(size: 17, weight: .semibold, design: .default)

    // Title 3 - Subsection headers
    static let title3 = Font.system(size: 15, weight: .semibold, design: .default)

    // Headline - Emphasized body
    static let headline = Font.system(size: 13, weight: .semibold, design: .default)

    // Body - Primary content
    static let body = Font.system(size: 13, weight: .regular, design: .default)

    // Callout - Secondary content
    static let callout = Font.system(size: 12, weight: .regular, design: .default)

    // Subheadline - Labels
    static let subheadline = Font.system(size: 11, weight: .regular, design: .default)

    // Footnote - Tertiary content
    static let footnote = Font.system(size: 10, weight: .regular, design: .default)

    // Caption - Smallest text
    static let caption = Font.system(size: 10, weight: .medium, design: .default)

    // Monospaced for values
    static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
}

// MARK: - Spacing System (8pt grid)

struct AppleSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let section: CGFloat = 40
}

// MARK: - Corner Radii

struct AppleRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 10
    static let xl: CGFloat = 12
    static let xxl: CGFloat = 16
    static let card: CGFloat = 12
    static let button: CGFloat = 6
}

// MARK: - Shadows

struct AppleShadow {
    static let subtle = Shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    static let card = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    static let elevated = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    static let modal = Shadow(color: .black.opacity(0.2), radius: 32, x: 0, y: 8)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appleShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Apple-Style Components

// Sidebar Filter Section
struct AppleSidebarSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppleSpacing.sm) {
            Text(title)
                .font(AppleTypography.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            content
        }
    }
}

// Apple-style pill badge
struct ApplePill: View {
    let text: String
    let color: Color
    var isOutlined: Bool = false

    var body: some View {
        Text(text)
            .font(AppleTypography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, AppleSpacing.sm)
            .padding(.vertical, AppleSpacing.xs)
            .background(
                isOutlined
                    ? AnyShapeStyle(color.opacity(0.1))
                    : AnyShapeStyle(color.opacity(0.15))
            )
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// Apple-style tag badge
struct AppleTag: View {
    let text: String
    var icon: String?
    var color: Color = .appleBlue

    var body: some View {
        HStack(spacing: AppleSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .medium))
            }
            Text(text)
                .font(AppleTypography.caption)
        }
        .padding(.horizontal, AppleSpacing.sm)
        .padding(.vertical, AppleSpacing.xs + 1)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.sm))
    }
}

// Apple-style section header
struct AppleSectionHeader: View {
    let title: String
    var subtitle: String?
    var icon: String?
    var iconColor: Color = .appleBlue

    var body: some View {
        HStack(spacing: AppleSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppleTypography.title2)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppleTypography.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// Apple-style specification row
struct AppleSpecRow: View {
    let label: String
    let value: String
    var icon: String?

    var body: some View {
        HStack {
            HStack(spacing: AppleSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }
                Text(label)
                    .font(AppleTypography.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(AppleTypography.callout)
                .fontWeight(.medium)
        }
        .padding(.vertical, AppleSpacing.xs)
    }
}

// Apple-style card with vibrancy
struct AppleCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppleSpacing.lg

    init(padding: CGFloat = AppleSpacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.card))
            .appleShadow(AppleShadow.subtle)
    }
}

// Apple-style info card for specs
struct AppleInfoCard: View {
    let title: String
    let value: String
    var icon: String?
    var tint: Color = .appleBlue

    var body: some View {
        VStack(alignment: .leading, spacing: AppleSpacing.sm) {
            HStack(spacing: AppleSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(AppleTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(AppleTypography.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppleSpacing.md)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: AppleRadius.md))
    }
}

// Apple-style primary button
struct ApplePrimaryButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppleSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(AppleTypography.headline)
            }
            .padding(.horizontal, AppleSpacing.lg)
            .padding(.vertical, AppleSpacing.sm + 2)
            .background(Color.appleBlue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.button))
        }
        .buttonStyle(.plain)
    }
}

// Apple-style secondary button
struct AppleSecondaryButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppleSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(AppleTypography.headline)
            }
            .padding(.horizontal, AppleSpacing.lg)
            .padding(.vertical, AppleSpacing.sm + 2)
            .background(Color.primary.opacity(0.06))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.button))
        }
        .buttonStyle(.plain)
    }
}

// Apple-style close button (for modals)
struct AppleCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// Apple-style empty state
struct AppleEmptyState: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: AppleSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.quaternary)

            VStack(spacing: AppleSpacing.xs) {
                Text(title)
                    .font(AppleTypography.title3)
                    .foregroundStyle(.secondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppleTypography.callout)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Apple-style loading state
struct AppleLoadingState: View {
    let message: String

    var body: some View {
        VStack(spacing: AppleSpacing.lg) {
            ProgressView()
                .scaleEffect(0.8)

            Text(message)
                .font(AppleTypography.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Apple-style error state
struct AppleErrorState: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: AppleSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.appleOrange)

            Text(message)
                .font(AppleTypography.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            AppleSecondaryButton(title: "Try Again", icon: "arrow.clockwise", action: retryAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Price Formatting

struct ApplePrice: View {
    let amount: Double
    var size: PriceSize = .medium

    enum PriceSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return AppleTypography.callout
            case .medium: return AppleTypography.title2
            case .large: return AppleTypography.title1
            }
        }
    }

    var body: some View {
        Text("$\(amount, specifier: "%.0f")")
            .font(size.font)
            .fontWeight(.semibold)
            .fontDesign(.rounded)
            .monospacedDigit()
    }
}

// MARK: - Image Components

struct AppleAsyncImage: View {
    let url: String?
    var fallbackIcon: String = "photo"
    var aspectRatio: ContentMode = .fit

    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.primary.opacity(0.03))
                    .overlay {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: aspectRatio)
            case .failure:
                Rectangle()
                    .fill(Color.primary.opacity(0.03))
                    .overlay {
                        Image(systemName: fallbackIcon)
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.quaternary)
                    }
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Divider

struct AppleDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appleSeparator)
            .frame(height: 0.5)
    }
}

// MARK: - Match Score Badge

struct AppleMatchBadge: View {
    let score: Int

    var body: some View {
        HStack(spacing: 2) {
            Text("\(score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
            Text("%")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppleSpacing.sm)
        .padding(.vertical, AppleSpacing.xs)
        .background(scoreColor)
        .clipShape(Capsule())
    }

    private var scoreColor: Color {
        if score >= 80 {
            return .appleGreen
        } else if score >= 60 {
            return .appleOrange
        } else {
            return .appleGray1
        }
    }
}

// MARK: - Flow Layout (re-exported)

struct AppleFlowLayout: Layout {
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

// MARK: - View Extensions

extension View {
    func appleCard() -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppleRadius.card))
            .appleShadow(AppleShadow.subtle)
    }

    func appleSidebar() -> some View {
        self
            .background(.ultraThinMaterial)
    }
}
