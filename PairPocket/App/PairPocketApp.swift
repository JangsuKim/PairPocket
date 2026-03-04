//
//  PairPocketApp.swift
//  PairPocket
//
//  Created by Jangsoo Kim on 2026/03/02.
//

import SwiftUI

@main
struct PairPocketApp: App {
    @State private var expenseStore = ExpenseStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(expenseStore)
        }
    }
}
