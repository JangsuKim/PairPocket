import SwiftUI
import UIKit

struct MemberAvatarView: View {
    let iconSystemName: String
    var photoData: Data? = nil
    var role: MemberRole? = nil
    var size: CGFloat = 34

    var body: some View {
        if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let role {
            switch MemberPreferences.resolvedIconSource(storedIconName: iconSystemName, for: role) {
            case .asset(let assetName):
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            case .system(let systemName):
                Circle()
                    .fill(.quaternary)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: systemName)
                            .font(.system(size: size * 0.46, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
            }
        } else {
            Circle()
                .fill(.quaternary)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: iconSystemName)
                        .font(.system(size: size * 0.46, weight: .regular))
                        .foregroundStyle(.secondary)
                }
        }
    }
}

struct MemberBadgeView: View {
    let role: MemberRole
    let name: String
    var iconSystemName: String = "person.circle.fill"
    var photoData: Data? = nil
    var showsRoleLabel: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            MemberAvatarView(iconSystemName: iconSystemName, photoData: photoData, role: role, size: 24)

            Text(displayName)
                .font(.subheadline.weight(.semibold))

            if showsRoleLabel {
                Text(roleTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }

    private var displayName: String {
        name.isEmpty ? defaultName : name
    }

    private var defaultName: String {
        role.displayName
    }

    private var roleTitle: String {
        role.displayName
    }
}

struct MemberProfileView: View {
    let role: MemberRole
    let name: String
    var iconSystemName: String
    var photoData: Data? = nil
    var avatarSize: CGFloat = 76
    var nameFont: Font = .subheadline.weight(.semibold)
    var showsRoleText: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            MemberAvatarView(iconSystemName: iconSystemName, photoData: photoData, role: role, size: avatarSize)

            Text(displayName)
                .font(nameFont)
                .lineLimit(1)

            if showsRoleText {
                Text(roleTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var displayName: String {
        name.isEmpty ? defaultName : name
    }

    private var defaultName: String {
        role.displayName
    }

    private var roleTitle: String {
        role.displayName
    }
}

#Preview {
    VStack(spacing: 12) {
        MemberBadgeView(role: .host, name: "Alex", iconSystemName: "person.circle.fill", showsRoleLabel: true)
        MemberBadgeView(role: .partner, name: "Jamie", iconSystemName: "person.circle", showsRoleLabel: true)
        MemberProfileView(role: .host, name: "Alex", iconSystemName: "person.circle.fill", showsRoleText: true)
        MemberProfileView(role: .partner, name: "Jamie", iconSystemName: "person.circle", showsRoleText: true)
    }
    .padding()
}
