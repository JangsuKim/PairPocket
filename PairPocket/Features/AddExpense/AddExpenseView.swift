import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var expenseStore

    @State private var selectedPocketID: Int = 0
    @State private var selectedDate = Date()
    @State private var selectedCategoryID: UUID = AddExpenseView.defaultCategoryID
    @State private var selectedPayer: MemberRole = .me
    @State private var amountText: String = ""
    @State private var memoText: String = ""

    private static let defaultCategoryID = UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!

    private let pockets: [ExpensePocket] = [
        .init(
            id: 0,
            domainId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "生活費",
            color: .green,
            ratioMe: 55,
            ratioPartner: 45
        ),
        .init(
            id: 1,
            domainId: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "旅行",
            color: .orange,
            ratioMe: 50,
            ratioPartner: 50
        ),
        .init(
            id: 2,
            domainId: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "家賃",
            color: .purple,
            ratioMe: 50,
            ratioPartner: 50
        ),
    ]

    private let categories: [ExpenseCategory] = [
        .init(id: UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!, name: "食費"),
        .init(id: UUID(uuidString: "E8F9E3FD-6309-4FA4-B36B-D5CF5B0E56A7")!, name: "生活"),
        .init(id: UUID(uuidString: "5C2EAE9B-349B-40BA-9817-9A0E13CE35F3")!, name: "交通"),
        .init(id: UUID(uuidString: "BFE80144-9D6A-47B0-B4D9-83096E74CF23")!, name: "娯楽"),
        .init(id: UUID(uuidString: "D2D8E4E9-D2A2-4C6A-840B-CCDBF07D82AD")!, name: "その他"),
    ]

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isAddEnabled: Bool {
        amountValue > 0
    }

    private var selectedPocket: ExpensePocket {
        pockets.first(where: { $0.id == selectedPocketID }) ?? pockets[0]
    }

    private var selectedCategory: ExpenseCategory {
        categories.first(where: { $0.id == selectedCategoryID }) ?? categories[0]
    }

    private var burdenA: Int {
        amountValue * selectedPocket.ratioMe / 100
    }

    private var burdenB: Int {
        amountValue - burdenA
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                pocketTabs

                VStack(alignment: .leading, spacing: 14) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Picker("Category", selection: $selectedCategoryID) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(selectedPocket.color)

                    Picker("Payer", selection: $selectedPayer) {
                        Text("A").tag(MemberRole.me)
                        Text("B").tag(MemberRole.partner)
                    }
                    .pickerStyle(.segmented)
                    .tint(selectedPocket.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("0", text: $amountText)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: amountText) { _, newValue in
                                amountText = newValue.filter(\.isNumber)
                            }

                        HStack(spacing: 20) {
                            burdenRow(name: "A", amount: burdenA)
                            burdenRow(name: "B", amount: burdenB)
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

                    TextField("Memo", text: $memoText)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                Button {
                    let newExpense = Expense(
                        id: UUID(),
                        pocketId: selectedPocket.domainId,
                        categoryId: selectedCategory.id,
                        payerRole: selectedPayer,
                        amount: amountValue,
                        ratioMe: selectedPocket.ratioMe,
                        ratioPartner: selectedPocket.ratioPartner,
                        memo: memoText.isEmpty ? nil : memoText,
                        date: selectedDate,
                        isSettled: false,
                        settlementId: nil,
                        settledAt: nil
                    )

                    expenseStore.addExpense(newExpense)
                    dismiss()
                } label: {
                    Text("Add")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(selectedPocket.color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(isAddEnabled ? 1 : 0.45)
                .disabled(!isAddEnabled)
            }
            .padding()
            .navigationTitle("支出入力")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
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
                                    selectedPocketID == pocket.id ? pocket.color.opacity(0.2) : Color.clear
                                )
                            )
                            .foregroundStyle(selectedPocketID == pocket.id ? pocket.color : .primary)
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
}

private struct ExpensePocket: Identifiable {
    let id: Int
    let domainId: UUID
    let name: String
    let color: Color
    let ratioMe: Int
    let ratioPartner: Int
}

private struct ExpenseCategory: Identifiable {
    let id: UUID
    let name: String
}

#Preview {
    AddExpenseView()
        .environment(ExpenseStore())
}
