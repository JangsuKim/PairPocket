import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("支出入力（詳細）（仮）")
                    .font(.headline)
                Text("日付 / ポケット / カテゴリ / 金額 / メモ")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("支出入力")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddExpenseView()
}
