//
//  KeyChainHelper.swift
//  Mammoth
//
//  Created by Benoit Nolens on 31/10/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import Security

struct KeyChainHelper {
    
    enum KeychainError: Error {
        case saveFailed
        case deleteFailed
        case accessFailed
        case publicKeyGenerationFailed
    }
    
    static func generateAndStoreKeyPair(forDeviceToken deviceToken: String) throws -> (privateKey: SecKey, publicKey: SecKey) {
        var error: Unmanaged<CFError>?
        
        // Define the private key attribute
        let privateKeyTag = "com.theblvd.mammoth.privateKey.\(deviceToken)"

        let privateKeyAttributes: [CFString: Any] = [
            kSecAttrIsPermanent: true,
            kSecAttrApplicationTag: privateKeyTag
        ]
        
        let keyPairAttributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecPrivateKeyAttrs: privateKeyAttributes
        ]
        
        // Generate the key pair
        guard let privateKey = SecKeyCreateRandomKey(keyPairAttributes as CFDictionary, &error) else {
            throw KeychainError.saveFailed
        }
        
        // Save the private key to the Keychain
        let privateKeyQuery: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: privateKeyTag,
            kSecValueRef: privateKey
        ]
        
        let privateKeyAddStatus = SecItemAdd(privateKeyQuery as CFDictionary, nil)
        
        guard privateKeyAddStatus == errSecSuccess || privateKeyAddStatus == errSecDuplicateItem else {
            throw KeychainError.saveFailed
        }
        
        // Generate the public key based on the private key
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw KeychainError.publicKeyGenerationFailed
        }
        
        return (privateKey: privateKey, publicKey: publicKey)
    }
    
    static func retrieveKeyPair(forDeviceToken deviceToken: String) throws -> (privateKey: SecKey, publicKey: SecKey)? {
        let privateKeyTag = "com.theblvd.mammoth.privateKey.\(deviceToken)"
        let query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: privateKeyTag,
            kSecReturnRef: true
        ]
        
        var privateKey: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &privateKey)
        
        guard status == errSecSuccess, privateKey != nil else {
            return nil
        }
        
        // Generate the public key based on the private key
        guard let publicKey = SecKeyCopyPublicKey(privateKey! as! SecKey) else {
            throw KeychainError.publicKeyGenerationFailed
        }
        
        return (privateKey: privateKey! as! SecKey, publicKey: publicKey)
    }
    
    static func saveStringToKeychain(service: String, key: String, value: String) -> Bool {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // Define the accessibility of the item
            ]

            // Delete any existing item in the keychain with the same service and key
            SecItemDelete(query as CFDictionary)

            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        }
        return false
    }

    static func getStringFromKeychain(service: String, key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    @discardableResult
    static func deleteStringFromKeychain(service: String, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
