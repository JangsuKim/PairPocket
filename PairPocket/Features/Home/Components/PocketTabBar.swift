import SwiftUI

struct PocketTabBar: View {
    let pockets: [Pocket]
    let selectedPocket: Pocket?
    let onSelect: (Pocket) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(pockets) { pocket in
                    pocketButton(for: pocket)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
    }

    private func pocketButton(for pocket: Pocket) -> some View {
        let isSelected = selectedPocket?.id == pocket.id
        let pocketColor = pocket.displayColor

        return Button {
            onSelect(pocket)
        } label: {
            HStack(spacing: 6) {
                if let icon = pocket.icon, icon.isEmpty == false {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }

                Text(pocket.name)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? pocketColor : Color.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background {
                PocketTabShape()
                    .fill(isSelected ? Color.white : Color(.systemGray6).opacity(0.92))
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isSelected ? Color.white : Color(.systemGray6).opacity(0.92))
                    .frame(height: isSelected ? 18 : 10)
                    .offset(y: isSelected ? 8 : 5)
                    .padding(.horizontal, isSelected ? 2 : 6)
            }
            .overlay {
                PocketTabShape()
                    .stroke(isSelected ? pocketColor.opacity(0.9) : Color(.separator).opacity(0.7), lineWidth: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isSelected ? Color.white : .clear)
                    .frame(height: 3)
                    .offset(y: 1)
            }
            .shadow(color: isSelected ? pocketColor.opacity(0.12) : .clear, radius: 10, x: 0, y: 4)
            .offset(y: isSelected ? 0 : 10)
            .zIndex(isSelected ? 1 : 0)
        }
        .buttonStyle(.plain)
    }
}

private struct PocketTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 14
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addQuadCurve(
            to: CGPoint(x: radius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: radius),
            control: CGPoint(x: rect.maxX, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    PocketTabBar(
        pockets: [
            Pocket(name: "Main", colorKey: "green", icon: "house", isMain: true),
            Pocket(name: "Travel", colorKey: "orange", icon: "airplane"),
            Pocket(name: "Rent", colorKey: "blue", icon: "building.2")
        ],
        selectedPocket: Pocket(name: "Main", colorKey: "green", icon: "house", isMain: true),
        onSelect: { _ in }
    )
}
