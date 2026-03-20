import SwiftUI

struct MemberSettingsSection: View {
    @AppStorage(SettingsStorageKeys.memberAName) private var memberAName = "MemberA"
    @AppStorage(SettingsStorageKeys.memberAIcon) private var memberAIcon = "person.circle.fill"
    @AppStorage(SettingsStorageKeys.memberBName) private var memberBName = "MemberB"
    @AppStorage(SettingsStorageKeys.memberBIcon) private var memberBIcon = "person.circle"
    @State private var editingMember: EditableMember?

    var body: some View {
        relationshipCard
            .sheet(item: $editingMember) { member in
                memberEditSheet(member)
            }
    }

    private var relationshipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("パートナー設定")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                memberArea(
                    member: .memberA,
                    name: $memberAName,
                    icon: $memberAIcon
                )

                linkingArea

                memberArea(
                    member: .memberB,
                    name: $memberBName,
                    icon: $memberBIcon
                )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func memberArea(
        member: EditableMember,
        name: Binding<String>,
        icon: Binding<String>
    ) -> some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    editingMember = member
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
            }

            MemberProfileView(
                role: memberRole(for: member),
                name: name.wrappedValue,
                iconSystemName: icon.wrappedValue,
                avatarSize: 76,
                showsRoleText: true
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func memberEditSheet(_ member: EditableMember) -> some View {
        NavigationStack {
            Form {
                Section("プロフィール") {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.quaternary)
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: memberIconBinding(for: member).wrappedValue)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            Button("アバターを編集 (準備中)") {
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Text("Avatar picker is coming soon.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("名前", text: memberNameBinding(for: member))
                }
            }
            .navigationTitle("\(memberTitle(for: member)) 編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        editingMember = nil
                    }
                }
            }
        }
    }

    private func memberTitle(for member: EditableMember) -> String {
        switch member {
        case .memberA:
            return "自分"
        case .memberB:
            return "パートナー"
        }
    }

    private func memberRole(for member: EditableMember) -> MemberRole {
        switch member {
        case .memberA:
            return .memberA
        case .memberB:
            return .memberB
        }
    }

    private func memberNameBinding(for member: EditableMember) -> Binding<String> {
        switch member {
        case .memberA:
            return $memberAName
        case .memberB:
            return $memberBName
        }
    }

    private func memberIconBinding(for member: EditableMember) -> Binding<String> {
        switch member {
        case .memberA:
            return $memberAIcon
        case .memberB:
            return $memberBIcon
        }
    }

    private var linkingArea: some View {
        VStack(spacing: 8) {
            Image(systemName: "link.badge.plus")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("未連携")
                .font(.footnote.weight(.semibold))
            Text("iCloud sync state")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum EditableMember: String, Identifiable {
    case memberA
    case memberB

    var id: String { rawValue }
}

private enum SettingsStorageKeys {
    static let memberAName = "settings.memberA.name"
    static let memberAIcon = "settings.memberA.icon"
    static let memberBName = "settings.memberB.name"
    static let memberBIcon = "settings.memberB.icon"
}

#Preview {
    MemberSettingsSection()
}
