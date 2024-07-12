//
//  Client.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Client: NSObject, ClientType, URLSessionTaskDelegate {
    let baseURL: String
//    let session: URLSession
    //    enum Constant: String {
    //        case sessionID = "com.shi.Mast.bgSession"
    //    }
    var session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: .main)
    }()
    
    var baseHost: String {
        if let url = URL(string: self.baseURL), let host = url.host {
            return host
        }
        return ""
    }
    
    var isMothClient: Bool = false
    
    public var accessToken: String?
    
//    private var observation: NSKeyValueObservation?
//    deinit {
//        observation?.invalidate()
//    }
    
    convenience init(baseURL: String, accessToken: String? = nil, session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil), isMothClient: Bool = false) {
        self.init(baseURL: baseURL, accessToken: accessToken, session: session)
        self.isMothClient = isMothClient
    }
    
    required public init(baseURL: String, accessToken: String? = nil, session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)) {
        self.baseURL = baseURL
        self.session = session
        self.accessToken = accessToken
    }
    
    public func run<Model>(_ request: Request<Model>, completion: @escaping (Result1<Model>) -> Void) {
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard
                let components = URLComponents(baseURL: self.baseURL, request: request),
                let url = components.url
                else {
                    completion(.failure(ClientError.malformedURL))
                    return
            }
            
            // Only send the token to the user's instance
            var accessToken: String? = nil
            let unrestrictedURLPaths = ["/api/v1/accounts/verify_credentials", "/api/v1/accounts"]
            if isMothClient {
                accessToken = self.accessToken
            } else if unrestrictedURLPaths.contains(url.path) {
                accessToken = self.accessToken
            } else {
                let userServer = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.account.server
                let urlServer = url.host
                if userServer != nil, urlServer != nil, userServer == urlServer {
                    accessToken = self.accessToken
                }
            }
            
            let urlRequest = URLRequest(url: url, request: request, accessToken: accessToken)
            let task = self.session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(ClientError.malformedJSON))
                    return
                }
                
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
                else {
                    log.error("error in response/status from: \(url)")
                    let statusCode = (response as? HTTPURLResponse)?.statusCode
                    log.error("error status code: \(statusCode ?? 0)")
                    let mastodonError = try? MastodonError.decode(data: data)
                    let error: ClientError = mastodonError.map { .mastodonError($0.description) } ?? (statusCode != nil ? .networkError(statusCode!) : .genericError)
                    completion(.failure(error))
                    NetworkMonitor.shared.logNetworkCall(response: response, isMothClient: self.isMothClient)
                    return
                }
                
                guard let model = try? Model.decode(data: data) else {
                    completion(.failure(ClientError.invalidModel))
                    return
                }
                
                log.debug("M_NETWORK", "success from: \(url)")
                completion(.success(model, httpResponse.pagination))
                NetworkMonitor.shared.logNetworkCall(response: response, isMothClient: self.isMothClient)
            }
            task.resume()
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        if OtherStruct.isImageUploading {
            OtherStruct.imagePercentage = uploadProgress
            NotificationCenter.default.post(name: Notification.Name(rawValue: "imagePercentage"), object: nil)
        }
    }
}
