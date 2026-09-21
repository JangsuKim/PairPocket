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
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(PocketStore.self) private var pocketStore

    let mode: Mode

    @State private var name: String
    @State private var colorKey: String
    @State private var artwork: PocketArtwork
    @State private var ratioHost: Int
    @State private var pocketMode: PocketMode
    @State private var isMain: Bool
    @State private var validationMessage: String?
    @State private var isShowingDeleteConfirmation = false

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _colorKey = State(initialValue: PocketColorOption.mint.rawValue)
            _artwork = State(initialValue: .home)
            _ratioHost = State(initialValue: 50)
            _pocketMode = State(initialValue: .settlementOnly)
            _isMain = State(initialValue: false)
        case let .edit(pocket):
            _name = State(initialValue: pocket.name)
            _colorKey = State(initialValue: pocket.colorKey)
            _artwork = State(initialValue: pocket.artwork)
            _ratioHost = State(initialValue: pocket.ratioHost)
            _pocketMode = State(initialValue: pocket.mode)
            _isMain = State(initialValue: pocket.isMain)
        }
    }

    private var ratioPartner: Int {
        100 - ratioHost
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var editingPocketID: UUID? {
        if case let .edit(pocket) = mode {
            return pocket.id
        }
        return nil
    }

    private var usedColorKeysByOtherActivePockets: Set<String> {
        Set(
            pocketStore.pockets
                .filter { pocket in
                    pocket.id != editingPocketID
                }
                .map { pocket in
                    normalizedColorKey(pocket.colorKey)
                }
        )
    }

    private var availableColorOptions: [PocketColorOption] {
        PocketColorOption.allCases.filter { option in
            isColorUnavailable(option) == false
        }
    }

    private var colorSelectionBinding: Binding<String> {
        Binding(
            get: { colorKey },
            set: { newValue in
                let normalizedNewValue = normalizedColorKey(newValue)

                guard usedColorKeysByOtherActivePockets.contains(normalizedNewValue) == false else {
                    return
                }

                colorKey = normalizedNewValue
            }
        )
    }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("ポケット名", text: $name)

                colorSelection
            }

            Section("カードイラスト") {
                artworkSelection
            }

            Section("分担比率") {
                Stepper("\(MemberRole.host.displayName) \(ratioHost)%", value: $ratioHost, in: 0...100)
                LabeledContent(MemberRole.partner.displayName) {
                    Text("\(ratioPartner)%")
                }
            }

            Section("ポケットモード") {
                Picker("モード", selection: $pocketMode) {
                    Text(PocketMode.settlementOnly.displayName).tag(PocketMode.settlementOnly)
                    Text(PocketMode.sharedManagement.displayName).tag(PocketMode.sharedManagement)
                }
                .pickerStyle(.segmented)
            }

            Section("役割") {
                Toggle("メインポケットに設定", isOn: $isMain)
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
        .alert("保存できません", isPresented: validationAlertBinding) {
            Button("OK", role: .cancel) {
                validationMessage = nil
            }
        } message: {
            Text(validationMessage ?? "")
        }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("色")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5),
                spacing: 6
            ) {
                ForEach(PocketColorOption.allCases) { option in
                    let unavailable = isColorUnavailable(option)
                    let isSelected = normalizedColorKey(colorKey) == option.rawValue

                    Button {
                        colorSelectionBinding.wrappedValue = option.rawValue
                    } label: {
                        VStack(spacing: 3) {
                            Circle()
                                .fill(unavailable ? Color.gray.opacity(0.55) : option.color)
                                .frame(width: 10, height: 10)

                            Text(option.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(unavailable ? .secondary : .primary)

                            if unavailable {
                                Text("使用中")
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundStyle(.secondary)
                            } else if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? option.color.opacity(0.9) : Color(.separator).opacity(0.5),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                        .clipShape(Capsule())
                        .opacity(unavailable ? 0.6 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(unavailable)
                }
            }
        }
        .onAppear {
            ensureColorSelectionIsAvailable()
        }
    }

    private var artworkSelection: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(PocketArtwork.allCases) { option in
                Button {
                    artwork = option
                } label: {
                    VStack(spacing: 6) {
                        Image(option.assetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(option == artwork ? selectedColor : .secondary)
                            .frame(width: 44, height: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(option == artwork ? selectedColor : Color.clear, lineWidth: 1.5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("カードイラスト: \(option.title)")
                .accessibilityAddTraits(option == artwork ? .isSelected : [])
            }
        }
    }

    private var selectedColor: Color {
        PocketColorOption(rawValue: normalizedColorKey(colorKey))?.color ?? .accentColor
    }

    private var validationAlertBinding: Binding<Bool> {
        Binding(
            get: { validationMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    validationMessage = nil
                }
            }
        )
    }

    private func save() {
        guard trimmedName.isEmpty == false else {
            validationMessage = "ポケット名を入力してください。"
            return
        }

        guard (0...100).contains(ratioHost), (0...100).contains(ratioPartner) else {
            validationMessage = "比率の値が正しくありません。"
            return
        }

        if usedColorKeysByOtherActivePockets.contains(normalizedColorKey(colorKey)) {
            validationMessage = "使用中の色は選択できません。"
            return
        }

        switch mode {
        case .add:
            let shouldBeMain = isMain || pocketStore.pockets.isEmpty
            let pocket = Pocket(
                name: trimmedName,
                colorKey: colorKey,
                icon: artwork.rawValue,
                ratioHost: ratioHost,
                ratioPartner: ratioPartner,
                mode: pocketMode,
                isMain: shouldBeMain
            )
            do {
                try pocketStore.addPocket(
                    pocket,
                    defaultCategoryName: "カテゴリ1",
                    in: modelContext
                )
                try categoryStore.reload(from: modelContext)
            } catch {
                validationMessage = error.localizedDescription
                return
            }
        case let .edit(existingPocket):
            let updatedPocket = Pocket(
                id: existingPocket.id,
                name: trimmedName,
                colorKey: colorKey,
                icon: artwork.rawValue,
                ratioHost: ratioHost,
                ratioPartner: ratioPartner,
                mode: pocketMode,
                isMain: isMain,
                createdAt: existingPocket.createdAt
            )
            do {
                try pocketStore.updatePocket(updatedPocket, in: modelContext)
            } catch {
                validationMessage = error.localizedDescription
                return
            }
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

    private func isColorUnavailable(_ option: PocketColorOption) -> Bool {
        usedColorKeysByOtherActivePockets.contains(option.rawValue)
    }

    private func ensureColorSelectionIsAvailable() {
        let normalizedSelectedColorKey = normalizedColorKey(colorKey)

        if usedColorKeysByOtherActivePockets.contains(normalizedSelectedColorKey) {
            if let firstAvailableColorOption = availableColorOptions.first {
                colorKey = firstAvailableColorOption.rawValue
            }
        }
    }

    private func normalizedColorKey(_ colorKey: String) -> String {
        switch colorKey {
        case "mint":
            return PocketColorOption.mint.rawValue
        case "peach":
            return PocketColorOption.peach.rawValue
        case "lavender":
            return PocketColorOption.lavender.rawValue
        case "sky":
            return PocketColorOption.sky.rawValue
        case "blush":
            return PocketColorOption.blush.rawValue
        default:
            return PocketColorOption.mint.rawValue
        }
    }

}

#Preview {
    NavigationStack {
        PocketFormView(mode: .add)
            .environment(CategoryStore())
            .environment(PocketStore())
            .modelContainer(for: [PocketRecord.self, CategoryRecord.self], inMemory: true)
    }
}
