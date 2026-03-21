import SwiftUI
import PhotosUI
import UIKit

struct MemberSettingsSection: View {
    @AppStorage(MemberPreferenceKeys.hostName) private var hostName = MemberRole.host.displayName
    @AppStorage(MemberPreferenceKeys.hostIcon) private var hostIcon = "person.circle.fill"
    @AppStorage(MemberPreferenceKeys.hostPhotoData) private var hostPhotoData = Data()
    @AppStorage(MemberPreferenceKeys.hostUploadedPhotoHistory) private var hostUploadedPhotoHistory = Data()
    @AppStorage(MemberPreferenceKeys.partnerName) private var partnerName = MemberRole.partner.displayName
    @AppStorage(MemberPreferenceKeys.partnerIcon) private var partnerIcon = "person.circle"
    @AppStorage(MemberPreferenceKeys.partnerPhotoData) private var partnerPhotoData = Data()
    @AppStorage(MemberPreferenceKeys.partnerUploadedPhotoHistory) private var partnerUploadedPhotoHistory = Data()
    @State private var editingMember: EditableMember?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var focusedNameMember: EditableMember?
    @State private var pendingUploadedPhotoDeletion: PendingUploadedPhotoDeletion?

    var body: some View {
        relationshipCard
            .sheet(item: $editingMember) { member in
                memberEditSheet(member)
            }
            .task {
                MemberPreferences.migrateLegacyValues()
            }
            .task(id: selectedPhotoItem) {
                guard let selectedPhotoItem, let member = editingMember else {
                    return
                }
                await applyPickedPhoto(from: selectedPhotoItem, to: member)
            }
    }

    private var relationshipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("パートナー設定")
                .font(.headline)

            HStack(alignment: .top, spacing: 12) {
                memberArea(
                    member: .host,
                    name: $hostName,
                    icon: $hostIcon
                )

                linkingArea

                memberArea(
                    member: .partner,
                    name: $partnerName,
                    icon: $partnerIcon
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
                    editButtonIcon(size: 18)
                }
                .buttonStyle(.plain)
            }

            MemberProfileView(
                role: memberRole(for: member),
                name: name.wrappedValue,
                iconSystemName: icon.wrappedValue,
                photoData: memberPhotoDataBinding(for: member).wrappedValue.isEmpty ? nil : memberPhotoDataBinding(for: member).wrappedValue,
                avatarSize: 76,
                showsRoleText: true
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func memberEditSheet(_ member: EditableMember) -> some View {
        NavigationStack {
            VStack {
                VStack(spacing: 20) {
                    MemberAvatarView(
                        iconSystemName: memberIconBinding(for: member).wrappedValue,
                        photoData: memberPhotoDataBinding(for: member).wrappedValue.isEmpty ? nil : memberPhotoDataBinding(for: member).wrappedValue,
                        role: memberRole(for: member),
                        size: 104
                    )

                    HStack(spacing: 8) {
                        TextField("名前", text: memberNameBinding(for: member))
                            .textFieldStyle(.plain)
                            .focused($focusedNameMember, equals: member)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )

                        Button {
                            focusedNameMember = member
                        } label: {
                            editButtonIcon(size: 20)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 48, maximum: 48), spacing: 12)],
                            alignment: .leading,
                            spacing: 12
                        ) {
                            ForEach(iconPresetAssetNames, id: \.self) { assetName in
                                Button {
                                    memberIconBinding(for: member).wrappedValue = assetName
                                    memberPhotoDataBinding(for: member).wrappedValue = Data()
                                } label: {
                                    MemberAvatarView(
                                        iconSystemName: assetName,
                                        photoData: nil,
                                        role: memberRole(for: member),
                                        size: 48
                                    )
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                isPresetSelected(assetName: assetName, for: member) ? Color.accentColor : Color.clear,
                                                lineWidth: 2
                                            )
                                    }
                                    .frame(width: 48, height: 48)
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(uploadedPhotoHistory(for: member).indices, id: \.self) { index in
                                let photo = uploadedPhotoHistory(for: member)[index]
                                ZStack(alignment: .topTrailing) {
                                Button {
                                    memberPhotoDataBinding(for: member).wrappedValue = photo
                                } label: {
                                    MemberAvatarView(
                                        iconSystemName: memberIconBinding(for: member).wrappedValue,
                                            photoData: photo,
                                            role: memberRole(for: member),
                                            size: 48
                                        )
                                        .overlay {
                                            Circle()
                                                .strokeBorder(
                                                    isUploadedPhotoSelected(photo, for: member) ? Color.accentColor : Color.clear,
                                                    lineWidth: 2
                                            )
                                    }
                                    .frame(width: 48, height: 48)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    pendingUploadedPhotoDeletion = PendingUploadedPhotoDeletion(
                                        member: member,
                                        index: index
                                    )
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white, .black.opacity(0.6))
                                        .background(Color.clear)
                                }
                                .buttonStyle(.plain)
                                .offset(x: 6, y: -6)
                            }
                            .frame(width: 48, height: 48)
                        }

                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Circle()
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                    Image(systemName: "plus")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 180)

                    Text("アップロード写真は最大\(MemberPreferences.uploadedPhotoHistoryLimit)枚まで保存されます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                .frame(maxWidth: 360)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("\(memberTitle(for: member)) 編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        editingMember = nil
                    }
                }
            }
            .alert(
                "この写真を削除しますか？",
                isPresented: Binding(
                    get: { pendingUploadedPhotoDeletion != nil },
                    set: { isPresented in
                        if isPresented == false {
                            pendingUploadedPhotoDeletion = nil
                        }
                    }
                )
            ) {
                Button("キャンセル", role: .cancel) {
                    pendingUploadedPhotoDeletion = nil
                }
                Button("削除", role: .destructive) {
                    guard let pending = pendingUploadedPhotoDeletion else {
                        return
                    }
                    removeUploadedPhoto(at: pending.index, for: pending.member)
                    pendingUploadedPhotoDeletion = nil
                }
            } message: {
                Text("削除した写真は履歴からも消去されます。")
            }
        }
    }

    private func memberTitle(for member: EditableMember) -> String {
        memberRole(for: member).displayName
    }

    private func memberRole(for member: EditableMember) -> MemberRole {
        switch member {
        case .host:
            return .host
        case .partner:
            return .partner
        }
    }

    private func memberNameBinding(for member: EditableMember) -> Binding<String> {
        switch member {
        case .host:
            return $hostName
        case .partner:
            return $partnerName
        }
    }

    private func memberIconBinding(for member: EditableMember) -> Binding<String> {
        switch member {
        case .host:
            return $hostIcon
        case .partner:
            return $partnerIcon
        }
    }

    private func memberPhotoDataBinding(for member: EditableMember) -> Binding<Data> {
        switch member {
        case .host:
            return $hostPhotoData
        case .partner:
            return $partnerPhotoData
        }
    }

    private var iconPresetAssetNames: [String] {
        [MemberPreferences.defaultMemberIconAssetName] + MemberPreferences.selectableDefaultIconAssetNames
    }

    private func isPresetSelected(assetName: String, for member: EditableMember) -> Bool {
        if memberPhotoDataBinding(for: member).wrappedValue.isEmpty == false {
            return false
        }
        let current = memberIconBinding(for: member).wrappedValue
        let role = memberRole(for: member)
        if case let .asset(selectedAsset) = MemberPreferences.resolvedIconSource(storedIconName: current, for: role) {
            return selectedAsset == assetName
        }
        return false
    }

    private func hasCustomPhoto(for member: EditableMember) -> Bool {
        memberPhotoDataBinding(for: member).wrappedValue.isEmpty == false
    }

    private func memberPhotoData(for member: EditableMember) -> Data? {
        let data = memberPhotoDataBinding(for: member).wrappedValue
        return data.isEmpty ? nil : data
    }

    private func applyPickedPhoto(from item: PhotosPickerItem, to member: EditableMember) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        let resized = resizedImage(image, maxDimension: 1024)
        let encodedData = resized.jpegData(compressionQuality: 0.8) ?? data
        memberPhotoDataBinding(for: member).wrappedValue = encodedData
        MemberPreferences.appendUploadedPhoto(encodedData, for: memberRole(for: member))
        selectedPhotoItem = nil
    }

    private func resizedImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else {
            return image
        }

        let scale = maxDimension / largestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    @ViewBuilder
    private func editButtonIcon(size: CGFloat) -> some View {
        Image("EditButtonIcon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
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

    private func uploadedPhotoHistory(for member: EditableMember) -> [Data] {
        // Touch AppStorage values so SwiftUI refreshes when defaults change.
        _ = hostUploadedPhotoHistory
        _ = partnerUploadedPhotoHistory
        return MemberPreferences.uploadedPhotoHistory(for: memberRole(for: member))
    }

    private func isUploadedPhotoSelected(_ photoData: Data, for member: EditableMember) -> Bool {
        memberPhotoDataBinding(for: member).wrappedValue == photoData
    }

    private func removeUploadedPhoto(at index: Int, for member: EditableMember) {
        let history = uploadedPhotoHistory(for: member)
        guard history.indices.contains(index) else {
            return
        }

        let removingData = history[index]
        MemberPreferences.removeUploadedPhoto(at: index, for: memberRole(for: member))

        if memberPhotoDataBinding(for: member).wrappedValue == removingData {
            memberPhotoDataBinding(for: member).wrappedValue = Data()
            memberIconBinding(for: member).wrappedValue = MemberPreferences.defaultMemberIconAssetName
        }
    }
}

private enum EditableMember: String, Identifiable {
    case host
    case partner

    var id: String { rawValue }
}

private struct PendingUploadedPhotoDeletion {
    let member: EditableMember
    let index: Int
}

#Preview {
    MemberSettingsSection()
}
