import SwiftUI

struct PocketTabBar: View {
    let pockets: [Pocket]
    let selectedPocket: Pocket?
    let layout: PocketTabLayout
    let onSelect: (Pocket) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(pockets) { pocket in
                pocketButton(for: pocket)
                    .frame(width: layout.width(for: pocket.id), height: layout.tabHeight)
                    .offset(
                        x: layout.xPosition(for: pocket.id),
                        y: selectedPocket?.id == pocket.id ? 0 : 4
                    )
                    .zIndex(selectedPocket?.id == pocket.id ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: layout.tabHeight, alignment: .leading)
    }

    private func pocketButton(for pocket: Pocket) -> some View {
        let isSelected = selectedPocket?.id == pocket.id
        let pocketColor = pocket.displayColor

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                onSelect(pocket)
            }
        } label: {
            Text(pocket.name)
                .font(.system(size: isSelected ? 15 : 11.5, weight: isSelected ? .semibold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
                .foregroundStyle(isSelected ? pocketColor : pocketColor.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, isSelected ? 10 : 6)
                .contentShape(Rectangle())
                .background {
                    if isSelected == false {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(pocketColor.opacity(0.11))
                            .overlay {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(pocketColor.opacity(0.17), lineWidth: 0.8)
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PocketTabLayout {
    let frames: [UUID: CGRect]
    let tabHeight: CGFloat

    func frame(for pocketID: UUID?) -> CGRect? {
        guard let pocketID else {
            return nil
        }

        return frames[pocketID]
    }

    func width(for pocketID: UUID) -> CGFloat {
        frames[pocketID]?.width ?? 0
    }

    func xPosition(for pocketID: UUID) -> CGFloat {
        frames[pocketID]?.minX ?? 0
    }

    static func make(
        pockets: [Pocket],
        selectedPocketID: UUID?,
        availableWidth: CGFloat
    ) -> PocketTabLayout {
        let tabHeight: CGFloat = 42
        let leadingInset: CGFloat = 22
        let trailingInset: CGFloat = 22
        let spacing: CGFloat = 4
        let count = pockets.count
        let usableWidth = max(availableWidth - leadingInset - trailingInset - (spacing * CGFloat(max(count - 1, 0))), 0)
        let preferredWidths = preferredWidths(for: count)
        let preferredTotal = preferredWidths.selected + (preferredWidths.inactive * CGFloat(max(count - 1, 0)))
        let scale = preferredTotal > usableWidth && preferredTotal > 0 ? usableWidth / preferredTotal : 1
        let selectedWidth = preferredWidths.selected * scale
        let inactiveWidth = preferredWidths.inactive * scale

        var currentX = leadingInset
        var frames: [UUID: CGRect] = [:]

        for pocket in pockets {
            let width = pocket.id == selectedPocketID ? selectedWidth : inactiveWidth
            frames[pocket.id] = CGRect(x: currentX, y: 0, width: width, height: tabHeight)
            currentX += width + spacing
        }

        return PocketTabLayout(frames: frames, tabHeight: tabHeight)
    }

    private static func preferredWidths(for count: Int) -> (selected: CGFloat, inactive: CGFloat) {
        switch count {
        case 1:
            return (136, 0)
        case 2:
            return (132, 110)
        case 3:
            return (124, 76)
        case 4:
            return (114, 64)
        default:
            return (106, 52)
        }
    }
}
