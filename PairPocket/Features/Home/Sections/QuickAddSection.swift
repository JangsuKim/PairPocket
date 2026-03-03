import SwiftUI

struct QuickAddSection: View {
    @State private var amountText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイック追加")
                .font(.headline)

            HStack(spacing: 12) {
                Menu("カテゴリ") {
                    Button("食費") {}
                    Button("生活") {}
                    Button("交通") {}
                    Button("その他") {}
                }

                TextField("金額", text: $amountText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            Button {
                // TODO: 追加ロジック
            } label: {
                Text("追加")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    QuickAddSection()
}
