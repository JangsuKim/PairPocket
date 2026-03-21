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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("クイック追加")
                    .font(.headline)

                Spacer()

                if let selectedPocket {
                    Text(selectedPocket.name)
                        .font(.subheadline)
                        .foregroundStyle(selectedPocket.displayColor)
                }
            }

            HStack(spacing: 12) {
                categoryMenu

                TextField("金額", text: $amountText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: amountText) { _, newValue in
                        amountText = newValue.filter(\.isNumber)
                    }
            }

            Button {
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
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task {
            MemberPreferences.migrateLegacyValues()
            try? categoryStore.loadIfNeeded(from: modelContext)
            syncSelectedCategory()
        }
        .onChange(of: selectedPocket?.id) { _, _ in
            syncSelectedCategory()
        }
        .onChange(of: categories.map(\.id)) { _, _ in
            syncSelectedCategory()
        }
        .alert("保存に失敗しました", isPresented: saveErrorAlertBinding) {
            Button("確認", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "不明なエラーが発生しました")
        }
    }

    @ViewBuilder
    private var categoryMenu: some View {
        if categories.isEmpty {
            Text("カテゴリがありません")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
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
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
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
            categoryId: selectedCategory.id,
            paymentSource: currentPaymentSource,
            amount: amountValue,
            ratioA: selectedPocket.hostRatio,
            ratioB: selectedPocket.partnerRatio,
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
            amountText = ""
            selectedCategoryID = categories.first?.id
            saveErrorMessage = nil
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
}

#Preview {
    QuickAddSection(
        selectedPocket: Pocket(name: "Main", colorKey: "green", isMain: true)
    )
}
