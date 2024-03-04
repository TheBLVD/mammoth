//
//  SKPhotoBrowser.swift
//  SKViewExample
//
//  Created by suzuki_keishi on 2015/10/01.
//  Copyright © 2015 suzuki_keishi. All rights reserved.
//

import UIKit
import AVKit
import Vision
import NaturalLanguage
import LinkPresentation

public let SKPHOTO_LOADING_DID_END_NOTIFICATION = "photoLoadingDidEndNotification"

// MARK: - SKPhotoBrowser
open class SKPhotoBrowser: UIViewController, UIContextMenuInteractionDelegate, UIActivityItemSource {
    // open function
    open var currentPageIndex: Int = 0 {
        didSet {
            if currentPageIndex != oldValue && self.descriptions[currentPageIndex] != nil {
                self.imageText = self.descriptions[currentPageIndex] ?? ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideViews()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self.configureToolbar()
                    }
                }
            }
        }
    }
    open var initPageIndex: Int = 0
    open var activityItemProvider: UIActivityItemProvider?
    open var photos: [SKPhotoProtocol] = []
    private var descriptions: [String?] = []
    
    internal lazy var pagingScrollView: SKPagingScrollView = SKPagingScrollView(frame: self.view.frame, browser: self)
    
    // appearance
    fileprivate let bgColor: UIColor = SKPhotoBrowserOptions.backgroundColor
    // animation
    let animator: SKAnimator = .init()
    
    // child component
    fileprivate var actionView: SKActionView!
    fileprivate(set) var paginationView: SKPaginationView!
//    var toolbar: SKToolbar!

    // actions
    fileprivate var activityViewController: UIActivityViewController!
    fileprivate var panGesture: UIPanGestureRecognizer?

    // for status check property
//    fileprivate var isEndAnimationByToolBar: Bool = true
    fileprivate var isViewActive: Bool = false
    fileprivate var isPerformingLayout: Bool = false
    
    // pangesture property
    fileprivate var firstX: CGFloat = 0.0
    fileprivate var firstY: CGFloat = 0.0
    
    // timer
    fileprivate var controlVisibilityTimer: Timer!
    
    // delegate
    open weak var delegate: SKPhotoBrowserDelegate?

    // statusbar initial state
    private var statusbarHidden: Bool = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
    
    // strings
    open var cancelTitle = "Cancel"
    
    fileprivate let crossView = UIButton()
    fileprivate let detailView = UIButton()
    fileprivate let detailText = ActiveLabel()
    fileprivate let detailView2 = UIButton()
    fileprivate var imageText : String? = ""
    fileprivate var imageText2 : Int? = 0
    fileprivate var imageText3 : Int? = 0
    fileprivate var imageText4 : String? = ""
    
    fileprivate var identity = CGAffineTransform.identity
    
    var detailY: CGFloat = 0

    // MARK: - Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    public convenience init(photos: [SKPhotoProtocol]) {
        self.init(photos: photos, initialPageIndex: 0)
    }
    
//    @available(*, deprecated)
    public convenience init(originImage: UIImage, photos: [SKPhotoProtocol], animatedFromView: UIView, imageText: String, imageText2: Int, imageText3: Int, imageText4: String) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
        self.photos.forEach { $0.checkCache() }
        animator.senderOriginImage = originImage
        animator.senderViewForAnimation = animatedFromView
        
        self.imageText = imageText
        self.imageText2 = imageText2
        self.imageText3 = imageText3
        self.imageText4 = imageText4
    }
    
    public convenience init(originImage: UIImage, photos: [SKPhotoProtocol], animatedFromView: UIView, descriptions: [String?], currentIndex: Int) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
        self.photos.forEach { $0.checkCache() }
        self.descriptions = descriptions
        animator.senderOriginImage = originImage
        animator.senderViewForAnimation = animatedFromView
        
        self.currentPageIndex = currentIndex
        self.imageText = descriptions.count > currentIndex ? descriptions[currentIndex] : nil
        self.imageText2 = 0
        self.imageText3 = 0
        self.imageText4 = ""
    }
    
    public convenience init(photos: [SKPhotoProtocol], initialPageIndex: Int) {
        self.init(nibName: nil, bundle: nil)
        self.photos = photos
        self.photos.forEach { $0.checkCache() }
        self.currentPageIndex = min(initialPageIndex, photos.count - 1)
        self.initPageIndex = self.currentPageIndex
        animator.senderOriginImage = photos[currentPageIndex].underlyingImage
        animator.senderViewForAnimation = photos[currentPageIndex] as? UIView
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setup() {
        modalPresentationCapturesStatusBarAppearance = true
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSKPhotoLoadingDidEndNotification(_:)),
                                               name: NSNotification.Name(rawValue: SKPHOTO_LOADING_DID_END_NOTIFICATION),
                                               object: nil)
    }
    
    open override var keyCommands: [UIKeyCommand]? {
        let dism = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dism))
        dism.discoverabilityTitle = NSLocalizedString("generic.dismiss", comment: "")
        if #available(iOS 15, *) {
            dism.wantsPriorityOverSystemBehavior = true
        }
        let right = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(rightMove))
        right.discoverabilityTitle = "Next"
        if #available(iOS 15, *) {
            right.wantsPriorityOverSystemBehavior = true
        }
        let left = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(leftMove))
        left.discoverabilityTitle = "Previous"
        if #available(iOS 15, *) {
            left.wantsPriorityOverSystemBehavior = true
        }
        let tap = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(tapMove))
        tap.discoverabilityTitle = "Toggle Display"
        if #available(iOS 15, *) {
            tap.wantsPriorityOverSystemBehavior = true
        }
        return [dism, right, left, tap]
    }
    
    @objc func rightMove() {
        if currentPageIndex < photos.count - 1 {
            currentPageIndex += 1
            jumpToPageAtIndex(currentPageIndex)
        }
    }
    
    @objc func leftMove() {
        if currentPageIndex == 0 {} else {
            currentPageIndex -= 1
            jumpToPageAtIndex(currentPageIndex)
        }
    }
    
    @objc func tapMove() {
        singleTap()
    }
    
    var isHidden: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.5) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override open var prefersStatusBarHidden: Bool {
        return self.isHidden
    }
    
    // MARK: - override
    override open func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        configurePagingScrollView()
        configureGestureControl()
        configureActionView()
        configurePaginationView()
        configureToolbar()
        animator.willPresent(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.singleTap), name: NSNotification.Name(rawValue: "sksingle"), object: nil)
        
        let interaction0 = UIContextMenuInteraction(delegate: self)
        self.pagingScrollView.addInteraction(interaction0)
        
        if UIDevice.current.userInterfaceIdiom == .phone && (UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0 > 0) {
            self.isHidden = true
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.current.userInterfaceIdiom == .phone && (UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0 > 0) {
            self.isHidden = false
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let pg = self.pagingScrollView.pageDisplayedAtIndex(self.currentPageIndex)
        pg?.backgroundColor = .clear
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: pg ?? UIView(), parameters: parameters)
    }
    
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let image = self.photos[self.currentPageIndex].underlyingImage ?? UIImage()
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        return metadata
    }
        
    func makeContextMenu() -> UIMenu {
        self.hideViews()
        let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
            UIPasteboard.general.image = self.photos[self.currentPageIndex].underlyingImage ?? UIImage()
        }
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { action in
            let imToShare = [self.photos[self.currentPageIndex].underlyingImage ?? UIImage(), self]
            let activityViewController = UIActivityViewController(activityItems: imToShare,  applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.paginationView
            activityViewController.popoverPresentationController?.sourceRect = self.paginationView.bounds
            self.present(activityViewController, animated: true, completion: nil)
            self.bringBackViews()
        }
        let save = UIAction(title: NSLocalizedString("generic.save", comment: ""), image: UIImage(systemName: "square.and.arrow.down"), identifier: nil) { action in
            UIImageWriteToSavedPhotosAlbum(self.photos[self.currentPageIndex].underlyingImage ?? UIImage(), nil, nil, nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "savedImage"), object: nil)
            self.bringBackViews()
        }
        let actMenu = UIMenu(title: "", options: [.displayInline], children: [copy, share, save])
        if #available(iOS 16.0, *) {
            actMenu.preferredElementSize = .small
        }
        return UIMenu(title: self.imageText4 ?? "", image: nil, identifier: nil, children: [actMenu])
    }
    
    func bringBackViews() {
        self.showViews()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        reloadData()
        
        var i = 0
        for photo: SKPhotoProtocol in photos {
            photo.index = i
            i += 1
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        isPerformingLayout = true
        // where did start
        delegate?.didShowPhotoAtIndex?(self, index: currentPageIndex)

        // toolbar
//        toolbar.frame = frameForToolbarAtOrientation()
        
        // action
        actionView.updateFrame(frame: view.frame)

        // paging
        switch SKCaptionOptions.captionLocation {
        case .basic:
            paginationView.updateFrame(frame: view.frame)
        case .bottom:
            paginationView.frame = frameForPaginationAtOrientation()
        }

        self.detailY = self.view.frame.maxY - self.detailView.bounds.height

        isPerformingLayout = false
    }
    
    override open func viewDidLayoutSubviews() {
        pagingScrollView.updateFrame(view.bounds, currentPageIndex: currentPageIndex)

        let offset:CGFloat = UIDevice.current.orientation.isLandscape ? 0 : 20
        self.crossView.frame = CGRect(x: 20, y: offset + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: 28, height: 28)

        let isShowing = (self.detailText.alpha == 1)
        self.detailText.frame = self.detailTextFrame(showing: isShowing)
        self.detailView.frame = self.detailViewFrame(showing: isShowing)
        self.detailView2.frame = self.detailView2Frame(showing: isShowing)

    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isViewActive = true
    }
    
    // MARK: - Notification
    @objc open func handleSKPhotoLoadingDidEndNotification(_ notification: Notification) {
        guard let photo = notification.object as? SKPhotoProtocol else {
            return
        }
        
        DispatchQueue.main.async(execute: { [weak self] in
            guard let page = self?.pagingScrollView.pageDisplayingAtPhoto(photo), let photo = page.photo else {
                return
            }
            
            if photo.underlyingImage != nil {
                page.displayImage(complete: true)
                self?.loadAdjacentPhotosIfNecessary(photo)
            } else {
                page.displayImageFailure()
            }
        })
    }
    
    open func loadAdjacentPhotosIfNecessary(_ photo: SKPhotoProtocol) {
        pagingScrollView.loadAdjacentPhotosIfNecessary(photo, currentPageIndex: currentPageIndex)
    }
    
    // MARK: - initialize / setup
    open func reloadData() {
        performLayout()
        view.setNeedsLayout()
    }
    
    open func performLayout() {
        isPerformingLayout = true

        // reset local cache
        pagingScrollView.reload()
        pagingScrollView.updateContentOffset(currentPageIndex)
        pagingScrollView.tilePages()
        
        delegate?.didShowPhotoAtIndex?(self, index: currentPageIndex)
        
        isPerformingLayout = false
    }
    
    open func prepareForClosePhotoBrowser() {
        cancelControlHiding()
        if let panGesture = panGesture {
            view.removeGestureRecognizer(panGesture)
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    open func dismissPhotoBrowser(animated: Bool, completion: (() -> Void)? = nil) {
        prepareForClosePhotoBrowser()
        dismiss(animated: !animated) {
            completion?()
            self.delegate?.didDismissAtPageIndex?(self.currentPageIndex)

            guard let sender = self.delegate?.viewForPhoto?(self, index: self.currentPageIndex) else {
                return
            }
            sender.alpha = 1
        }
    }
    
    @objc func dism() {
        self.determineAndClose()
    }
    
    open func determineAndClose() {
        delegate?.willDismissAtPageIndex?(self.currentPageIndex)
        animator.willDismiss(self)
    }
    
    open func popupShare(includeCaption: Bool = true) {
        let photo = photos[currentPageIndex]
        guard let underlyingImage = photo.underlyingImage else {
            return
        }
        
        var activityItems: [AnyObject] = [underlyingImage]
        if photo.caption != nil && includeCaption {
            if let shareExtraCaption = SKPhotoBrowserOptions.shareExtraCaption {
                let caption = photo.caption ?? "" + shareExtraCaption
                activityItems.append(caption as AnyObject)
            } else {
                activityItems.append(photo.caption as AnyObject)
            }
        }
        
        if let activityItemProvider = activityItemProvider {
            activityItems.append(activityItemProvider)
        }
        
        activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (activity, success, items, error) in
            self.hideControlsAfterDelay()
            self.activityViewController = nil
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            present(activityViewController, animated: true, completion: nil)
        } else {
            activityViewController.modalPresentationStyle = .popover
            present(activityViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - Public Function For Customizing Buttons

public extension SKPhotoBrowser {
    func updateCloseButton(_ image: UIImage, size: CGSize? = nil) {
        actionView.updateCloseButton(image: image, size: size)
    }
    
    func updateDeleteButton(_ image: UIImage, size: CGSize? = nil) {
        actionView.updateDeleteButton(image: image, size: size)
    }
}

// MARK: - Public Function For Browser Control

public extension SKPhotoBrowser {
    func initializePageIndex(_ index: Int) {
        let i = min(index, photos.count - 1)
        currentPageIndex = i
        
        if isViewLoaded {
            jumpToPageAtIndex(index)
            if !isViewActive {
                pagingScrollView.tilePages()
            }
            paginationView.update(currentPageIndex)
        }
        self.initPageIndex = currentPageIndex
    }
    
    func jumpToPageAtIndex(_ index: Int) {
        if index < photos.count {
//            if !isEndAnimationByToolBar {
//                return
//            }
//            isEndAnimationByToolBar = false

            let pageFrame = frameForPageAtIndex(index)
            pagingScrollView.jumpToPageAtIndex(pageFrame)
        }
        hideControlsAfterDelay()
    }
    
    func photoAtIndex(_ index: Int) -> SKPhotoProtocol {
        return photos[index]
    }
    
    @objc func gotoPreviousPage() {
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    @objc func gotoNextPage() {
        jumpToPageAtIndex(currentPageIndex + 1)
    }
    
    func cancelControlHiding() {
        if controlVisibilityTimer != nil {
            controlVisibilityTimer.invalidate()
            controlVisibilityTimer = nil
        }
    }
    
    func hideControlsAfterDelay() {
        // reset
        cancelControlHiding()
        // start
        controlVisibilityTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.hideControls(_:)), userInfo: nil, repeats: false)
    }
    
    func hideControls() {
        setControlsHidden(true, animated: true, permanent: false)
    }
    
    @objc func hideControls(_ timer: Timer) {
        hideControls()
        delegate?.controlsVisibilityToggled?(self, hidden: true)
    }
    
    func toggleControls() {
        if self.crossView.alpha == 1 {
            self.hideViews()
        } else {
            self.showViews()
        }
    }
    
    func areControlsHidden() -> Bool {
        return paginationView.alpha == 0.0
    }
    
    func getCurrentPageIndex() -> Int {
        return currentPageIndex
    }
    
    func addPhotos(photos: [SKPhotoProtocol]) {
        self.photos.append(contentsOf: photos)
        self.reloadData()
    }
    
    func insertPhotos(photos: [SKPhotoProtocol], at index: Int) {
        self.photos.insert(contentsOf: photos, at: index)
        self.reloadData()
    }
}

// MARK: - Internal Function

internal extension SKPhotoBrowser {
    func showButtons() {
        actionView.animate(hidden: false)
    }
    
    func pageDisplayedAtIndex(_ index: Int) -> SKZoomingScrollView? {
        return pagingScrollView.pageDisplayedAtIndex(index)
    }
    
    func getImageFromView(_ sender: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sender.frame.size, true, 0.0)
        sender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

// MARK: - Internal Function For Frame Calc

internal extension SKPhotoBrowser {
    func frameForToolbarAtOrientation() -> CGRect {
        let offset: CGFloat = {
            if #available(iOS 11.0, *) {
                return view.safeAreaInsets.bottom
            } else {
                return 15
            }
        }()
        return view.bounds.divided(atDistance: 44, from: .maxYEdge).slice.offsetBy(dx: 0, dy: -offset)
    }
    
    func frameForToolbarHideAtOrientation() -> CGRect {
        return view.bounds.divided(atDistance: 44, from: .maxYEdge).slice.offsetBy(dx: 0, dy: 44)
    }
    
    func frameForPaginationAtOrientation() -> CGRect {
        let offset = UIDevice.current.orientation.isLandscape ? 35 : 44
        
        return CGRect(x: 0, y: self.view.bounds.size.height - CGFloat(offset), width: self.view.bounds.size.width, height: CGFloat(offset))
    }
    
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + 10
        return pageFrame
    }
}

// MARK: - Internal Function For Button Pressed, UIGesture Control

internal extension SKPhotoBrowser {
    @objc func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        guard let zoomingScrollView: SKZoomingScrollView = pagingScrollView.pageDisplayedAtIndex(currentPageIndex) else {
            return
        }
        
        animator.backgroundView.isHidden = true
        let viewHeight: CGFloat = zoomingScrollView.frame.size.height
        let viewHalfHeight: CGFloat = viewHeight/2
        var translatedPoint: CGPoint = sender.translation(in: self.view)
        
        // gesture began
        if sender.state == .began {
            firstX = zoomingScrollView.center.x
            firstY = zoomingScrollView.center.y
            
            self.hideViews()
            
            hideControls()
            setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPoint(x: firstX + translatedPoint.x, y: firstY + translatedPoint.y)
        zoomingScrollView.center = translatedPoint
        
        let minOffset: CGFloat = viewHalfHeight / 6
        let offset: CGFloat = 1 - (zoomingScrollView.center.y > viewHalfHeight
            ? zoomingScrollView.center.y - viewHalfHeight
            : -(zoomingScrollView.center.y - viewHalfHeight)) / viewHalfHeight
        
        view.backgroundColor = bgColor.withAlphaComponent(max(0.7, offset))
        
        // gesture end
        if sender.state == .ended {
            
            if zoomingScrollView.center.y > viewHalfHeight + minOffset
                || zoomingScrollView.center.y < viewHalfHeight - minOffset {
                
                if UIDevice.current.userInterfaceIdiom == .phone && (UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.safeAreaInsets.bottom ?? 0 > 0) {
                    self.isHidden = false
                    setNeedsStatusBarAppearanceUpdate()
                }
                
                determineAndClose()
                
            } else {
                // Continue Showing View
                setNeedsStatusBarAppearanceUpdate()
                view.backgroundColor = bgColor

                let velocityY: CGFloat = CGFloat(0.35) * sender.velocity(in: self.view).y
                let finalX: CGFloat = firstX
                let finalY: CGFloat = viewHalfHeight
                
                let animationDuration: Double = Double(abs(velocityY) * 0.0002 + 0.2)
                
                UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseIn], animations: { () -> Void in
                    zoomingScrollView.center = CGPoint(x: finalX, y: finalY)
                }) { (animationCompleted: Bool) -> Void in
                    
                }

//                self.showViews()
            }
        }
    }
   
    @objc func actionButtonPressed(ignoreAndShare: Bool) {
        delegate?.willShowActionSheet?(currentPageIndex)
        
        guard photos.count > 0 else {
            return
        }
        
        if let titles = SKPhotoBrowserOptions.actionButtonTitles {
            let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheetController.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
            
            for idx in titles.indices {
                actionSheetController.addAction(UIAlertAction(title: titles[idx], style: .default, handler: { (_) -> Void in
                    self.delegate?.didDismissActionSheetWithButtonIndex?(idx, photoIndex: self.currentPageIndex)
                }))
            }
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                present(actionSheetController, animated: true, completion: nil)
            } else {
                actionSheetController.modalPresentationStyle = .popover
                
                if let popoverController = actionSheetController.popoverPresentationController {
                    popoverController.sourceView = self.view
//                    popoverController.barButtonItem = toolbar.toolActionButton
                }
                
                present(actionSheetController, animated: true, completion: { () -> Void in
                })
            }
            
        } else {
            popupShare()
        }
    }
    
    func deleteImage() {
        defer {
            reloadData()
        }
        
        if photos.count > 1 {
            pagingScrollView.deleteImage()
            
            photos.remove(at: currentPageIndex)
            if currentPageIndex != 0 {
                gotoPreviousPage()
            }
            paginationView.update(currentPageIndex)
            
        } else if photos.count == 1 {
            dismissPhotoBrowser(animated: true)
        }
    }
}

// MARK: - Private Function
private extension SKPhotoBrowser {
    func configureAppearance() {
        view.backgroundColor = bgColor
        view.clipsToBounds = true
        view.isOpaque = false
        
        if #available(iOS 11.0, *) {
            view.accessibilityIgnoresInvertColors = true
        }
    }
    
    func configurePagingScrollView() {
        pagingScrollView.delegate = self
        view.addSubview(pagingScrollView)
    }

    func configureGestureControl() {
        guard !SKPhotoBrowserOptions.disableVerticalSwipe else { return }
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(SKPhotoBrowser.panGestureRecognized(_:)))
        panGesture?.allowedScrollTypesMask = .continuous
//        panGesture?.minimumNumberOfTouches = 1

        if let panGesture = panGesture {
            view.addGestureRecognizer(panGesture)
        }
    }
    
    func configureActionView() {
        actionView = SKActionView(frame: view.frame, browser: self)
        view.addSubview(actionView)
    }

    func configurePaginationView() {
        paginationView = SKPaginationView(frame: view.frame, browser: self)
        view.addSubview(paginationView)
    }
    
    func transCopy(_ str: String) {
        let alert = UIAlertController(title: nil, message: str, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Copy to Clipboard", style: .default , handler:{ (UIAlertAction) in
            let pasteboard = UIPasteboard.general
            pasteboard.string = str
            self.bringBackViews()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("generic.dismiss", comment: ""), style: .cancel , handler:{ (UIAlertAction) in
            self.bringBackViews()
        }))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        let messageText = NSMutableAttributedString(
            string: str,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            ]
        )
        alert.setValue(messageText, forKey: "attributedMessage")
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.paginationView
            presenter.sourceRect = self.paginationView.bounds
        }
        getTopMostViewController()?.present(alert, animated: true, completion: nil)
    }
    
    @objc func singleTap() {
        if self.crossView.alpha == 1 {
            self.hideViews()
        } else {
            self.showViews()
        }
    }
    
    func hideViews() {
        UIView.animate(withDuration: 0.38, delay: 0.012, options: [.curveEaseInOut], animations: { () -> Void in
            self.detailView2.alpha = 0
            self.detailView2.frame = self.detailView2Frame(showing: false)
        }) { (animationCompleted: Bool) -> Void in
        }
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut], animations: { () -> Void in
            self.detailView.alpha = 0
            self.detailText.alpha = 0
            self.detailText.frame = self.detailTextFrame(showing: false)
            self.detailView.frame = self.detailViewFrame(showing: false)
        }) { (animationCompleted: Bool) -> Void in
        }
        UIView.animate(withDuration: 0.14, animations: {
            self.crossView.alpha = 0
            self.crossView.transform = self.identity.scaledBy(x: 0.1, y: 0.1)
        })
    }
    
    func showViews() {
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut], animations: { () -> Void in
//            self.detailView2.alpha = 1
            self.detailView2.frame = self.detailView2Frame(showing: true)
        }) { (animationCompleted: Bool) -> Void in
        }
        UIView.animate(withDuration: 0.34, delay: 0, options: [.curveEaseInOut], animations: { () -> Void in
            if self.imageText == nil || self.imageText == "" {} else {
                self.detailView.alpha = 1
                self.detailText.alpha = 1
                self.detailText.frame = self.detailTextFrame(showing: true)
                self.detailView.frame = self.detailViewFrame(showing: true)
            }
        }) { (animationCompleted: Bool) -> Void in
        }
        UIView.animate(withDuration: 0.14, animations: {
            self.crossView.alpha = 1
            self.crossView.transform = self.identity.scaledBy(x: 1, y: 1)
        })
    }
    
    func detailView2Frame(showing: Bool) -> CGRect {
        if showing {
            var rect = detailView2.frame
            rect.origin.y = self.detailY - 8 - self.detailView2.bounds.height - 10
            return rect
        } else {
            var rect = detailView2.frame
            rect.origin.y = self.view.bounds.height + 200
            return rect
        }
    }
    
    func detailViewFrame(showing: Bool) -> CGRect {
        if showing {
            var rect = detailView.frame
            rect.origin.y = self.detailText.frame.origin.y - 8
            return rect
        } else {
            var rect = detailView.frame
            rect.origin.y = self.view.bounds.height + 200
            return rect
        }
    }
    
    func detailTextFrame(showing: Bool) -> CGRect {
        if showing {
            var rect = detailText.frame
            rect.origin.y = self.detailY
            return rect
        } else {
            var rect = detailText.frame
            rect.origin.y = self.view.bounds.height + 200
            return rect
        }

    }
    
    @objc func crossTapped() {
        self.determineAndClose()
    }
    
    @objc func hovering1(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            DispatchQueue.main.async { [weak self] in
                UIView.animate(withDuration: 0.06, delay: 0.0, options: [.curveEaseInOut], animations: { () -> Void in
                    self?.crossView.transform = self?.identity.scaledBy(x: 1.2, y: 1.2) ?? .identity
                }) { (animationCompleted: Bool) -> Void in
                }
            }
            #if targetEnvironment(macCatalyst)
//            NSCursor.pointingHand.set()
            #endif
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.06, delay: 0.0, options: [.curveEaseInOut], animations: { () -> Void in
                self.crossView.transform = self.identity.scaledBy(x: 1, y: 1)
            }) { (animationCompleted: Bool) -> Void in
            }
            #if targetEnvironment(macCatalyst)
//            NSCursor.arrow.set()
            #endif
        default:
            break
        }
    }
    
    func configureToolbar() {
        let symbolConfig0 = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2, weight: .semibold)
        
        #if targetEnvironment(macCatalyst)
        self.crossView.frame = CGRect(x: self.view.bounds.width - 56, y: 20 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: 28, height: 28)
        #elseif !targetEnvironment(macCatalyst)
        self.crossView.frame = CGRect(x: 20, y: 20 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: 28, height: 28)
        #endif
        
        self.crossView.setImage(UIImage(systemName: "xmark", withConfiguration: symbolConfig0)?.withTintColor(UIColor.white.withAlphaComponent(0.54), renderingMode: .alwaysOriginal), for: .normal)
        self.crossView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.33)
        self.crossView.layer.cornerRadius = 14
        self.crossView.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        
        self.crossView.addTarget(self, action: #selector(self.crossTapped), for: .touchUpInside)
        self.view.addSubview(self.crossView)
        
        let hover1 = UIHoverGestureRecognizer(target: self, action: #selector(hovering1(_:)))
        self.crossView.addGestureRecognizer(hover1)
        self.crossView.addInteraction(UIPointerInteraction(delegate: nil))
        
        detailView.layer.cornerRadius = 10
        detailView.backgroundColor = UIColor.clear
        if #available(iOS 13.0, *) {
            detailView.layer.cornerCurve = .continuous
        }
        
        if self.imageText == "" && self.imageText2 == 0 && self.imageText3 == 0 {} else {
            self.view.addSubview(detailView)
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            detailText.frame = CGRect(x: 30, y: self.view.bounds.height - 40 - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: self.view.bounds.width - 60, height: 50)
        } else {
            detailText.frame = CGRect(x: 30, y: self.view.bounds.height - 40 - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), width: (self.view.bounds.width - 60) / 2, height: 50)
        }
        detailText.commitUpdates {
            self.detailText.textAlignment = .left
            self.detailText.text = self.imageText
            self.detailText.textColor = UIColor.white
            self.detailText.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular)
            self.detailText.isUserInteractionEnabled = false
            self.detailText.numberOfLines = 0
            self.detailText.sizeToFit()
            #if targetEnvironment(macCatalyst)
            self.detailText.frame.origin.y = self.view.bounds.height - detailText.frame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 20
            #elseif !targetEnvironment(macCatalyst)
            self.detailText.frame.origin.y = self.view.bounds.height - detailText.frame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) - 40
            #endif
            self.detailText.enabledTypes = [.mention, .hashtag, .url]
            self.detailText.mentionColor = .custom.baseTint
            self.detailText.hashtagColor = .custom.baseTint
            self.detailText.URLColor = .custom.baseTint
            self.detailText.urlMaximumLength = 30
        }
        
        self.detailY = self.detailText.frame.origin.y

        if self.imageText == "" && self.imageText2 == 0 && self.imageText3 == 0 {} else {
            self.view.addSubview(detailText)
        }
        
        detailView.frame = detailText.frame
        if UIDevice.current.userInterfaceIdiom == .phone {
            detailView.frame.size.width = self.view.bounds.width - 40
        } else {
            detailView.frame.size.width = (self.view.bounds.width - 30) / 2
        }
        detailView.frame.size.height = detailText.bounds.height + 16
        detailView.frame.origin.y = detailText.frame.origin.y - 8
        detailView.frame.origin.x = detailText.frame.origin.x - 10
        
        detailView2.layer.cornerRadius = 10
        detailView2.backgroundColor = UIColor.clear

        if #available(iOS 13.0, *) {
            detailView2.layer.cornerCurve = .continuous
        }
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value: imageText2 ?? 0))
        let numberFormatter2 = NumberFormatter()
        numberFormatter2.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber2 = numberFormatter2.string(from: NSNumber(value: imageText3 ?? 0))
        let normalFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize - 2)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "arrow.2.squarepath", withConfiguration: symbolConfig)?.withTintColor(UIColor.white.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        let attachment2 = NSTextAttachment()
        attachment2.image = UIImage(systemName: "heart", withConfiguration: symbolConfig)?.withTintColor(UIColor.white.withAlphaComponent(0.4), renderingMode: .alwaysOriginal)
        let attStringNewLine = NSMutableAttributedString(string: "\(formattedNumber ?? "0")", attributes: [NSAttributedString.Key.font : normalFont, NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(1)])
        let attStringNewLine2 = NSMutableAttributedString(string: "\(formattedNumber2 ?? "0")", attributes: [NSAttributedString.Key.font : normalFont, NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(1)])
        let attString = NSAttributedString(attachment: attachment)
        let attString2 = NSAttributedString(attachment: attachment2)
        let fullString = NSMutableAttributedString(string: "")
        let spaceString0 = NSMutableAttributedString(string: " ")
        let spaceString = NSMutableAttributedString(string: "  ")
        fullString.append(attString)
        fullString.append(spaceString0)
        fullString.append(attStringNewLine)
        fullString.append(spaceString)
        fullString.append(attString2)
        fullString.append(spaceString0)
        fullString.append(attStringNewLine2)
        detailView2.setAttributedTitle(fullString, for: .normal)
        detailView2.contentHorizontalAlignment = .left
        detailView2.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        detailView2.sizeToFit()
        detailView2.frame.origin.y = detailView.frame.origin.y - detailView2.bounds.height - 10
        detailView2.frame.origin.x = detailView.frame.origin.x
        
        if self.imageText == "" && self.imageText2 == 0 && self.imageText3 == 0 {} else {
            self.view.addSubview(detailView2)
        }
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.detailView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.removeFromSuperview()
        self.detailView.addSubview(blurEffectView)
        self.detailView.layer.masksToBounds = true
        
        let blurEffect2 = UIBlurEffect(style: UIBlurEffect.Style.systemThinMaterialDark)
        let blurEffectView2 = UIVisualEffectView(effect: blurEffect2)
        blurEffectView2.frame = self.detailView2.bounds
        blurEffectView2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView2.removeFromSuperview()
        self.detailView2.addSubview(blurEffectView2)
        self.detailView2.layer.masksToBounds = true
        
        UIView.animate(withDuration: 2, animations: {
//            if self.imageText4 == "" {
                self.crossView.alpha = 0
                self.detailView.alpha = 0
                self.detailView2.alpha = 0
                self.detailText.alpha = 0
//            } else {
//                self.crossView.alpha = 1
//                if self.imageText == nil || self.imageText == "" {} else {
//                    self.detailView.alpha = 1
////                    self.detailView2.alpha = 1
//                    self.detailText.alpha = 1
//                }
//            }
        }, completion: { _ in
            
        })
        
        self.detailView2.frame.origin.y = self.view.bounds.height + 200
        self.detailText.frame.origin.y = self.view.bounds.height + 200
        self.detailView.frame.origin.y = self.view.bounds.height + 200
        self.crossView.transform = self.identity.scaledBy(x: 0.1, y: 0.1)
    }

    func setControlsHidden(_ hidden: Bool, animated: Bool, permanent: Bool) {
        // timer update
        cancelControlHiding()
        
        // scroll animation
        pagingScrollView.setControlsHidden(hidden: hidden)

        // paging animation
        paginationView.setControlsHidden(hidden: hidden)
        
        // action view animation
        actionView.animate(hidden: hidden)
        
        if !hidden && !permanent {
            hideControlsAfterDelay()
        }
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - UIScrollView Delegate

extension SKPhotoBrowser: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isViewActive else { return }
        guard !isPerformingLayout else { return }
        
        // tile page
        pagingScrollView.tilePages()
        
        // Calculate current page
        let previousCurrentPage = currentPageIndex
        let visibleBounds = pagingScrollView.bounds
        currentPageIndex = min(max(Int(floor(visibleBounds.midX / visibleBounds.width)), 0), photos.count - 1)
                
        if currentPageIndex != previousCurrentPage {
            delegate?.didShowPhotoAtIndex?(self, index: currentPageIndex)
            paginationView.update(currentPageIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hideControlsAfterDelay()
        
        let currentIndex = pagingScrollView.contentOffset.x / pagingScrollView.frame.size.width
        delegate?.didScrollToIndex?(self, index: Int(currentIndex))
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        isEndAnimationByToolBar = true
    }
}

// MARK: - RotatingViewController Protocol

extension SKPhotoBrowser: RotatingViewController {
    func customSupportedRotations() -> UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}
