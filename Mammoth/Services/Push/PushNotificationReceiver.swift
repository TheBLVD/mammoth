import Foundation
import Security
import CommonCrypto

let PushNotificationStatesKey = "PushNotificationStates"
let DeprecatedStatesKey = "PushNotificationStateDict"

public struct PushNotificationReceiver: Codable, Equatable, Hashable {
    
	public let privateKeyData: Data
	public let publicKeyData: Data
	public let authentication: Data
}

extension PushNotificationReceiver {
    public init(forDeviceToken deviceToken: String) throws {
        var error: Unmanaged<CFError>?
        
        // Retrieve a previously generated keypair or generate and store a new keypair
        let keypair = try (KeyChainHelper.retrieveKeyPair(forDeviceToken: deviceToken) ?? KeyChainHelper.generateAndStoreKeyPair(forDeviceToken: deviceToken))
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(keypair.privateKey, &error) as Data? else {
            throw PushNotificationReceiverErrorType.extractingPrivateKeyFailed(error?.takeRetainedValue())
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(keypair.publicKey, &error) as Data? else {
            throw PushNotificationReceiverErrorType.extractingPublicKeyFailed(error?.takeRetainedValue())
        }
        
        let authentication = Self.createRandomAuthBytes()

        self.init(
            privateKeyData: privateKeyData,
            publicKeyData: publicKeyData,
            authentication: authentication
        )
    }
    
    @available(*, deprecated)
	public init() throws {
		var error: Unmanaged<CFError>?

		guard let privateKey = SecKeyCreateRandomKey([
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.creatingKeyFailed(error?.takeRetainedValue())
		}

		guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
			throw PushNotificationReceiverErrorType.extractingPrivateKeyFailed(error?.takeRetainedValue())
		}

		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			throw PushNotificationReceiverErrorType.impossible
		}

		guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
			throw PushNotificationReceiverErrorType.extractingPublicKeyFailed(error?.takeRetainedValue())
		}

		var authentication = Data(count: 16)
		try authentication.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
			guard SecRandomCopyBytes(kSecRandomDefault, 16, bytes) == errSecSuccess else {
				throw PushNotificationReceiverErrorType.creatingRandomDataFailed(error?.takeRetainedValue())
			}
		}

		self.init(
			privateKeyData: privateKeyData,
			publicKeyData: publicKeyData,
			authentication: authentication
		)
	}
    
    private static func createRandomAuthBytes() -> Data {
        let byteCount = 16
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!) }
        return bytes
    }
}

extension PushNotificationReceiver {
	func decrypt(payload: Data, salt: Data, serverPublicKeyData: Data) throws -> Data {
		var error: Unmanaged<CFError>?

		guard let privateKey = SecKeyCreateWithData(privateKeyData as CFData,[
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.restoringKeyFailed(error?.takeRetainedValue())
		}

		guard let serverPublicKey = SecKeyCreateWithData(serverPublicKeyData as CFData,[
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.creatingKeyFailed(error?.takeRetainedValue())
		}

		guard let sharedSecret = SecKeyCopyKeyExchangeResult(privateKey, .ecdhKeyExchangeStandard, serverPublicKey, [:] as CFDictionary, &error) as Data? else {
			throw PushNotificationReceiverErrorType.keyExchangedFailed(error?.takeRetainedValue())
		}

		// TODO: These steps are slightly different from aes128gcm
		let secondSaltInfo = "Content-Encoding: auth\0".data(using: .utf8)!
		let secondSalt = deriveKey(firstSalt: authentication, secondSalt: sharedSecret, info: secondSaltInfo, length: 32)

        
        
        
		let keyInfo = info(type: "aesgcm", clientPublicKey: publicKeyData, serverPublicKey: serverPublicKeyData)
		let key = deriveKey(firstSalt: salt, secondSalt: secondSalt, info: keyInfo, length: 16)

		let nonceInfo = info(type: "nonce", clientPublicKey: publicKeyData, serverPublicKey: serverPublicKeyData)
		let nonce = deriveKey(firstSalt: salt, secondSalt: secondSalt, info: nonceInfo, length: 12)

		let gcm = try SwiftGCM(key: key, nonce: nonce, tagSize: 16)
		let clearText = try gcm.decrypt(auth: nil, ciphertext: payload)
        
        log.debug("M_PUSH_NOTIFICATIONS", String(decoding: sharedSecret, as: UTF8.self))
        log.debug("M_PUSH_NOTIFICATIONS", String(decoding: secondSalt, as: UTF8.self))
        log.debug("M_PUSH_NOTIFICATIONS", String(decoding: key, as: UTF8.self))
        log.debug("M_PUSH_NOTIFICATIONS", String(decoding: nonce, as: UTF8.self))
        // log.debug("M_PUSH_NOTIFICATIONS", gcm)
        log.debug("M_PUSH_NOTIFICATIONS", String(decoding: clearText, as: UTF8.self))

		guard clearText.count >= 2 else {
			throw PushNotificationReceiverErrorType.clearTextTooShort
		}

		let paddingLength = Int(clearText[0]) * 256 + Int(clearText[1])
		guard clearText.count >= 2 + paddingLength else {
			throw PushNotificationReceiverErrorType.clearTextTooShort
		}

		let unpadded = clearText.suffix(from: paddingLength + 2)

		return unpadded
	}

	private func deriveKey(firstSalt: Data, secondSalt: Data, info: Data, length: Int) -> Data {
		return firstSalt.withUnsafeBytes { (firstSaltBytes: UnsafePointer<UInt8>) -> Data in
			return secondSalt.withUnsafeBytes { (secondSaltBytes: UnsafePointer<UInt8>) -> Data in
				return info.withUnsafeBytes { (infoBytes: UnsafePointer<UInt8>) -> Data in
					// RFC5869 Extract
					var context = CCHmacContext()
					CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), firstSaltBytes, firstSalt.count)
					CCHmacUpdate(&context, secondSaltBytes, secondSalt.count)

					var hmac: [UInt8] = .init(repeating: 0, count: 32)
					CCHmacFinal(&context, &hmac)

					// RFC5869 Expand
					CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), &hmac, hmac.count)
					CCHmacUpdate(&context, infoBytes, info.count)

					var one: [UInt8] = [1] // Add sequence byte. We only support short keys so this is always just 1.
					CCHmacUpdate(&context, &one, 1)
					CCHmacFinal(&context, &hmac)

                    return Data(hmac.prefix(upTo: length))
				}
			}
		}
	}

	private func info(type: String, clientPublicKey: Data, serverPublicKey: Data) -> Data {
		var info = Data()

		info.append("Content-Encoding: ".data(using: .utf8)!)
		info.append(type.data(using: .utf8)!)
		info.append(0)
		info.append("P-256".data(using: .utf8)!)
		info.append(0)
		info.append(0)
		info.append(65)
		info.append(clientPublicKey)
		info.append(0)
		info.append(65)
		info.append(serverPublicKey)

		return info
	}
    
    
    static func setState(state: PushNotificationState?, for accountID: String) {
        if let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole" ) {
            // Get the state dictionary...
            var stateDict: [String:Data]?
            stateDict = userDefaults.object(forKey: PushNotificationStatesKey) as? [String:Data]
            if stateDict == nil {
                stateDict = [:]
            }
            // If the state is valid, store it in the dictionary
            if let state {
                guard let statedata = try? JSONEncoder().encode(state) else {
                    return
                }
                stateDict![accountID] = statedata
            } else {
                // State is nil; just remove it from the dictionary
                stateDict!.removeValue(forKey: accountID)
            }
            // Store the dictionary
            userDefaults.set(stateDict, forKey: PushNotificationStatesKey)
            userDefaults.synchronize()
            log.debug("\(processID()) " + "Set notification state dict to \(stateDict)")
        }
    }
    
    static func getAllStates() -> [PushNotificationState] {
         if let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole" ) {
             guard let stateDict = userDefaults.object(forKey: PushNotificationStatesKey) as? [String:Data] else {
                 
                 // In version 2.0 we started storing states under a different key.
                 // In the scenario where the app was updated to 2.0 but never launched we keep looking for
                 // states under the old key (as a fallback) to make sure push notifications are correctly decrypted
                 guard let oldStateDict = userDefaults.object(forKey: DeprecatedStatesKey) as? [String:Data] else {
                     log.warning("\(processID()) " + "getAllStates() returning an empty list - no new keys, no old keys")
                     return []
                 }
                 
                 let allStates = Array(oldStateDict.values).compactMap { data in
                     let stateFromData = try? JSONDecoder().decode(PushNotificationState.self, from:data)
                     return stateFromData!
                 }
                 log.warning("\(processID()) " + "getAllStates() returning \(allStates.count) item(s) from OLD settings")
                 return allStates
             }
             let allStates = Array(stateDict.values).compactMap { data in
                 let stateFromData = try? JSONDecoder().decode(PushNotificationState.self, from:data)
                 return stateFromData!
             }
             log.warning("\(processID()) " + "getAllStates() returning \(allStates.count) item(s) from NEW settings")
             return allStates
         }
        log.warning("\(processID()) " + "getAllStates() returning an empty list - no user default found")
        return []
    }
}

// Migration helpers
// In version 2.0 we rewrote the logic that generate keypairs and we started storing states under a different key.
// To prevent conflicting states we run a migration routing when pre-2.0 states are found.
// We force the instance to unsubscribe from push notifications for these accounts are clear the old (deprecated) states from disk.
extension PushNotificationReceiver {
    static func hasDeprecatedState(for accountID: String) -> Bool {
         if let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole" ) {
             guard let stateDict = userDefaults.object(forKey: DeprecatedStatesKey) as? [String:Data] else {
                 return false
             }
             
             if let data = stateDict[accountID] {
                 let obj = try? JSONDecoder().decode(PushNotificationState.self, from: data)
                 return obj != nil
             }
             
        }
        return false
    }
    
    static func clearAllDeprecatedStates() {
         if let userDefaults = UserDefaults(suiteName: "group.com.theblvd.mammoth.wormhole" ) {
             guard let _ = userDefaults.object(forKey: DeprecatedStatesKey) as? [String:Data] else {
                 return
             }
             
             userDefaults.removeObject(forKey: DeprecatedStatesKey)
             userDefaults.synchronize()
        }
    }
}

enum PushNotificationReceiverErrorType: Error {
	case invalidKey
	case impossible
	case creatingKeyFailed(Error?)
	case restoringKeyFailed(Error?)
	case extractingPrivateKeyFailed(Error?)
	case extractingPublicKeyFailed(Error?)
	case creatingRandomDataFailed(Error?)
	case keyExchangedFailed(Error?)
	case clearTextTooShort
    case noReciverSet
}
