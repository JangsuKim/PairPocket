import SwiftUI

struct MonthlySummarySection: View {
    @State private var selectedPocketID: Int = 0

    private let pockets: [Pocket] = [
        .init(id: 0, name: "トータル", amountYen: 73312, count: 3),
        .init(id: 1, name: "生活費", amountYen: 42180, count: 2),
        .init(id: 2, name: "旅行", amountYen: 26800, count: 1),
        .init(id: 3, name: "家賃", amountYen: 78000, count: 1),
    ]

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: Date())) 現在出費"
    }

    private var currentSummary: PocketSummary {
        guard let selectedPocket = pockets.first(where: { $0.id == selectedPocketID }) else {
            return .init(amountYen: 0, count: 0)
        }
        return .init(amountYen: selectedPocket.amountYen, count: selectedPocket.count)
    }

    private var amountText: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: currentSummary.amountYen)) ?? "0"
        return "¥\(formatted)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(pockets) { pocket in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedPocketID = pocket.id
                            }
                        } label: {
                            Text(pocket.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule().fill(selectedPocketID == pocket.id ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider().opacity(0.4)

            Text(todayLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(amountText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Spacer()
                Text("\(currentSummary.count)件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    MonthlySummarySection()
}
