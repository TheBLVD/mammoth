//
//  GlobalStruct.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import PhotosUI
import AVFoundation
import AVKit
import LinkPresentation

public struct GlobalStruct {
    static var isSubscribed: Bool = false
    
    // client and credentials
    init() {
        
    }
    static let shared = GlobalStruct()
    
    // The supported localizations / app languages
    static let supportedLocalizations = ["en", "de", "de-US", "de-AT", "de-BE", "de-CH", "de-DE", "de-LI", "de-LU", "nl", "nl-BE", "nl-NL", "pt-BR"]
    static let rootLocalization = "en"
    
    static var clientID = ""
    static var clientSecret = ""
    static var returnedText = ""
    static var accessToken = ""
    static var authCode = ""
    static var redirect = ""
    static var newClient = Client(baseURL: "")
    static var newInstance: InstanceData?
    static var maxChars: Int = 500
    static var newPollPost: [Any]? = nil
    static var savedPostSearch: [String] = []
    static var drafts: [Draft] = []
    static var currentDraft: Draft?
    static var showCW: Bool = true
    static var emoticonToAdd: String = ""
    static var blurSensitiveContent: Bool = true
    static var autoPlayVideos: Bool = true
    static var currentFilterId: String = ""
    static var currentFilter: Filters? = nil
    static var circleProfiles: Bool = true
    static var chatView: Bool = true
    static var currentPostLang2: String? = nil // used to set the user's profile language
    static var tabTapRestore: Bool = true
    static var hasSetupNewsDots: Bool = false
    static var fullScreen: Bool = true
    static var inVideoPlayer: Bool = false
    static var postsToKeep: Int = 250
    static var activityBadges: Bool = true
    static var whichImagesAltText: [Int] = []
    static var limitProfileLines: Bool = false
    static var timer1 = Timer()
    static var canLoadLink: Bool = true
    static var altAdded: [Int: String] = [:]
    static var accountIDsToFollow: [String] = []
    static var accountIDsToUnfollow: [String] = []
    static var deviceToken: Data?
    static var deviceTokenAccountUID: String?
    static var audioPlayer = AVAudioPlayer()
    static var actionFromInstance: String = ""
    static var votedOnPolls: [String: Poll] = [:]
    static var sidebarItem: Int = 0
    static var tempUpdateMetrics: [Status] = []
    static var tempUpdateIndex: Int? = nil
    static var blockedUsers: [String] = []
    static var tempFollowing: [Account] = []
    static var reviewPrompt: Bool = true
    static var enableLogging: Bool = false
    static var dmSecurityAlert: Bool = true
    static var mediaEditID: String = ""
    static var mediaEditDescription: String = ""
    
    static var dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = GlobalStruct.dateFormat
        return formatter
    }
    
    static var linkPreviewCards1: Bool = true
    static var linkPreviewCards2: Bool = true
    static var linkPreviewCardsLarge: Bool = true
    
    // 0 for first time, 1 for displaying, 2 for hidden
    static var displayingVIPLists: Int = 0
    
    static var VIPListID: String = ""
    static var topAccounts: [Account] = []
    
    static var curIDNoti = ""
    
    static var pnMentions: Bool = true
    static var pnLikes: Bool = true
    static var pnReposts: Bool = true
    static var pnFollows: Bool = true
    static var pnPolls: Bool = true
    static var pnStatuses: Bool = true
    static var pnFollowRequests: Bool = true
    
    static var refreshToken: String = ""
    static var allPinned: [Status] = []
    
    // app settings
    static var overrideTheme: Int = 0
    static var overrideThemeHighContrast = false
    static var soundsEnabled: Bool = true
    static var hapticsEnabled: Bool = true
    static var actionAnimations: Bool = true
    
    // appearance
    static var timeStampStyle: Int = 0
    static var originalPostTimeStamp: Bool = true
    enum DisplayNameType: Int {
        case full = 0
        case usernameOnly = 1
        case usertagOnly = 2
        case none = 3
    }
    static var displayName: DisplayNameType = .usernameOnly
    static var maxLines: Int = 0
    
    @available(*, deprecated, message: "Use GlobalStruct.mediaSize instead")
    static var hideMed: Bool { mediaSize == .hidden }
    
    @available(*, deprecated, message: "Use GlobalStruct.mediaSize instead")
    static var smallImages: Bool { mediaSize == .small }
    
    static var mediaSize: PostCardCell.PostCardMediaVariant = PostCardCell.PostCardMediaVariant.large
    
    static var feedReadDirection: NewsFeedReadDirection = .bottomUp
    
    static var shareAsImageText: Bool = false
    static var shareAsImageTextCaption: String = "Check this out!"
    
    // general
    static var tabBarTitles: Bool = false
    static var tabBarAnimations: Bool = true
    static var tabBarProfileIcon: Bool = true

    static var langStr: String = Locale.current.languageCode ?? "en"
    static var tintedCounters: Bool = false
    static var hideNavBars: Bool = false
    static var hideNavBars2: Bool = false
    static var scrollDirectionDown: Bool = true
    static var openLinksInBrowser: Bool = false
    static var appLock: Bool = false
    
    // composer
    static var keyboardType: Int = 0
    static var altText: Bool = false
    
    // fonts
    static var smallerFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 2
    static var customTextSize: CGFloat = 0
    static var customLineSize: CGFloat = 0

    // videos
    static var videoUrls: [String:String] = [:]
    static var feedVideoUrl: String = ""
    
    // likes and reposts
    static var allLikes: [String] = []
    static var allReposts: [String] = []
    static var allBookmarks: [String] = []
    static var allCW: [String] = []
    
    // other
    static var listTabIndex: Int = 0
    static var currentlyPosting: Bool = false
    static var canPostPost: Bool = true
    enum PostButtonLocationType: Int {
        case extremeLeft = -1
        case lowerLeft = 0
        case lowerRight = 1
    }
    static var postButtonLocation: PostButtonLocationType = .lowerRight
    static var showingNewPostComposer: Bool = false
    static var canvasImage = UIImage()
    static var currentTrendPost: Int = 0
    static var idToDelete: String = ""
    static var idsToUnlike: [String] = []
    static var idsToUnbookmark: [String] = []
    static var animatedOnce: Bool = false
    static var placeID: String = ""
    static var schemeId: String = ""
    static var schemeProfileName: String = ""
    static var currentScore: Int = 0
    static var excludeUsers: [String] = []
    static var postPostError: String = ""
    static var difficulty: String = "easy"
    static var siriPhrases: [String] = []
    static var tempPostTranslate: String = ""
    static var threaderMode: Bool = false
    static var threaderStyle: Int = 0
    static var reviewCount: Int = 0
    static var notifs1: Bool = false
    static var notifIDs: [String] = []
    static var isNeedingColumnsUpdate: Bool = false
    static var isNeedingColumnsUpdate2: Bool = false
    
    // custom tabs
    static var tab1Index: Int = 0
    static var tab2Index: Int = 1
    static var tab3Index: Int = 2
    static var tab4Index: Int = 3
    static var tab5Index: Int = 4
    static var tab2: Bool = true
    static var tab3: Bool = true
    static var tab4: Bool = true
    
    // popups
    static var popupPostPosted: Bool = true
    static var popupPostDeleted: Bool = true
    static var popupUserActions: Bool = true
    static var popupListActions: Bool = true
    static var popupBookmarkActions: Bool = true
    static var popupRateLimits: Bool = true
    
    // iPad
    static var isCompact: Bool = false
    static var padColWidth: Int = 412
    static var objects: [DiffSections] = []
    static var sidebarHighlight: Int = 0
    static var singleColumn: Bool = false
    static var currentSingleColumnViewController = SingleColumnViewController()
        
    // iPad columns
    static var columnsViews2: [UIViewController] = [
        HomeViewController(),
        ActivityViewController(),
        MentionsViewController(),
        SearchHostViewController(),
        ProfileViewController(acctData: AccountsManager.shared.currentAccount),
        NewsFeedViewController(type: .likes),
        NewsFeedViewController(type: .bookmarks),
        FiltersViewController()
    ]
        
    static var columnsOrder: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
}

public func GlobalHostServer() -> String {
    if CommandLine.arguments.contains("-M_STAGING_SERVER") {
        return "staging.moth.social"
    } else {
        return "moth.social"
    }
}

struct Draft: Codable, Hashable {
    var id: Int
    var contents: Status
    var images: [Data?]
    var imagesIds: [String]?
    var replyPost: [Status]
    
    init(id: Int, contents: Status, images: [Data?], imagesIds: [String]?, replyPost: [Status]) {
        self.id = id
        self.contents = contents
        self.images = images
        self.imagesIds = imagesIds
        self.replyPost = replyPost
    }
    
    static func == (lhs: Draft, rhs: Draft) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension String {
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        return Range(nsRange, in: self)
    }
    
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = self.range(
            of: substring,
            options: options,
            range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
                ranges.append(range)
        }
        return ranges
    }
    
    func stripHTML() -> String {
        var z = self.replacingOccurrences(of: "</p><p>", with: "\n\n", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "<br>", with: "\n", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "<br />", with: "\n", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "<br/>", with: "\n", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "<[^>]+>", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&apos;", with: "'", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&amp;", with: "&", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&nbsp;", with: " ", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&lt;", with: "<", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&gt;", with: ">", options: NSString.CompareOptions.regularExpression, range: nil)
        z = z.replacingOccurrences(of: "&#39;", with: "'", options: NSString.CompareOptions.regularExpression, range: nil)
        return z
    }
    
    func toDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateFormatter.date(from: self) {
            return date
        } else {
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "E MMM d HH:mm:ss Z yyyy"
            dateFormatter2.locale = Locale(identifier: "en_US_POSIX")
            let date2 = dateFormatter2.date(from: self)
            return date2 ?? Date()
        }
    }
    
    func toFeedDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d HH:mm:ss Z yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let date = dateFormatter.date(from: self)
        return date ?? Date()
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound.samePosition(in: utf16)
        let to = range.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from!),
                       length: utf16.distance(from: from!, to: to!))
    }
    
    func capitalizingFirstLetter() -> String {
        return suffix(1).capitalized
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
    
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    func removingUrls() -> String {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return self
        }
        return detector.stringByReplacingMatches(in: self,
                                                 options: [],
                                                 range: NSRange(location: 0, length: self.utf16.count),
                                                 withTemplate: "")
    }
    
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1F1E6...0x1F1FF: // Flags
                return true
            default:
                continue
            }
        }
        return false
    }
}

extension UITextView {
#if targetEnvironment(macCatalyst)
    @objc(_focusRingType)
    override var focusRingType: UInt {
        return 1 //NSFocusRingTypeNone
    }
#endif
    
    var cursorOffset: Int? {
        guard let range = selectedTextRange else { return nil }
        return offset(from: beginningOfDocument, to: range.start)
    }
    var cursorIndex: String.Index? {
        guard let location = cursorOffset else { return nil }
        return Range(.init(location: location, length: 0), in: text)?.lowerBound
    }
    var cursorDistance: Int? {
        guard let cursorIndex = cursorIndex else { return nil }
        return text.distance(from: text.startIndex, to: cursorIndex)
    }
}

extension UIViewController {
    func isInWindowHierarchy() -> Bool {
        return self.isViewLoaded && self.view.window != nil
    }
    
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.windows.first?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        if let alert = controller as? UIAlertController {
            if let navigationController = alert.presentingViewController as? UINavigationController {
                return navigationController.viewControllers.last
            }
            return alert.presentingViewController
        }
        return controller
    }
}

extension Int {
    func withCommas() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value:self))!
    }
    
    func formatUsingAbbrevation () -> String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        } else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)K"
        } else {
            return "\(self)"
        }
    }
}

extension UserDefaults {
    func color(forKey key: String) -> UIColor? {
        guard let colorData = data(forKey: key) else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
        } catch let error {
            log.error("color error \(error.localizedDescription)")
            return nil
        }
    }

    func set(_ value: UIColor?, forKey key: String) {
        guard let color = value else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch let error {
            log.error("error color key data not saved \(error.localizedDescription)")
        }
    }
}

extension URL {
    func getGifImageDataFromAssetUrl(completion: @escaping(_ imageData: Data?) -> Void) {
        let asset = PHAsset.fetchAssets(withALAssetURLs: [self], options: nil)
        if let image = asset.firstObject {
            PHImageManager.default().requestImageDataAndOrientation(for: image, options: nil, resultHandler: { imageData, _, _, _ in
                completion(imageData)
            })
        }
    }
}


func getMinutesDifferenceFromTwoDates(start: Date, end: Date) -> Int {
    let diffSeconds = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)
    let minutes = diffSeconds / 60
    return minutes
}

extension UITableViewCell {
    func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.preferredApplicationWindow?.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            topMostViewController = presentedViewController
        }
        return topMostViewController
    }
}

extension UIImage {
    public func withRoundedCorners(_ roundingFactor: CGFloat = 2) -> UIImage? {
        let maxRadius = min(size.width, size.height) / roundingFactor
        let cornerRadius: CGFloat
        cornerRadius = maxRadius
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: targetSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func withInset(_ insets: UIEdgeInsets) -> UIImage? {
        let cgSize = CGSize(width: self.size.width + insets.left * self.scale + insets.right * self.scale,
                            height: self.size.height + insets.top * self.scale + insets.bottom * self.scale)
        
        UIGraphicsBeginImageContextWithOptions(cgSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        
        let origin = CGPoint(x: insets.left * self.scale, y: insets.top * self.scale)
        self.draw(at: origin)
        
        return UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(self.renderingMode)
    }
}

extension AVPlayer {
    func isPlaying() -> Bool {
        return (self.rate != 0.0 && self.status == .readyToPlay)
    }
}

class CustomButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
}

class CustomStackView: UIStackView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
}

extension UIFont {
    static func swizzle() {
        method_exchangeImplementations(
                class_getInstanceMethod(self, #selector(getter: descender))!,
                class_getInstanceMethod(self, #selector(getter: swizzledDescender))!
        )
        method_exchangeImplementations(
                class_getInstanceMethod(self, #selector(getter: lineHeight))!,
                class_getInstanceMethod(self, #selector(getter: swizzledLineHeight))!
        )
    }

    @objc private var swizzledDescender: CGFloat {
        return self.swizzledDescender * 1.1
    }

    @objc private var swizzledLineHeight: CGFloat {
        return self.swizzledLineHeight * 1.1
    }
}

extension UIColor {
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
    
    func isLight() -> Bool? {
        let originalCGColor = self.cgColor
        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }
        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > 0.7)
    }
}

extension UIView {
    #if targetEnvironment(macCatalyst)
    @objc(_focusRingType)
    var focusRingType: UInt {
        return 1 //NSFocusRingTypeNone
    }
    #endif
}

extension UIView {
    func takeScreenshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if (image != nil) {
            return image!
        }
        return UIImage()
    }
    func rotate360Degrees(duration: CFTimeInterval = 1) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount=Float.infinity
        self.layer.add(rotateAnimation, forKey: nil)
    }
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
    }
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

extension Data {
    func getAVAsset() -> AVAsset {
        let directory = NSTemporaryDirectory()
        let fileName = "\(NSUUID().uuidString).mov"
        let fullURL = NSURL.fileURL(withPathComponents: [directory, fileName])
        try! self.write(to: fullURL!)
        let asset = AVAsset(url: fullURL!)
        return asset
    }
}

extension UIDevice {
    var hasNotch: Bool {
        guard #available(iOS 11.0, *), let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first else { return false }
        if UIDevice.current.orientation.isPortrait {
            return window.safeAreaInsets.top >= 44
        } else {
            return window.safeAreaInsets.left > 0 || window.safeAreaInsets.right > 0
        }
    }
}

extension AVAsset {
    var videoSize: CGSize? {
        tracks(withMediaType: .video).first.flatMap {
            tracks.count > 0 ? $0.naturalSize.applying($0.preferredTransform) : nil
        }
    }
}

class PaddedTextField: UITextField {
    let padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

class tempEmptyView: UIViewController {
    var placeholder = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .custom.background
        self.navigationItem.title = "Coming soon..."
        
        // set up nav bar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
        
        if GlobalStruct.hideNavBars2 {
            self.extendedLayoutIncludesOpaqueBars = true
        } else {
            self.extendedLayoutIncludesOpaqueBars = false
        }
        
        self.placeholder.text = "Coming soon..."
        self.placeholder.textColor = .secondaryLabel
        self.placeholder.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        self.placeholder.sizeToFit()
        self.placeholder.center = self.navigationController?.view.center ?? self.view.center
        self.view.addSubview(self.placeholder)
    }
}

extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else { return false }
        return !window.frame.equalTo(window.screen.bounds)
    }
    
    public func isRunningInFullScreen() -> Bool {
        let keyWindow = self.windows.filter {$0.isKeyWindow}.first
        if let w = keyWindow {
            let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let minScreenSize = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
            let maxAppSize = max(w.bounds.size.width, w.bounds.size.height)
            let minAppSize = min(w.bounds.size.width, w.bounds.size.height)
            return maxScreenSize == maxAppSize && minScreenSize == minAppSize
        }
        return true
    }
}


