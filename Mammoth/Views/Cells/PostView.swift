//
//  PostView.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 26/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Vision
import MobileCoreServices
import Photos
import NaturalLanguage
import LinkPresentation
import Kingfisher

extension UIButton {
    // Returns the first superview that is a UITableViewCell
    func parentCell() -> UITableViewCell? {
        var parentCell: UITableViewCell? = nil
        var parentView: UIView? = self
        repeat
        {
            parentView = parentView?.superview
            if let parentViewAsCell = parentView as? UITableViewCell {
                parentCell = parentViewAsCell
            }
        } while parentCell == nil && parentView != nil
        return parentCell
    }
}

extension UIGestureRecognizer {
    // Returns the first superview that is a UITableViewCell
    func parentCell() -> UITableViewCell? {
        var parentCell: UITableViewCell? = nil
        var parentView: UIView? = self.view
        repeat
        {
            parentView = parentView?.superview
            if let parentViewAsCell = parentView as? UITableViewCell {
                parentCell = parentViewAsCell
            }
        } while parentCell == nil && parentView != nil
        return parentCell
    }
}

protocol PostCellDelegate : AnyObject {
    func statusForCell(_ cell: UITableViewCell) -> Status?
    func notificationForCell(_ cell: UITableViewCell) -> Notificationt?
}

class PostView: UIView, UICollectionViewDataSource, UICollectionViewDelegate, SKPhotoBrowserDelegate, AVPlayerViewControllerDelegate, UIContextMenuInteractionDelegate, UICollectionViewDragDelegate, UIDragInteractionDelegate, UIActivityItemSource {
    
    weak var delegate: PostCellDelegate? = nil
    var profileIcon21 = UIButton()
    var profileIcon22 = UIButton()
    var pipView = UIPiPView()
    var highlightBG = UIView()
    var profileIcon = UIButton()
    var lockedBadge = UIImageView()
    var lockedBackground = UIView()
    var userTag = UILabel()
    var userName = UILabel()
    var indicator = UIImageView()
    var dateTime = UILabel()
    var postText = ActiveLabel()
    var collectionView1: UICollectionView!
    var imageHeight: CGFloat = 220
    var inDetail: Bool = false
    var altText: [String] = []
    let bgV = UIImageView()
    let shareAsImageText = UILabel()
    let cwOverlay = UIButton()
    var activityIndicator = UIButton()
    // a post with a URL/link in it
    let linkStackViewHorizontal = UIStackView()
    let linkUsername = UILabel()
    let linkUsertag = UILabel()
    let linkPost = ActiveLabel()           // this is the body of the above
    let linkStackView0 = UIStackView()
    let linkStackView = UIStackView()
    var linkCollectionView1: UICollectionView!
    var id: String = ""
    var lpImage = UIImageView()
    // actual quote post view; can be either...
    //  (A) full post content (Plain), or
    //  (B) more muted/shorter content (Muted)
    let quotePostHostView = QuotePostHostView()
    // repost / quote post button
    let repostView = RepostButtonView()
    // poll
    var pollStack = UIStackView()
    // actions
    let repliesImage = UIImageView()
    let repliesText = UILabel()
    let repliesB = CustomStackView()
    let repostsImage = UIImageView()
    let repostsText = UILabel()
    let repostsStack = CustomStackView()
    let repostsB = UIButton(type: .custom)
    let likesImage = UIImageView()
    let likesText = UILabel()
    let likesB = CustomStackView()
    let moreB = CustomButton()
    let stackViewB = UIStackView()
    // constraints
    var constraintsOther: [NSLayoutConstraint] = []
    var constraints0: [NSLayoutConstraint] = []
    var constraints1: [NSLayoutConstraint] = []
    var constraints2: [NSLayoutConstraint] = []
    var constraintsS: [NSLayoutConstraint] = []
    var constraintsS2: [NSLayoutConstraint] = []
    var constraintsW: [NSLayoutConstraint] = []
    var constraintsW2: [NSLayoutConstraint] = []
    var constraintsC1: [NSLayoutConstraint] = []
    var constraintsC2: [NSLayoutConstraint] = []
    var widthCo: NSLayoutConstraint?
    var conI1: NSLayoutConstraint?
    var conQ1: NSLayoutConstraint?
    var conS1: NSLayoutConstraint?
    var conLP1: NSLayoutConstraint?
    var conLP2: NSLayoutConstraint?
    // other
    var topThreadDot = UIView()
    var topThreadLine = UIView()
    var bottomThreadLine = UIView()
    var bottomThreadLine2 = UIView()
    var fromFeed: Bool = false
    var watermarkView = UIView()
    var watermarkText = UILabel()
    var watermarkImage = UIImageView()
    var tmpIndex: Int = 0
    var tmpCollection: UICollectionView?
    let symbolConfigLP = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    let countButton2 = UIButton()

    func prepareForReuse() {
        self.player.isMuted = true

        self.playButton.isHidden = true
        self.playButtonQ.isHidden = true

        self.lpImage.image = UIImage()

        self.linkUsername.text = ""
        self.linkUsertag.text = ""
        self.linkPost.text = ""

        self.images = []
        self.images2 = []
        self.images3 = []

        self.linkCountButtonBG.alpha = 0
        self.linkImages = []
        self.linkImages2 = []
        self.linkImages3 = []

        self.playerController.view.isHidden = true
        self.playerControllerQ.view.isHidden = true
        
        self.quotePostHostView.updateForQuotePost(nil)
        
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        self.player.isMuted = true
        NotificationCenter.default.removeObserver(self)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    

    func commonInit() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

//        let _ = self.constraints.map ({ x in
//            x.isActive = false
//        })

        pipView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(pipView)

        self.topThreadDot.alpha = 0
        self.topThreadLine.alpha = 0
        self.bottomThreadLine.alpha = 0
        self.bottomThreadLine2.alpha = 0

        self.player.automaticallyWaitsToMinimizeStalling = false
        self.player.isMuted = true
        self.playerController.allowsPictureInPicturePlayback = true
        self.playerController.videoGravity = .resizeAspectFill
        self.playerController.showsPlaybackControls = false

        highlightBG.translatesAutoresizingMaskIntoConstraints = false
        pipView.addSubview(highlightBG)

        userName.translatesAutoresizingMaskIntoConstraints = false
        userName.textAlignment = .left
        userName.textColor = UIColor.label
        userName.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        userName.accessibilityIdentifier = "userName"
        pipView.addSubview(userName)

        userTag.translatesAutoresizingMaskIntoConstraints = false
        userTag.textAlignment = .left
        userTag.textColor = UIColor.secondaryLabel
        userTag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        userTag.accessibilityIdentifier = "userTag"
        pipView.addSubview(userTag)

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .regular)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.alpha = 0
        indicator.image = UIImage(systemName: "arrowshape.turn.up.left", withConfiguration: symbolConfig)?.withTintColor(UIColor.secondaryLabel, renderingMode: .alwaysOriginal)
        indicator.contentMode = .scaleAspectFit
        indicator.accessibilityIdentifier = "indicator"
        pipView.addSubview(indicator)

        dateTime.translatesAutoresizingMaskIntoConstraints = false
        dateTime.textAlignment = .right
        dateTime.textColor = UIColor.secondaryLabel
        dateTime.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        dateTime.accessibilityIdentifier = "dateTime"
        pipView.addSubview(dateTime)

        postText.translatesAutoresizingMaskIntoConstraints = false
        postText.numberOfLines = 0
        postText.textColor = .custom.mainTextColor
        postText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        postText.enabledTypes = [.mention, .hashtag, .url, .email]
        postText.mentionColor = .custom.baseTint
        postText.hashtagColor = .custom.baseTint
        postText.URLColor = .custom.baseTint
        postText.emailColor = .custom.baseTint
        postText.linkWeight = .regular
        postText.urlMaximumLength = 30
        postText.accessibilityIdentifier = "postText"
        postText.lineSpacing = GlobalStruct.customLineSize
        pipView.addSubview(postText)

        // thread lines
        
        topThreadDot.translatesAutoresizingMaskIntoConstraints = false
        topThreadDot.backgroundColor = .custom.quoteTint
        topThreadDot.layer.cornerRadius = 1
        topThreadDot.alpha = 0
        topThreadDot.accessibilityIdentifier = "topThreadDot"
        pipView.addSubview(topThreadDot)

        topThreadLine.translatesAutoresizingMaskIntoConstraints = false
        topThreadLine.backgroundColor = .custom.quoteTint
        topThreadLine.alpha = 0
        topThreadLine.accessibilityIdentifier = "topThreadLine"
        pipView.addSubview(topThreadLine)

        bottomThreadLine.translatesAutoresizingMaskIntoConstraints = false
        bottomThreadLine.backgroundColor = .custom.quoteTint
        bottomThreadLine.alpha = 0
        bottomThreadLine.accessibilityIdentifier = "bottomThreadLine"
        pipView.addSubview(bottomThreadLine)
        
        bottomThreadLine2.translatesAutoresizingMaskIntoConstraints = false
        bottomThreadLine2.backgroundColor = .custom.quoteTint
        bottomThreadLine2.layer.cornerRadius = 2
        bottomThreadLine2.alpha = 0
        bottomThreadLine2.accessibilityIdentifier = "bottomThreadLine2"
        pipView.addSubview(bottomThreadLine2)

        // images

        let layout0 = ColumnFlowLayout(
            cellsPerRow: 4,
            minimumInteritemSpacing: 0,
            minimumLineSpacing: 0,
            sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        layout0.scrollDirection = .horizontal
        if GlobalStruct.smallImages {
            let layout1 = ColumnFlowLayoutS(
                cellsPerRow: 1,
                minimumInteritemSpacing: 0,
                minimumLineSpacing: 0,
                sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            )
            layout1.itemSize = CGSize(width: 66, height: 66)
            layout1.scrollDirection = .horizontal
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(66), height: CGFloat(66)), collectionViewLayout: layout1)
        } else {
            if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(220)), collectionViewLayout: layout0)
            } else {
                #if targetEnvironment(macCatalyst)
                collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(220)), collectionViewLayout: layout0)
                #else
                collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: CGFloat(220)), collectionViewLayout: layout0)
                #endif
            }
        }
        collectionView1.translatesAutoresizingMaskIntoConstraints = false
        collectionView1.backgroundColor = .clear
        collectionView1.delegate = self
        collectionView1.dataSource = self
        collectionView1.showsHorizontalScrollIndicator = false
        collectionView1.isPagingEnabled = true
        collectionView1.register(CollectionImageCell.self, forCellWithReuseIdentifier: "CollectionImageCell")
        collectionView1.register(CollectionImageCell2.self, forCellWithReuseIdentifier: "CollectionImageCell2")
        collectionView1.register(CollectionImageCellActivity.self, forCellWithReuseIdentifier: "CollectionImageCellActivity")
        collectionView1.register(CollectionImageCell3.self, forCellWithReuseIdentifier: "CollectionImageCell3")
        collectionView1.register(CollectionImageCellS.self, forCellWithReuseIdentifier: "CollectionImageCellS")
        collectionView1.accessibilityIdentifier = "collectionView1"
        collectionView1.dragDelegate = self
        collectionView1.layer.masksToBounds = false
        pipView.addSubview(collectionView1)

        if GlobalStruct.smallImages {
            conI1 = self.collectionView1.heightAnchor.constraint(equalToConstant: 66)
        } else {
            conI1 = self.collectionView1.heightAnchor.constraint(equalToConstant: 220)
        }
        conI1?.priority = UILayoutPriority(rawValue: 999)
        conI1?.isActive = true

        countButtonBG.translatesAutoresizingMaskIntoConstraints = false
        countButtonBG.layer.cornerCurve = .continuous
        countButtonBG.layer.cornerRadius = 10
        countButtonBG.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = countButtonBG.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.removeFromSuperview()
        countButtonBG.addSubview(blurEffectView)
        countButtonBG.layer.masksToBounds = true
        countButtonBG.accessibilityIdentifier = "countButtonBG"
        pipView.addSubview(countButtonBG)

       
        pipView.addSubview(repostView)

        conS1 = self.repostView.heightAnchor.constraint(equalToConstant: 20)
        conS1?.priority = UILayoutPriority(rawValue: 999)
        conS1?.isActive = true

        // create stack for link

        linkUsername.text = ""
        linkUsername.textColor = .label
        linkUsername.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold)
        linkUsername.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        linkUsername.accessibilityIdentifier = "linkUsername"
        linkUsername.numberOfLines = 1

        linkUsertag.text = ""
        linkUsertag.textColor = .secondaryLabel
        linkUsertag.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .light)
        linkUsertag.sizeToFit()
        linkUsertag.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        linkUsertag.accessibilityIdentifier = "linkUsertag"

        let spacer2 = UIView()
        spacer2.isUserInteractionEnabled = false
        spacer2.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        spacer2.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)

        linkStackViewHorizontal.translatesAutoresizingMaskIntoConstraints = false
        linkStackViewHorizontal.addArrangedSubview(linkUsername)
        linkStackViewHorizontal.addArrangedSubview(linkUsertag)
        linkStackViewHorizontal.addArrangedSubview(spacer2)
        linkStackViewHorizontal.axis = .horizontal
        linkStackViewHorizontal.distribution = .fill
        linkStackViewHorizontal.spacing = 1
        linkStackViewHorizontal.isUserInteractionEnabled = true
        linkStackViewHorizontal.backgroundColor = .custom.quoteTint
        linkStackViewHorizontal.layer.masksToBounds = true
        linkStackViewHorizontal.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        linkStackViewHorizontal.accessibilityIdentifier = "linkStackViewHorizontal"
        pipView.addSubview(linkStackViewHorizontal)

        linkPost.text = ""
        linkPost.textColor = .secondaryLabel
        linkPost.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular)
        linkPost.numberOfLines = 0
        linkPost.enabledTypes = [.mention, .hashtag, .url, .email]
        linkPost.mentionColor = .custom.baseTint
        linkPost.hashtagColor = .custom.baseTint
        linkPost.emailColor = .custom.baseTint
        linkPost.URLColor = .custom.baseTint
        linkPost.urlMaximumLength = 30
        linkPost.lineSpacing = GlobalStruct.customLineSize
        linkPost.sizeToFit()
        linkPost.accessibilityIdentifier = "linkPost"

        let layout = ColumnFlowLayout2(
            cellsPerRow: 4,
            minimumInteritemSpacing: 0,
            minimumLineSpacing: 0,
            sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        layout.scrollDirection = .horizontal
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            linkCollectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(190)), collectionViewLayout: layout)
        } else {
            #if targetEnvironment(macCatalyst)
            linkCollectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(190)), collectionViewLayout: layout)
            #else
            linkCollectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: CGFloat(190)), collectionViewLayout: layout)
            #endif
        }
        linkCollectionView1.translatesAutoresizingMaskIntoConstraints = false
        linkCollectionView1.backgroundColor = .clear
        linkCollectionView1.delegate = self
        linkCollectionView1.dataSource = self
        linkCollectionView1.showsHorizontalScrollIndicator = false
        linkCollectionView1.isPagingEnabled = true
        linkCollectionView1.register(CollectionImageCell.self, forCellWithReuseIdentifier: "CollectionImageCell")
        linkCollectionView1.register(CollectionImageCell2.self, forCellWithReuseIdentifier: "CollectionImageCell2")
        linkCollectionView1.register(CollectionImageCell3.self, forCellWithReuseIdentifier: "CollectionImageCell3")
        linkCollectionView1.accessibilityIdentifier = "linkCollectionView1"

        conQ1 = self.linkCollectionView1.heightAnchor.constraint(equalToConstant: 190)
        conQ1?.priority = UILayoutPriority(rawValue: 999)
        conQ1?.isActive = true
        
        linkUsername.setContentCompressionResistancePriority(.required, for: .vertical)

        linkStackView0.addArrangedSubview(linkStackViewHorizontal)
        linkStackView0.addArrangedSubview(linkPost)
        
        linkStackView0.addArrangedSubview(quotePostHostView)
        
        linkStackView0.axis = .vertical
        linkStackView0.distribution = .fill
        linkStackView0.spacing = 0
        linkStackView0.isUserInteractionEnabled = true
        linkStackView0.backgroundColor = .custom.quoteTint
        linkStackView0.isLayoutMarginsRelativeArrangement = true
        linkStackView0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        linkStackView0.layer.masksToBounds = true
        linkStackView0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        linkStackView0.accessibilityIdentifier = "linkStackView0"
        pipView.addSubview(linkStackView0)
        
        lpImage.image = UIImage()
        lpImage.translatesAutoresizingMaskIntoConstraints = false
        conLP1 = self.lpImage.heightAnchor.constraint(equalToConstant: 130)
        conLP2 = self.lpImage.heightAnchor.constraint(equalToConstant: 65)
        lpImage.backgroundColor = .custom.quoteTint
        lpImage.contentMode = .scaleAspectFill
        pipView.addSubview(lpImage)
        conLP1?.isActive = true
        
        linkStackView.translatesAutoresizingMaskIntoConstraints = false
        linkStackView.addArrangedSubview(lpImage)
        linkStackView.addArrangedSubview(linkStackView0)
        linkStackView.axis = .vertical
        linkStackView.distribution = .fill
        linkStackView.spacing = 0
        linkStackView.isUserInteractionEnabled = true
        linkStackView.backgroundColor = .custom.quoteTint
        linkStackView.layer.borderWidth = 0.4
        linkStackView.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
        linkStackView.layer.masksToBounds = true
        linkStackView.layer.cornerRadius = 10
        linkStackView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
        linkStackView.accessibilityIdentifier = "linkStackView"
        pipView.addSubview(linkStackView)
        
        let qGesture = UITapGestureRecognizer(target: self, action: #selector(self.linkTapped))
        linkStackView.addGestureRecognizer(qGesture)

        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.allowsSimultaneousRecognitionDuringLift = true
        linkStackView.addInteraction(dragInteraction)
        let interaction = UIContextMenuInteraction(delegate: self)
        linkStackView.addInteraction(interaction)

        linkCountButtonBG.layer.cornerCurve = .continuous
        linkCountButtonBG.layer.cornerRadius = 10
        linkCountButtonBG.backgroundColor = .clear
        let blurEffectQ = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurEffectViewQ = UIVisualEffectView(effect: blurEffectQ)
        blurEffectViewQ.frame = linkCountButtonBG.bounds
        blurEffectViewQ.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectViewQ.removeFromSuperview()
        linkCountButtonBG.addSubview(blurEffectViewQ)
        linkCountButtonBG.layer.masksToBounds = true
        linkCollectionView1.addSubview(linkCountButtonBG)

        // actions
        let symbolConfigB = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)

        // replies
        repliesImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        repliesImage.image = UIImage(systemName: "arrowshape.turn.up.left", withConfiguration: symbolConfigB)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
        repliesImage.contentMode = .scaleAspectFit
        repliesText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        repliesText.text = "0"
        repliesText.textColor = .custom.actionButtons
        repliesText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        repliesText.sizeToFit()
        repliesText.accessibilityLabel = "repliesText"

        repliesB.addArrangedSubview(repliesImage)
        repliesB.addArrangedSubview(repliesText)
        repliesB.alignment = .center
        repliesB.axis = .horizontal
        repliesB.distribution = .equalSpacing
        repliesB.spacing = 4
        repliesB.isUserInteractionEnabled = true
        repliesB.isAccessibilityElement = false

        // reposts
        repostsImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        repostsImage.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfigB)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
        repostsImage.contentMode = .scaleAspectFit
        repostsText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        repostsText.text = "0"
        repostsText.textColor = .custom.actionButtons
        repostsText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        repostsText.sizeToFit()
        repostsText.accessibilityLabel = "repostsText"

        // Put the repost icon and count in a stack view,
        // and then put that inside the repostsB button
        repostsStack.addArrangedSubview(repostsImage)
        repostsStack.addArrangedSubview(repostsText)
        repostsStack.alignment = .center
        repostsStack.axis = .horizontal
        repostsStack.distribution = .equalSpacing
        repostsStack.spacing = 4
        repostsStack.isUserInteractionEnabled = false
        repostsStack.isAccessibilityElement = false
        repostsStack.translatesAutoresizingMaskIntoConstraints = false
        repostsB.addSubview(repostsStack)
                
        // Line up the edges of the button with the stack inside it
        repostsB.translatesAutoresizingMaskIntoConstraints = false
        repostsB.addConstraints( [
            repostsB.leftAnchor.constraint(equalTo: repostsStack.leftAnchor),
            repostsB.topAnchor.constraint(equalTo: repostsStack.topAnchor),
            repostsB.bottomAnchor.constraint(equalTo: repostsStack.bottomAnchor),
            repostsB.rightAnchor.constraint(equalTo: repostsStack.rightAnchor)
        ])

        // likes
        likesImage.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        likesImage.image = UIImage(systemName: "heart", withConfiguration: symbolConfigB)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal)
        likesImage.contentMode = .scaleAspectFit
        likesText.frame = CGRect(x: 30, y: 0, width: 30, height: 20)
        likesText.text = "0"
        likesText.textColor = .custom.actionButtons
        likesText.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        likesText.sizeToFit()
        likesText.accessibilityLabel = "likesText"

        likesB.addArrangedSubview(likesImage)
        likesB.addArrangedSubview(likesText)
        likesB.alignment = .center
        likesB.axis = .horizontal
        likesB.distribution = .equalSpacing
        likesB.spacing = 4
        likesB.isUserInteractionEnabled = true
        likesB.isAccessibilityElement = false

        // more
        moreB.setImage(UIImage(systemName: "ellipsis", withConfiguration: symbolConfigB)?.withTintColor(.custom.actionButtons, renderingMode: .alwaysOriginal), for: .normal)
        moreB.bounds.size.width = 80
        moreB.bounds.size.height = 80
        moreB.accessibilityLabel = "moreB"

        stackViewB.translatesAutoresizingMaskIntoConstraints = false
        stackViewB.addArrangedSubview(repliesB)
        stackViewB.addArrangedSubview(repostsB)
        stackViewB.addArrangedSubview(likesB)
        stackViewB.addArrangedSubview(moreB)
        stackViewB.alignment = .center
        stackViewB.axis = .horizontal
        stackViewB.distribution = .equalSpacing
        stackViewB.spacing = 2
        pipView.addSubview(stackViewB)

        // profile icons

        profileIcon.translatesAutoresizingMaskIntoConstraints = false
        profileIcon.backgroundColor = .custom.quoteTint
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.layer.masksToBounds = true
        profileIcon.imageView?.contentMode = .scaleAspectFill
        profileIcon.contentMode = .scaleAspectFill
        profileIcon.accessibilityLabel = "profileIcon"
        pipView.addSubview(profileIcon)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.backgroundColor = .custom.quoteTint
        activityIndicator.contentMode = .scaleAspectFill
        activityIndicator.layer.masksToBounds = true
        activityIndicator.imageView?.contentMode = .scaleAspectFill
        activityIndicator.contentMode = .scaleAspectFill
        activityIndicator.accessibilityLabel = "activityIndicator"
        activityIndicator.alpha = 0
        activityIndicator.layer.cornerRadius = 13
        activityIndicator.isUserInteractionEnabled = false
        pipView.addSubview(activityIndicator)
        
        // create 2 user group
        
        profileIcon21.frame = CGRect(x: -1, y: -1, width: 28, height: 28)
        profileIcon21.backgroundColor = .custom.quoteTint
        profileIcon21.contentMode = .scaleAspectFill
        profileIcon21.layer.masksToBounds = true
        profileIcon21.imageView?.contentMode = .scaleAspectFill
        profileIcon21.contentMode = .scaleAspectFill
        profileIcon21.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        profileIcon21.alpha = 0
        profileIcon.addSubview(profileIcon21)
        
        profileIcon22.frame = CGRect(x: 26, y: 26, width: 28, height: 28)
        profileIcon22.backgroundColor = .custom.quoteTint
        profileIcon22.contentMode = .scaleAspectFill
        profileIcon22.layer.masksToBounds = true
        profileIcon22.imageView?.contentMode = .scaleAspectFill
        profileIcon22.contentMode = .scaleAspectFill
        profileIcon22.accessibilityLabel = NSLocalizedString("navigator.profile", comment: "")
        profileIcon22.alpha = 0
        profileIcon.addSubview(profileIcon22)

        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: GlobalStruct.smallerFontSize, weight: .bold)
        lockedBadge.translatesAutoresizingMaskIntoConstraints = false
        lockedBadge.backgroundColor = .clear
        lockedBadge.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: symbolConfig0)?.withTintColor(.custom.appCol, renderingMode: .alwaysOriginal)
        lockedBadge.alpha = 0
        lockedBadge.accessibilityIdentifier = "lockedBadge"
        pipView.addSubview(lockedBadge)

        lockedBackground.backgroundColor = .custom.backgroundTint
        lockedBackground.frame = CGRect(x: 57, y: 51, width: 12, height: 12)
        lockedBackground.layer.cornerRadius = 6
        lockedBackground.alpha = 0
        lockedBackground.accessibilityIdentifier = "lockedBackground"
        self.pipView.insertSubview(lockedBackground, belowSubview: lockedBadge)

        dateTime.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateTime.setContentCompressionResistancePriority(.required, for: .vertical)
        userName.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        userTag.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        postText.setContentCompressionResistancePriority(.required, for: .vertical)

        // share as image text
        shareAsImageText.translatesAutoresizingMaskIntoConstraints = false
        shareAsImageText.textAlignment = .left
        shareAsImageText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .bold)
        shareAsImageText.text = ""
        shareAsImageText.numberOfLines = 0
        shareAsImageText.accessibilityIdentifier = "shareAsImageText"
        shareAsImageText.isHidden = true
        pipView.addSubview(shareAsImageText)
        
        cwOverlay.translatesAutoresizingMaskIntoConstraints = false
        cwOverlay.backgroundColor = .custom.quoteTint
        cwOverlay.layer.cornerRadius = 8
        cwOverlay.layer.cornerCurve = .continuous
        cwOverlay.setTitleColor(.secondaryLabel, for: .normal)
        cwOverlay.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
        cwOverlay.setTitle("Sensitive Content", for: .normal)
        cwOverlay.addTarget(self, action: #selector(self.cwTap), for: .touchUpInside)
        cwOverlay.titleLabel?.numberOfLines = 0
        cwOverlay.alpha = 0
        cwOverlay.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        cwOverlay.contentVerticalAlignment = .top
        cwOverlay.contentHorizontalAlignment = .left
        pipView.addSubview(cwOverlay)

        let viewsDict = [
            "pipView" : pipView,
            "highlightBG" : highlightBG,
            "activityIndicator" : activityIndicator,
            "profileIcon" : profileIcon,
            "lockedBadge" : lockedBadge,
            "userName" : userName,
            "userTag" : userTag,
            "indicator" : indicator,
            "dateTime" : dateTime,
            "postText" : postText,
            "collectionView1" : collectionView1!,
            "countButtonBG" : countButtonBG,
            "repostView" : repostView,
            "linkStackView" : linkStackView,
            "stackViewB" : stackViewB,
            "topThreadDot" : topThreadDot,
            "topThreadLine" : topThreadLine,
            "bottomThreadLine" : bottomThreadLine,
            "bottomThreadLine2" : bottomThreadLine2,
            "shareAsImageText" : shareAsImageText,
            "cwOverlay" : cwOverlay,
        ] as [String : Any]
        let metricsDict = [
            "smallHeight" : GlobalStruct.smallerFontSize,
            "usernameHeight" : UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize,
            "padCo" : CGFloat(GlobalStruct.padColWidth - 92)
        ]

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[shareAsImageText]-0-|", options: [], metrics: nil, views: viewsDict))

        constraintsW = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pipView]-0-|", options: [], metrics: nil, views: viewsDict)
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            constraintsW2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[pipView]-20-|", options: [], metrics: nil, views: viewsDict)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[linkStackView(padCo)]-(>=20)-|", options: [], metrics: metricsDict, views: viewsDict))
        } else {
            constraintsW2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pipView]-0-|", options: [], metrics: nil, views: viewsDict)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[linkStackView]-20-|", options: [], metrics: nil, views: viewsDict))
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && self.window?.traitCollection.horizontalSizeClass != .compact {
            constraintsW2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[pipView]-10-|", options: [], metrics: nil, views: viewsDict)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[linkStackView(padCo)]-(>=20)-|", options: [], metrics: metricsDict, views: viewsDict))
        } else {
            constraintsW2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pipView]-0-|", options: [], metrics: nil, views: viewsDict)
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[linkStackView]-20-|", options: [], metrics: nil, views: viewsDict))
        }
#endif

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[topThreadDot(2)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[topThreadLine(2)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[topThreadDot(18)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topThreadLine(18)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[bottomThreadLine(2)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[bottomThreadLine2(2)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-30-[bottomThreadLine]-0-|", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-25-[bottomThreadLine2]-8-|", options: [], metrics: nil, views: viewsDict))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[highlightBG]-0-|", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[highlightBG]-0-|", options: [], metrics: nil, views: viewsDict))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-52-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-46-[lockedBadge(20)]", options: [], metrics: nil, views: viewsDict))

        // horizontal
        if GlobalStruct.smallImages {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=85)-[countButtonBG]-47-|", options: [], metrics: nil, views: viewsDict))
        } else {
            constraintsC2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-85-[countButtonBG]", options: [], metrics: nil, views: viewsDict)
        }
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[repostView]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[stackViewB]-28-|", options: [], metrics: nil, views: viewsDict))

        // vertical
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[profileIcon(50)]-(>=14)-|", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[indicator(smallHeight)]", options: [], metrics: metricsDict, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]", options: [], metrics: metricsDict, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[dateTime(usernameHeight)]", options: [], metrics: metricsDict, views: viewsDict))
        
        // activity
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[activityIndicator(26)]", options: [], metrics: nil, views: viewsDict))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-10-[activityIndicator(26)]", options: [], metrics: nil, views: viewsDict))

        // images
        if GlobalStruct.smallImages {

        } else {
            constraintsC1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[collectionView1]-0-|", options: [], metrics: nil, views: viewsDict)
        }

        let _ = self.constraintsW.map ({ x in
            x.isActive = true
        })
        let _ = self.constraintsW2.map ({ x in
            x.isActive = true
        })
        let _ = self.constraintsC1.map ({ x in
            x.isActive = true
        })
        let _ = self.constraintsC2.map ({ x in
            x.isActive = true
        })

        pipView.backgroundColor = .clear
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-76-[cwOverlay]-10-|", options: [], metrics: nil, views: viewsDict))
    }
    
    @objc func cwTap() {
        triggerHapticImpact(style: .light)
        self.cwOverlay.alpha = 0
        GlobalStruct.allCW.append(self.theStat?.id ?? "")
    }
    
    func setupActivityIndicator(_ show: Bool = false, type: Int = 0) {
        self.activityIndicator.imageEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        self.activityIndicator.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        if show {
            self.activityIndicator.alpha = 1
            let symbolConfig2 = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
            if type == 0 {
                self.activityIndicator.backgroundColor = UIColor.systemBlue
                self.activityIndicator.setImage(UIImage(systemName: "person.fill", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
                self.activityIndicator.imageEdgeInsets = UIEdgeInsets(top: 2.5, left: 3, bottom: 3.5, right: 3)
                self.activityIndicator.contentEdgeInsets = UIEdgeInsets(top: 2.5, left: 3, bottom: 3.5, right: 3)
            }
            if type == 1 {
                self.activityIndicator.backgroundColor = UIColor.systemPink
                self.activityIndicator.setImage(UIImage(systemName: "heart.fill", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
            }
            if type == 2 {
                self.activityIndicator.backgroundColor = UIColor(red: 63/255, green: 180/255, blue: 78/255, alpha: 1)
                self.activityIndicator.setImage(UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
            }
            if type == 3 {
                self.activityIndicator.backgroundColor = UIColor.systemPurple
                self.activityIndicator.setImage(UIImage(systemName: "person.fill.questionmark", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
            }
            if type == 4 {
                self.activityIndicator.backgroundColor = UIColor.systemIndigo
                self.activityIndicator.setImage(UIImage(systemName: "chart.pie.fill", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
            }
            if type == 5 {
                self.activityIndicator.backgroundColor = UIColor(red: 248/255, green: 115/255, blue: 65/255, alpha: 1)
                self.activityIndicator.setImage(UIImage(systemName: "heart.text.square.fill", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
                self.activityIndicator.imageEdgeInsets = UIEdgeInsets(top: 3, left: 2.5, bottom: 3, right: 3.5)
                self.activityIndicator.contentEdgeInsets = UIEdgeInsets(top: 3, left: 2.5, bottom: 3, right: 3.5)
            }
            if type == 6 {
                self.activityIndicator.backgroundColor = UIColor.systemYellow
                self.activityIndicator.setImage(UIImage(systemName: "pencil.circle.fill", withConfiguration: symbolConfig2)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal), for: .normal)
            }
        } else {
            self.activityIndicator.alpha = 0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    var theStat: Status? = nil
    func setupConstraints(containsImages: Bool, quotePostCard: Card?, containsRepost: Bool, imageHeight: CGFloat = 220, inDetail: Bool = false, containsPoll: Bool, pollOptions: Poll?, link: Card? = nil, showButtons: Bool = true, stat: Status? = nil, acc: Account? = nil, activity: Bool = false) {
        var pollOptions = pollOptions
        self.widthCo?.isActive = false
        self.theStat = stat
        
        if GlobalStruct.circleProfiles {
            profileIcon.layer.cornerRadius = 25
            repostView.repostProfileIcon.layer.cornerRadius = 10
        } else {
            profileIcon.layer.cornerRadius = 8
            repostView.repostProfileIcon.layer.cornerRadius = 2
        }
        repliesText.isHidden = false
        repostsText.isHidden = false
        likesText.isHidden = false

        if self.isHidden {} else {
            self.userTag.sizeToFit()

            // remove spaces within posts
            if (postText.text ?? "").suffix(2) == "\n\n" {
                postText.text = String(String((postText.text ?? "").dropLast()).dropLast())
            }
            
            if stat?.reblog?.emojis.isEmpty ?? stat?.emojis.isEmpty ?? false {

            } else {
                var attributedString = NSMutableAttributedString(string: "\(stat?.reblog?.content.stripHTML() ?? stat?.content.stripHTML() ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
                if activity {
                    attributedString = NSMutableAttributedString(string: "\(stat?.reblog?.content.stripHTML() ?? stat?.content.stripHTML() ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .regular), NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel])
                }
                if let z = stat?.reblog?.emojis ?? stat?.emojis {
                    let _ = z.map({
                        let textAttachment = NSTextAttachment()
                        textAttachment.kf.setImage(with: $0.url, attributedView: self.postText, completionHandler:  { r in
                            self.postText.setNeedsDisplay()
                        })
                        textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.postText.font.lineHeight - 6), height: Int(self.postText.font.lineHeight - 6))
                        let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                        while attributedString.mutableString.contains(":\($0.shortcode):") {
                            let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                            attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                        }
                    })
#if !targetEnvironment(macCatalyst)
                    self.postText.attributedText = attributedString
#endif
                }
            }

            if stat?.reblog?.account?.emojis.isEmpty ?? stat?.account?.emojis.isEmpty ?? false {

            } else {
                let attributedString = NSMutableAttributedString(string: "\(stat?.reblog?.account?.displayName ?? stat?.account?.displayName ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
                if let z = stat?.reblog?.account?.emojis ?? stat?.account?.emojis {
                    let _ = z.map({
                        let textAttachment = NSTextAttachment()
                        textAttachment.kf.setImage(with: $0.url, attributedView: self.userName, completionHandler:  { r in
                            self.userName.setNeedsDisplay()
                        })
                        textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.userName.font.lineHeight - 6), height: Int(self.userName.font.lineHeight - 6))
                        let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                        while attributedString.mutableString.contains(":\($0.shortcode):") {
                            let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                            attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                        }
                    })
#if !targetEnvironment(macCatalyst)
                    self.userName.attributedText = attributedString
#endif
                }
            }
            
            if let _ = stat?.reblog {
                if let ur = URL(string: stat?.account?.avatar ?? "") {
                    repostView.repostProfileIcon.sd_setImage(with: ur)
                }
                
                let myString = stat?.account?.displayName ?? ""
                let regex = try? NSRegularExpression(pattern: "\\:(.*?)\\:", options: .caseInsensitive)
                let range = NSMakeRange(0, myString.count)
                let modString = regex?.stringByReplacingMatches(in: myString, options: [], range: range, withTemplate: "") ?? myString
                if modString == "" || modString == " " {
                    repostView.repostText.text = "@\(stat?.account?.acct ?? "")"
                } else {
                    repostView.repostText.text = modString
                }
            }
            
            if acc?.emojis.isEmpty ?? false {

            } else {
                let attributedString = NSMutableAttributedString(string: "\(acc?.displayName ?? "")", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.custom.mainTextColor.withAlphaComponent(0.85)])
                if let z = acc?.emojis {
                    let _ = z.map({
                        let textAttachment = NSTextAttachment()
                        textAttachment.kf.setImage(with: $0.url, attributedView: self.userName, completionHandler:  { r in
                            self.userName.setNeedsDisplay()
                        })
                        textAttachment.bounds = CGRect(x:0, y: Int(-2), width: Int(self.userName.font.lineHeight - 6), height: Int(self.userName.font.lineHeight - 6))
                        let attrStringWithImage = NSAttributedString(attachment: textAttachment)
                        while attributedString.mutableString.contains(":\($0.shortcode):") {
                            let range: NSRange = (attributedString.mutableString as NSString).range(of: ":\($0.shortcode):")
                            attributedString.replaceCharacters(in: range, with: attrStringWithImage)
                        }
                    })
#if !targetEnvironment(macCatalyst)
                    self.userName.attributedText = attributedString
#endif
                }
            }

            let cust = GlobalStruct.customTextSize

            let viewsDict = [
                "profileIcon" : profileIcon,
                "userName" : userName,
                "userTag" : userTag,
                "indicator" : indicator,
                "dateTime" : dateTime,
                "postText" : postText,
                "collectionView1" : collectionView1!,
                "countButtonBG" : countButtonBG,
                "repostView" : repostView,
                "pollStack" : pollStack,
                "linkStackView" : linkStackView,
                "stackViewB" : stackViewB,
                "cwOverlay" : cwOverlay,
            ] as [String : Any]
            let metricsDict = [
                "smallHeight" : GlobalStruct.smallerFontSize,
                "usernameHeight" : UIFont.preferredFont(forTextStyle: .body).pointSize + cust
            ]

            if showButtons {
                self.stackViewB.isHidden = false
            } else {
                self.stackViewB.isHidden = true
            }

            var tag1 = "[userName]-4-[userTag]"
            
            if GlobalStruct.displayName == .full {
                self.userName.isHidden = false
                self.userTag.isHidden = false
                self.linkUsername.isHidden = false
                self.linkUsertag.isHidden = false
                tag1 = "[userName]-4-[userTag]"
            } else if GlobalStruct.displayName == .usernameOnly {
                self.userName.isHidden = false
                self.userTag.isHidden = true
                self.linkUsername.isHidden = false
                self.linkUsertag.isHidden = true
                tag1 = "[userName]-0-[userTag]"
            } else if GlobalStruct.displayName == .usertagOnly {
                self.userName.text = ""
                self.userName.isHidden = true
                self.userTag.isHidden = false
                self.linkUsername.text = ""
                self.linkUsername.isHidden = true
                self.linkUsertag.isHidden = false
                tag1 = "[userName]-0-[userTag]"
            } else {    // .none
                self.userName.isHidden = true
                self.userTag.isHidden = true
                self.linkUsername.isHidden = true
                self.linkUsertag.isHidden = true
                tag1 = "[userName]-0-[userTag]"
            }

            self.removeConstraints(constraintsOther)
            self.removeConstraints(constraints0)
            self.removeConstraints(constraints1)
            self.removeConstraints(constraints2)
            self.removeConstraints(constraintsS)
            self.removeConstraints(constraintsS2)
            
            let _ = self.constraints0.map ({ x in
                x.isActive = false
            })
            self.constraints0 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-\(tag1)-(>=5)-[indicator(smallHeight)]-2-[dateTime]-16-|", options: [], metrics: metricsDict, views: viewsDict)
            let _ = self.constraints0.map ({ x in
                x.isActive = true
            })
            self.addConstraints(constraints0)

            linkPost.numberOfLines = 0
            self.linkStr = link
            
            if let link {
                self.setupLinkPreview(link)
            } else if let quotePostCard {
                self.setupQuotePostPreview(quotePostCard)
            } else {
                linkStackView.isHidden = true
            }

            var inlineDiff0 = "12"
            var inlineDiff = "12"
            var inlineDiff1 = ""
            
            if showButtons {
                inlineDiff0 = "12-[stackViewB]-10"
                inlineDiff = "12-[stackViewB]-14"
                inlineDiff1 = "[stackViewB]"
            }

            var postTextDiff = "-4-[postText]-6-"
            var postTextDiffb = "-4-[postText]-15-"
            var postTextDiff2 = "-4-[postText]-14-"
            var postTextDiff2b = "-4-[postText]-19-"
            var postTextDiffs = "-4-[postText]-(>=10)-"
            var postTextDiff2s = "-4-[postText]-(>=14)-"
            if postText.text == "" || postText.text == " " {
                postTextDiff = "-6-"
                postTextDiffb = "-15-"
                postTextDiff2 = "-14-"
                postTextDiff2b = "-19-"
                postTextDiffs = "-(>=10)-"
                postTextDiff2s = "-(>=14)-"
            }

            let _ = self.constraintsS.map ({ x in
                x.isActive = false
            })
            let _ = self.constraintsS2.map ({ x in
                x.isActive = false
            })
            let _ = self.constraints1.map ({ x in
                x.isActive = false
            })
            let _ = self.constraints2.map ({ x in
                x.isActive = false
            })

            pollStack.isHidden = true

            if GlobalStruct.hideMed {
                self.linkCollectionView1.isHidden = true
                self.conQ1 = self.linkCollectionView1.heightAnchor.constraint(equalToConstant: 0)
            }
                
            if (containsImages && GlobalStruct.hideMed == false) {
                if GlobalStruct.smallImages {
                    constraintsS = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[postText]-8-[collectionView1(66)]-16-|", options: [], metrics: nil, views: viewsDict)
                    let _ = self.constraintsS.map ({ x in
                        x.isActive = true
                    })
                } else {
                    constraintsS = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[postText]-16-|", options: [], metrics: nil, views: viewsDict)
                    let _ = self.constraintsS.map ({ x in
                        x.isActive = true
                    })
                }
                if (quotePostCard != nil) || (link != nil) {
                    countButtonBG.isHidden = false
                    collectionView1.isHidden = false
                    if containsRepost {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = false
                        if GlobalStruct.smallImages {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiffs)[linkStackView]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsS2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-6-[collectionView1]-(>=12)-[linkStackView]", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraintsS2.map ({ x in
                                x.isActive = true
                            })
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-11-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        } else {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[collectionView1]-14-[linkStackView]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]\(postTextDiffb)[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        }
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    } else {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-10-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = true
                        if GlobalStruct.smallImages {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiffs)[linkStackView]-\(inlineDiff)-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsS2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-6-[collectionView1]-(>=12)-[linkStackView]", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraintsS2.map ({ x in
                                x.isActive = true
                            })
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-11-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        } else {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[collectionView1]-14-[linkStackView]-\(inlineDiff)-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]\(postTextDiffb)[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        }
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    }
                } else {
                    countButtonBG.isHidden = false
                    collectionView1.isHidden = false
                    if containsRepost {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = false
                        if GlobalStruct.smallImages {
                            var a1 = "V:|-14-[userName(usernameHeight)]\(postTextDiff2s)\(inlineDiff1)-[repostView(20)]-14-|"
                            a1 = a1.replacingOccurrences(of: "--", with: "-")
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: a1, options: [], metrics: metricsDict, views: viewsDict)
                            if inlineDiff1 == "" {
                                inlineDiff1 = "|"
                            }
                            constraintsS2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-6-[collectionView1]-(>=12)-\(inlineDiff1)", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraintsS2.map ({ x in
                                x.isActive = true
                            })
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-11-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        } else {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff2)[collectionView1]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]\(postTextDiff2b)[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        }
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    } else {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-10-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = true
                        if GlobalStruct.smallImages {
                            var diffText = "V:|-14-[userName(usernameHeight)]\(postTextDiff2s)\(inlineDiff1)-10-|"
                            diffText = diffText.replacingOccurrences(of: "--", with: "-").replacingOccurrences(of: "(>=14)-10", with: "10")
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: diffText, options: [], metrics: metricsDict, views: viewsDict)
                            if inlineDiff1 == "" {
                                inlineDiff1 = "|"
                            }
                            constraintsS2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-6-[collectionView1]-(>=12)-\(inlineDiff1)", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraintsS2.map ({ x in
                                x.isActive = true
                            })
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]-11-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        } else {
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff2)[collectionView1]-\(inlineDiff)-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[userName(usernameHeight)]\(postTextDiff2b)[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        }
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    }
                }
            } else {
                constraintsS = NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[profileIcon(50)]-12-[postText]-16-|", options: [], metrics: nil, views: viewsDict)
                let _ = self.constraintsS.map ({ x in
                    x.isActive = true
                })
                if (quotePostCard != nil) || (link != nil) {
                    countButtonBG.isHidden = true
                    collectionView1.isHidden = true
                    if containsRepost {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = false
                        constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[linkStackView]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[linkStackView]-19-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    } else {
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-10-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)
                        repostView.isHidden = true
                        constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[linkStackView]-\(inlineDiff)-|", options: [], metrics: metricsDict, views: viewsDict)
                        constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[linkStackView]-19-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                        let _ = self.constraints1.map ({ x in
                            x.isActive = true
                        })
                        let _ = self.constraints2.map ({ x in
                            x.isActive = true
                        })
                    }
                } else {
                    countButtonBG.isHidden = true
                    collectionView1.isHidden = true
                    
                    if containsPoll {
                        // poll
                        if GlobalStruct.votedOnPolls[self.pollId] != nil {
                            if pollOptions?.voted ?? false && (pollOptions?.id ?? "" == self.pollId) {
                                pollOptions = GlobalStruct.votedOnPolls[self.pollId]
                            }
                        }
                        
                        self.pollId = pollOptions?.id ?? ""
                        
                        for x in pollStack.arrangedSubviews {
                            pollStack.removeArrangedSubview(x)
                        }
                        for x in pollStack.subviews {
                            x.removeFromSuperview()
                        }
                        pollStack.removeFromSuperview()

                        if let pOp = pollOptions?.options {
                            var totalVotes = 0
                            _ = pOp.map({ x in
                                totalVotes += x.votesCount ?? 0
                            })

                            // add poll end or ended time

                            var tVote = "\(totalVotes.withCommas()) votes"
                            if totalVotes == 1 {
                                tVote = "\(totalVotes.withCommas()) vote"
                            }

                            let date1 = pollOptions?.expiresAt ?? ""
                            var tText = "ends in"
                            var tText2 = ""
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = GlobalStruct.dateFormat
                            let date = dateFormatter.date(from: date1)
                            
                            var diff = getMinutesDifferenceFromTwoDates(start: Date(), end: date ?? Date())
                            var mVote = "\(diff) minutes"
                            if diff == 1 {
                                mVote = "\(diff) minute"
                            }
                            if diff > 60 {
                                diff = diff/60
                                mVote = "\(diff) hours"
                                if diff == 1 {
                                    mVote = "\(diff) hour"
                                }
                            } else if diff < 0 {
                                tText = "ended"
                                tText2 = "ago"
                                diff = diff * -1
                                mVote = "\(diff) minutes"
                                if diff == 1 {
                                    mVote = "\(diff) minute"
                                }
                                if diff > 60 {
                                    diff = diff/60
                                    mVote = "\(diff) hours"
                                    if diff == 1 {
                                        mVote = "\(diff) hour"
                                    }
                                    if diff > 24 {
                                        diff = diff/24
                                        mVote = "\(diff) days"
                                        if diff == 1 {
                                            mVote = "\(diff) day"
                                        }
                                        if diff > 30 {
                                            diff = diff/30
                                            mVote = "\(diff) months"
                                            if diff == 1 {
                                                mVote = "\(diff) month"
                                            }
                                        }
                                    }
                                }
                            }
                            
                            for (c,x) in pOp.enumerated() {
                                let barText = UIButton()
                                barText.frame = CGRect(x: 0, y: 0, width: self.bounds.width - 80, height: 40)
                                barText.backgroundColor = .clear
                                barText.setTitle("  \(x.title)  ", for: .normal)
                                barText.setTitleColor(.label, for: .normal)
                                barText.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                                barText.titleLabel?.textAlignment = .left
                                barText.contentHorizontalAlignment = .left
                                barText.layer.cornerRadius = 6
                                barText.layer.masksToBounds = true
                                barText.tag = c
                                if tText != "ended" {
                                    let bGesture = UITapGestureRecognizer(target: self, action: #selector(self.pollOptionsTap(_:)))
                                    barText.addGestureRecognizer(bGesture)
                                }
                                barText.titleLabel?.lineBreakMode = .byTruncatingTail

                                let underlay = UIView()
                                underlay.layer.cornerRadius = 6
                                underlay.layer.masksToBounds = true
                                if (pollOptions?.voted ?? false) || (tText == "ended") || ((pollOptions?.voted ?? false) && GlobalStruct.votedOnPolls[self.pollId] != nil) {
                                    if let own = pollOptions?.ownVotes, own.contains(c) {
                                        underlay.backgroundColor = .custom.baseTint
                                    } else {
                                        underlay.backgroundColor = .custom.baseTint.withAlphaComponent(0.5)
                                    }
                                    if totalVotes == 0 {
                                        underlay.frame = CGRect(x: 0, y: 0, width: 0, height: 32)
                                    } else {
                                        let diff = (Double(x.votesCount ?? 0)/Double(totalVotes))
                                        var wid9 = UIScreen.main.bounds.size.width
                                        if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {} else {
                                            wid9 = CGFloat(GlobalStruct.padColWidth)
                                        }
                                        underlay.frame = CGRect(x: 0, y: 0, width: CGFloat((((wid9 - 120) - 40) * (diff))), height: 32)
                                    }
                                } else {
                                    underlay.backgroundColor = .custom.backgroundTint
                                    var wid9 = UIScreen.main.bounds.size.width
                                    if GlobalStruct.isCompact || UIDevice.current.userInterfaceIdiom == .phone {} else {
                                        wid9 = CGFloat(GlobalStruct.padColWidth)
                                    }
                                    underlay.frame = CGRect(x: 0, y: 0, width: CGFloat(wid9 - 120), height: 32)
                                }
                                underlay.removeFromSuperview()
                                barText.insertSubview(underlay, at: 0)

                                let barDetail = UILabel()
                                barDetail.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
                                if pollOptions?.voted ?? false {
                                    if totalVotes == 0 {
                                        barDetail.text = "0%"
                                    } else {
                                        let diff = Int((Double(x.votesCount ?? 0)/Double(totalVotes))*100)
                                        barDetail.text = "\(diff)%"
                                    }
                                } else {
                                    barDetail.text = ""
                                }
                                barDetail.textColor = .label
                                barDetail.font = UIFont.systemFont(ofSize: 16, weight: .regular)
                                barDetail.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

                                let bar1 = UIStackView()
                                bar1.addArrangedSubview(barText)
                                bar1.addArrangedSubview(barDetail)
                                bar1.alignment = .center
                                bar1.axis = .horizontal
                                bar1.distribution = .fill
                                bar1.spacing = 10

                                pollStack.addArrangedSubview(bar1)
                            }

                            let endPoll = UILabel()
                            endPoll.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
                            endPoll.text = "\(tVote) • Poll \(tText) \(mVote) \(tText2)"
                            endPoll.textColor = .secondaryLabel
                            endPoll.textAlignment = .center
                            endPoll.font = UIFont.systemFont(ofSize: 14, weight: .regular)

                            pollStack.addArrangedSubview(endPoll)

                        }

                        pollStack.translatesAutoresizingMaskIntoConstraints = false
                        pollStack.alignment = .fill
                        pollStack.axis = .vertical
                        pollStack.distribution = .equalSpacing
                        pollStack.spacing = 8
                        pollStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
                        pollStack.isLayoutMarginsRelativeArrangement = true
                        pollStack.backgroundColor = .custom.quoteTint
                        pollStack.layer.cornerRadius = 8
                        pollStack.layer.masksToBounds = true
                        pollStack.layer.borderWidth = 0.4
                        pollStack.layer.borderColor = UIColor.label.withAlphaComponent(0.2).cgColor
                        self.pipView.addSubview(pollStack)
                        
                        self.pipView.bringSubviewToFront(self.cwOverlay)

                        pollStack.isHidden = false
                        let constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-80-[pollStack]-20-|", options: [], metrics: nil, views: viewsDict)
                        constraintsOther.append(contentsOf: constraints)
                        self.addConstraints(constraints)

                        if containsRepost {
                            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsOther.append(contentsOf: constraints)
                            self.addConstraints(constraints)
                            repostView.isHidden = false
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[pollStack]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-19-[countButtonBG]", options: [], metrics: nil, views: viewsDict)
                            let _ = self.constraints1.map ({ x in
                                x.isActive = true
                            })
                            let _ = self.constraints2.map ({ x in
                                x.isActive = true
                            })
                        } else {
                            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-10-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsOther.append(contentsOf: constraints)
                            self.addConstraints(constraints)
                            repostView.isHidden = true
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]\(postTextDiff)[pollStack]-\(inlineDiff)-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-19-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraints1.map ({ x in
                                x.isActive = true
                            })
                            let _ = self.constraints2.map ({ x in
                                x.isActive = true
                            })
                        }
                        
                    } else {
                        
                        if containsRepost {
                            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsOther.append(contentsOf: constraints)
                            self.addConstraints(constraints)
                            repostView.isHidden = false
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]-4-[postText]-\(inlineDiff0)-[repostView(20)]-14-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-19-[countButtonBG]", options: [], metrics: nil, views: viewsDict)
                            let _ = self.constraints1.map ({ x in
                                x.isActive = true
                            })
                            let _ = self.constraints2.map ({ x in
                                x.isActive = true
                            })
                        } else {
                            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userTag(usernameHeight)]-4-[cwOverlay]-10-|", options: [], metrics: metricsDict, views: viewsDict)
                            constraintsOther.append(contentsOf: constraints)
                            self.addConstraints(constraints)
                            repostView.isHidden = true
                            let dif = "-\(inlineDiff)-|"
                            constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-14-[userName(usernameHeight)]-4-[postText]\(dif)", options: [], metrics: metricsDict, views: viewsDict)
                            constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:[postText]-19-[countButtonBG]", options: [], metrics: metricsDict, views: viewsDict)
                            let _ = self.constraints1.map ({ x in
                                x.isActive = true
                            })
                            let _ = self.constraints2.map ({ x in
                                x.isActive = true
                            })
                        }
                        
                    }

                }
            }
        }
    }
    
    var pollId: String = ""
    @objc func pollOptionsTap(_ sender: UITapGestureRecognizer) {
        triggerHapticImpact(style: .light)
        let alert = UIAlertController(title: "Vote for '\((sender.view as? UIButton)?.titleLabel?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")'?", message: "You cannot change your vote once you have voted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Vote", style: .default , handler:{ (UIAlertAction) in
            self.voteOnThis(sender.view?.tag ?? 0)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            
        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = getTopMostViewController()?.view
            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    func voteOnThis(_ sender: Int) {
        let request = Polls.vote(id: self.pollId, choices: [sender])
        AccountsManager.shared.currentAccountClient.run(request) { (statuses) in
            if let err = statuses.error {
                if "\(err)".contains("ended") {
                    DispatchQueue.main.async {
                        triggerHapticNotification(feedback: .warning)
                        let alert = UIAlertController(title: "Poll Ended", message: "You can't vote on this poll as it has already ended.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                            
                        }))
                        if let presenter = alert.popoverPresentationController {
                            presenter.sourceView = getTopMostViewController()?.view
                            presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                        }
                        getTopMostViewController()?.present(alert, animated: true, completion: nil)
                    }
                } else {
                    if "\(err)".contains("already voted") {
                        DispatchQueue.main.async {
                            triggerHapticNotification(feedback: .warning)
                            let alert = UIAlertController(title: "Already Voted", message: "You can't vote on this poll as you have already voted on it.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
                                
                            }))
                            if let presenter = alert.popoverPresentationController {
                                presenter.sourceView = getTopMostViewController()?.view
                                presenter.sourceRect = getTopMostViewController()?.view.bounds ?? .zero
                            }
                            getTopMostViewController()?.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
            if let poll = statuses.value {
                log.debug("Vote Sent")
                DispatchQueue.main.async {
                    triggerHapticNotification()
                    GlobalStruct.votedOnPolls[self.pollId] = poll
                    do {
                        try Disk.save(GlobalStruct.votedOnPolls, to: .documents, as: "votedOnPolls.json")
                    } catch {
                        log.error("error saving votedOnPolls to Disk")
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "pollVoted"), object: nil)
                }
            }
        }
    }

    // images

    var imagesFull: [Attachment] = []
    var images: [String] = []
    var images2: [UIImageView] = []
    var images3: [String] = []
    let countButtonBG = UIButton()
    let countButton = UIButton()
    var allCounts: Int = 0
    var currentIndex: Int = 0
    var dataImages: [Data?] = []

    var linkImages: [String] = []
    var linkImages2: [UIImageView] = []
    var linkImages3: [String] = []
    var linkAllCounts: Int = 0
    var linkCurrentIndex: Int = 0
    var linkDataImages: [Data?] = []
    let linkCountButtonBG = UIButton()
    let linkCountButton = UIButton()

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView1 {
            if dataImages.isEmpty {
                return self.images.count
            } else {
                return self.dataImages.count
            }
        } else {
            if self.lpImage != UIImage() {
                return 1
            } else {
                if linkDataImages.isEmpty {
                    return self.linkImages.count
                } else {
                    return self.linkDataImages.count
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var image1: UIImage = UIImage()
        if GlobalStruct.smallImages {
            if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellS {
                image1 = cell.image.image ?? UIImage()
            }
        } else {
            if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
                image1 = cell.image.image ?? UIImage()
            }
            if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
                image1 = cell.image.image ?? UIImage()
            }
        }
        if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell2 {
            image1 = cell.image.image ?? UIImage()
        }
        if let cell = linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCell2 {
            image1 = cell.image.image ?? UIImage()
        }
        if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell3 {
            image1 = cell.image.image ?? UIImage()
        }
        let itemProvider = NSItemProvider(object: image1)
        return [UIDragItem(itemProvider: itemProvider)]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        previewParameters.backgroundColor = UIColor.clear
        if GlobalStruct.smallImages {
            previewParameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 50, height: 50), cornerRadius: 8)
        } else {
            if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                previewParameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220), cornerRadius: 10)
            } else {
                #if targetEnvironment(macCatalyst)
                previewParameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 80, y: 0, width: CGFloat(GlobalStruct.padColWidth - 100), height: 220), cornerRadius: 10)
                #else
                previewParameters.visiblePath = UIBezierPath(roundedRect: CGRect(x: 80, y: 0, width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 220), cornerRadius: 10)
                #endif
            }
        }
        return previewParameters
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView1 {
            if inDetail {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCell3", for: indexPath) as! CollectionImageCell3
                if self.images.isEmpty {

                } else {
                    cell.configure()
                    if indexPath.item == 0 {
                        if self.altText.count > 0 && !self.altText[0].isEmpty {
                            cell.altTextButton.alpha = 1
                            cell.image.accessibilityLabel = self.altText[0]
                        }
                    }
                    if indexPath.item == 1 {
                        if self.altText.count > 1 && !self.altText[1].isEmpty {
                            cell.altTextButton.alpha = 1
                            cell.image.accessibilityLabel = self.altText[1]
                        }
                    }
                    if indexPath.item == 2 {
                        if self.altText.count > 2 && !self.altText[2].isEmpty {
                            cell.altTextButton.alpha = 1
                            cell.image.accessibilityLabel = self.altText[2]
                        }
                    }
                    if indexPath.item == 3 {
                        if self.altText.count > 3 && !self.altText[3].isEmpty {
                            cell.altTextButton.alpha = 1
                            cell.image.accessibilityLabel = self.altText[3]
                        }
                    }
                    cell.altTextButton.tag = indexPath.item
                    cell.altTextButton.addTarget(self, action: #selector(self.altTextTap), for: .touchUpInside)
                    cell.image.contentMode = .scaleAspectFill
                    
                    if let ur = URL(string: self.images[indexPath.item]) {
                        cell.image.sd_setImage(with: ur)
                    }
                    cell.image.layer.masksToBounds = true
                }
                cell.backgroundColor = .clear
                for x in cell.image.subviews {
                    x.removeFromSuperview()
                }
                if (self.theStat?.reblog?.sensitive ?? self.theStat?.sensitive ?? false) && GlobalStruct.blurSensitiveContent {
                    let blurEffect = UIBlurEffect(style: .regular)
                    var blurredEffectView = UIVisualEffectView()
                    blurredEffectView = UIVisualEffectView(effect: blurEffect)
                    blurredEffectView.frame = cell.image.bounds
                    blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    cell.image.addSubview(blurredEffectView)
                }
                return cell
            } else {
                if GlobalStruct.smallImages {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCellS", for: indexPath) as! CollectionImageCellS
                    if self.images.isEmpty {

                    } else {
                        cell.configure()
                        cell.image.contentMode = .scaleAspectFill
                        if let ur = URL(string: self.images[indexPath.item]) {
                            cell.image.sd_setImage(with: ur)
                        }
                        cell.image.layer.masksToBounds = true
                    }
                    cell.backgroundColor = .clear
                    for x in cell.image.subviews {
                        x.removeFromSuperview()
                    }
                    if (self.theStat?.reblog?.sensitive ?? self.theStat?.sensitive ?? false) && GlobalStruct.blurSensitiveContent {
                        let blurEffect = UIBlurEffect(style: .regular)
                        var blurredEffectView = UIVisualEffectView()
                        blurredEffectView = UIVisualEffectView(effect: blurEffect)
                        blurredEffectView.frame = cell.image.bounds
                        blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                        cell.image.addSubview(blurredEffectView)
                    }
                    return cell
                } else {
                    if self.imageHeight == 220 {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCell", for: indexPath) as! CollectionImageCell
                        if self.images.isEmpty {} else {
                            cell.configure()
                            if indexPath.item == 0 {
                                if self.altText.count > 0 && !self.altText[0].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[0]
                                }
                            }
                            if indexPath.item == 1 {
                                if self.altText.count > 1 && !self.altText[1].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[1]
                                }
                            }
                            if indexPath.item == 2 {
                                if self.altText.count > 2 && !self.altText[2].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[2]
                                }
                            }
                            if indexPath.item == 3 {
                                if self.altText.count > 3 && !self.altText[3].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[3]
                                }
                            }
                            cell.altTextButton.tag = indexPath.item
                            cell.altTextButton.addTarget(self, action: #selector(self.altTextTap), for: .touchUpInside)
                            cell.image.contentMode = .scaleAspectFill
                            if dataImages.isEmpty {
                                if let ur = URL(string: self.images[indexPath.item]) ?? URL(string: "www.google.com") {
                                    cell.image.sd_setImage(with: ur)
                                }
                            } else {
                                cell.image.image = UIImage(data: dataImages[indexPath.item] ?? Data())
                            }
                            cell.image.layer.masksToBounds = true
                        }
                        cell.backgroundColor = .clear
                        for x in cell.image.subviews {
                            x.removeFromSuperview()
                        }
                        if (self.theStat?.reblog?.sensitive ?? self.theStat?.sensitive ?? false)  && GlobalStruct.blurSensitiveContent {
                            let blurEffect = UIBlurEffect(style: .regular)
                            var blurredEffectView = UIVisualEffectView()
                            blurredEffectView = UIVisualEffectView(effect: blurEffect)
                            blurredEffectView.frame = cell.image.bounds
                            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            cell.image.addSubview(blurredEffectView)
                        }
                        return cell
                    } else {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCell2", for: indexPath) as! CollectionImageCell2
                        if self.images.isEmpty {

                        } else {
                            cell.configure()
                            if indexPath.item == 0 {
                                if self.altText.count > 0 && !self.altText[0].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[0]
                                }
                            }
                            if indexPath.item == 1 {
                                if self.altText.count > 1 && !self.altText[1].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[1]
                                }
                            }
                            if indexPath.item == 2 {
                                if self.altText.count > 2 && !self.altText[2].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[2]
                                }
                            }
                            if indexPath.item == 3 {
                                if self.altText.count > 3 && !self.altText[3].isEmpty {
                                    cell.altTextButton.alpha = 1
                                    cell.image.accessibilityLabel = self.altText[3]
                                }
                            }
                            cell.altTextButton.tag = indexPath.item
                            cell.altTextButton.addTarget(self, action: #selector(self.altTextTap), for: .touchUpInside)
                            cell.image.contentMode = .scaleAspectFill
                            if let ur = URL(string: self.images[indexPath.item]) {
                                cell.image.sd_setImage(with: ur)
                            }
                            cell.image.layer.masksToBounds = true
                        }
                        cell.backgroundColor = .clear
                        for x in cell.image.subviews {
                            x.removeFromSuperview()
                        }
                        if (self.theStat?.reblog?.sensitive ?? self.theStat?.sensitive ?? false) && GlobalStruct.blurSensitiveContent {
                            let blurEffect = UIBlurEffect(style: .regular)
                            var blurredEffectView = UIVisualEffectView()
                            blurredEffectView = UIVisualEffectView(effect: blurEffect)
                            blurredEffectView.frame = cell.image.bounds
                            blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            cell.image.addSubview(blurredEffectView)
                        }
                        return cell
                    }
                }
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCell2", for: indexPath) as! CollectionImageCell2
            if self.lpImage != UIImage() {} else {
                if self.linkImages.isEmpty {} else {
                    cell.configure()
                    cell.image.contentMode = .scaleAspectFill
                    if let ur = URL(string: self.linkImages[indexPath.item]) {
                        cell.image.sd_setImage(with: ur)
                    }
                    cell.image.layer.masksToBounds = true
                }
            }
            cell.backgroundColor = .clear
            for x in cell.image.subviews {
                x.removeFromSuperview()
            }
            if (self.theStat?.reblog?.sensitive ?? self.theStat?.sensitive ?? false) && GlobalStruct.blurSensitiveContent {
                let blurEffect = UIBlurEffect(style: .regular)
                var blurredEffectView = UIVisualEffectView()
                blurredEffectView = UIVisualEffectView(effect: blurEffect)
                blurredEffectView.frame = cell.image.bounds
                blurredEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.image.addSubview(blurredEffectView)
            }
            return cell
        }
    }

    @objc func altTextTap(_ sender: UIButton) {
        triggerHapticImpact(style: .light)
        let altTextPopup = self.altText[sender.tag]
        let alert = UIAlertController(title: nil, message: altTextPopup, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.copy", comment: ""), style: .default , handler:{ (UIAlertAction) in
            let pasteboard = UIPasteboard.general
            pasteboard.string = altTextPopup
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in

        }))
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self
            presenter.sourceRect = self.bounds
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }

    func setupLinkPreview(_ link2: Card) {
        // Only one of these two should be visible at any time
        quotePostHostView.isHidden = true
        linkStackViewHorizontal.isHidden = false

        playButtonQ.isHidden = true
        linkStackView.isHidden = false
        linkUsertag.text = ""
        linkPost.numberOfLines = 2
        linkUsername.numberOfLines = 2
        
        if GlobalStruct.linkPreviewCardsLarge == false {
            self.linkPost.isHidden = true
            self.conLP1?.isActive = false
            self.conLP2?.isActive = true
            lpImage.widthAnchor.constraint(equalToConstant: 65).isActive = true
            linkStackView.axis = .horizontal
        } else {
            self.linkPost.isHidden = false
            self.conLP1?.isActive = true
            self.conLP2?.isActive = false
            lpImage.widthAnchor.constraint(equalToConstant: 65).isActive = false
            linkStackView.axis = .vertical
        }
        
        if link2.title == "" {
            linkUsername.text = link2.authorName
        } else {
            linkUsername.text = link2.title.replacingOccurrences(of: "\n", with: " ")
        }
        if link2.description == "" {
            if let x = link2.url {
                linkPost.text = x
            }
        } else {
            linkPost.text = link2.description.replacingOccurrences(of: "\n", with: " ")
        }
        linkPost.URLColor = .secondaryLabel
        if !self.images.isEmpty {
            self.lpImage.isHidden = true
        } else {
            self.lpImage.isHidden = false
            if let x = link2.image?.absoluteString {
                if let profileURL = URL(string: x) {
                    self.lpImage.sd_setImage(with: profileURL, completed: nil)
                } else {
                    self.lpImage.isHidden = true
                }
            } else {
                self.lpImage.isHidden = true
            }
        }
        self.linkCollectionView1.isHidden = true
        self.conQ1 = self.linkCollectionView1.heightAnchor.constraint(equalToConstant: 0)
    }
    
    func setupQuotePostPreview(_ link2: Card) {
        // Only one of these two should be visible at any time
        quotePostHostView.isHidden = false
        linkStackView.isHidden = true
        linkStackViewHorizontal.isHidden = true

        playButtonQ.isHidden = true
        linkStackView.isHidden = false

        linkUsertag.text = ""
        linkPost.numberOfLines = 0
        linkUsername.numberOfLines = 2
        

        self.linkPost.isHidden = true
        
        
        self.conLP1?.isActive = false
        self.conLP2?.isActive = false
        lpImage.widthAnchor.constraint(equalToConstant: 65).isActive = false
        linkStackView.axis = .vertical

        
        if link2.title == "" {
            linkUsername.text = link2.authorName
        } else {
            linkUsername.text = link2.title.replacingOccurrences(of: "\n", with: " ")
        }
        if link2.description == "" {
            if let x = link2.url {
                linkPost.text = x
            }
        } else {
            linkPost.text = link2.description.replacingOccurrences(of: "\n", with: " ")
        }
        linkPost.URLColor = .secondaryLabel
        if !self.images.isEmpty {
            self.lpImage.isHidden = true
        } else {
            self.lpImage.isHidden = false
            if let x = link2.image?.absoluteString {
                if let profileURL = URL(string: x) {
                    self.lpImage.sd_setImage(with: profileURL, completed: nil)
                } else {
                    self.lpImage.isHidden = true
                }
            } else {
                self.lpImage.isHidden = true
            }
        }
        self.linkCollectionView1.isHidden = true
        self.conQ1 = self.linkCollectionView1.heightAnchor.constraint(equalToConstant: 0)
        
        // This is the important part for quote posts
        let cardURL = URL(string: link2.url ?? "")
        self.quotePostHostView.updateForQuotePost(cardURL)
    }

    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        return []
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }

    func makeContextMenu() -> UIMenu {
        let openLink = UIAction(title: "Open Link", image: UIImage(systemName: "safari"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                if let ur = URL(string: x) {
                    PostActions.openLink(ur)
                }
            }
        }
        let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                UIPasteboard.general.string = x
            }
        }
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
            if let x = self.linkStr?.url {
                let linkToShare = [x]
                let activityViewController = UIActivityViewController(activityItems: linkToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self
                activityViewController.popoverPresentationController?.sourceRect = self.bounds
                getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, children: [openLink, copy, share])
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        if collectionView == self.linkCollectionView1 {
            return nil
        } else {
            if GlobalStruct.smallImages {
                if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellS {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else {
                    return nil
                }
            } else {
                if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else {
                    return nil
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath else { return nil }
        if collectionView == self.linkCollectionView1 {
            return nil
        } else {
            if GlobalStruct.smallImages {
                if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellS {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else {
                    return nil
                }
            } else {
                if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else if let cell = collectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
                    let parameters = UIPreviewParameters()
                    parameters.backgroundColor = .clear
                    return UITargetedPreview(view: cell.image, parameters: parameters)
                } else {
                    return nil
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: {
            if self.videoUrl != "" {
                return self.makePreviewV()
            } else if self.videoUrlQ != "" {
                return self.makePreviewV2()
            } else {
                if collectionView == self.collectionView1 {
                    return self.makePreview(indexPath.row)
                } else {
                    return self.makePreview2(0)
                }
            }
        }, actionProvider: { suggestedActions in
            return self.makeContextMenu(indexPath.row, collectionView: collectionView)
        })
    }

    func makePreviewV() -> UIViewController {
        let viewController = UIViewController()
        let asset = AVAsset(url: URL(string: self.videoUrl)!)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.play()
        let playerLayer = AVPlayerLayer(player: player)
        let size = asset.videoSize ?? .zero
        var ratioS: CGFloat = 1
        if size.height == 0 {} else {
            ratioS = size.width/size.height
        }
        if size.height >= (size.width * 2) {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.width/2/ratioS)
        } else {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
        }
        playerLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(playerLayer)
        viewController.preferredContentSize = playerLayer.frame.size
        return viewController
    }

    func makePreviewV2() -> UIViewController {
        let viewController = UIViewController()
        let asset = AVAsset(url: URL(string: self.videoUrlQ)!)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.play()
        let playerLayer = AVPlayerLayer(player: player)
        let size = asset.videoSize ?? .zero
        var ratioS: CGFloat = 1
        if size.height == 0 {} else {
            ratioS = size.width/size.height
        }
        if size.height >= (size.width * 2) {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.width/2/ratioS)
        } else {
            playerLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
        }
        playerLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(playerLayer)
        viewController.preferredContentSize = playerLayer.frame.size
        return viewController
    }

    func makePreview(_ index: Int) -> UIViewController {
        if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCellS {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCell {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCellActivity {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCell2 {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else if let cell = collectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCell3 {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else {
            return UIViewController()
        }
    }

    func makePreview2(_ index: Int) -> UIViewController {
        if let cell = linkCollectionView1.cellForItem(at: IndexPath(row: index, section: 0)) as? CollectionImageCell2 {
            let theImage = cell.image.image ?? UIImage()
            let viewController = UIViewController()
            let imageView = UIImageView(image: theImage)
            viewController.view = imageView
            var ratioS: CGFloat = 1
            if theImage.size.height == 0 {} else {
                ratioS = theImage.size.width/theImage.size.height
            }
            if theImage == UIImage() {
                imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            } else {
                imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/ratioS)
            }
            imageView.contentMode = .scaleAspectFit
            viewController.preferredContentSize = imageView.frame.size
            return viewController
        } else {
            return UIViewController()
        }
    }

    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        var image1: UIImage = UIImage()
        if self.tmpCollection == self.collectionView1 {
            if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCellS {
                image1 = cell.image.image ?? UIImage()
            }
            if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCell {
                image1 = cell.image.image ?? UIImage()
            }
            if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCellActivity {
                image1 = cell.image.image ?? UIImage()
            }
            if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCell2 {
                image1 = cell.image.image ?? UIImage()
            }
            if let cell = collectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCell3 {
                image1 = cell.image.image ?? UIImage()
            }
        } else {
            if let cell = linkCollectionView1.cellForItem(at: IndexPath(item: self.tmpIndex, section: 0)) as? CollectionImageCell2 {
                image1 = cell.image.image ?? UIImage()
            }
        }
        let image = image1
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        return metadata
    }

    func makeContextMenu(_ index: Int, collectionView: UICollectionView) -> UIMenu {
        self.tmpCollection = collectionView
        var image1: UIImage = UIImage()
        if self.videoUrl != "" {
            let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrl) {
                    let imageToShare = [videoURL]
                    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                    if collectionView == self.collectionView1 {
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellS {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellActivity {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell3 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                    } else {
                        if let cell = self.linkCollectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                    }
                    getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
                }
            }
            let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrl) {
                    DispatchQueue.global(qos: .background).async {
                        if let urlData = NSData(contentsOf: videoURL) {
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let filePath="\(documentsPath)/tempFile.mp4"
                            DispatchQueue.main.async {
                                urlData.write(toFile: filePath, atomically: true)
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                                }) { completed, error in
                                    if completed {
                                        print("Video is saved!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return UIMenu(title: "", image: nil, identifier: nil, children: [share, save])
        } else if self.videoUrlQ != "" {
            let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrlQ) {
                    let imageToShare = [videoURL]
                    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
                    if collectionView == self.collectionView1 {
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellS {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellActivity {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                        if let cell = self.collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell3 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                    } else {
                        if let cell = self.linkCollectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                            activityViewController.popoverPresentationController?.sourceView = cell.image
                        }
                    }
                    getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
                }
            }
            let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
                if let videoURL = URL(string: self.videoUrlQ) {
                    DispatchQueue.global(qos: .background).async {
                        if let urlData = NSData(contentsOf: videoURL) {
                            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let filePath="\(documentsPath)/tempFile.mp4"
                            DispatchQueue.main.async {
                                urlData.write(toFile: filePath, atomically: true)
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
                                }) { completed, error in
                                    if completed {
                                        print("Video is saved!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return UIMenu(title: "", image: nil, identifier: nil, children: [share, save])
        } else {
            if collectionView == self.collectionView1 {
                if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellS {
                    image1 = cell.image.image ?? UIImage()
                }
                if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell {
                    image1 = cell.image.image ?? UIImage()
                }
                if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCellActivity {
                    image1 = cell.image.image ?? UIImage()
                }
                if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                    image1 = cell.image.image ?? UIImage()
                }
                if let cell = collectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell3 {
                    image1 = cell.image.image ?? UIImage()
                }
            } else {
                if let cell = linkCollectionView1.cellForItem(at: IndexPath(item: index, section: 0)) as? CollectionImageCell2 {
                    image1 = cell.image.image ?? UIImage()
                }
            }
            let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
                UIPasteboard.general.image = image1
            }
            let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: UIImage(systemName: "square.and.arrow.up"), identifier: nil) { action in
                self.tmpIndex = index
                let imToShare = [image1, self]
                let activityViewController = UIActivityViewController(activityItems: imToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self
                activityViewController.popoverPresentationController?.sourceRect = self.bounds
                getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
            }
            let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
                UIImageWriteToSavedPhotosAlbum(image1, nil, nil, nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "savedImage"), object: nil)
            }
            let actMenu = UIMenu(title: "", options: [.displayInline], children: [copy, share, save])
            if #available(iOS 16.0, *) {
                actMenu.preferredElementSize = .small
            }
            var alt = ""
            if index < self.altText.count {
                alt = self.altText[index]
            }
            return UIMenu(title: alt, image: nil, identifier: nil, children: [actMenu])
        }
    }

    func setupImages(url1: String, url2: String?, url3: String?, url4: String?, isVideo: Bool? = false, altText: [String] = [], fullImages: [Attachment] = []) {
        self.imagesFull = fullImages
        self.isVideo = isVideo ?? false
        self.altText = altText
        images = []
        images.append(url1)
        if url2 != nil {
            images.append(url2 ?? "")
        }
        if url3 != nil {
            images.append(url3 ?? "")
        }
        if url4 != nil {
            images.append(url4 ?? "")
        }
        collectionView1.reloadData()

        if url2 != nil {
            allCounts = images.count
            countButtonBG.alpha = 1
            countButtonBG.frame = CGRect(x: 35, y: collectionView1.frame.origin.y, width: 40, height: 25)

            countButton.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
            countButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
            countButton.setTitle("1/\(allCounts)", for: .normal)
            countButton.sizeToFit()
            countButtonBG.widthAnchor.constraint(equalToConstant: countButton.bounds.size.width).isActive = true
            countButtonBG.heightAnchor.constraint(equalToConstant: countButton.bounds.size.height).isActive = true
            countButton.setTitleColor(UIColor.white, for: .normal)
            countButton.backgroundColor = .clear
            countButton.removeFromSuperview()
            countButtonBG.addSubview(countButton)
            countButtonBG.isUserInteractionEnabled = false
        } else {
            countButtonBG.alpha = 0
            if self.dataImages.count < 2 {

            } else {
                countButtonBG.alpha = 1
                countButtonBG.frame = CGRect(x: 35, y: collectionView1.frame.origin.y, width: 40, height: 25)

                countButton.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
                countButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
                countButton.setTitle("1/\(self.dataImages.count)", for: .normal)
                countButton.sizeToFit()
                countButtonBG.widthAnchor.constraint(equalToConstant: countButton.bounds.size.width).isActive = true
                countButtonBG.heightAnchor.constraint(equalToConstant: countButton.bounds.size.height).isActive = true
                countButton.setTitleColor(UIColor.white, for: .normal)
                countButton.backgroundColor = .clear
                countButton.removeFromSuperview()
                countButtonBG.addSubview(countButton)
                countButtonBG.isUserInteractionEnabled = false
            }
        }
    }

    func setupQuoteImages(url1: String, url2: String?, url3: String?, url4: String?, isVideo: Bool? = false) {
        linkImages = []
        linkImages.append(url1)
        if url2 != nil {
            linkImages.append(url2 ?? "")
        }
        if url3 != nil {
            linkImages.append(url3 ?? "")
        }
        if url4 != nil {
            linkImages.append(url4 ?? "")
        }
        linkCollectionView1.reloadData()

        if url2 != nil {
            // show count
            if GlobalStruct.smallImages {

            } else {
                linkAllCounts = linkImages.count
                linkCountButtonBG.alpha = 1
                linkCountButtonBG.frame = CGRect(x: 6, y: 6, width: 40, height: 25)

                linkCountButton.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
                linkCountButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
                linkCountButton.setTitle("1/\(linkAllCounts)", for: .normal)
                linkCountButton.sizeToFit()
                linkCountButtonBG.frame.size.width = linkCountButton.bounds.size.width
                linkCountButtonBG.frame.size.height = linkCountButton.bounds.size.height
                linkCountButton.setTitleColor(UIColor.white, for: .normal)
                linkCountButton.backgroundColor = .clear
                linkCountButton.removeFromSuperview()
                linkCountButtonBG.addSubview(linkCountButton)
                linkCountButtonBG.isUserInteractionEnabled = false
            }
        } else {
            linkCountButtonBG.alpha = 0
            if self.dataImages.count < 2 {

            } else {
                linkCountButtonBG.alpha = 1
                linkCountButtonBG.frame = CGRect(x: 6, y: 6, width: 40, height: 25)

                linkCountButton.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
                linkCountButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize + GlobalStruct.customTextSize, weight: .bold)
                linkCountButton.setTitle("1/\(self.linkDataImages.count)", for: .normal)
                linkCountButton.sizeToFit()
                linkCountButtonBG.frame.size.width = linkCountButton.bounds.size.width
                linkCountButtonBG.frame.size.height = linkCountButton.bounds.size.height
                linkCountButton.setTitleColor(UIColor.white, for: .normal)
                linkCountButton.backgroundColor = .clear
                linkCountButton.removeFromSuperview()
                linkCountButtonBG.addSubview(linkCountButton)
                linkCountButtonBG.isUserInteractionEnabled = false
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        if let ip = self.collectionView1.indexPathForItem(at: center) {
            currentIndex = ip.row
            countButton.alpha = 1
            if self.dataImages.isEmpty {
                countButton.setTitle("\(ip.row + 1)/\(allCounts)", for: .normal)
            } else {
                countButton.setTitle("\(ip.row + 1)/\(self.dataImages.count)", for: .normal)
            }
        }
        if let ip = self.linkCollectionView1.indexPathForItem(at: center) {
            linkCurrentIndex = ip.row
            linkCountButton.alpha = 1
            if self.linkDataImages.isEmpty {
                linkCountButton.setTitle("\(ip.row + 1)/\(linkAllCounts)", for: .normal)
            } else {
                linkCountButton.setTitle("\(ip.row + 1)/\(self.linkDataImages.count)", for: .normal)
            }
        }
    }

    var isVideo: Bool = false
    var videoUrl: String = ""
    var player = AVPlayer()
    var playerController = CustomVideoPlayer()
    let playButton = UIButton()
    var videoUrlQ: String = ""
    var playerQ = AVPlayer()
    var playerControllerQ = CustomVideoPlayer()
    let playButtonQ = UIButton()

    func setupPlayButton(_ videoUrl: String, isAudio: Bool = false) {
        self.videoUrl = ""
        playButton.isHidden = true
        if videoUrl != "" {
            self.videoUrl = videoUrl
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
            let symbolConfigS = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)

            if GlobalStruct.smallImages {
                self.playButton.frame = CGRect(x: 15, y: 15, width: 36, height: 36)
                self.playButton.layer.cornerRadius = 18
                self.collectionView1.addSubview(self.playButton)
            } else {
                var wid: CGFloat = 0
                if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                    wid = (CGFloat(GlobalStruct.padColWidth - 100))/2
                } else {
                    #if targetEnvironment(macCatalyst)
                    wid = (CGFloat(GlobalStruct.padColWidth - 100))/2
                    #else
                    wid = ((UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100)/2
                    #endif
                }
                self.playButton.frame = CGRect(x: wid + 80 - 35, y: 110 - 35, width: 70, height: 70)
                self.playButton.layer.cornerRadius = 35
                self.collectionView1.addSubview(self.playButton)
            }
            playButton.backgroundColor = UIColor.white
            playButton.isHidden = false
            playButton.isUserInteractionEnabled = false

            countButton2.removeFromSuperview()
            if GlobalStruct.smallImages {
                countButton2.frame.size.width = 36
                countButton2.frame.size.height = 36
            } else {
                countButton2.frame.size.width = 70
                countButton2.frame.size.height = 70
            }
            countButton2.isUserInteractionEnabled = false
            countButton2.backgroundColor = UIColor.clear
            if isAudio {
                if GlobalStruct.smallImages {
                    countButton2.setImage(UIImage(systemName: "waveform.path", withConfiguration: symbolConfigS)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
                } else {
                    countButton2.setImage(UIImage(systemName: "waveform.path", withConfiguration: symbolConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
                }
            } else {
                if GlobalStruct.smallImages {
                    countButton2.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfigS)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
                } else {
                    countButton2.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
                }
            }
            self.playButton.addSubview(countButton2)
        }
    }

    func setupPlayButtonQ(_ videoUrl: String) {
        self.videoUrlQ = ""
        self.playButtonQ.isHidden = true
        if videoUrl != "" {
            self.videoUrlQ = videoUrl
            if GlobalStruct.smallImages {} else {
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)

                var wid: CGFloat = 0
                if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                    wid = (CGFloat(GlobalStruct.padColWidth - 92))/2
                } else {
                    #if targetEnvironment(macCatalyst)
                    wid = (CGFloat(GlobalStruct.padColWidth - 92))/2
                    #else
                    wid = ((UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 92)/2
                    #endif
                }
                self.playButtonQ.frame = CGRect(x: wid - 35, y: 95 - 35, width: 70, height: 70)
                self.playButtonQ.layer.cornerRadius = 35
                self.linkCollectionView1.addSubview(self.playButtonQ)

                self.playButtonQ.backgroundColor = UIColor.white
                self.playButtonQ.isHidden = false
                self.playButtonQ.isUserInteractionEnabled = false

                let countButton2 = UIButton()
                countButton2.frame.size.width = 70
                countButton2.frame.size.height = 70
                countButton2.isUserInteractionEnabled = false
                countButton2.backgroundColor = UIColor.clear
                countButton2.setImage(UIImage(systemName: "play.fill", withConfiguration: symbolConfig)?.withTintColor(.black, renderingMode: .alwaysOriginal), for: .normal)
                self.playButtonQ.addSubview(countButton2)
            }
        }
    }

    func setupVideoUrl(_ videoUrl: String) {
        DispatchQueue.global(qos: .background).async {
            self.videoUrl = videoUrl
            if let fileURL = URL(string: videoUrl) {
                let assetForCache = AVAsset(url: fileURL)
                let playerItem = AVPlayerItem(asset: assetForCache)
                let keys = ["playable", "tracks", "duration"]
                assetForCache.loadValuesAsynchronously(forKeys: keys, completionHandler: {
                    self.player = AVPlayer(playerItem: playerItem)
                    self.player.isMuted = true
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: nil) { (_) in
                        if UIApplication.shared.applicationState == .active {
                            self.player.seek(to: CMTime.zero)
                            self.player.play()
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.playerController.view.isHidden = false
                        self.playerController.videoGravity = .resizeAspectFill
                        self.playerController.player = self.player
                        if let vi = self.playerController.view {
                            if let cell = self.collectionView1.cellForItem(at: (IndexPath(item: 0, section: 0))) as? CollectionImageCell {
                                vi.backgroundColor = .custom.quoteTint
                                vi.layer.cornerRadius = 10
                                vi.layer.masksToBounds = true
                                vi.frame = cell.image.frame
                                self.inputViewController?.addChild(self.playerController)
                                self.collectionView1.addSubview(vi)
                                
                                self.player.play()
                                self.playerController.player?.play()
                            }
                            if let cell = self.collectionView1.cellForItem(at: (IndexPath(item: 0, section: 0))) as? CollectionImageCellActivity {
                                vi.backgroundColor = .custom.quoteTint
                                vi.layer.cornerRadius = 10
                                vi.layer.masksToBounds = true
                                vi.frame = cell.image.frame
                                self.inputViewController?.addChild(self.playerController)
                                self.collectionView1.addSubview(vi)
                                
                                self.player.play()
                                self.playerController.player?.play()
                            }
                        }
                    }
                })
            }
        }
    }

    func setupVideoUrlQ(_ videoUrl: String) {
        DispatchQueue.global(qos: .background).async {
            self.videoUrlQ = videoUrl
            if let fileURL = URL(string: videoUrl) {
                let assetForCache = AVAsset(url: fileURL)
                let playerItem = AVPlayerItem(asset: assetForCache)
                let keys = ["playable", "tracks", "duration"]
                assetForCache.loadValuesAsynchronously(forKeys: keys, completionHandler: {
                    self.playerQ = AVPlayer(playerItem: playerItem)
                    self.playerQ.isMuted = true
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.playerQ.currentItem, queue: nil) { (_) in
                        if UIApplication.shared.applicationState == .active {
                            self.playerQ.seek(to: CMTime.zero)
                            self.playerQ.play()
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.playerControllerQ.view.isHidden = false
                        self.playerControllerQ.videoGravity = .resizeAspectFill
                        self.playerControllerQ.player = self.playerQ
                        if let vi = self.playerControllerQ.view {
                            if let cell = self.linkCollectionView1.cellForItem(at: (IndexPath(item: 0, section: 0))) as? CollectionImageCell2 {
                                vi.backgroundColor = .custom.quoteTint
//                                vi.layer.cornerRadius = 10
                                vi.layer.masksToBounds = true
                                vi.frame = CGRect(x: 0, y: 0, width: cell.image.frame.size.width, height: cell.image.frame.size.height)
                                self.inputViewController?.addChild(self.playerControllerQ)
                                self.linkCollectionView1.addSubview(vi)
                                
                                self.playerQ.play()
                                self.playerControllerQ.player?.play()
                            }
                        }
                    }
                })
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView1 {
            if self.videoUrl != "" {
                if let ur = URL(string: self.videoUrl) {
                    let player = AVPlayer(url: ur)
                    let vc = CustomVideoPlayer()
                    vc.delegate = self
                    vc.allowsPictureInPicturePlayback = true
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
                        if UIApplication.shared.applicationState == .active {
                            player.seek(to: CMTime.zero)
                            player.play()
                        }
                    }
                    
                    vc.player = player
                    GlobalStruct.inVideoPlayer = true
                    getTopMostViewController()?.present(vc, animated: true) {
                        vc.player?.play()
                    }
                }
            } else {
                if dataImages.isEmpty {
                    var images = [SKPhoto]()
                    if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
                        if let originImage = cell.image.image {
                            for x in self.imagesFull {
                                let photo = SKPhoto.photoWithImageURL(x.url)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(currentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
                        if let originImage = cell.image.image {
                            for x in self.imagesFull {
                                let photo = SKPhoto.photoWithImageURL(x.url)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(currentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCellS {
                        if let originImage = cell.image.image {
                            for x in self.imagesFull {
                                let photo = SKPhoto.photoWithImageURL(x.url)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(currentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCell2 {
                        if let originImage = cell.image.image {
                            for x in self.imagesFull {
                                let photo = SKPhoto.photoWithImageURL(x.url)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(currentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.collectionView1.cellForItem(at: indexPath) as? CollectionImageCell3 {
                        if let originImage = cell.image.image {
                            for x in self.imagesFull {
                                let photo = SKPhoto.photoWithImageURL(x.url)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.postText.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(currentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                }
            }
        } else {
            if self.videoUrlQ != "" && self.lpImage == UIImage() {
                if let ur = URL(string: self.videoUrlQ) {
                    let player = AVPlayer(url: ur)
                    let vc = CustomVideoPlayer()
                    vc.delegate = self
                    vc.allowsPictureInPicturePlayback = true
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (_) in
                        if UIApplication.shared.applicationState == .active {
                            player.seek(to: CMTime.zero)
                            player.play()
                        }
                    }
                    
                    vc.player = player
                    GlobalStruct.inVideoPlayer = true
                    getTopMostViewController()?.present(vc, animated: true) {
                        vc.player?.play()
                    }
                }
            } else {
                if linkDataImages.isEmpty {
                    var images = [SKPhoto]()
                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCell {
                        if let originImage = cell.image.image {
                            for x in self.linkImages {
                                let photo = SKPhoto.photoWithImageURL(x)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(linkCurrentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCellActivity {
                        if let originImage = cell.image.image {
                            for x in self.linkImages {
                                let photo = SKPhoto.photoWithImageURL(x)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(linkCurrentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                    if let cell = self.linkCollectionView1.cellForItem(at: indexPath) as? CollectionImageCell3 {
                        if let originImage = cell.image.image {
                            for x in self.linkImages {
                                let photo = SKPhoto.photoWithImageURL(x)
                                photo.shouldCachePhotoURLImage = true
                                images.append(photo)
                            }
                            var alt = ""
                            if indexPath.item < self.altText.count {
                                alt = self.altText[indexPath.item]
                            }
                            let browser = SKPhotoBrowser(originImage: originImage, photos: images, animatedFromView: cell.image, imageText: self.linkPost.text ?? "", imageText2: 0, imageText3: 0, imageText4: alt)
                            browser.delegate = self
                            SKPhotoBrowserOptions.enableSingleTapDismiss = false
                            SKPhotoBrowserOptions.displayCounterLabel = false
                            SKPhotoBrowserOptions.displayBackAndForwardButton = false
                            SKPhotoBrowserOptions.displayAction = false
                            SKPhotoBrowserOptions.displayHorizontalScrollIndicator = false
                            SKPhotoBrowserOptions.displayVerticalScrollIndicator = false
                            SKPhotoBrowserOptions.displayCloseButton = false
                            SKPhotoBrowserOptions.displayStatusbar = false
                            browser.initializePageIndex(linkCurrentIndex)
                            getTopMostViewController()?.present(browser, animated: true, completion: {})
                        }
                    }
                }
            }
        }
    }

    var linkStr: Card? = nil
    @objc func linkTapped() {
        triggerHapticImpact(style: .light)
        // open url
        if let x = self.linkStr?.url {
            if let ur = URL(string: x) {
                PostActions.openLink(ur)
            }
        }
    }

}
