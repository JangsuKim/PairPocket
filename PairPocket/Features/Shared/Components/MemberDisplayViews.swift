import SwiftUI

struct MemberAvatarView: View {
    let iconSystemName: String
    var size: CGFloat = 34

    var body: some View {
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

struct MemberBadgeView: View {
    let role: MemberRole
    let name: String
    var iconSystemName: String = "person.circle.fill"
    var showsRoleLabel: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            MemberAvatarView(iconSystemName: iconSystemName, size: 24)

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
        switch role {
        case .memberA:
            return "MemberA"
        case .memberB:
            return "MemberB"
        }
    }

    private var roleTitle: String {
        switch role {
        case .memberA:
            return "自分"
        case .memberB:
            return "パートナー"
        }
    }
}

struct MemberProfileView: View {
    let role: MemberRole
    let name: String
    var iconSystemName: String
    var avatarSize: CGFloat = 76
    var nameFont: Font = .subheadline.weight(.semibold)
    var showsRoleText: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            MemberAvatarView(iconSystemName: iconSystemName, size: avatarSize)

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
        switch role {
        case .memberA:
            return "MemberA"
        case .memberB:
            return "MemberB"
        }
    }

    private var roleTitle: String {
        switch role {
        case .memberA:
            return "自分"
        case .memberB:
            return "パートナー"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        MemberBadgeView(role: .memberA, name: "Alex", iconSystemName: "person.circle.fill", showsRoleLabel: true)
        MemberBadgeView(role: .memberB, name: "Jamie", iconSystemName: "person.circle", showsRoleLabel: true)
        MemberProfileView(role: .memberA, name: "Alex", iconSystemName: "person.circle.fill", showsRoleText: true)
        MemberProfileView(role: .memberB, name: "Jamie", iconSystemName: "person.circle", showsRoleText: true)
    }
    .padding()
}
