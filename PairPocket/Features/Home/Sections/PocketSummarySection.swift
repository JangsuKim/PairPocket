import SwiftUI

struct PocketSummarySection: View {
    let pockets: [Pocket]
    let selectedPocket: Pocket?
    let summaryLabel: String
    let totalAmountYen: Int
    let totalCount: Int
    let periodStartDate: Date
    let onSelectPocket: (Pocket) -> Void

    private let cardHeight: CGFloat = 160

    private var pocketColor: Color {
        selectedPocket?.displayColor ?? .accentColor
    }

    private var summaryTitle: String {
        HomeSummaryTextFormatter.summaryTitle(label: summaryLabel)
    }

    private var amountText: String {
        HomeSummaryTextFormatter.yenAmountText(totalAmountYen)
    }

    private var amountColor: Color {
        guard let selectedPocket else {
            return MoneyValueStyle.color(forExpenseAmount: totalAmountYen)
        }

        switch selectedPocket.mode {
        case .settlementOnly:
            return MoneyValueStyle.color(forExpenseAmount: totalAmountYen)
        case .sharedManagement:
            return MoneyValueStyle.color(forSignedAmount: totalAmountYen)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = PocketTabLayout.make(
                pockets: pockets,
                selectedPocketID: selectedPocket?.id,
                availableWidth: proxy.size.width
            )
            let selectedTabFrame = layout.frame(for: selectedPocket?.id) ?? defaultTabFrame

            ZStack(alignment: .topLeading) {
                PocketCardShape(
                    tabFrame: selectedTabFrame,
                    cardTop: layout.tabHeight
                )
                .fill(Color(.systemBackground))
                .overlay {
                    PocketCardShape(
                        tabFrame: selectedTabFrame,
                        cardTop: layout.tabHeight
                    )
                    .fill(cardBackground)
                }
                .overlay {
                    PocketCardShape(
                        tabFrame: selectedTabFrame,
                        cardTop: layout.tabHeight
                    )
                    .stroke(PocketSurfaceStyle.border(for: pocketColor), lineWidth: 0.9)
                }
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)

                summaryContent
                    .padding(.top, layout.tabHeight)

                PocketTabBar(
                    pockets: pockets,
                    selectedPocket: selectedPocket,
                    layout: layout,
                    onSelect: onSelectPocket
                )
            }
            .animation(.easeInOut(duration: 0.22), value: selectedPocket?.id)
        }
        .frame(height: cardHeight + 42)
    }

    private var summaryContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                Text(summaryTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(amountText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(amountColor)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(
                        HomeSummaryTextFormatter.summaryPeriodText(
                            startDate: periodStartDate,
                            endDate: context.date,
                            count: totalCount
                        )
                    )
                }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)

            decorativeArtwork
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 22)
                .padding(.bottom, 22)
                .accessibilityHidden(true)
                .allowsHitTesting(false)

            detailLink
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 20)
                .padding(.top, 18)
        }
    }

    @ViewBuilder
    private var detailLink: some View {
        if let selectedPocket {
            NavigationLink {
                PocketDetailView(pocketID: selectedPocket.id)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(pocketColor)
                    .frame(width: 40, height: 40)
                    .background(pocketColor.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(selectedPocket.name)の詳細")
        }
    }

    private var decorativeArtwork: some View {
        Image(selectedPocket?.artwork.assetName ?? PocketArtwork.home.assetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 92, height: 92)
            .foregroundStyle(pocketColor)
            .opacity(0.10)
    }

    private var cardBackground: LinearGradient {
        PocketSurfaceStyle.background(for: pocketColor)
    }

    private var defaultTabFrame: CGRect {
        CGRect(x: 8, y: 0, width: 106, height: 42)
    }
}

private struct PocketCardShape: Shape {
    let tabFrame: CGRect
    let cardTop: CGFloat

    func path(in rect: CGRect) -> Path {
        let cornerRadius = min(CGFloat(26), (rect.height - cardTop) / 2)
        let tab = normalizedTab(in: rect)
        let tabCornerRadius = min(CGFloat(14), tab.height / 2)
        let transitionWidth: CGFloat = 10
        // The first tab gets only the shoulder width that actually fits before its curve.
        let leftCornerX = min(cornerRadius, max(tab.minX - transitionWidth, 0))
        let rightCornerRadius = min(cornerRadius, max(rect.maxX - tab.maxX - transitionWidth, 0))
        let rightCornerX = rect.maxX - rightCornerRadius
        let leftTransitionWidth = min(transitionWidth, max(tab.minX - leftCornerX, 0))
        let rightTransitionWidth = min(transitionWidth, max(rightCornerX - tab.maxX, 0))

        var path = Path()
        path.move(to: CGPoint(x: rightCornerX, y: cardTop))

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: cardTop + rightCornerRadius),
            control: CGPoint(x: rect.maxX, y: cardTop)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - cornerRadius),
            control: CGPoint(x: 0, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: 0, y: cardTop + leftCornerX))
        path.addQuadCurve(
            to: CGPoint(x: leftCornerX, y: cardTop),
            control: CGPoint(x: 0, y: cardTop)
        )

        if leftTransitionWidth > 0 {
            path.addLine(to: CGPoint(x: tab.minX - leftTransitionWidth, y: cardTop))
            path.addCurve(
                to: CGPoint(x: tab.minX, y: cardTop - leftTransitionWidth),
                control1: CGPoint(x: tab.minX - 4, y: cardTop),
                control2: CGPoint(x: tab.minX, y: cardTop - 4)
            )
        } else {
            path.addCurve(
                to: CGPoint(x: tab.minX, y: cardTop - transitionWidth),
                control1: CGPoint(x: leftCornerX, y: cardTop),
                control2: CGPoint(x: tab.minX, y: cardTop - 4)
            )
        }

        path.addLine(to: CGPoint(x: tab.minX, y: tab.minY + tabCornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: tab.minX + tabCornerRadius, y: tab.minY),
            control: CGPoint(x: tab.minX, y: tab.minY)
        )
        path.addLine(to: CGPoint(x: tab.maxX - tabCornerRadius, y: tab.minY))
        path.addQuadCurve(
            to: CGPoint(x: tab.maxX, y: tab.minY + tabCornerRadius),
            control: CGPoint(x: tab.maxX, y: tab.minY)
        )
        if rightTransitionWidth > 0 {
            path.addLine(to: CGPoint(x: tab.maxX, y: cardTop - rightTransitionWidth))
            path.addCurve(
                to: CGPoint(x: tab.maxX + rightTransitionWidth, y: cardTop),
                control1: CGPoint(x: tab.maxX, y: cardTop - 4),
                control2: CGPoint(x: tab.maxX + 4, y: cardTop)
            )
            path.addLine(to: CGPoint(x: rightCornerX, y: cardTop))
        } else {
            path.addCurve(
                to: CGPoint(x: rightCornerX, y: cardTop),
                control1: CGPoint(x: tab.maxX, y: cardTop - 4),
                control2: CGPoint(x: rightCornerX - 4, y: cardTop)
            )
        }
        path.closeSubpath()

        return path
    }

    private func normalizedTab(in rect: CGRect) -> CGRect {
        let minimumX = max(tabFrame.minX, 0)
        let maximumX = min(tabFrame.maxX, rect.maxX - 8)
        let height = min(max(tabFrame.height, 36), cardTop)
        return CGRect(x: minimumX, y: max(tabFrame.minY, 0), width: maximumX - minimumX, height: height)
    }
}
