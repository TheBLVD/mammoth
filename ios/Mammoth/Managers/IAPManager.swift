//
//  IAPManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 29/11/2023.
//

import UIKit
import StoreKit
import ArkanaKeys

public let didUpdatePurchaseStatus = Notification.Name("didUpdatePurchaseStatus")

class IAPManager: NSObject {
    static let shared = IAPManager()
    
    static let GOLD_MONTH_PRODUCT_ID = "com.theblvd.mammoth.gold.monthly"
    static let GOLD_YEAR_PRODUCT_ID = "com.theblvd.mammoth.gold.yearly"
    
    public enum IAPManagerAlertType {
        case disabled
        case restored
        case purchased
        case failed(Error?)
        
        func toString() -> String {
            switch self {
            case .disabled: "disabled"
            case .restored: "restored"
            case .purchased: "purchased"
            case .failed: "failed"
            }
        }
        
        func message() -> String {
            switch self {
            case .disabled: return "Purchases are disabled on your device!"
            case .restored: return "You've successfully restored your purchase!"
            case .purchased: return "You've successfully bought this purchase!"
            case .failed: return "Could not complete purchase process.\nPlease try again."
            }
        }
    }

    fileprivate let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"

    fileprivate var appConfiguration: AppConfiguration {
      if isDebug {
        return .Debug
      } else if isTestFlight {
        return .TestFlight
      } else {
        return .AppStore
      }
    }

    fileprivate enum AppConfiguration: String {
      case Debug
      case TestFlight
      case AppStore
    }

    fileprivate var isDebug: Bool {
      #if DEBUG
      return true
      #else
      return false
      #endif
    }

    fileprivate typealias ProductId = String
    
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var pendingFetchProduct: String!
    
    public var iapProducts = [SKProduct]()
    public var purchaseStatusBlock: ((IAPManagerAlertType) -> Void)?
    public var fetchAvailableProductsBlock : (([SKProduct]) -> Void)? = nil {
        didSet {
            if !iapProducts.isEmpty {
                fetchAvailableProductsBlock?(iapProducts)
            }
        }
    }

    public func prepareForUse() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)
        
        fetchAvailableProducts()
        Task {
            await syncLocalPurchaseState()
        }
    }
    
    @objc private func appDidBecomeActive() {
        Task {
            await syncLocalPurchaseState()
        }
    }
    
    private func fetchAvailableProducts() {
        productsRequest.cancel()
        
        let productIdentifiers = NSSet(objects: Self.GOLD_YEAR_PRODUCT_ID, Self.GOLD_MONTH_PRODUCT_ID)
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    public func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }
    
    public func purchaseProduct(productIdentifier: String) {
        if iapProducts.isEmpty {
            pendingFetchProduct = productIdentifier
            fetchAvailableProducts()
            return
        }
        
        if canMakePurchases() {
            for product in iapProducts {
                if product.productIdentifier == productIdentifier {
                    let payment = SKPayment(product: product)
                    SKPaymentQueue.default().add(self)
                    SKPaymentQueue.default().add(payment)
                }
            }
        } else {
            purchaseStatusBlock?(.disabled)
            NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.disabled.toString()])
        }
    }
    
    public func restorePurchase(){
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - Upgrade alert
extension IAPManager {
    
    private var upgradeActionCount: Int {
        if let actionCount = UserDefaults.standard.value(forKey: "upgrade-action-count") as? Int {
            return actionCount
        }
        return 0
    }
    private var shouldShowUpgradeAlert: Bool {
        return self.upgradeActionCount == 3
    }
    
    func showUpgradeAlertIfNeeded() {
        guard !Self.isGoldMember else { return }
        UserDefaults.standard.set(self.upgradeActionCount + 1, forKey: "upgrade-action-count")
        if self.shouldShowUpgradeAlert {
            let alert = UIAlertController(title: "Upgrade to Gold!", message: "Support Mammoth to get custom app icons and priority access to new features.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "No Thanks", style: .default, handler: nil))
            let actionButton = UIAlertAction(title: "Learn More", style: .default, handler: {_ in
                DispatchQueue.main.async {
                    let vc = SettingsViewController(expandUpgradeCell: true)
                    getTopMostViewController()?.present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
                }
            })
            
            actionButton.setValue(UIColor.custom.gold, forKey: "titleTextColor")
            
            alert.addAction(actionButton)
            getTopMostViewController()?.present(alert, animated: true)
        }
    }
}

// MARK: - Local IAP state store access
extension IAPManager {
    public static var isGoldMember: Bool {
        if let purchaseId = self.loadPurchase(), [Self.GOLD_MONTH_PRODUCT_ID, Self.GOLD_YEAR_PRODUCT_ID].contains(purchaseId) {
            return true
        }
        return false
    }
    
    @discardableResult
    private static func storePurchase(purchaseId: String) -> Bool {
        return KeyChainHelper.saveStringToKeychain(service: "com.theblvd.mammoth", key: "mammoth_gold_plan", value: purchaseId)
    }
    
    private static func loadPurchase() -> String? {
        return KeyChainHelper.getStringFromKeychain(service: "com.theblvd.mammoth", key: "mammoth_gold_plan")
    }
    
    private func syncLocalPurchaseState() async {
        if Self.isGoldMember == true {
            let isValidReceipt = await self.isReceiptValid()
            if !isValidReceipt {
                KeyChainHelper.deleteStringFromKeychain(service: "com.theblvd.mammoth", key: "mammoth_gold_plan")
            }
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
    public func productsRequest (_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count > 0 {
            // set the IAP products and make sure yearly is the first item
            iapProducts = response.products.sorted(by: { (left, right) in
                return left.productIdentifier == Self.GOLD_YEAR_PRODUCT_ID
            })
            fetchAvailableProductsBlock?(response.products)
            
            if let product = pendingFetchProduct {
                purchaseProduct(productIdentifier: product)
            }
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        log.error("Error load products: \(error)")
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchasing:
                    break
                case .purchased:
                    // Store purchased productId in KeyChain store
                    Self.storePurchase(purchaseId: trans.payment.productIdentifier)
                    SKPaymentQueue.default().finishTransaction(trans)
                    purchaseStatusBlock?(.purchased)
                    NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.purchased.toString()])
                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    purchaseStatusBlock?(.failed(trans.error))
                    NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.failed(trans.error).toString()])
                case .restored:
                    // Store purchased productId in KeyChain store
                    Self.storePurchase(purchaseId: trans.payment.productIdentifier)
                    SKPaymentQueue.default().finishTransaction(trans)
                    purchaseStatusBlock?(.restored)
                    NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.restored.toString()])
                default: break
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        if canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            return true
        } else {
            return false
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        purchaseStatusBlock?(.failed(error))
        NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.failed(error).toString()])
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction: AnyObject in queue.transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .restored:
                    Self.storePurchase(purchaseId: trans.payment.productIdentifier)
                    SKPaymentQueue.default().finishTransaction(trans)
                    purchaseStatusBlock?(.restored)
                    NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.restored.toString()])
                   return
                default:
                    break
                }
            }
        }
        
        if !Self.isGoldMember {
            let error = NSError(domain: "Restore Failed", code: -1)
            purchaseStatusBlock?(.failed(error))
            NotificationCenter.default.post(name: didUpdatePurchaseStatus, object: self, userInfo: ["status": IAPManagerAlertType.failed(error).toString()])
        }
    }
}

// MARK: - Receipt validation
extension IAPManager {
    // Status code returned by remote server
    public enum ReceiptStatus: Int {
        // Not decodable status
        case unknown = -2
        // No status returned
        case none = -1
        // valid statu
        case valid = 0
        // The App Store could not read the JSON object you provided.
        case jsonNotReadable = 21000
        // The data in the receipt-data property was malformed or missing.
        case malformedOrMissingData = 21002
        // The receipt could not be authenticated.
        case receiptCouldNotBeAuthenticated = 21003
        // The shared secret you provided does not match the shared secret on file for your account.
        case secretNotMatching = 21004
        // The receipt server is not currently available.
        case receiptServerUnavailable = 21005
        // This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response.
        case subscriptionExpired = 21006
        //  This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead.
        case testReceipt = 21007
        // This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead.
        case productionEnvironment = 21008

        var isValid: Bool { return self == .valid}
    }
    
    enum ReceiptValidationResult {
        case success(data: Data)
        case failure(error: Error)
    }
    
    func isReceiptValid() async -> Bool {
        let validationResult = await self.validateReceipt()
        switch validationResult {
        case .success(let data):
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let status = jsonResponse["status"] as? Int {
                    let receiptStatus = ReceiptStatus(rawValue: status) ?? ReceiptStatus.unknown
                    log.debug("Receipt validation with code \(status)")
                    return receiptStatus.isValid
                }
            } else {
                log.error("Failed to parse receipt validation response")
                return false
            }
        case .failure(let error):
            // Server Error (Timeout)
            if (error as NSError).code != -1 {
                return true
            }
            return false
        }
        
        log.debug("Receipt validation without code")
        return false
    }

    var validationURLString: String {
      if appConfiguration != .AppStore { return "https://sandbox.itunes.apple.com/verifyReceipt" }
      return "https://buy.itunes.apple.com/verifyReceipt"
    }

    func validateReceipt() async -> ReceiptValidationResult {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
            return .failure(error: NSError(domain: "Receipt Validation", code: -1, userInfo: [NSLocalizedDescriptionKey: "No receipt found"]))
        }

        do {
            let receiptData = try Data(contentsOf: appStoreReceiptURL)
            let receiptString = receiptData.base64EncodedString()

            let receiptDictionary = ["receipt-data": receiptString, "password": ArkanaKeys.Global().iAPVerificationSecret]

            guard let requestData = try? JSONSerialization.data(withJSONObject: receiptDictionary) else {
                return .failure(error: NSError(domain: "Receipt Validation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid receipt format"]))
            }

            var request = URLRequest(url: URL(string: validationURLString)!)
            request.httpMethod = "POST"
            request.httpBody = requestData

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    return .success(data: data)
                }
            } catch {
                log.debug("Error validating receipt with production: \(error.localizedDescription)")
                return .failure(error: error)
            }

            return .failure(error: NSError(domain: "Receipt Validation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to validate receipt"]))
        } catch {
            return .failure(error: error)
        }
    }
}

