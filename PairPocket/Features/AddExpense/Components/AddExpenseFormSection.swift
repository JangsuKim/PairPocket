import SwiftUI

struct AddExpenseFormSection: View {
    let selectedPocket: Pocket?
    let availableEntryTypes: [PocketEntryType]
    let isEditingExpense: Bool
    @Binding var selectedEntryType: PocketEntryType
    @Binding var selectedDate: Date
    let isDepositEntry: Bool
    let selectableCategories: [Category]
    let selectedCategorySelection: Binding<UUID?>
    let selectedPocketColor: Color
    let availablePaymentSources: [PaymentSource]
    @Binding var selectedPaymentSource: PaymentSource
    @Binding var amountText: String
    let burdenA: Int
    let burdenB: Int
    @Binding var memoText: String

    var body: some View {
        if selectedPocket != nil {
            VStack(alignment: .leading, spacing: 14) {
                if availableEntryTypes.count > 1, isEditingExpense == false {
                    Picker("種別", selection: $selectedEntryType) {
                        Text("支出").tag(PocketEntryType.expense)
                        Text("入金").tag(PocketEntryType.deposit)
                    }
                    .pickerStyle(.segmented)
                    .tint(selectedPocketColor)
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
                        Text(source.displayName).tag(source)
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
