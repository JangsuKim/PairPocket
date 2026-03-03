import SwiftUI

struct PocketListView: View {
    private let isProUser = false

    private let pockets: [Pocket] = [
        .init(id: 1, name: "生活費", amountYen: 84_360, count: 7, color: .green),
        .init(id: 2, name: "旅行", amountYen: 26_800, count: 2, color: .orange),
    ]

    @State private var selectedPocketID: Int = 1

    private var selectedPocket: Pocket {
        pockets.first(where: { $0.id == selectedPocketID }) ?? pockets[0]
    }

    private var remainingPockets: [Pocket] {
        pockets.filter { $0.id != selectedPocket.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NavigationLink {
                    PocketDetailView(pocket: selectedPocket)
                } label: {
                    selectedPocketCard(pocket: selectedPocket)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Other Pockets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !remainingPockets.isEmpty {
                        stackedCardsArea
                    }

                    addPocketCard
                        .onTapGesture {
                            print("add pocket tapped")
                        }
                        .padding(.top, 6)
                }
            }
            .padding()
        }
        .navigationTitle("ポケット")
        .tint(selectedPocket.color)
    }

    private var stackedCardsArea: some View {
        VStack(spacing: -28) {
            ForEach(Array(remainingPockets.enumerated()), id: \.element.id) { index, pocket in
                smallPocketCard(pocket: pocket)
                    .zIndex(Double(remainingPockets.count - index))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            selectedPocketID = pocket.id
                        }
                    }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func selectedPocketCard(pocket: Pocket) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pocket.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .font(.headline)
                    .opacity(0.9)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("This month")
                    .font(.caption)
                    .opacity(0.85)
                Text(formatYen(pocket.amountYen))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }

            HStack {
                Text("\(pocket.count) tx")
                Spacer()
                Text("A → B \(formatYen(3_000))")
            }
            .font(.subheadline)
            .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(pocket.color)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func smallPocketCard(pocket: Pocket) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pocket.name)
                    .font(.headline)
                Text(formatYen(pocket.amountYen))
                    .font(.subheadline)
                    .opacity(0.9)
            }
            Spacer()
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 10, height: 10)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(pocket.color.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
        .opacity(isProUser ? 0 : 1)
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

#Preview {
    NavigationStack {
        PocketListView()
    }
}
