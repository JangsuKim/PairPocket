# PairPocket (ペアポケ)

**PairPocket** is an iOS app designed for couples to record shared expenses and complete settlements clearly based on an agreed ratio.

This app is **not a household ledger**.

PairPocket exists for one purpose:

> Record shared expenses and finish settlement clearly.

---

# Concept

Couples often experience these problems when managing shared expenses:

- Hard to remember who paid how much
- Alternating payments creates perceived imbalance
- Settlement becomes emotional

PairPocket solves this using three principles:

```
Data instead of memory
Calculation instead of emotion
Agreed ratio instead of assumption
```

The app does not judge fairness.  
It simply calculates based on a ratio both people agreed on.

---

# Core Concept: Pocket

The main unit in PairPocket is a **Pocket**.

A Pocket represents a shared expense group with its own ratio.

Example

```
Living Pocket   A:B = 6:4
Travel Pocket   A:B = 5:5
Housing Pocket  A:B = 5.5:4.5
```

Each Pocket contains

- name
- color (5 semantic colors: mint, peach, lavender, sky, blush)
- split ratio
- mode

Pocket has two operating modes

```
settlementOnly     Each member pays individually, settle later (後精算)
sharedManagement   Shared pot + individual payments (両方管理)
```

Settlement is calculated **per Pocket**.

Constraints: max 5 active Pockets, one designated as main.

---

# Core Concept: PocketEntry

Each record in a Pocket is a **PocketEntry** (aliased as Expense / Transaction).

```
Entry types:    expense / deposit
Payment source: host / partner / pocket (shared pot)
```

Each entry records

- amount
- per-entry split ratio (inherited from Pocket, overridable)
- category
- payment source (who paid)
- date and memo
- settlement status (isSettled, settlementId, settledAt)
- identity fields (createdByUserId, paidByUserId)

Soft-delete is supported (isDeleted, deletedAt).

---

# Tech Stack

Platform

```
iOS 17+ (SwiftUI)
```

Persistence

```
SwiftData
```

Sync (planned)

```
iCloud + CloudKit Shared Database
```

Infrastructure for iCloud sync is prepared (RelationshipContext, userId fields)  
but not yet active. Requires Apple Developer Program enrollment.

Benefits

- No external server required
- Financial data stays in user's iCloud
- Zero backend infrastructure cost

---

# Architecture

The project follows a **feature-based architecture**.

```
App
 └─ PairPocketApp

Features
 ├─ Home            Dashboard, pocket selector, quick add, monthly summary
 ├─ AddExpense      Create / edit expenses and deposits
 ├─ History         Calendar view, expense list, detail view
 ├─ Pocket          Pocket list, detail (charts), form, category management
 ├─ Settlement      Full settlement workflow (calculate → confirm → execute)
 ├─ Settings        Member settings, role toggle
 └─ Shared          Reusable components, presenters, styles

Domain
 ├─ Models
 │   ├─ Member              MemberRole (host / partner)
 │   ├─ Pocket              PocketMode (settlementOnly / sharedManagement)
 │   ├─ Category
 │   ├─ Expense             PocketEntry, PaymentSource, PocketEntryType
 │   ├─ Settlement          SettlementScope (pocket / total)
 │   ├─ SettlementSummary   Full financial breakdown for display
 │   └─ RelationshipContext iCloud sync identity (planned)
 │
 └─ Services
     ├─ SettlementEngine                Core calculation with rounding bias prevention
     ├─ SettlementCalculator            High-level input → SettlementSummary
     ├─ SettlementExecutor              Marks expenses settled atomically
     ├─ MemberRoleResolver              userId → MemberRole mapping
     ├─ ExpenseIdentityPolicy           Normalize identity fields
     └─ SettlementInterpretationBoundary  PaymentSource → role resolution

Persistence
 ├─ Records (SwiftData @Model)
 │   ├─ ExpenseRecord
 │   ├─ PocketRecord
 │   ├─ CategoryRecord
 │   └─ DeletedPocketRecord
 │
 ├─ Stores (Observable, @MainActor)
 │   ├─ ExpenseStore
 │   ├─ PocketStore
 │   └─ CategoryStore
 │
 └─ Preferences
     └─ MemberPreferences   UserDefaults (member names, icons, photos, role)

Resources
 └─ Assets (colors, icons)
```

Architecture layers

```
UI (Features)
   ↓
Domain (Models / Services)
   ↓
Persistence (SwiftData + UserDefaults)
```

| Layer | Role |
|-----|-----|
| Features | UI and user interaction |
| Domain | Business logic and models |
| Services | Settlement calculation and identity resolution |
| Persistence | SwiftData records, stores, and user preferences |

---

# Key Features

## Implemented

- Pocket-based expense structure with two operating modes
- Expense and deposit entry (create / edit / soft-delete)
- Quick add from home screen
- Payment source tracking (host / partner / shared pot)
- Per-pocket category management (add, rename, reorder, toggle)
- History view (calendar + list with detail)
- Pocket detail with donut chart (by category) and monthly bar chart
- Settlement workflow (calculate → review → confirm → execute)
- Settlement engine with period-level rounding to prevent bias accumulation
- Settled expense protection (blocks edit / delete after settlement)
- Member settings (name, icon, photo with 8-image history)
- Host / partner role toggle per device
- Soft-delete pattern for expenses and pockets
- Max 5 pockets constraint with main pocket designation
- Default pocket and categories bootstrapping (Japanese locale)

## Planned

- iCloud sync via CloudKit (infrastructure ready, pending Apple Developer Program)
- Partner invite and linking flow
- Settlement history (dedicated log view)
- OCR receipt input
- Onboarding flow

---

# Settlement Engine

The settlement engine uses a **period-level rounding strategy**.

```
1. Aggregate proportional share numerators across all unsettled expenses
2. Round once at the period level (not per-expense)
3. Tie-breaking: larger remainder wins → lower payer wins → host wins
```

This prevents accumulating per-transaction rounding bias that would create 1-yen discrepancies over many expenses.

---

# Design Principles

PairPocket follows three UI principles.

```
Input in 3 seconds
Calculation must be clear
Transparency over emotion
```

The goal is to make settlements **simple and objective**.

---

# Project Status

Current stage

```
MVP — single device feature complete
```

Core features are implemented and working on a single device.  
The remaining major milestone is iCloud sync for two-device usage.

Progress (excluding sync): **~85%**

| Area | Status |
|------|--------|
| Expense CRUD | Done |
| Pocket management | Done |
| Settlement workflow | Done |
| History / Calendar | Done |
| Settings | Done |
| Charts | Done |
| iCloud sync | Infrastructure only |
| Partner linking | UI only |
| Settlement history | Not started |
| Onboarding | Not started |

---

PairPocket

**Simple · Fair · Clear**
