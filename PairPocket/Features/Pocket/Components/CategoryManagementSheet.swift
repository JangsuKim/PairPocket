import SwiftData
import SwiftUI

struct CategoryManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore

    let pocket: Pocket

    @State private var newCategoryName = ""
    @State private var errorMessage: String?
    @State private var editingCategoryID: UUID?
    @State private var isReordering = false

    private var categories: [Category] {
        categoryStore.categories(for: pocket.id)
    }

    private var activeCategoryCount: Int {
        categories.filter(\.isActive).count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("カテゴリ一覧") {
                    if categories.isEmpty {
                        Text("カテゴリがありません")
                            .foregroundStyle(.secondary)
                    } else if isReordering {
                        ForEach(categories) { category in
                            ReorderableCategoryRow(category: category)
                        }
                        .onMove(perform: moveCategories)
                    } else {
                        ForEach(categories) { category in
                            EditableCategoryRow(
                                category: category,
                                isEditing: editingCategoryID == category.id,
                                isInteractionLocked: editingCategoryID != nil && editingCategoryID != category.id,
                                isStatusToggleDisabled: category.isActive && activeCategoryCount == 1
                            ) { updatedName in
                                do {
                                    try categoryStore.renameCategory(id: category.id, to: updatedName, in: modelContext)
                                    editingCategoryID = nil
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            } onStartEditing: {
                                editingCategoryID = category.id
                            } onCancelEditing: {
                                editingCategoryID = nil
                            } onSetActive: { isActive in
                                do {
                                    try categoryStore.setCategoryActive(id: category.id, isActive: isActive, in: modelContext)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }

                if isReordering == false {
                    Section("カテゴリ追加") {
                        HStack(spacing: 12) {
                            TextField("新しいカテゴリ名", text: $newCategoryName)

                            Button("追加") {
                                do {
                                    _ = try categoryStore.addCategory(
                                        name: newCategoryName,
                                        to: pocket.id,
                                        in: modelContext
                                    )
                                    newCategoryName = ""
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .navigationTitle("カテゴリー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                if categories.isEmpty == false {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isReordering ? "完了" : "並び替え") {
                            withAnimation {
                                isReordering.toggle()
                                editingCategoryID = nil
                                editMode?.wrappedValue = isReordering ? .inactive : .active
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
            .task {
                try? categoryStore.loadIfNeeded(from: modelContext)
                try? categoryStore.reload(from: modelContext)
            }
            .alert("保存に失敗しました", isPresented: errorAlertBinding) {
                Button("確認", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました。")
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = nil
                }
            }
        )
    }

    private func moveCategories(fromOffsets: IndexSet, toOffset: Int) {
        do {
            try categoryStore.moveCategories(
                in: pocket.id,
                fromOffsets: fromOffsets,
                toOffset: toOffset,
                in: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct EditableCategoryRow: View {
    let category: Category
    let isEditing: Bool
    let isInteractionLocked: Bool
    let isStatusToggleDisabled: Bool
    let onSave: (String) -> Void
    let onStartEditing: () -> Void
    let onCancelEditing: () -> Void
    let onSetActive: (Bool) -> Void

    @State private var draftName: String

    init(
        category: Category,
        isEditing: Bool,
        isInteractionLocked: Bool,
        isStatusToggleDisabled: Bool,
        onSave: @escaping (String) -> Void,
        onStartEditing: @escaping () -> Void,
        onCancelEditing: @escaping () -> Void,
        onSetActive: @escaping (Bool) -> Void
    ) {
        self.category = category
        self.isEditing = isEditing
        self.isInteractionLocked = isInteractionLocked
        self.isStatusToggleDisabled = isStatusToggleDisabled
        self.onSave = onSave
        self.onStartEditing = onStartEditing
        self.onCancelEditing = onCancelEditing
        self.onSetActive = onSetActive
        _draftName = State(initialValue: category.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if isEditing {
                    TextField("カテゴリ名", text: $draftName)
                } else {
                    Text(category.name)
                        .foregroundStyle(category.isActive ? .primary : .secondary)
                }
            }

            Spacer()

            if isEditing {
                Button {
                    onSave(draftName)
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderless)
                .disabled(trimmedDraftName.isEmpty || trimmedDraftName == category.name)

                Button {
                    draftName = category.name
                    onCancelEditing()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            } else {
                Button {
                    draftName = category.name
                    onStartEditing()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .disabled(isInteractionLocked)

                Toggle("", isOn: activeBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(isStatusToggleDisabled || isInteractionLocked)
            }
        }
    }

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var activeBinding: Binding<Bool> {
        Binding(
            get: { category.isActive },
            set: { newValue in
                onSetActive(newValue)
            }
        )
    }
}

private struct ReorderableCategoryRow: View {
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .foregroundStyle(category.isActive ? .primary : .secondary)

                if category.isActive == false {
                    Text("非表示")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

