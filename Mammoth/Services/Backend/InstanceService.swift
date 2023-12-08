//
//  InstanceService.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/06/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import ArkanaKeys

struct InstanceService {
    
    static func serverConstants() async throws -> serverConstants {
        let request = Instances.serverConstants()
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func customEmojis() async throws -> [Emoji] {
        let request = Instances.customEmojis()
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func instanceDetails() async throws -> Instance {
        let request = Instances.current()
        let result = try await ClientService.runRequest(request: request)
        return result
    }
    
    static func allInstances() async -> [tagInstance] {
        // Make the network request to get the instances
        let urlStr = "https://feature.\(GlobalHostServer())/api/v1/instances/list"
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        do {
            let result = try await session.data(for: request)
            let data = result.0
            let json = try JSONDecoder().decode(tagInstances.self, from: data)
            let allInstancesFromNetwork =  json.instances.sorted(by: { x, y in
                Int(x.users ?? "0") ?? 0 > Int(y.users ?? "0") ?? 0
            })
            return allInstancesFromNetwork
        } catch {
            log.error("err creating the list of instances - \(error)")
            return []
        }
    }
    
    static func searchForInstances(query: String) async -> [tagInstance] {
        // Make the network request to get the instances
        let urlStr = "https://feature.\(GlobalHostServer())/api/v1/instances/search"
        let url: URL = URL(string: urlStr)!
        var request = URLRequest(url: url)
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "count", value: "50"), URLQueryItem(name: "q", value: query)]
        request.url = components.url
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        do {
            let result = try await session.data(for: request)
            let data = result.0
            let json = try JSONDecoder().decode(tagInstances.self, from: data)
            let allInstancesFromNetwork =  json.instances.sorted(by: { x, y in
                Int(x.users ?? "0") ?? 0 > Int(y.users ?? "0") ?? 0
            })
            return allInstancesFromNetwork
        } catch {
            log.error("err creating the list of instances - \(error)")
            return []
        }
    }

    static func trendingTags() async throws -> [Tag] {
        let request = TrendingTags.trendingTags()
        let result = try await ClientService.runRequest(request: request)
        return result
    }

}
