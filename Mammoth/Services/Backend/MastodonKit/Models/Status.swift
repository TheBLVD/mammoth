//
//  Status.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/9/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Status: Codable, Hashable {
    /// The ID of the status.
    public var id: String?
    /// A Fediverse-unique resource ID.
    public let uri: String?
    /// URL to the status page (can be remote).
    public let url: String?
    /// The Account which posted the status.
    public let account: Account?
    /// null or the ID of the status it replies to.
    public let inReplyToID: String?
    /// null or the ID of the account it replies to.
    public let inReplyToAccountID: String?
    /// Body of the status; this will contain HTML (remote HTML already sanitized).
    public var content: String
    /// The time the status was created.
    public let createdAt: String
    /// An array of Emoji.
    public let emojis: [Emoji]
    /// The number of replies for the status.
    public var repliesCount: Int
    /// The number of reblogs for the status.
    public var reblogsCount: Int
    /// The number of favourites for the status.
    public var favouritesCount: Int
    /// Whether the authenticated user has reblogged the status.
    public var reblogged: Bool?
    /// Whether the authenticated user has favourited the status.
    public var favourited: Bool?
    /// Whether the authenticated user has bookmarked the status.
    public var bookmarked: Bool?
    /// Whether media attachments should be hidden by default.
    public var sensitive: Bool?
    /// If not empty, warning text that should be displayed before the actual content.
    public let spoilerText: String
    /// The visibility of the status.
    public let visibility: Visibility
    /// An array of attachments.
    public let mediaAttachments: [Attachment]
    /// An array of mentions.
    public let mentions: [Mention]
    /// An array of tags.
    public let tags: [Tag]
    /// A card.
    public let card: Card?
    /// Application from which the status was posted.
    public let application: Application?
    /// The detected language for the status.
    public let language: String?
    /// The reblogged Status.
    public var reblog: Status?
    /// Whether this is the pinned status for the account that posted it.
    public var pinned: Bool?
    /// The status poll.
    public let poll: Poll?
    
    public let editedAt: String?
    public let muted: Bool?
    public let filtered: [FilterResult]?
    
    public var uniqueId: String? {
        return self.reblog?.uri ?? self.uri
    }
    
    public var originalId: String? {
        if let uri = self.reblog?.uri ?? self.uri, let url = URL(string: uri) {
            return url.lastPathComponent
        }
        
        return nil
    }
    
    public var serverName: String? {
        if let url = self.reblog?.url ?? self.url, let url = URL(string: url) {
            return url.host
        }
        
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case uri
        case url
        case account
        case inReplyToID = "in_reply_to_id"
        case inReplyToAccountID = "in_reply_to_account_id"
        case content
        case createdAt = "created_at"
        case emojis
        case repliesCount = "replies_count"
        case reblogsCount = "reblogs_count"
        case favouritesCount = "favourites_count"
        case reblogged
        case favourited
        case bookmarked
        case sensitive
        case spoilerText = "spoiler_text"
        case visibility
        case mediaAttachments = "media_attachments"
        case mentions
        case tags
        case card
        case application
        case language
        case reblog
        case pinned
        case poll
        case editedAt = "edited_at"
        case muted
        case filtered
    }
    
    public init(id: String,
                uri: String,
                url: String? = nil,
                account: Account,
                inReplyToID: String? = nil,
                inReplyToAccountID: String? = nil,
                content: String,
                createdAt: String,
                emojis: [Emoji],
                repliesCount: Int,
                reblogsCount: Int,
                favouritesCount: Int,
                reblogged: Bool? = nil,
                favourited: Bool? = nil,
                bookmarked: Bool? = nil,
                sensitive: Bool? = nil,
                spoilerText: String,
                visibility: Visibility,
                mediaAttachments: [Attachment],
                mentions: [Mention],
                tags: [Tag],
                card: Card? = nil,
                application: Application? = nil,
                language: String? = nil,
                reblog: Status? = nil,
                pinned: Bool? = nil,
                poll: Poll? = nil,
                editedAt: String? = nil,
                muted: Bool? = nil,
                filtered: [FilterResult]? = nil) {
        self.id = id
        self.uri = uri
        self.url = url
        self.account = account
        self.inReplyToID = inReplyToID
        self.inReplyToAccountID = inReplyToAccountID
        self.content = content
        self.createdAt = createdAt
        self.emojis = emojis
        self.repliesCount = repliesCount
        self.reblogsCount = reblogsCount
        self.favouritesCount = favouritesCount
        self.reblogged = reblogged
        self.favourited = favourited
        self.bookmarked = bookmarked
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.visibility = visibility
        self.mediaAttachments = mediaAttachments
        self.mentions = mentions
        self.tags = tags
        self.card = card
        self.application = application
        self.language = language
        self.reblog = reblog
        self.pinned = pinned
        self.poll = poll
        self.editedAt = editedAt
        self.muted = muted
        self.filtered = filtered
    }
    
    @discardableResult
    public func likeTap() -> Int {
        favouritesCount += 1
        favourited = true
        return getLikesCount()
    }
    
    @discardableResult
    public func unlikeTap() -> Int {
        favouritesCount -= 1
        favourited = false
        return getLikesCount()
    }
    
    @discardableResult
    private func getLikesCount() -> Int {
        return favouritesCount
    }
    
    @discardableResult
    public func repostTap() -> Int {
        reblogsCount += 1
        reblogged = true
        return getRepostsCount()
    }
    
    @discardableResult
    public func unrepostTap() -> Int {
        reblogsCount -= 1
        reblogged = false
        return getRepostsCount()
    }
    
    private func getRepostsCount() -> Int {
        return reblogsCount
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Status: Equatable {
    
   static public func ==(lhs: Status, rhs: Status) -> Bool {
        return lhs.id == rhs.id
    }
    
}

extension Status {
    
    public func quotePostCard() -> Card? {
        var quotePostCard: Card? = nil
        
        let text = self.content
        
        // If there is any link in this text, find the last link,
        // and see if it's an @ URL.
        //
        // Based on multiple case studies, our best algo is:
        //      1. Find the position of the last "href="
        //      2. Get the first URL after that
        //      3. See if the URL matches a post URL pattern
        
        if let hrefStart = text.range(of:"href=\"", options:.backwards) {

            // Make a link card from the content
            //
            // Typical content:
            // Quote Posts from mammoth; similar from others
            //
            // content = "<p>QP this!</p><p>From: <span class=\"h-card\"><a href=\"https://moth.social/@bart\" class=\"u-url mention\">@<span>bart</span></a></span><br /><a href=\"https://moth.social/@bart/110231660759681860\" target=\"_blank\" rel=\"nofollow noopener noreferrer\"><span class=\"invisible\">https://</span><span class=\"ellipsis\">moth.social/@bart/110231660759</span><span class=\"invisible\">681860</span></a></p>"
            // content = "<p>Boom</p><p>From: @ploink<br /><a href=\"https://mastodon.design/@ploink/110272502146442833?public_follow=true\" target=\"_blank\" rel=\"nofollow noopener noreferrer\"><span class=\"invisible\">https://</span><span class=\"ellipsis\">mastodon.design/@ploink/110272</span><span class=\"invisible\">502146442833?public_follow=true</span></a></p>"
            //
            // More examples: from this…
            // content = "<p>QP this guy!</p><p>From: @aarondavid<br /><a href=\"https://mastodonapp.uk/@aarondavid/110300508837718942?public_follow=false\" target=\"_blank\" rel=\"nofollow noopener noreferrer\"><span class=\"invisible\">https://</span><span class=\"ellipsis\">mastodonapp.uk/@aarondavid/110</span><span class=\"invisible\">300508837718942?public_follow=false</span></a></p>"
            //
            // …the returned URLs are these: (note one is http, one https)
            // [0] = "https://mastodonapp.uk/@aarondavid/110300508837718942?public_follow=false"
            // [1] = "http://mastodonapp.uk/@aarondavid/110"

            // Find the list of URLs, starting from where we found the href
            let urls = URLsFromHTML(String(text.suffix(from: hrefStart.lowerBound)))
            
            // Use the first valid URL, and see if it looks like a quote post
            if let firstURL = urls.first {
                if firstURL.isPostURL() {
                    // Create a card from this URL
                    quotePostCard = Card(url: firstURL.absoluteString, title: "", description: "", type: .link, authorName: "", authorUrl: "", providerName: "", html: "", width: 0, height: 0)
                }
            }
        }
        
        return quotePostCard
    }
    
    static var urlDetector: NSDataDetector? = nil
    func URLsFromHTML(_ html: String) -> [URL] {
        var urlsInHTML: [URL] = []
        let types: NSTextCheckingResult.CheckingType = .link

        if Status.urlDetector == nil {
            Status.urlDetector = try? NSDataDetector(types: types.rawValue)
        }
        guard Status.urlDetector != nil else {
            log.error("unable to create Status.urlDetector")
            return []
        }

        let matches = Status.urlDetector?.matches(in: html, options: .reportCompletion, range: NSMakeRange(0, html.count))
        urlsInHTML = matches?.compactMap { $0.url } ?? []
        return urlsInHTML
    }

}

