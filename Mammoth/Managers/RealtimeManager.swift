//
//  RealtimeManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 08/11/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import Reachability

class RealtimeManager {
    static let shared = RealtimeManager()
    
    enum CallbackData {
        case notification(Notificationt)
        case error(Error?)
    }
    
    typealias Callback = (_ data: CallbackData) -> Void
    
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private let reachability = try? Reachability(hostname: "google.com")
    private var callbacks: [Callback] = []
    private var receivedCallback: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)? = nil
    
    public func prepareForUse() {
        
        self.receivedCallback = { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let event = try JSONDecoder().decode(EventData.self, from: jsonData)
                            if let notification = event.payload {
                                self.callListeners(.notification(notification))
                            }
                        } catch {
                            self.callListeners(.error(error))
                        }
                    }
                default:
                    log.warning("got an unexpected webSocket message; sleeping to prevent a tight loop")
                    sleep(1)
                    break
                }
                break
            case .failure(let error):
                log.error("[websocket error]: \(error)")
                break
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reachabilityChanged),
                                               name: .reachabilityChanged,
                                               object: nil)
        
        try? self.reachability?.startNotifier()
    }

    public func connect() throws {
        guard let _ = AccountsManager.shared.currentAccount as? MastodonAcctData else {
            let error = NSError(domain: "RealtimeManager.connect called with no current account", code: 401)
            log.error("\(error)")
            throw error
        }
        
        let client = AccountsManager.shared.currentAccountClient
        
        guard let accessToken = client.accessToken else {
            let error = NSError(domain: "RealtimeManager.connect called with no access token", code: 401)
            log.error("\(error)")
            throw error
        }
        
        var request = URLRequest(url: URL(string: "wss://\(client.baseHost)/api/v1/streaming?type=subscribe&stream=user:notification&access_token=\(accessToken)")!)
        request.timeoutInterval = 5
        
        session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        webSocket = session?.webSocketTask(with: request)
        self.setListener()
        webSocket?.resume()
    }
    
    public func disconnect() {
        webSocket?.cancel()
        webSocket = nil
    }
    
    public func onEvent(callback: @escaping Callback) {
        DispatchQueue.main.async {
            self.callbacks.append(callback)
        }
    }
    
    public func clearAllListeners() {
        DispatchQueue.main.async {
            self.callbacks = []
        }
    }
    
    // MARK: - Internal methods
    
    private func setListener() {
        if let callback = self.receivedCallback {
            self.webSocket?.receive(completionHandler: callback)
        }
    }
    
    private func callListeners(_ data: CallbackData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.callbacks.forEach({
                $0(data)
            })
        }
    }
    
    @objc private func appDidBecomeActive() {
        if let ws = self.webSocket, [.canceling, .suspended].contains(ws.state) {
            try? self.connect()
        }
        
        self.setListener()
    }
    
    @objc private func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability

        switch reachability.connection {
        case .wifi, .cellular:
            if let ws = self.webSocket, [.canceling, .suspended].contains(ws.state) {
                try? self.connect()
            }
            self.setListener()
        case .unavailable:
            self.disconnect()
        }
    }
}

struct EventData {
    let stream: [String]
    let event: String
    let payload: Notificationt?
    
    enum CodingKeys: String, CodingKey {
        case stream, event, payload
    }
}

extension EventData: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stream = try values.decode([String].self, forKey: .stream)
        event = try values.decode(String.self, forKey: .event)
        
        switch event {
        case "notification":
            let payloadString = try values.decode(String.self, forKey: .payload)
            if let data = payloadString.data(using: .utf8) {
                payload = try JSONDecoder().decode(Notificationt.self, from: data)
            } else {
                log.error("[RealtimeManager] cannot parse payload")
                payload = nil
            }
        default:
            payload = nil
        }
    }
}
