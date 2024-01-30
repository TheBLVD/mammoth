//
//  AcctDataViewModel.swift
//  Mammoth
//
//  Created by Riley Howard on 7/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

protocol AcctDataViewModel {
    var fullAcct: String { get }    // foo@bar.social
    var avatar: String { get }      // URL to the user's avatar
    var remoteFullOriginalAcct: String { get } // MaMmoth@moth.social
}


extension MastodonAcctData: AcctDataViewModel {
    
    var fullAcct: String {
        return account.fullAcct
    }
    
    var avatar: String {
        return account.avatar
    }
    
    var remoteFullOriginalAcct: String {
        return account.remoteFullOriginalAcct
    }

    
}

extension BlueskyAcctData: AcctDataViewModel {
    

    var fullAcct: String { handle }
    var remoteFullOriginalAcct: String {""} // Placeholder to conform to protocol
    var mothSocialJWT: String { "" } // Placeholder to conform to protocol
        
}
