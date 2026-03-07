import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("ポケット") {
                Text("ポケット管理（仮）")
                Text("比率設定（仮）")
            }
            Section("その他") {
                Text("Pro（仮）")
                Text("データ管理（仮）")
            }
        }
        .navigationTitle("設定")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
