import SwiftUI
import SwiftData

private struct PocketCardStackLayout: Layout {
    let cardPeekOffset: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard subviews.isEmpty == false else {
            return .zero
        }

        let measuredSizes = measuredSizes(for: subviews, proposal: proposal)
        let maxWidth = measuredSizes.map(\.width).max() ?? 0
        let totalHeight = measuredSizes.enumerated().reduce(CGFloat.zero) { currentMax, element in
            let (index, size) = element
            let originY = CGFloat(index) * cardPeekOffset
            return max(currentMax, originY + size.height)
        }

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let childProposal = ProposedViewSize(width: bounds.width, height: nil)

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX, y: bounds.minY + CGFloat(index) * cardPeekOffset),
                anchor: .topLeading,
                proposal: childProposal
            )
        }
    }

    private func measuredSizes(for subviews: Subviews, proposal: ProposedViewSize) -> [CGSize] {
        let childProposal = ProposedViewSize(width: proposal.width, height: nil)
        return subviews.map { $0.sizeThatFits(childProposal) }
    }
}

struct PocketListView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingAddPocket = false
    @State private var editingPocket: Pocket?
    @State private var selectedPocketID: UUID?
    @State private var isShowingPocketLimitAlert = false

    private var cardHeight: CGFloat {
        190
    }

    private var cardPeekOffset: CGFloat {
        switch activePockets.count {
        case 1:
            return 0
        case 2:
            return 120
        case 3:
            return 105
        case 4:
            return 100
        case 5:
            return 95
        default:
            return 60
        }
    }

    private let pocketCardPrimaryForeground = Color(red: 0.24, green: 0.25, blue: 0.28)
    private let pocketCardSecondaryForeground = Color(red: 0.35, green: 0.36, blue: 0.40)

    private var activePockets: [Pocket] {
        pocketStore.pockets
    }

    private var archivedPockets: [Pocket] {
        pocketStore.archivedPockets
    }

    private var mainPocket: Pocket? {
        activePockets.first(where: \.isMain)
    }

    private var hasReachedPocketLimit: Bool {
        activePockets.count >= PocketStore.maximumPocketCount
    }

    private var displayedPocket: Pocket? {
        guard let selectedPocketID else {
            return mainPocket ?? activePockets.first
        }

        return activePockets.first(where: { $0.id == selectedPocketID }) ?? mainPocket ?? activePockets.first
    }

    private var stackedPockets: [Pocket] {
        guard let displayedPocket else {
            return []
        }

        let remainingPockets = activePockets.filter { $0.id != displayedPocket.id }
        return remainingPockets + [displayedPocket]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                if stackedPockets.isEmpty {
                    emptyMainPocketCard
                } else {
                    pocketWalletStack
                }

                pocketManagementSection

                if archivedPockets.isEmpty == false {
                    archivedPocketSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .bottomTabBarContentInset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
        .tint(mainPocket?.displayColor ?? .accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ポケット")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .sheet(isPresented: $isPresentingAddPocket) {
            NavigationStack {
                PocketFormView(mode: .add)
            }
        }
        .sheet(item: $editingPocket) { pocket in
            NavigationStack {
                PocketFormView(mode: .edit(pocket))
            }
        }
        .alert("ポケットを追加できません", isPresented: $isShowingPocketLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("ポケットは最大\(PocketStore.maximumPocketCount)個まで作成できます。")
        }
        .task {
            try? expenseStore.loadIfNeeded(from: modelContext)
            try? pocketStore.loadIfNeeded(from: modelContext)
            syncSelectedPocket()
        }
        .onChange(of: pocketStore.pockets.map(\.id)) { _, _ in
            syncSelectedPocket()
        }
    }

    private var pocketWalletStack: some View {
        PocketCardStackLayout(cardPeekOffset: cardPeekOffset) {
            ForEach(Array(stackedPockets.enumerated()), id: \.element.id) { index, pocket in
                walletCard(for: pocket, isFrontCard: pocket.id == displayedPocket?.id)
                    .zIndex(Double(index + 1))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var pocketManagementSection: some View {
        Button {
            if hasReachedPocketLimit {
                isShowingPocketLimitAlert = true
            } else {
                isPresentingAddPocket = true
            }
        } label: {
            addPocketCard
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func walletCard(for pocket: Pocket, isFrontCard: Bool) -> some View {
        if isFrontCard {
            NavigationLink(value: pocket.id) {
                pocketCard(pocket: pocket, isFrontCard: true)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    selectedPocketID = pocket.id
                }
            } label: {
                pocketCard(pocket: pocket, isFrontCard: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func pocketCard(pocket: Pocket, isFrontCard: Bool) -> some View {
        let pocketEntries = entries(for: pocket.id)
        let pocketExpenses = pocketEntries.filter { $0.type == .expense }
        let totalExpense = pocketExpenses.reduce(0) { $0 + $1.amount }
        let currentBalance = SettlementEngine.calculate(entries: pocketEntries).currentBalance
        let displayedAmount = displayedAmount(for: pocket, totalExpense: totalExpense, currentBalance: currentBalance)
        let amountCaption = amountCaption(for: pocket, currentBalance: currentBalance)
        let amountColor = MoneyValueStyle.colorForPocketDisplay(
            mode: pocket.mode,
            displayedAmount: displayedAmount,
            currentBalance: currentBalance
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pocket.name)
                        .font(isFrontCard ? .title3.weight(.semibold) : .headline.weight(.semibold))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        if pocket.isMain {
                            cardBadge(title: "メイン")
                        }

                        if isFrontCard, pocket.isMain == false {
                            cardBadge(title: "表示中")
                        }
                    }
                }

                Spacer()

                if isFrontCard {
                    HStack(spacing: 8) {
                        Button {
                            editingPocket = pocket
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline.weight(.semibold))
                                .padding(10)
                                .background(pocketCardPrimaryForeground.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Image(systemName: "wallet.pass.fill")
                            .font(.headline)
                            .foregroundStyle(pocketCardSecondaryForeground)
                    }
                }
            }

            if isFrontCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text(amountCaption)
                        .font(.caption)
                        .foregroundStyle(pocketCardSecondaryForeground)
                    Text(formatYen(displayedAmount))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)
                }

                HStack {
                    Text("\(pocketExpenses.count)件")
                    Spacer()
                    Text(pocketModeLabel(for: pocket))
                }
                .font(.subheadline)
                .foregroundStyle(pocketCardSecondaryForeground)
            } else {
                HStack {
                    Text(formatYen(displayedAmount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(amountColor)
                    Spacer()
                    Text(pocketModeLabel(for: pocket))
                        .font(.caption)
                        .foregroundStyle(pocketCardSecondaryForeground)
                }
            }
        }
        .foregroundStyle(pocketCardPrimaryForeground)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: cardHeight, alignment: .topLeading)
        .background(pocket.displayColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(isFrontCard ? 0.16 : 0.08), radius: isFrontCard ? 18 : 10, x: 0, y: 8)
    }

    private func cardBadge(title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(pocketCardSecondaryForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(pocketCardPrimaryForeground.opacity(0.08))
            .clipShape(Capsule())
    }

    private var addPocketCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.subheadline.weight(.bold))
            Text("ポケットを追加")
                .font(.headline)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(.tertiary)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var archivedPocketSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("終了したポケット")
                    .font(.headline)
                Spacer()
                Text("\(archivedPockets.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(archivedPockets) { pocket in
                    archivedPocketRow(for: pocket)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func archivedPocketRow(for pocket: Pocket) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(pocket.displayColor.opacity(0.75))
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(pocket.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("アーカイブ済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(pocket.mode.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyMainPocketCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メインポケットがありません")
                .font(.headline)
            Text("ポケットを作成して始めましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func entries(for pocketId: UUID) -> [Transaction] {
        expenseStore.entries(for: pocketId)
    }

    private func displayedAmount(for pocket: Pocket, totalExpense: Int, currentBalance: Int) -> Int {
        switch pocket.mode {
        case .settlementOnly:
            return totalExpense
        case .sharedManagement:
            return currentBalance > 0 ? currentBalance : totalExpense
        }
    }

    private func amountCaption(for pocket: Pocket, currentBalance: Int) -> String {
        switch pocket.mode {
        case .settlementOnly:
            return "支出"
        case .sharedManagement:
            return currentBalance > 0 ? "残高" : "支出"
        }
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }

    private func pocketModeLabel(for pocket: Pocket) -> String {
        pocket.mode.displayName
    }

    private func syncSelectedPocket() {
        guard activePockets.isEmpty == false else {
            selectedPocketID = nil
            return
        }

        if let selectedPocketID,
           activePockets.contains(where: { $0.id == selectedPocketID }) {
            return
        }

        selectedPocketID = mainPocket?.id ?? activePockets.first?.id
    }
}

#Preview {
    NavigationStack {
        PocketListView()
            .environment(ExpenseStore())
            .environment(PocketStore())
            .modelContainer(for: [ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self], inMemory: true)
    }
}
