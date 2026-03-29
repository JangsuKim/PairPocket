import SwiftUI

struct PocketSummarySection: View {
    let pockets: [Pocket]
    let selectedPocket: Pocket?
    let summaryLabel: String
    let totalAmountYen: Int
    let totalCount: Int
    let onSelectPocket: (Pocket) -> Void

    private var pocketColor: Color {
        selectedPocket?.displayColor ?? .accentColor
    }

    private var summaryTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: Date())) \(summaryLabel)"
    }

    private var amountText: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: totalAmountYen)) ?? "0"
        return "¥\(formatted)"
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
        VStack(alignment: .leading, spacing: 0) {
            PocketTabBar(
                pockets: pockets,
                selectedPocket: selectedPocket,
                onSelect: onSelectPocket
            )
            .padding(.bottom, -3)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedPocket?.name ?? "Pocket")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(summaryTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Circle()
                        .fill(pocketColor.opacity(0.16))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: selectedPocket?.icon ?? "wallet.pass")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(pocketColor)
                        }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(amountText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)
                        .contentTransition(.numericText())

                    Spacer()

                    Text("\(totalCount)件")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                pocketColor.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(pocketColor.opacity(0.28), lineWidth: 1)
                    .mask {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 18)
                            Rectangle()
                        }
                    }
            }
            .shadow(color: pocketColor.opacity(0.12), radius: 18, x: 0, y: 10)
        }
    }
}
