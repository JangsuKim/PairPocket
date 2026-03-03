import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("月別履歴（仮）")
                .font(.headline)
            Text("上：月切替/カレンダー\n中下：リスト")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("履歴")
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
