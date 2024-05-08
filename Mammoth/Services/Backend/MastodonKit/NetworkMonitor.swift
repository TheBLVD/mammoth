//
//  NetworkMonitor.swift
//  Mammoth
//
//  Created by Riley Howard on 9/5/23.
//

// This class observes rate-limit information in headers, and
// tracks if the user is close to their instance's limit.

// This class observes network calls and looks for a 429
// to signal "rate limiting", and puts up an alert in that case.
//
// If 10 non-rate-limited results arrive in sequence, it's assumed the user
// is no longer blocked, and the state returns to .normal
//
// The reason for looking for many good results in a row is that in this
// stream is a mix of calls to the user's instance, as well as moth.social.
// As a result, a single good response may not be from the rate-limited
// instance.


import UIKit

final class NetworkMonitor {
    
    static let shared = NetworkMonitor()
    private var processingQueue = DispatchQueue(label: "Network Monitor Queue")
#if DEBUG
    private let showAlerts = true
#else
    private let showAlerts = false
#endif

    //
    // For tracking the rate limiting errors
    //
    private let RateLimitError = 429
    private let MinConsecutiveGood = 10 // minimum number of consecutive non-rate limit results
                                // before we consider the pipeline cleared
    enum MonitorState {
        case normal         // Seeing 200 / similar (not 429)
        case rateLimited    // Seeing 429 / rate limiting
    }
    var currentState: MonitorState = .normal {
        didSet {
            if currentState == .rateLimited {
                postRateLimitedAlert()
            }
        }
    }
    private var consecutiveGoodResults: Int = 0
    
    //
    // For checking the response headers
    //
    public var isNearRateLimit = false
    private var rateLimitCheckCounter = 0
    private var lastNearAlertDate: Date? = nil

    //
    // For storing the URLs used in the last 5 minutes
    //
    struct URLLogEntry {
        let URL: URL
        let date: Date
    }
    private var recentURLs: [URLLogEntry] = []
    
    public func logNetworkCall(response: URLResponse?, isMothClient: Bool) {
        // Ignore mothClient calls. These have no effect on the user's
        // instance rate limit.
        guard !isMothClient, let httpURLResponse = (response as? HTTPURLResponse) else {
            return
        }
        
        // Serialize processing these, as this may get called in parallel on various threads
        processingQueue.async {
            // Log the result
            self.trackResult(httpURLResponse)
            
            // Check for possible rate limiting result (429)
            self.updateStateFromResponse(httpURLResponse)
            
            // Check for approaching rate limit once every 10 network calls
            self.rateLimitCheckCounter = self.rateLimitCheckCounter + 1
            if (self.rateLimitCheckCounter % 10) == 0 {
                self.checkRemainingRateLimitFromResponse(httpURLResponse)
            }
        }
    }
}

// MARK: - Keep track of all URLs used in the last 5 minutes
extension NetworkMonitor {
    private func trackResult(_ response: HTTPURLResponse) {
        if let url = response.url {
            // Append the latest response
            let newLogEntry = URLLogEntry(URL: url, date: Date())
            recentURLs.append(newLogEntry)
            // Remove any that are over 5 minutes old
            while recentURLs.first?.date.timeIntervalSinceNow ?? 0 < -(5*60) {
                recentURLs.removeFirst()
            }
        } else {
            log.error("expected URL in response")
        }
    }
}

// MARK: - Keep track of 429 / rate limiting status
extension NetworkMonitor {
    private func updateStateFromResponse(_ response: HTTPURLResponse) {
        let status = response.statusCode

        // For easy testing
//        var status = response.statusCode
//        if rateLimitCheckCounter % 20 == 19 {
//            status = 429
//        }
        
        switch currentState {
            // If in the normal state, transition to
            // "rateLimited" as soon as we hit our first 429
        case .normal:
            if status == RateLimitError {
                log.error("NetworkMonitor: switching to .rateLimited")
                consecutiveGoodResults = 0
                currentState = .rateLimited
            }
            
            // If rateLimited, stay here unless we get at least
            // 10 non-rate limited results in a row.
        case .rateLimited:
            if status == RateLimitError {
                // still rate limited
                consecutiveGoodResults = 0
            } else {
                consecutiveGoodResults += 1
                if consecutiveGoodResults >= MinConsecutiveGood {
                    log.warning("NetworkMonitor: switching to .normal")
                    currentState = .normal
                }
            }
        }
    }
        
    private func postRateLimitedAlert(withEmail: Bool = false) {
        guard showAlerts else {
            log.error("Not showing rate limited alert!")
            return
        }
        if withEmail {
            // Create a string with all the URLs in the last 5 mins
            var recentURLsText = ""
            for logEntry in self.recentURLs {
                recentURLsText += logEntry.date.toString() + " " + logEntry.URL.absoluteString + "\n"
            }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Rate Limit Reached 🛑", message: "Some servers limit how frequently you can get new posts. Try again in 5 minutes. Email logs to feedback@theblvd.app?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler:{ (UIAlertAction) in
                }))
                alert.addAction(UIAlertAction(title: "Email", style: .default , handler:{ (UIAlertAction) in
                    EmailHandler.shared.sendEmail(destination: "feedback@theblvd.app",
                                                  subject: "Rate-limit - Recent URLs",
                                                  body: "Please review the URLs accessed by Mammoth in the last 5 minutes.\n\n\n" + recentURLsText)
                }))
                if let presentingVC = getTopMostViewController() {
                    presentingVC.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Rate Limit Reached", message: "Some servers limit how frequently you can get new posts. Try again in 5 minutes.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                }))
                if let presentingVC = getTopMostViewController() {
                    presentingVC.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

}

// MARK: - Monitor the available rate limit headroom
extension NetworkMonitor {
    // Set isNearRateLimit to true to disable the opportunistic polling
    // if the remaining headroom is low.
    private func checkRemainingRateLimitFromResponse(_ response: HTTPURLResponse) {
        // Figure out the remaining rate limit from the header, if any.
        
        // If it's a media-upload, skip it.
        let isMediaURL = response.url?.absoluteString.contains("/api/v2/media") ?? false
        guard !isMediaURL else {
            log.warning("skipping ratelimit check on media response")
            return
        }
        
        // If it's not present, bail.
        let remainingRateLimitString: String? = response.allHeaderFields["x-ratelimit-remaining"] as? String
        guard remainingRateLimitString != nil else {
            log.warning("no x-ratelimit-remaining header")
            return
        }
        
        let remainingRateLimit = Int(remainingRateLimitString!) ?? 100
        
        // Figure out the total available rate limit. Check the header first,
        // otherwise, go with 100
        var rateLimit = 300
        let rateLimitString = response.allHeaderFields["x-ratelimit-limit"] as? String
        if rateLimitString != nil {
            rateLimit = Int(rateLimitString!) ?? 300
        }
        
        // If the rate limit cap is <50, it's probably during onboarding,
        // and can be safely ignored
        guard rateLimit >= 50 else {
            log.warning("rate limit is less than 50 (\(rateLimit); skipping check")
            return
        }
        
        // Figure out the remaining headroom
        let remainingHeadroomPercent = 100.0 * Double(remainingRateLimit) / Double(rateLimit)
        
        // Consider us near the rate limit if there are < 40 network requests remaining,
        // or there is less than 20% room remaining
        isNearRateLimit = (remainingRateLimit < 40) || (remainingHeadroomPercent < 20.0)

        let logString = String(format: "Rate-limiting headroom: %.2f% (%ld remaining, %ld limit)", remainingHeadroomPercent, remainingRateLimit, rateLimit)
        if isNearRateLimit {
            log.warning(logString)
            postNearRateLimitAlertAsNeeded(remainingRateLimit: remainingRateLimit, rateLimit: rateLimit)
        } else {
            log.debug(logString)
        }
    }
    
    private func postNearRateLimitAlertAsNeeded(remainingRateLimit: Int, rateLimit: Int) {
        // Only post the alert if we haven't posted in the last few minutes
        let showAlert: Bool
        if let timeSinceLastAlert = lastNearAlertDate?.timeIntervalSinceNow {
            showAlert = timeSinceLastAlert < -(3*60)
        } else {
            showAlert = true
        }
        if showAlert {
            lastNearAlertDate = Date()
            postNearRateLimitAlert(remainingRateLimit: remainingRateLimit, rateLimit: rateLimit)
        }
    }
    
    private func postNearRateLimitAlert(remainingRateLimit: Int, rateLimit: Int) {
        guard showAlerts else {
            log.warning("Not showing NEAR rate limited alert!")
            return
        }
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Nearing Rate Limit ⚠️", message: "You are reaching the rate limit for your server. (Services have used \(rateLimit - remainingRateLimit) of the \(rateLimit) alloted network calls in the last 5 minutes). Background network fetches have been disabled temporarily.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            }))
            if let presentingVC = getTopMostViewController() {
                presentingVC.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
