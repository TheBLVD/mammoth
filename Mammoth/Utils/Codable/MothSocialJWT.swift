import SwiftJWT
import ArkanaKeys


/// Claims are the embedded payload in a JWT
/// sub: accounts full remote username
struct MammothClaims: Claims {
    let iss: String
    let sub: String
    let gold: Bool
}

private func mothSocialSecretKey() -> Data {
    if CommandLine.arguments.contains("-M_STAGING_SERVER") {
        return ArkanaKeys.Staging().mothSocialSecretKey.data(using: .utf8)!
    } else {
        return ArkanaKeys.Production().mothSocialSecretKey.data(using: .utf8)!
    }
    
}

/// Generate JWT for authorization specificly to Moth.Social for Mammoth related API calls
/// This is NOT the account's instance generated token. Only used with MothClient.
func MothSocialJWT(acct: String) -> String {
    /// Make the JWT
    let jwt = JWT(claims: MammothClaims(iss: "Mammoth", sub: acct, gold: IAPManager.isGoldMember))
    /// Create the signer
    let hsJWTEncoder = JWTEncoder(jwtSigner: JWTSigner.hs256(key: mothSocialSecretKey()))
    do {
       return try hsJWTEncoder.encodeToString(jwt)
    } catch {
        log.error("Failed to encode JWT: \(error)")
        return ""
    }
}


    
    
    

