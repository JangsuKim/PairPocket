import SwiftUI
import SwiftData

struct AddExpenseView: View {
    let editingExpense: Expense?

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
    @State private var saveErrorMessage: String?
    @State private var hasInitializedForm = false

    init(editingExpense: Expense? = nil) {
        self.editingExpense = editingExpense
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
            get: { selectedCategoryID ?? selectableCategories.first?.id },
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
                pocketTabs
                expenseFormContent

                Spacer()

                submitButton
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
            .alert("取引の保存に失敗しました", isPresented: saveErrorMessageAlertBinding) {
                Button("確認", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "不明なエラーが発生しました。")
            }
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

    @ViewBuilder
    private var expenseFormContent: some View {
        if selectedPocket != nil {
            VStack(alignment: .leading, spacing: 14) {
                if availableEntryTypes.count > 1 {
                    if isEditingExpense == false {
                        Picker("種別", selection: $selectedEntryType) {
                            Text("支出").tag(PocketEntryType.expense)
                            Text("入金").tag(PocketEntryType.deposit)
                        }
                        .pickerStyle(.segmented)
                        .tint(selectedPocketColor)
                    }
                }

                DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)

                if isDepositEntry == false {
                    if selectableCategories.isEmpty {
                        Text("このポケットには有効なカテゴリがありません")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("カテゴリ", selection: selectedCategorySelection) {
                            ForEach(selectableCategories) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(selectedPocketColor)
                    }
                }

                Picker("支払元", selection: $selectedPaymentSource) {
                    ForEach(availablePaymentSources, id: \.self) { source in
                        Text(paymentSourceLabel(source)).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .tint(selectedPocketColor)

                VStack(alignment: .leading, spacing: 8) {
                    Text("金額")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("0", text: $amountText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: amountText) { _, newValue in
                            amountText = newValue.filter(\.isNumber)
                        }

                    if isDepositEntry == false {
                        HStack(spacing: 20) {
                            burdenRow(name: MemberRole.host.displayName, amount: burdenA)
                            burdenRow(name: MemberRole.partner.displayName, amount: burdenB)
                        }

                        Button {
                            print("change ratio tapped")
                        } label: {
                            Text("比率を変更")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }

                TextField("メモ", text: $memoText)
                    .textFieldStyle(.roundedBorder)
            }
        } else {
            ContentUnavailableView("ポケットがありません", systemImage: "wallet.pass")
        }
    }

    private var submitButton: some View {
        Button {
            saveEntry()
        } label: {
            Text(submitButtonTitle)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(selectedPocket?.displayColor ?? .gray)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isAddEnabled ? 1 : 0.45)
        .disabled(!isAddEnabled)
    }

    private var pocketTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(pockets) { pocket in
                    Button {
                        selectedPocketID = pocket.id
                    } label: {
                        Text(pocket.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(
                                    selectedPocket?.id == pocket.id ? pocket.displayColor.opacity(0.2) : Color.clear
                                )
                            )
                            .foregroundStyle(selectedPocket?.id == pocket.id ? pocket.displayColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func burdenRow(name: String, amount: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
            Text(name)
            Text(formattedYen(amount))
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func formattedYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }

    private func paymentSourceLabel(_ source: PaymentSource) -> String {
        source.displayName
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
                try expenseStore.updateExpense(updatedExpense, in: modelContext)
            } else if selectedEntryType == .deposit {
                try expenseStore.addDeposit(entry, in: modelContext)
            } else {
                try expenseStore.addExpense(entry, in: modelContext)
            }
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private var saveErrorMessageAlertBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    saveErrorMessage = nil
                }
            }
        )
    }
}

#Preview {
    AddExpenseView()
        .environment(ExpenseStore())
        .environment(CategoryStore())
        .environment(PocketStore())
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self, CategoryRecord.self], inMemory: true)
}
