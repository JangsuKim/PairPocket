import SwiftUI
import SwiftData

struct PocketFormView: View {
    enum Mode {
        case add
        case edit(Pocket)

        var title: String {
            switch self {
            case .add:
                return "ポケット追加"
            case .edit:
                return "ポケット編集"
            }
        }

        var submitTitle: String {
            switch self {
            case .add:
                return "保存"
            case .edit:
                return "更新"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PocketStore.self) private var pocketStore

    let mode: Mode

    @State private var name: String
    @State private var colorKey: String
    @State private var ratioA: Int
    @State private var sharedBalanceEnabled: Bool
    @State private var personalPaymentEnabled: Bool
    @State private var isMain: Bool
    @State private var validationMessage: String?
    @State private var isShowingDeleteConfirmation = false

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _colorKey = State(initialValue: PocketColorOption.green.rawValue)
            _ratioA = State(initialValue: 50)
            _sharedBalanceEnabled = State(initialValue: false)
            _personalPaymentEnabled = State(initialValue: true)
            _isMain = State(initialValue: false)
        case let .edit(pocket):
            _name = State(initialValue: pocket.name)
            _colorKey = State(initialValue: pocket.colorKey)
            _ratioA = State(initialValue: pocket.ratioA)
            _sharedBalanceEnabled = State(initialValue: pocket.sharedBalanceEnabled)
            _personalPaymentEnabled = State(initialValue: pocket.personalPaymentEnabled)
            _isMain = State(initialValue: pocket.isMain)
        }
    }

    private var ratioB: Int {
        100 - ratioA
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("ポケット名", text: $name)

                colorSelection
            }

            Section("分担比率") {
                Stepper("memberA \(ratioA)%", value: $ratioA, in: 0...100)
                LabeledContent("memberB") {
                    Text("\(ratioB)%")
                }
            }

            Section("支払い設定") {
                Toggle("共有残高を有効にする", isOn: $sharedBalanceEnabled)
                Toggle("個人支払いを有効にする", isOn: $personalPaymentEnabled)
            }

            Section("役割") {
                Toggle("メインポケットに設定", isOn: $isMain)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if case let .edit(pocket) = mode {
                Section {
                    Button("ポケットを削除", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                    .disabled(pocket.isMain)
                } footer: {
                    if pocket.isMain {
                        Text("メインポケットは削除できません。")
                    } else {
                        Text("削除したポケットは新規入力では選べなくなりますが、過去の履歴には残ります。")
                    }
                }
            }
        }
        .navigationTitle(mode.title)
        .alert("ポケットを削除しますか？", isPresented: $isShowingDeleteConfirmation) {
            Button("削除", role: .destructive) {
                deletePocket()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(mode.submitTitle) {
                    save()
                }
            }
        }
    }

    private var colorSelection: some View {
        Picker("色", selection: $colorKey) {
            ForEach(PocketColorOption.allCases) { option in
                HStack(spacing: 8) {
                    Circle()
                        .fill(option.color)
                        .frame(width: 12, height: 12)
                    Text(option.title)
                }
                .tag(option.rawValue)
            }
        }
    }

    private func save() {
        guard trimmedName.isEmpty == false else {
            validationMessage = "ポケット名を入力してください。"
            return
        }

        guard (0...100).contains(ratioA), (0...100).contains(ratioB) else {
            validationMessage = "比率の値が正しくありません。"
            return
        }

        switch mode {
        case .add:
            let shouldBeMain = isMain || pocketStore.pockets.isEmpty
            let pocket = Pocket(
                name: trimmedName,
                colorKey: colorKey,
                ratioA: ratioA,
                ratioB: ratioB,
                sharedBalanceEnabled: sharedBalanceEnabled,
                personalPaymentEnabled: personalPaymentEnabled,
                isMain: shouldBeMain
            )
            try? pocketStore.addPocket(pocket, in: modelContext)
        case let .edit(existingPocket):
            let updatedPocket = Pocket(
                id: existingPocket.id,
                name: trimmedName,
                colorKey: colorKey,
                icon: existingPocket.icon,
                ratioA: ratioA,
                ratioB: ratioB,
                sharedBalanceEnabled: sharedBalanceEnabled,
                personalPaymentEnabled: personalPaymentEnabled,
                isMain: isMain,
                createdAt: existingPocket.createdAt
            )
            try? pocketStore.updatePocket(updatedPocket, in: modelContext)
        }

        dismiss()
    }

    private func deletePocket() {
        guard case let .edit(existingPocket) = mode else {
            return
        }

        do {
            try pocketStore.softDeletePocket(id: existingPocket.id, in: modelContext)
            try pocketStore.reload(from: modelContext)
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        PocketFormView(mode: .add)
            .environment(PocketStore())
            .modelContainer(for: [PocketRecord.self], inMemory: true)
    }
}
