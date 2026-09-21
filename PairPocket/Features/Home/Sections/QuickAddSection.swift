import SwiftUI
import SwiftData

struct QuickAddSection: View {
    @AppStorage(MemberPreferenceKeys.currentMemberRole) private var currentMemberRoleRawValue = MemberRole.host.rawValue
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(ExpenseStore.self) private var expenseStore

    let selectedPocket: Pocket?

    @State private var amountText: String = ""
    @State private var selectedCategoryID: UUID?
    @State private var saveErrorMessage: String?
    @State private var isShowingSaveSuccessAlert = false
    @State private var saveSuccessSummaryMessage = ""
    @FocusState private var isAmountFieldFocused: Bool

    private let quickAddBackground = Color("QuickAddButter")
    private let quickAddAccent = Color("QuickAddAmber")

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isAddEnabled: Bool {
        selectedPocket != nil && selectedCategory != nil
    }

    private var currentMemberRole: MemberRole {
        MemberRole.fromPersistedRawValue(currentMemberRoleRawValue)
    }

    private var localUserId: String {
        MemberPreferences.ensureLocalUserId()
    }

    private var currentPaymentSource: PaymentSource {
        switch currentMemberRole {
        case .host:
            return .host
        case .partner:
            return .partner
        }
    }

    private var categories: [Category] {
        guard let selectedPocket else {
            return []
        }

        return categoryStore.categories(for: selectedPocket.id).filter(\.isActive)
    }

    private var selectedCategory: Category? {
        guard let selectedCategoryID else {
            return categories.first
        }

        return categories.first(where: { $0.id == selectedCategoryID }) ?? categories.first
    }

    var body: some View {
        let accentColor = selectedPocket?.displayColor ?? .accentColor

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("クイック支出追加")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if let selectedPocket {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)

                        Text(selectedPocket.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.14))
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 12) {
                categoryMenu
                    .tint(accentColor)
                    .frame(maxWidth: .infinity)

                TextField("金額", text: $amountText)
                    .keyboardType(.numberPad)
                    .focused($isAmountFieldFocused)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(.primary)
                    .tint(accentColor)
                    .onChange(of: amountText) { _, newValue in
                        amountText = newValue.filter(\.isNumber)
                    }
                    .frame(maxWidth: .infinity)
            }

            Button {
                isAmountFieldFocused = false
                saveExpense()
            } label: {
                Text("追加")
                    .frame(maxWidth: .infinity)
                    .frame(width: 140, height: 24)
            }
            .buttonStyle(.borderedProminent)
            .tint(selectedPocket?.displayColor ?? .accentColor)
            .disabled(!isAddEnabled)
            .opacity(isAddEnabled ? 1 : 0.45)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            quickAddBackground.opacity(0.82),
                            quickAddBackground.opacity(0.46)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(quickAddAccent.opacity(0.20), lineWidth: 0.9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task {
            try? categoryStore.loadIfNeeded(from: modelContext)
            syncSelectedCategory()
        }
        .onChange(of: selectedPocket?.id) { _, _ in
            syncSelectedCategory()
        }
        .onChange(of: categories.map(\.id)) { _, _ in
            syncSelectedCategory()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDismissToolbarButton {
                    isAmountFieldFocused = false
                }
            }
        }
        .background(saveErrorAlertHost)
        .background(saveSuccessAlertHost)
    }

    @ViewBuilder
    private var categoryMenu: some View {
        if categories.isEmpty {
            Text("カテゴリがありません")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Menu {
                ForEach(categories) { category in
                    Button(category.name) {
                        selectedCategoryID = category.id
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedCategory?.name ?? "カテゴリ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func syncSelectedCategory() {
        guard categories.isEmpty == false else {
            selectedCategoryID = nil
            return
        }

        if let selectedCategoryID,
           categories.contains(where: { $0.id == selectedCategoryID }) {
            return
        }

        selectedCategoryID = categories.first?.id
    }

    private func saveExpense() {
        guard let selectedPocket, let selectedCategory else {
            return
        }

        guard amountValue > 0 else {
            saveErrorMessage = "金額を入力してください。"
            return
        }

        let expense = Expense(
            pocketId: selectedPocket.id,
            type: .expense,
            categoryId: selectedCategory.id,
            paymentSource: currentPaymentSource,
            amount: amountValue,
            ratioHost: selectedPocket.ratioHost,
            ratioPartner: selectedPocket.ratioPartner,
            memo: nil,
            date: Date(),
            isSettled: false,
            settlementId: nil,
            settledAt: nil,
            createdByUserId: localUserId,
            paidByUserId: MemberPreferences.resolvePaidByUserId(
                paymentSource: currentPaymentSource,
                localUserId: localUserId,
                localRole: currentMemberRole
            )
        )

        do {
            try expenseStore.addExpense(expense, in: modelContext)
            saveSuccessSummaryMessage = quickAddSuccessSummary(
                categoryName: selectedCategory.name,
                amount: amountValue,
                paymentSource: currentPaymentSource
            )
            amountText = ""
            selectedCategoryID = categories.first?.id
            saveErrorMessage = nil
            isShowingSaveSuccessAlert = true
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private var saveErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    saveErrorMessage = nil
                }
            }
        )
    }

    @ViewBuilder
    private var saveErrorAlertHost: some View {
        Color.clear
            .tint(.blue)
            .alert("保存に失敗しました", isPresented: saveErrorAlertBinding) {
                Button("確認", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "不明なエラーが発生しました")
            }
    }

    @ViewBuilder
    private var saveSuccessAlertHost: some View {
        Color.clear
            .tint(.blue)
            .alert("支出を追加しました", isPresented: $isShowingSaveSuccessAlert) {
                Button("確認", role: .cancel) {
                    isShowingSaveSuccessAlert = false
                }
            } message: {
                Text(saveSuccessSummaryMessage)
            }
    }

    private func quickAddSuccessSummary(categoryName: String, amount: Int, paymentSource: PaymentSource) -> String {
        let payerName: String
        if let role = paymentSource.memberRole {
            payerName = MemberPreferences.memberDisplayName(for: role)
        } else {
            payerName = paymentSource.displayName
        }

        return """
        カテゴリ: \(categoryName)
        支払者: \(payerName)
        金額: \(formattedYen(amount))
        """
    }

    private func formattedYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}
