import Foundation
import Testing
@testable import PairPocket

struct MemberRoleResolverTests {

    private let linkedContext = RelationshipContext(
        isLinked: true,
        coupleId: "couple-1",
        hostUserId: "user-host",
        partnerUserId: "user-partner"
    )

    // MARK: - role(of:in:)

    @Test func unlinkedContext_roleReturnsNil() {
        let result = MemberRoleResolver.role(of: "user-host", in: .standalone)
        #expect(result == nil)
    }

    @Test func hostUserId_returnsHost() {
        let result = MemberRoleResolver.role(of: "user-host", in: linkedContext)
        #expect(result == .host)
    }

    @Test func partnerUserId_returnsPartner() {
        let result = MemberRoleResolver.role(of: "user-partner", in: linkedContext)
        #expect(result == .partner)
    }

    @Test func unknownUserId_returnsNil() {
        let result = MemberRoleResolver.role(of: "user-unknown", in: linkedContext)
        #expect(result == nil)
    }

    // MARK: - userId(for:in:)

    @Test func unlinkedContext_userIdReturnsNil() {
        #expect(MemberRoleResolver.userId(for: .host, in: .standalone) == nil)
        #expect(MemberRoleResolver.userId(for: .partner, in: .standalone) == nil)
    }

    @Test func hostRole_returnsHostUserId() {
        let result = MemberRoleResolver.userId(for: .host, in: linkedContext)
        #expect(result == "user-host")
    }

    @Test func partnerRole_returnsPartnerUserId() {
        let result = MemberRoleResolver.userId(for: .partner, in: linkedContext)
        #expect(result == "user-partner")
    }
}
