import SwiftUI

struct SettingsView: View {
    @AppStorage(MemberPreferenceKeys.bootstrapIsLocalOnlyMode) private var localOnlyBootstrapMode = true
    @AppStorage(MemberPreferenceKeys.currentMemberRole) private var currentMemberRoleRawValue = MemberRole.host.rawValue
    @AppStorage(MemberPreferenceKeys.relationshipIsLinked) private var relationshipIsLinked = false

    private var isLocalOnlyMode: Bool {
        localOnlyBootstrapMode
    }

    private var currentMemberRole: MemberRole {
        MemberRole.fromPersistedRawValue(currentMemberRoleRawValue)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                MemberSettingsSection(
                    isLocalOnlyMode: isLocalOnlyMode,
                    currentMemberRole: currentMemberRole
                )
                iCloudSettingsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iCloudSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("iCloud設定")
                .font(.headline)

            if isLocalOnlyMode {
                Text("現在はローカル専用モードです。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("iCloudを開始する") {
                    if localOnlyBootstrapMode {
                        localOnlyBootstrapMode = false
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(relationshipIsLinked ? "連携済み" : "パートナー待機中")
                        .font(.subheadline.weight(.semibold))
                    Text(relationshipIsLinked ? "パートナーと同期しています。" : "iCloud同期を開始済みです。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if relationshipIsLinked == false {
                    Button("パートナーを招待する") {
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
