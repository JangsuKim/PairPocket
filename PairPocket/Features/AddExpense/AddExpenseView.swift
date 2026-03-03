import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPocketID: Int = 0
    @State private var selectedDate = Date()
    @State private var selectedCategory: String = "食費"
    @State private var selectedPayer: String = "A"
    @State private var amountText: String = ""
    @State private var memoText: String = ""

    private let pockets: [ExpensePocket] = [
        .init(id: 0, name: "生活費", color: .green),
        .init(id: 1, name: "旅行", color: .orange),
        .init(id: 2, name: "家賃", color: .purple),
    ]

    private let categories: [String] = ["食費", "生活", "交通", "娯楽", "その他"]
    private let payers: [String] = ["A", "B"]

    private let ratioA = 0.55
    private let ratioB = 0.45

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isAddEnabled: Bool {
        amountValue > 0
    }

    private var selectedPocket: ExpensePocket {
        pockets.first(where: { $0.id == selectedPocketID }) ?? pockets[0]
    }

    private var burdenA: Int {
        Int((Double(amountValue) * ratioA).rounded())
    }

    private var burdenB: Int {
        max(0, amountValue - burdenA)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                pocketTabs

                VStack(alignment: .leading, spacing: 14) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(selectedPocket.color)

                    Picker("Payer", selection: $selectedPayer) {
                        ForEach(payers, id: \.self) { payer in
                            Text(payer).tag(payer)
                        }
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
    let name: String
    let color: Color
}

#Preview {
    AddExpenseView()
}
