import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Query(sort: \PocketRecord.createdAt, order: .forward) private var pocketRecords: [PocketRecord]
    @Query private var deletedPocketRecords: [DeletedPocketRecord]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PocketStore.self) private var pocketStore

    @State private var selectedPocketID: UUID?
    @State private var selectedDate = Date()
    @State private var selectedCategoryID: UUID = AddExpenseView.defaultCategoryID
    @State private var selectedPaymentSource: PaymentSource = .memberA
    @State private var amountText: String = ""
    @State private var memoText: String = ""
    @State private var saveErrorMessage: String?

    private static let defaultCategoryID = UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!

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
        amountValue > 0 && selectedPocket != nil
    }

    private var deletedPocketIDs: Set<UUID> {
        Set(deletedPocketRecords.map(\.pocketId))
    }

    private var pockets: [Pocket] {
        pocketRecords
            .filter { deletedPocketIDs.contains($0.id) == false }
            .map(\.pocket)
    }

    private var selectedPocket: Pocket? {
        if let selectedPocketID,
           let matchedPocket = pockets.first(where: { $0.id == selectedPocketID }) {
            return matchedPocket
        }

        return pockets.first(where: \.isMain) ?? pockets.first
    }

    private var selectedCategory: ExpenseCategory {
        categories.first(where: { $0.id == selectedCategoryID }) ?? categories[0]
    }

    private var availablePaymentSources: [PaymentSource] {
        guard let selectedPocket else {
            return []
        }

        var sources: [PaymentSource] = []

        if selectedPocket.personalPaymentEnabled {
            sources.append(.memberA)
            sources.append(.memberB)
        }

        if selectedPocket.sharedBalanceEnabled {
            sources.append(.pocket)
        }

        return sources
    }

    private var burdenA: Int {
        amountValue * (selectedPocket?.ratioA ?? 0) / 100
    }

    private var burdenB: Int {
        amountValue - burdenA
    }

    private var selectedPocketColor: Color {
        selectedPocket?.displayColor ?? .accentColor
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                pocketTabs

                if selectedPocket != nil {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker("日付", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)

                        Picker("カテゴリ", selection: $selectedCategoryID) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(selectedPocketColor)

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

                        TextField("メモ", text: $memoText)
                            .textFieldStyle(.roundedBorder)
                    }
                } else {
                    ContentUnavailableView("ポケットがありません", systemImage: "wallet.pass")
                }

                Spacer()

                Button {
                    guard let selectedPocket else {
                        return
                    }

                    let record = ExpenseRecord(
                        pocketId: selectedPocket.id,
                        categoryId: selectedCategory.id,
                        amount: amountValue,
                        date: selectedDate,
                        memo: memoText,
                        paymentSource: selectedPaymentSource,
                        ratioA: selectedPocket.ratioA,
                        ratioB: selectedPocket.ratioB,
                        isSettled: false,
                        settlementId: nil,
                        settledAt: nil
                    )

                    modelContext.insert(record)

                    do {
                        try modelContext.save()
                        dismiss()
                    } catch {
                        modelContext.delete(record)
                        saveErrorMessage = error.localizedDescription
                    }
                } label: {
                    Text("追加")
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
            .padding()
            .navigationTitle("支出入力")
            .onAppear {
                try? pocketStore.loadIfNeeded(from: modelContext)
                syncSelectedPocket()
                syncSelectedPaymentSource()
            }
            .onChange(of: selectedPocketID) { _, _ in
                syncSelectedPaymentSource()
            }
            .onChange(of: deletedPocketRecords.map(\.pocketId)) { _, _ in
                syncSelectedPocket()
                syncSelectedPaymentSource()
            }
            .onChange(of: pocketRecords.map(\.id)) { _, _ in
                syncSelectedPocket()
                syncSelectedPaymentSource()
            }
            .alert("保存に失敗しました", isPresented: saveErrorMessageAlertBinding) {
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
        switch source {
        case .memberA:
            return "A"
        case .memberB:
            return "B"
        case .pocket:
            return "ポケット"
        }
    }

    private func syncSelectedPaymentSource() {
        if availablePaymentSources.contains(selectedPaymentSource) == false {
            selectedPaymentSource = availablePaymentSources.first ?? .memberA
        }
    }

    private func syncSelectedPocket() {
        if let selectedPocketID,
           pockets.contains(where: { $0.id == selectedPocketID }) {
            return
        }

        selectedPocketID = pockets.first(where: \.isMain)?.id ?? pockets.first?.id
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

private struct ExpenseCategory: Identifiable {
    let id: UUID
    let name: String
}

#Preview {
    AddExpenseView()
        .environment(PocketStore())
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self], inMemory: true)
}
