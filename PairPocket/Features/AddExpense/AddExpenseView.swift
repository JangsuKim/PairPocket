import SwiftUI
import SwiftData

struct AddExpenseView: View {
    let editingExpense: Expense?
    let onDeleteSuccess: (() -> Void)?

    @AppStorage(MemberPreferenceKeys.currentMemberRole) private var currentMemberRoleRawValue = MemberRole.host.rawValue
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var selectedPocketID: UUID?
    @State private var selectedDate = Date()
    @State private var selectedEntryType: PocketEntryType = .expense
    @State private var selectedCategoryID: UUID?
    @State private var selectedPaymentSource: PaymentSource = .host
    @State private var amountText: String = ""
    @State private var memoText: String = ""
    @State private var operationErrorMessage: String?
    @State private var hasInitializedForm = false
    @State private var showDeleteConfirmation = false

    init(editingExpense: Expense? = nil, onDeleteSuccess: (() -> Void)? = nil) {
        self.editingExpense = editingExpense
        self.onDeleteSuccess = onDeleteSuccess
    }

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var currentMemberRole: MemberRole {
        MemberRole.fromPersistedRawValue(currentMemberRoleRawValue)
    }

    private var isEditingExpense: Bool {
        editingExpense != nil
    }

    private var localUserId: String {
        MemberPreferences.ensureLocalUserId()
    }

    private var isAddEnabled: Bool {
        amountValue > 0 && selectedPocket != nil
    }

    private var isDepositEntry: Bool {
        selectedEntryType == .deposit
    }

    private var submitButtonTitle: String {
        if isEditingExpense {
            return "支出を保存"
        }

        return selectedEntryType == .expense ? "支出を追加" : "入金を追加"
    }

    private var pockets: [Pocket] {
        pocketStore.pockets
    }

    private var selectedPocket: Pocket? {
        if isEditingExpense, let selectedPocketID {
            return pockets.first(where: { $0.id == selectedPocketID })
        }

        if let selectedPocketID,
           let matchedPocket = pockets.first(where: { $0.id == selectedPocketID }) {
            return matchedPocket
        }

        return pockets.first(where: \.isMain) ?? pockets.first
    }

    private var categories: [Category] {
        guard let selectedPocket else {
            return []
        }

        return categoryStore.categories(for: selectedPocket.id)
    }

    private var selectableCategories: [Category] {
        categories.filter(\.isActive)
    }

    private var selectedCategory: Category? {
        guard let selectedCategoryID else {
            return selectableCategories.first
        }

        return selectableCategories.first(where: { $0.id == selectedCategoryID }) ?? selectableCategories.first
    }

    private var selectedCategorySelection: Binding<UUID?> {
        Binding(
            get: {
                guard let selectedCategoryID else {
                    return selectableCategories.first?.id
                }

                return selectableCategories.contains(where: { $0.id == selectedCategoryID })
                    ? selectedCategoryID
                    : selectableCategories.first?.id
            },
            set: { selectedCategoryID = $0 }
        )
    }

    private var availableEntryTypes: [PocketEntryType] {
        guard let selectedPocket else {
            return [.expense]
        }

        switch selectedPocket.mode {
        case .settlementOnly:
            return [.expense]
        case .sharedManagement:
            return [.expense, .deposit]
        }
    }

    private var availablePaymentSources: [PaymentSource] {
        guard let selectedPocket else {
            return []
        }

        if selectedEntryType == .deposit {
            return [.host, .partner]
        }

        switch selectedPocket.mode {
        case .settlementOnly:
            return [.host, .partner]
        case .sharedManagement:
            return [.host, .partner, .pocket]
        }
    }

    private var burdenA: Int {
        amountValue * (selectedPocket?.ratioHost ?? 0) / 100
    }

    private var burdenB: Int {
        amountValue - burdenA
    }

    private var selectedPocketColor: Color {
        selectedPocket?.displayColor ?? .accentColor
    }

    private var pocketIDs: [UUID] {
        pocketStore.pockets.map(\.id)
    }

    private var categoryIDs: [UUID] {
        selectableCategories.map(\.id)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AddExpensePocketTabs(
                    pockets: pockets,
                    selectedPocket: selectedPocket,
                    onSelectPocket: { selectedPocketID = $0 }
                )
                AddExpenseFormSection(
                    selectedPocket: selectedPocket,
                    availableEntryTypes: availableEntryTypes,
                    isEditingExpense: isEditingExpense,
                    selectedEntryType: $selectedEntryType,
                    selectedDate: $selectedDate,
                    isDepositEntry: isDepositEntry,
                    selectableCategories: selectableCategories,
                    selectedCategorySelection: selectedCategorySelection,
                    selectedPocketColor: selectedPocketColor,
                    availablePaymentSources: availablePaymentSources,
                    selectedPaymentSource: $selectedPaymentSource,
                    amountText: $amountText,
                    burdenA: burdenA,
                    burdenB: burdenB,
                    memoText: $memoText
                )

                Spacer()

                AddExpensePrimaryButton(
                    title: submitButtonTitle,
                    color: selectedPocket?.displayColor ?? .gray,
                    isEnabled: isAddEnabled,
                    action: saveEntry
                )

                if canDeleteEditingExpense {
                    AddExpenseDeleteButton(action: {
                        showDeleteConfirmation = true
                    })
                }
            }
            .padding()
            .navigationTitle(navigationTitle)
            .onAppear {
                try? expenseStore.loadIfNeeded(from: modelContext)
                try? pocketStore.loadIfNeeded(from: modelContext)
                try? categoryStore.loadIfNeeded(from: modelContext)
                initializeFormIfNeeded()
            }
            .onChange(of: selectedPocketID) { _, _ in
                if isEditingExpense == false {
                    syncSelectedEntryType()
                }
                syncSelectedCategory()
                syncSelectedPaymentSource()
            }
            .onChange(of: pocketIDs) { _, _ in
                syncSelectedPocket()
                if isEditingExpense == false {
                    syncSelectedEntryType()
                }
                syncSelectedCategory()
                syncSelectedPaymentSource()
            }
            .onChange(of: selectedEntryType) { _, _ in
                syncSelectedCategory()
                syncSelectedPaymentSource()
            }
            .onChange(of: categoryIDs) { _, _ in
                syncSelectedCategory()
            }
            .modifier(
                AddExpenseDialogPresentationModifier(
                    operationErrorMessageAlertBinding: operationErrorMessageAlertBinding,
                    operationErrorMessage: operationErrorMessage,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    onConfirmDelete: deleteExpense,
                    onDismissErrorAlert: { operationErrorMessage = nil }
                )
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var navigationTitle: String {
        if isEditingExpense {
            return "支出編集"
        }

        return selectedEntryType == .expense ? "支出入力" : "入金入力"
    }

    private var canDeleteEditingExpense: Bool {
        if let editingExpense {
            return editingExpense.isSettled == false && editingExpense.isDeleted == false
        }

        return false
    }

    private func syncSelectedPaymentSource() {
        if availablePaymentSources.contains(selectedPaymentSource) == false {
            selectedPaymentSource = availablePaymentSources.first ?? .host
        }
    }

    private func syncSelectedEntryType() {
        if availableEntryTypes.contains(selectedEntryType) == false {
            selectedEntryType = availableEntryTypes.first ?? .expense
        }
    }

    private func syncSelectedPocket() {
        if isEditingExpense {
            return
        }

        if let selectedPocketID,
           pockets.contains(where: { $0.id == selectedPocketID }) {
            return
        }

        selectedPocketID = pockets.first(where: \.isMain)?.id ?? pockets.first?.id
    }

    private func syncSelectedCategory() {
        if isDepositEntry {
            selectedCategoryID = nil
            return
        }

        guard selectableCategories.isEmpty == false else {
            selectedCategoryID = nil
            return
        }

        if let selectedCategoryID,
           selectableCategories.contains(where: { $0.id == selectedCategoryID }) {
            return
        }

        selectedCategoryID = selectableCategories.first?.id
    }

    private func initializeFormIfNeeded() {
        guard hasInitializedForm == false else {
            return
        }

        if let editingExpense {
            selectedPocketID = editingExpense.pocketId
            selectedDate = editingExpense.date
            selectedEntryType = .expense
            selectedCategoryID = editingExpense.categoryId
            selectedPaymentSource = editingExpense.paymentSource
            amountText = editingExpense.amount > 0 ? String(editingExpense.amount) : ""
            memoText = editingExpense.memo ?? ""
        } else {
            syncSelectedPocket()
            syncSelectedEntryType()
            syncSelectedCategory()
            syncSelectedPaymentSource()
        }

        hasInitializedForm = true
    }

    private func saveEntry() {
        if let editingExpense, editingExpense.isDeleted {
            operationErrorMessage = "Deleted expenses cannot be edited."
            return
        }

        guard let selectedPocket else {
            return
        }

        let createdByUserId = editingExpense?.createdByUserId ?? localUserId
        let paidByUserId = MemberPreferences.resolvePaidByUserId(
            paymentSource: selectedPaymentSource,
            localUserId: localUserId,
            localRole: currentMemberRole
        )

        let entry = Expense(
            id: editingExpense?.id ?? UUID(),
            pocketId: selectedPocket.id,
            type: selectedEntryType,
            categoryId: isDepositEntry ? nil : selectedCategory?.id,
            paymentSource: selectedPaymentSource,
            amount: amountValue,
            ratioHost: isDepositEntry ? 0 : selectedPocket.ratioHost,
            ratioPartner: isDepositEntry ? 0 : selectedPocket.ratioPartner,
            memo: memoText,
            date: selectedDate,
            createdAt: editingExpense?.createdAt ?? Date(),
            isSettled: false,
            settlementId: nil,
            settledAt: nil,
            createdByUserId: createdByUserId,
            paidByUserId: paidByUserId
        )

        do {
            if let editingExpense {
                var updatedExpense = entry
                updatedExpense.id = editingExpense.id
                updatedExpense.createdAt = editingExpense.createdAt
                updatedExpense.isSettled = editingExpense.isSettled
                updatedExpense.settlementId = editingExpense.settlementId
                updatedExpense.settledAt = editingExpense.settledAt
                updatedExpense.isDeleted = editingExpense.isDeleted
                updatedExpense.deletedAt = editingExpense.deletedAt
                try expenseStore.updateExpense(updatedExpense, in: modelContext)
            } else if selectedEntryType == .deposit {
                try expenseStore.addDeposit(entry, in: modelContext)
            } else {
                try expenseStore.addExpense(entry, in: modelContext)
            }
            dismiss()
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }

    private func deleteExpense() {
        guard let editingExpense else {
            return
        }

        guard editingExpense.isDeleted == false else {
            operationErrorMessage = "Deleted expenses cannot be deleted."
            return
        }

        do {
            try expenseStore.deleteExpense(id: editingExpense.id, in: modelContext)
            onDeleteSuccess?()
            dismiss()
        } catch {
            operationErrorMessage = error.localizedDescription
        }
    }

    private var operationErrorMessageAlertBinding: Binding<Bool> {
        Binding(
            get: { operationErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    operationErrorMessage = nil
                }
            }
        )
    }
}

private struct AddExpenseDialogPresentationModifier: ViewModifier {
    let operationErrorMessageAlertBinding: Binding<Bool>
    let operationErrorMessage: String?
    @Binding var showDeleteConfirmation: Bool
    let onConfirmDelete: () -> Void
    let onDismissErrorAlert: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("取引の操作に失敗しました", isPresented: operationErrorMessageAlertBinding) {
                Button("確認", role: .cancel) {
                    onDismissErrorAlert()
                }
            } message: {
                Text(operationErrorMessage ?? "不明なエラーが発生しました。")
            }
            .confirmationDialog(
                "この支出を削除しますか？",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("支出を削除", role: .destructive) {
                    onConfirmDelete()
                }
                Button("キャンセル", role: .cancel) {
                }
            } message: {
                Text("この操作は取り消せません。")
            }
    }
}

#Preview {
    AddExpenseView()
        .environment(ExpenseStore())
        .environment(CategoryStore())
        .environment(PocketStore())
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self, CategoryRecord.self], inMemory: true)
}
