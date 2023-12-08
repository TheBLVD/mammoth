//
//  InstanceData.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 04/11/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class InstanceData: Codable {
    var redirect: String
    var clientID: String
    var clientSecret: String
    var authCode: String
    var accessToken: String
    var returnedText: String
    var instanceText: String
    
    init(clientID: String = "", clientSecret: String = "", authCode: String = "", accessToken: String = "", returnedText: String = "", instanceText: String = "", redirect: String = "") {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.authCode = authCode
        self.accessToken = accessToken
        self.returnedText = returnedText
        self.instanceText = instanceText
        self.redirect = redirect
    }
    
    static func getAllInstances() -> [InstanceData] {
        guard let instaceData = UserDefaults.standard.object(forKey: "instances") as? Data, let instances = try? PropertyListDecoder().decode(Array<InstanceData>.self, from: instaceData) else {
            return [InstanceData]()
        }
        return instances
    }
    
    static func getCurrentInstance() -> InstanceData? {
        guard let instanceData = UserDefaults.standard.data(forKey: "currentInstance"), let instance = try? JSONDecoder().decode(InstanceData.self, from: instanceData) else {
            return nil
        }
        return instance
    }
        
    static func clearInstances() {
        UserDefaults.standard.setValue(nil, forKey: "instances")
    }
}

extension InstanceData: Equatable {
    static func == (lhs: InstanceData, rhs: InstanceData) -> Bool {
        return lhs.accessToken == rhs.accessToken && lhs.authCode == rhs.authCode
    }
}


