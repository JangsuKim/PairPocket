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
- color
- icon
- split ratio

Settlement is calculated **per Pocket**.

---

# Tech Stack

Platform

```
iOS (SwiftUI)
```

Persistence

```
SwiftData
```

Sync

```
iCloud + CloudKit Shared Database
```

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
 ├─ Home
 ├─ AddExpense
 ├─ History
 ├─ Pocket
 └─ Settings

Domain
 ├─ Models
 │   ├─ Member
 │   ├─ Pocket
 │   ├─ Category
 │   ├─ Expense
 │   └─ Settlement
 │
 └─ Services
     └─ SettlementCalculator

Persistence
 ├─ Records
 │   ├─ ExpenseRecord
 │   ├─ PocketRecord
 │   ├─ CategoryRecord
 │   └─ DeletedPocketRecord
 │
 └─ Stores
     └─ SwiftData access layer

Resources
 └─ Assets
```

Architecture layers

```
UI (Features)
   ↓
Domain (Models / Services)
   ↓
Persistence (SwiftData)
```

Responsibilities

| Layer | Role |
|-----|-----|
| Features | UI and user interaction |
| Domain | business logic |
| Persistence | data storage |
| Services | calculation logic |

Settlement calculation is handled by

```
SettlementCalculator
```

---

# Key Features

Current implemented features

- Pocket based expense structure
- Expense quick input
- History view (list / calendar)
- Pocket management
- Settlement calculation logic
- SwiftData persistence

Planned features

- Settlement confirmation flow
- OCR receipt input
- Pocket UX improvements
- Settlement history

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
MVP development
```

Core structure is implemented and the project is focused on completing the settlement workflow.

---

PairPocket

**Simple · Fair · Clear**
