//
//  StoreKitManager.swift
//  Mizan
//
//  StoreKit 2 integration for Pro subscriptions
//

import Foundation
import StoreKit
import SwiftUI
import Combine

// Use typealias to avoid conflict with app's Task model
typealias AsyncTask = _Concurrency.Task

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs - must match App Store Connect
    static let monthlyProductId = "com.mizan.pro.monthly"
    static let annualProductId = "com.mizan.pro.annual"
    static let lifetimeProductId = "com.mizan.pro.lifetime"

    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var updateListenerTask: AsyncTask<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()

        AsyncTask {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Check Pro Status

    var isPro: Bool {
        !purchasedProductIds.isEmpty
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIds = [
                Self.monthlyProductId,
                Self.annualProductId,
                Self.lifetimeProductId
            ]

            products = try await Product.products(for: productIds)
                .sorted { $0.price < $1.price }

            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            errorMessage = "تعذر تحميل الأسعار"
        }

        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                print("✅ Purchase successful: \(product.id)")
                isLoading = false
                return true

            case .userCancelled:
                print("⚠️ User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                print("⏳ Purchase pending")
                isLoading = false
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            errorMessage = "فشل الشراء - حاول مرة أخرى"
            isLoading = false
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Purchases restored")
        } catch {
            print("❌ Restore failed: \(error)")
            errorMessage = "تعذر استعادة المشتريات"
        }

        isLoading = false
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIds = purchased
        print("📦 Active entitlements: \(purchased)")
    }

    // MARK: - Listen for Transactions

    private func listenForTransactions() -> AsyncTask<Void, Error> {
        return AsyncTask.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Methods

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    var monthlyProduct: Product? {
        product(for: Self.monthlyProductId)
    }

    var annualProduct: Product? {
        product(for: Self.annualProductId)
    }

    var lifetimeProduct: Product? {
        product(for: Self.lifetimeProductId)
    }

    // Calculate savings for annual
    var annualSavingsPercent: Int {
        guard let monthly = monthlyProduct, let annual = annualProduct else { return 0 }
        let monthlyYearCost = monthly.price * 12
        let savings = (1 - (annual.price / monthlyYearCost)) * 100
        return NSDecimalNumber(decimal: savings).intValue
    }
}

// MARK: - Errors

enum StoreError: Error {
    case failedVerification
    case productNotFound
}

// MARK: - Product Extension

extension Product {
    var localizedPrice: String {
        displayPrice
    }

    var periodText: String {
        guard let subscription = subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .month:
            return subscription.subscriptionPeriod.value == 1 ? "شهريًا" : "\(subscription.subscriptionPeriod.value) أشهر"
        case .year:
            return subscription.subscriptionPeriod.value == 1 ? "سنويًا" : "\(subscription.subscriptionPeriod.value) سنوات"
        case .week:
            return "أسبوعيًا"
        case .day:
            return "يوميًا"
        @unknown default:
            return ""
        }
    }

    var isLifetime: Bool {
        subscription == nil && type == .nonConsumable
    }
}
