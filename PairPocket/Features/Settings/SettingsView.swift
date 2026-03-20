import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsStorageKeys.memberAName) private var memberAName = "MemberA"
    @AppStorage(SettingsStorageKeys.memberAIcon) private var memberAIcon = "person.circle.fill"
    @AppStorage(SettingsStorageKeys.memberBName) private var memberBName = "MemberB"
    @AppStorage(SettingsStorageKeys.memberBIcon) private var memberBIcon = "person.circle"
    @State private var showingProfileEditor = false

    var body: some View {
        ScrollView {
            relationshipCard
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingProfileEditor) {
            NavigationStack {
                VStack(spacing: 12) {
                    Text("Edit icon and name (coming soon)")
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .navigationTitle("プロフィール編集")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完了") {
                            showingProfileEditor = false
                        }
                    }
                }
            }
        }
    }

    private var relationshipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("パートナー設定")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                memberArea(
                    title: "自分",
                    name: $memberAName,
                    icon: $memberAIcon
                )

                linkingArea

                memberArea(
                    title: "パートナー",
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
        title: String,
        name: Binding<String>,
        icon: Binding<String>
    ) -> some View {
        VStack(spacing: 10) {
            Button {
                showingProfileEditor = true
            } label: {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.quaternary)
                            .frame(width: 76, height: 76)

                        Image(systemName: icon.wrappedValue)
                            .font(.system(size: 34, weight: .regular))
                            .foregroundStyle(.secondary)
                    }

                    Text(name.wrappedValue.isEmpty ? "未設定" : name.wrappedValue)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
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

private enum SettingsStorageKeys {
    static let memberAName = "settings.memberA.name"
    static let memberAIcon = "settings.memberA.icon"
    static let memberBName = "settings.memberB.name"
    static let memberBIcon = "settings.memberB.icon"
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
