//
//  PairPocketApp.swift
//  PairPocket
//
//  Created by Jangsoo Kim on 2026/03/02.
//

import SwiftUI
import SwiftData

@main
struct PairPocketApp: App {
    @State private var expenseStore = ExpenseStore()
    @State private var pocketStore = PocketStore()
    @State private var categoryStore = CategoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(expenseStore)
                .environment(pocketStore)
                .environment(categoryStore)
                .task {
                    _ = MemberPreferences.ensureLocalUserId()
                    MemberPreferences.migrateLegacyValues()
                    MemberPreferences.backfillRelationshipContextIfNeeded()
                }
        }
        // SwiftData schema changed. 개발 중에는 시뮬레이터에서 앱 삭제 후 재설치해 저장소를 재생성하세요.
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self, CategoryRecord.self])
    }
}
