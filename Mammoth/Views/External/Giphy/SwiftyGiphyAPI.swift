//
//  SwiftyGiphyAPI.swift
//  SwiftyGiphy
//
//  Created by Brendan Lee on 3/9/17.
//  Copyright © 2017 52inc. All rights reserved.
//

import UIKit

public let kGiphyNetworkingErrorDomain = "kGiphyNetworkingErrorDomain"

public typealias GiphyMultipleGIFResponseBlock = (_ error: NSError?, _ response: GiphyMultipleGIFResponse?) -> Void
public typealias GiphySingleGIFResponseBlock = (_ error: NSError?, _ response: GiphySingleGIFResponse?) -> Void
public typealias GiphySimpleSingleGIFResponseBlock = (_ error: NSError?, _ response: GiphySimpleSingleGIFResponse?) -> Void


fileprivate typealias GiphyAPIResponseBlock = (_ error: NSError?, _ response: [String : AnyObject]?) -> Void

fileprivate let kGiphyUnknownResponseError = NSLocalizedString("composer.giphy.error", comment: "")

fileprivate let kGiphyDefaultAPIBase = URL(string: "https://api.giphy.com/v1/gifs/")!
fileprivate let kGiphyDefaultStickerAPIBase = URL(string: "https://api.giphy.com/v1/stickers/")!

public enum SwiftyGiphyAPIContentRating: String {
    
    case y = "y"
    case g = "g"
    case pg = "pg"
    case pg13 = "pg-13"
    case r = "r"
}

public class SwiftyGiphyAPI {

    public static let publicBetaKey = "dc6zaTOxFJmzC"
    
    /// Access the Giphy API through the shared singleton.
    public static let shared: SwiftyGiphyAPI = SwiftyGiphyAPI()
    
    /// Before you can use SwiftyGiphy, you need to set your API key.
    public var apiKey: String? {
        didSet {
            
            if apiKey == SwiftyGiphyAPI.publicBetaKey
            {
                print("****************************************************************************************************************************")
                print("*                                                                                                                          *")
                print("*     IMPORTANT: You seem to be using Giphy's public beta key. Please change this to a production key before shipping.     *")
                print("*     Apply for one here: http://api.giphy.com/submit                                                                      *")
                print("*                                                                                                                          *")
                print("****************************************************************************************************************************")
                print("")
            }
        }
    }
    
    /// This can be overriden to use a custom API base url, in the scenario that you want requests to pass through your own server.
    /// - Note: 
    ///     - Changing this URL will disable the requirement for an API key to be set on SwiftyGiphyAPI. You can still set one if you want, but we allow it to be nil in case you want the API key to live on your server.
    public var giphyAPIBase: URL = kGiphyDefaultAPIBase
    
    /// This can be overriden to use a custom API base url, in the scenario that you want requests to pass through your own server.
    /// - Note:
    ///     - Changing this URL will disable the requirement for an API key to be set on SwiftyGiphyAPI. You can still set one if you want, but we allow it to be nil in case you want the API key to live on your server.
    public var giphyStickerAPIBase: URL = kGiphyDefaultStickerAPIBase

    fileprivate var isUsingDefaultAPIBase: Bool {
        get {
            return giphyAPIBase == kGiphyDefaultAPIBase
        }
    }
    
    fileprivate var isUsingDefaultStickerAPIBase: Bool {
        get {
            return giphyStickerAPIBase == kGiphyDefaultStickerAPIBase
        }
    }
    
    /// This is private, you should use the shared singleton instead of creating your own instance.
    fileprivate init() { }
    
    // MARK: Networking Utilities
    
    /**
     Send a request
     
     - parameter request:    The request to send.
     - parameter completion: The completion block to call when done.
     */
    fileprivate func send(request: URLRequest, completion: GiphyAPIResponseBlock?)
    {
        SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: true)
        
        let APIStartTime = NSDate().timeIntervalSince1970

        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            
            let requestURLString = request.url?.absoluteString
            let requestTime = NSDate().timeIntervalSince1970 - APIStartTime
            
            print("Giphy Request: \(requestURLString!) completed in: \(requestTime)")
            
            // Check for network error
            guard error == nil else {
                
                completion?(error as NSError?, nil)
                SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: false)
                return;
            }
            
            // Check for valid JSON
            guard let
                validData = data,
                let jsonObj = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments),
                let jsonDict = jsonObj as? [String : AnyObject],
                let httpResponse = response as? HTTPURLResponse else {
                    
                    if let validData = data,
                        let jsonObj = try? JSONSerialization.jsonObject(with: validData, options: .allowFragments),
                        let jsonArray = jsonObj as? [[String : AnyObject]]
                    {
                        // Ok, it's a root array. It'll bypass some error checking..but it'll be fine.
                        let response: [String : AnyObject] = ["response" : jsonArray as AnyObject]
                        completion?(nil, response)
                        
                        SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: false)
                        
                        return
                    }
                    
                    let error = NSError(domain: kGiphyNetworkingErrorDomain, code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey : kGiphyUnknownResponseError])
                    
                    completion?(error, nil)
                    
                    SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: false)
                    return;
            }
            
            // Check the network error code
            guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                

                let error = NSError(domain: kGiphyNetworkingErrorDomain, code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey : kGiphyUnknownResponseError
                    ])
                
                completion?(error, jsonDict)
                SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: false)
                return;
            }
            
            // It looks like we have a valid response in the 200 range.
            completion?(nil, jsonDict)
            SwiftyGiphyAPI.setNetworkActivityIndicatorVisible(visible: false)
        }).resume()
    }
    
    
    /// Create a basic network error with a given description.
    ///
    /// - parameter description: The description for the error
    ///
    /// - returns: The created error
    fileprivate func networkError(description: String) -> NSError
    {
        return NSError(domain: kGiphyNetworkingErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : description])
    }
    
    /**
     Create a request.
     
     - parameter relativePath:    The relative path for the request (relative to the Giphy API base)
     - parameter method: The method for the request
     - parameter json:   The object to serialize to JSON (Array or Dictionary)
     
     - returns: The generated request, or nil if a JSON error occurred.
     */
    fileprivate func createRequest(baseURL: URL, relativePath:String, method:String, params: [String : Any]?) -> URLRequest
    {
        var request = URLRequest(url: URL(string: relativePath, relativeTo: baseURL)!)
        
        request.httpMethod = method
        
        if let localparams = params as [String : AnyObject]?
        {
            if method == "GET"
            {
                // GET params
                var queryItems = [URLQueryItem]()
                
                for (key, value) in localparams
                {
                    let stringValue = (value as? String) ?? String(describing: value)

                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                }
                
                var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                
                components.queryItems = queryItems
                
                request.url = components.url
            }
            else
            {
                
                // JSON params
                let jsonData = try? JSONSerialization.data(withJSONObject: localparams, options: JSONSerialization.WritingOptions())
                request.httpBody = jsonData
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        return request
    }
    
    // MARK: Networking Indicator
    
    fileprivate static var NumberOfCallsToSetActivityIndicatorVisible: NSInteger = 0
    
    fileprivate static func setNetworkActivityIndicatorVisible(visible: Bool)
    {
        DispatchQueue.main.async {
            
            if visible
            {
                SwiftyGiphyAPI.NumberOfCallsToSetActivityIndicatorVisible += 1
            }
            else
            {
                SwiftyGiphyAPI.NumberOfCallsToSetActivityIndicatorVisible -= 1
                
                if SwiftyGiphyAPI.NumberOfCallsToSetActivityIndicatorVisible < 0
                {
                    SwiftyGiphyAPI.NumberOfCallsToSetActivityIndicatorVisible = 0
                }
            }
            
//            UIApplication.shared.isNetworkActivityIndicatorVisible = SwiftyGiphyAPI.NumberOfCallsToSetActivityIndicatorVisible > 0
        }
    }
}

// MARK: - GIF Support
public extension SwiftyGiphyAPI {
    
    /// Get the currently trending gifs from Giphy
    ///
    /// - Parameters:
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the gifs
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getTrending(limit: Int = 25, rating: SwiftyGiphyAPIContentRating = .pg13, offset: Int? = nil, completion: GiphyMultipleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["limit"] = limit
        params["rating"] = rating.rawValue
        
        if let currentOffset = offset
        {
            params["offset"] = currentOffset
        }
        
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "trending", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gifs!
            guard let validResponse = response, let gifs = Mapper<GiphyMultipleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get the results for a search from Giphy
    ///
    /// - Parameters:
    ///   - searchTerm: The phrase to use to search Giphy
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the gifs
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getSearch(searchTerm: String, limit: Int = 25, rating: SwiftyGiphyAPIContentRating = .pg13, offset: Int? = nil, completion: GiphyMultipleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["q"] = searchTerm
        params["limit"] = limit
        params["rating"] = rating.rawValue
        
        if let currentOffset = offset
        {
            params["offset"] = currentOffset
        }
        
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "search", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gifs!
            guard let validResponse = response, let gifs = Mapper<GiphyMultipleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Translate a search term into an image.
    ///
    /// - Parameters:
    ///   - searchTerm: The search term to translate
    ///   - rating: The max rating for the image (optional, defaults to pg13)
    ///   - languageCode: The language code (optional)
    ///   - completion: The completion block to call when done
    func getTranslation(searchTerm: String, rating: SwiftyGiphyAPIContentRating = .pg13, languageCode: String? = nil, completion: GiphySingleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["s"] = searchTerm
        params["rating"] = rating.rawValue
        
        if let language = languageCode
        {
            params["lang"] = language
        }
        
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "translate", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gif!
            guard let validResponse = response, let gifs = Mapper<GiphySingleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get a random gif
    ///
    /// - Parameters:
    ///   - tag: The tag to limit the randomness with
    ///   - rating: The max rating to limit the image to
    ///   - completion: The completion block to call when done
    func getRandom(tag: String, rating: SwiftyGiphyAPIContentRating = .pg13, completion: GiphySimpleSingleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["tag"] = tag
        params["rating"] = rating.rawValue
        
        let request = createRequest(baseURL: giphyAPIBase, relativePath: "random", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gif!
            guard let validResponse = response, let gifs = Mapper<GiphySimpleSingleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get a gif with a specific Giphy ID
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the gif
    ///   - completion: The completion block to call when done.
    func getGIFById(identifier: String, completion: GiphySingleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params: [String : Any]?
        
        if let validAPIKey = apiKey
        {
            params = [String : Any]()
            params?["api_key"] = validAPIKey
        }
        
        let request = createRequest(baseURL: giphyAPIBase, relativePath: identifier, method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gif!
            guard let validResponse = response, let gifs = Mapper<GiphySingleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
}

// MARK: - Sticker support
public extension SwiftyGiphyAPI {
    
    /// Get the currently trending stickers from Giphy
    ///
    /// - Parameters:
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the stickers
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getTrendingStickers(limit: Int = 25, rating: SwiftyGiphyAPIContentRating = .pg13, offset: Int? = nil, completion: GiphyMultipleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultStickerAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["limit"] = limit
        params["rating"] = rating.rawValue
        
        if let currentOffset = offset
        {
            params["offset"] = currentOffset
        }
        
        let request = createRequest(baseURL: giphyStickerAPIBase, relativePath: "trending", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gifs!
            guard let validResponse = response, let gifs = Mapper<GiphyMultipleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get the results for a search from Giphy for stickers
    ///
    /// - Parameters:
    ///   - searchTerm: The phrase to use to search Giphy
    ///   - limit: The limit of results to fetch
    ///   - rating: The max rating for the stickers
    ///   - offset: The paging offset
    ///   - completion: The completion block to call when done
    func getSearchStickers(searchTerm: String, limit: Int = 25, rating: SwiftyGiphyAPIContentRating = .pg13, offset: Int? = nil, completion: GiphyMultipleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultStickerAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["q"] = searchTerm
        params["limit"] = limit
        params["rating"] = rating.rawValue
        
        if let currentOffset = offset
        {
            params["offset"] = currentOffset
        }
        
        let request = createRequest(baseURL: giphyStickerAPIBase, relativePath: "search", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gifs!
            guard let validResponse = response, let gifs = Mapper<GiphyMultipleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Translate a search term into an image.
    ///
    /// - Parameters:
    ///   - searchTerm: The search term to translate
    ///   - rating: The max rating for the image (optional, defaults to pg13)
    ///   - languageCode: The language code (optional)
    ///   - completion: The completion block to call when done
    func getTranslationStickers(searchTerm: String, rating: SwiftyGiphyAPIContentRating = .pg13, languageCode: String? = nil, completion: GiphySingleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultStickerAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["s"] = searchTerm
        params["rating"] = rating.rawValue
        
        if let language = languageCode
        {
            params["lang"] = language
        }
        
        let request = createRequest(baseURL: giphyStickerAPIBase, relativePath: "translate", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gif!
            guard let validResponse = response, let gifs = Mapper<GiphySingleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
    
    /// Get a random sticker
    ///
    /// - Parameters:
    ///   - tag: The tag to limit the randomness with
    ///   - rating: The max rating to limit the image to
    ///   - completion: The completion block to call when done
    func getRandomSticker(tag: String, rating: SwiftyGiphyAPIContentRating = .pg13, completion: GiphySimpleSingleGIFResponseBlock?)
    {
        guard apiKey != nil || !isUsingDefaultStickerAPIBase else {
            print("ATTENTION: You need to set your Giphy API key before using SwiftyGiphy.")
            
            completion?(networkError(description: "You need to set your Giphy API key before using SwiftyGiphy."), nil)
            return
        }
        
        var params = [String : Any]()
        
        if let validAPIKey = apiKey
        {
            params["api_key"] = validAPIKey
        }
        
        params["tag"] = tag
        params["rating"] = rating.rawValue
        
        let request = createRequest(baseURL: giphyStickerAPIBase, relativePath: "random", method: "GET", params: params)
        
        send(request: request) { [unowned self] (error, response) in
            
            guard error == nil, response != nil else {
                DispatchQueue.main.async {
                    
                    completion?(error ?? self.networkError(description: kGiphyUnknownResponseError), nil)
                }
                
                return
            }
            
            // We have gif!
            guard let validResponse = response, let gifs = Mapper<GiphySimpleSingleGIFResponse>().map(JSONObject: validResponse) else {
                
                completion?(self.networkError(description: kGiphyUnknownResponseError), nil)
                return
            }
            
            DispatchQueue.main.async {
                completion?(nil, gifs)
            }
        }
    }
}
