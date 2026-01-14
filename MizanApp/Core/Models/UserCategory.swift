//
//  UserCategory.swift
//  Mizan
//
//  SwiftData model for user-customizable task categories
//

import Foundation
import SwiftData

@Model
final class UserCategory {
    // MARK: - Identity
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Core Properties
    var name: String           // English name
    var nameArabic: String?    // Arabic name (optional)
    var icon: String           // SF Symbol name
    var colorHex: String       // Hex color code

    // MARK: - Organization
    var order: Int             // Display order
    var isDefault: Bool        // True for system-generated categories

    // MARK: - Relationships
    @Relationship(deleteRule: .nullify, inverse: \Task.userCategory)
    var tasks: [Task]?

    // MARK: - Initialization
    init(
        name: String,
        nameArabic: String? = nil,
        icon: String,
        colorHex: String,
        order: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.name = name
        self.nameArabic = nameArabic
        self.icon = icon
        self.colorHex = colorHex
        self.order = order
        self.isDefault = isDefault
    }

    // MARK: - Computed Properties

    /// Display name (Arabic if available, otherwise English)
    var displayName: String {
        nameArabic ?? name
    }

    // MARK: - Methods

    func update(name: String? = nil, nameArabic: String? = nil, icon: String? = nil, colorHex: String? = nil) {
        if let name = name {
            self.name = name
        }
        if let nameArabic = nameArabic {
            self.nameArabic = nameArabic
        }
        if let icon = icon {
            self.icon = icon
        }
        if let colorHex = colorHex {
            self.colorHex = colorHex
        }
        self.updatedAt = Date()
    }
}

// MARK: - Default Categories Factory

extension UserCategory {
    /// Creates default categories based on the existing TaskCategory enum
    static func createDefaultCategories() -> [UserCategory] {
        return [
            UserCategory(
                name: "Work",
                nameArabic: "عمل",
                icon: "briefcase.fill",
                colorHex: "#3B82F6",
                order: 0,
                isDefault: true
            ),
            UserCategory(
                name: "Personal",
                nameArabic: "شخصي",
                icon: "house.fill",
                colorHex: "#10B981",
                order: 1,
                isDefault: true
            ),
            UserCategory(
                name: "Study",
                nameArabic: "دراسة",
                icon: "book.fill",
                colorHex: "#8B5CF6",
                order: 2,
                isDefault: true
            ),
            UserCategory(
                name: "Health",
                nameArabic: "صحة",
                icon: "heart.fill",
                colorHex: "#EF4444",
                order: 3,
                isDefault: true
            ),
            UserCategory(
                name: "Social",
                nameArabic: "اجتماعي",
                icon: "person.2.fill",
                colorHex: "#F59E0B",
                order: 4,
                isDefault: true
            ),
            UserCategory(
                name: "Worship",
                nameArabic: "عبادة",
                icon: "moon.stars.fill",
                colorHex: "#6366F1",
                order: 5,
                isDefault: true
            )
        ]
    }

    /// Maps old TaskCategory enum to UserCategory name for migration
    static func nameForLegacyCategory(_ category: TaskCategory) -> String {
        switch category {
        case .work: return "Work"
        case .personal: return "Personal"
        case .study: return "Study"
        case .health: return "Health"
        case .social: return "Social"
        case .worship: return "Worship"
        }
    }
}

// MARK: - Suggested Icons

extension UserCategory {
    /// Common SF Symbols for category selection
    static let suggestedIcons: [String] = [
        // Work & Productivity
        "briefcase.fill",
        "doc.text.fill",
        "folder.fill",
        "laptopcomputer",
        "desktopcomputer",
        "chart.bar.fill",
        "building.2.fill",

        // Personal & Home
        "house.fill",
        "bed.double.fill",
        "sofa.fill",
        "car.fill",
        "cart.fill",

        // Education & Learning
        "book.fill",
        "graduationcap.fill",
        "pencil",
        "books.vertical.fill",
        "brain.head.profile",

        // Health & Wellness
        "heart.fill",
        "figure.walk",
        "figure.run",
        "dumbbell.fill",
        "apple.logo",
        "cross.case.fill",

        // Social & Communication
        "person.2.fill",
        "person.3.fill",
        "bubble.left.and.bubble.right.fill",
        "phone.fill",
        "video.fill",

        // Worship & Spirituality
        "moon.stars.fill",
        "moon.fill",
        "sun.max.fill",
        "star.fill",
        "sparkles",

        // Hobbies & Entertainment
        "gamecontroller.fill",
        "music.note",
        "paintbrush.fill",
        "camera.fill",
        "film.fill",
        "sportscourt.fill",

        // Finance & Shopping
        "dollarsign.circle.fill",
        "creditcard.fill",
        "banknote.fill",
        "bag.fill",

        // Travel & Transport
        "airplane",
        "ferry.fill",
        "tram.fill",
        "bicycle",

        // Technology
        "iphone",
        "applewatch",
        "headphones",
        "wifi",

        // Nature & Environment
        "leaf.fill",
        "tree.fill",
        "drop.fill",
        "flame.fill",

        // Time & Calendar
        "clock.fill",
        "calendar",
        "alarm.fill",
        "timer",

        // Misc
        "tag.fill",
        "flag.fill",
        "bolt.fill",
        "lightbulb.fill",
        "wrench.fill",
        "hammer.fill"
    ]
}
