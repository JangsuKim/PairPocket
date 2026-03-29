import SwiftUI

struct AddExpensePrimaryButton: View {
    let title: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(isEnabled ? 1 : 0.45)
        .disabled(!isEnabled)
    }
}

struct AddExpenseDeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text("支出を削除")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.red)
    }
}
