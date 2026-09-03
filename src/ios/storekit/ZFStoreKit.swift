// StoreKit 2 implementation for the Zombie Fire iOS plugin.
//
// Everything Apple-facing lives here; the Objective-C++ layer only forwards to
// Godot signals. Two rules this file keeps:
//   1. Entitlements are never inferred from a single transaction. The plugin
//      always reports Transaction.currentEntitlements, which the OS verifies and
//      which drops refunded, revoked and expired purchases on its own.
//   2. Every callback is delivered on the main thread, because the Godot side
//      emits signals that reach GDScript and the scene tree.

import Foundation
import StoreKit

@objc public protocol ZFStoreKitDelegate: AnyObject {
    func productsLoaded(_ products: [[String: String]])
    func transactionUpdated(_ transaction: [String: String])
    func entitlementsSynced(_ productIds: [String])
    func storeError(_ message: String)
}

@available(iOS 15.0, *)
@objc public final class ZFStoreKit: NSObject {
    @objc public static let shared = ZFStoreKit()

    @objc public weak var delegate: ZFStoreKitDelegate?

    private var productIds: [String] = []
    private var products: [String: Product] = [:]
    private var updatesTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    // MARK: - Entry points called from Objective-C++

    @objc public func initialize(_ ids: [String]) {
        productIds = ids
        // A long-lived listener is required by StoreKit 2: it delivers purchases
        // made outside the app (Ask to Buy approvals, redemptions, purchases
        // started in the App Store) and revocations such as refunds.
        if updatesTask == nil {
            updatesTask = Task.detached(priority: .background) { [weak self] in
                for await update in Transaction.updates {
                    await self?.handle(update, origin: "update")
                }
            }
        }
        Task { await loadProducts() }
    }

    @objc public func purchase(_ productId: String) {
        Task { await performPurchase(productId) }
    }

    @objc public func restore() {
        Task {
            do {
                // Asks the App Store to refresh this device's transactions. It may
                // prompt for the Apple Account password, so it only ever runs from
                // an explicit Restore tap.
                try await AppStore.sync()
                await syncEntitlements()
            } catch {
                await emitError("restore_failed", error.localizedDescription)
            }
        }
    }

    @objc public func refreshEntitlements() {
        Task { await syncEntitlements() }
    }

    // MARK: - Product catalogue

    private func loadProducts() async {
        guard !productIds.isEmpty else { return }
        do {
            let fetched = try await Product.products(for: productIds)
            var payload: [[String: String]] = []
            for product in fetched {
                products[product.id] = product
                payload.append([
                    "product_id": product.id,
                    // displayPrice is already formatted in the storefront's
                    // currency and locale; never build a price string by hand.
                    "price_text": product.displayPrice,
                    "title": product.displayName,
                    "description": product.description,
                ])
            }
            let delivered = payload
            await MainActor.run { [weak self] in
                self?.delegate?.productsLoaded(delivered)
            }
        } catch {
            await emitError("products_failed", error.localizedDescription)
        }
    }

    // MARK: - Purchase

    private func performPurchase(_ productId: String) async {
        var product = products[productId]
        if product == nil {
            product = try? await Product.products(for: [productId]).first
            if let resolved = product {
                products[productId] = resolved
            }
        }
        guard let product else {
            await emitTransaction(productId, "failed", "product_unavailable")
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification, origin: "purchase")
            case .userCancelled:
                await emitTransaction(productId, "cancelled", "user_cancelled")
            case .pending:
                // Ask to Buy and Strong Customer Authentication land here. The
                // purchase may still complete later through Transaction.updates.
                await emitTransaction(productId, "pending", "pending_approval")
            @unknown default:
                await emitTransaction(productId, "failed", "unknown_result")
            }
        } catch {
            await emitTransaction(productId, "failed", error.localizedDescription)
        }
    }

    // MARK: - Verification and entitlements

    private func handle(_ result: VerificationResult<Transaction>, origin: String) async {
        switch result {
        case .verified(let transaction):
            // Finishing is what tells Apple the content was delivered. Our content
            // is unlocked from currentEntitlements, so it is safe to finish here.
            await transaction.finish()
            let state = transaction.revocationDate == nil
                ? (origin == "purchase" ? "purchased" : "restored")
                : "revoked"
            await emitTransaction(transaction.productID, state, origin)
            await syncEntitlements()
        case .unverified(let transaction, let error):
            // A failed signature check is the one case where we must not unlock.
            await emitTransaction(transaction.productID, "failed", "unverified: \(error.localizedDescription)")
        }
    }

    private func syncEntitlements() async {
        var owned: [String] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.revocationDate != nil { continue }
            if let expiry = transaction.expirationDate, expiry < Date() { continue }
            if !owned.contains(transaction.productID) {
                owned.append(transaction.productID)
            }
        }
        let delivered = owned
        await MainActor.run { [weak self] in
            self?.delegate?.entitlementsSynced(delivered)
        }
    }

    // MARK: - Delivery

    private func emitTransaction(_ productId: String, _ state: String, _ message: String) async {
        let payload = ["product_id": productId, "state": state, "message": message]
        await MainActor.run { [weak self] in
            self?.delegate?.transactionUpdated(payload)
        }
    }

    private func emitError(_ code: String, _ message: String) async {
        let text = "\(code): \(message)"
        await MainActor.run { [weak self] in
            self?.delegate?.storeError(text)
        }
    }
}
