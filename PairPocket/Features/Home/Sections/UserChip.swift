import SwiftUI

struct UserChip: View {
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    UserChip(name: "A")
}
