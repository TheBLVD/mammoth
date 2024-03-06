//
//  MentionsViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/08/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class MentionsViewController : UIViewController {
    
    public let headerView: CarouselNavigationHeader = {
        let headerView = CarouselNavigationHeader(title: NSLocalizedString("title.mentions", comment: ""))
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    private let blurEffectView: BlurredBackground = {
        let blurredEffectView = BlurredBackground(dimmed: true)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        return blurredEffectView
    }()
    
    private let pageViewController: UIPageViewController
    private let pages = [NewsFeedViewController(type: .mentionsIn), NewsFeedViewController(type: .mentionsOut)]
    
    required init() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
        
        self.pages.forEach({$0.delegate = self})
        pageViewController.setViewControllers([pages.first!], direction: .forward, animated: false)
        
        setupUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = NSLocalizedString("title.mentions", comment: "")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Prompt the user one time here, so we don't pester them each
        // time they switch to this view.
        EnablePushNotificationSetting(checkOnlyOnceFlag: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.pages.forEach({$0.additionalSafeAreaInsets.top = self.headerView.frame.size.height + 2}) // add 2 to make top border visible
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.delegate = self
        }
        
        self.addChild(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        self.view.bringSubviewToFront(blurEffectView)
        self.view.bringSubviewToFront(headerView)
        
        self.headerView.carousel.delegate = self
    
        self.view.addSubview(blurEffectView)
        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo:self.view.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: self.view.topAnchor)
        ])
        
        self.view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: blurEffectView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: blurEffectView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 2),
            headerView.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor)
        ])
        
        self.headerView.carousel.content = [NSLocalizedString("title.received", comment: ""), NSLocalizedString("title.sent", comment: "")]
    }
}

// MARK: - UIPageViewController delegate methods and helper methods
extension MentionsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    
    func currentPageIndex() -> Int? {
        if let currentPageViewController = pageViewController.viewControllers?.first {
            return self.pages.firstIndex(of: currentPageViewController as! NewsFeedViewController)
        }
        
        return nil
    }
    
    func currentPage() -> NewsFeedViewController? {
        if let currentIndex = self.currentPageIndex() {
            return self.pages[currentIndex]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let currentIndex = self.pages.firstIndex(of: viewController as! NewsFeedViewController) {
            if currentIndex > 0 {
                return self.pages[currentIndex - 1]
            }
        }

        return nil
    }
      
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let currentIndex = self.pages.firstIndex(of: viewController as! NewsFeedViewController) {
            if currentIndex < self.pages.count - 1 {
                return self.pages[currentIndex + 1]
            }
        }

        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentIndex = self.currentPageIndex() {
            self.headerView.carousel.selectItem(atIndex: currentIndex)
            
            // Pause all videos when switching feeds
            if let previousPageViewController = previousViewControllers.first as? NewsFeedViewController {
                DispatchQueue.main.async {
                    previousPageViewController.pauseAllVideos()
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let width = scrollView.frame.size.width
            let offset = scrollView.contentOffset.x
            let offsetPercentage = (offset - width) / width
            self.headerView.carousel.adjustScrollOffset(withPercentageToNextItem: offsetPercentage)
        }
    }
}

// MARK: Carousel delegate and helpers
extension MentionsViewController: CarouselDelegate {
    
    func carouselItemPressed(withIndex carouselIndex: Int) {
        DispatchQueue.main.async {
            var direction = UIPageViewController.NavigationDirection.reverse
            if let currentIndex = self.currentPageIndex() {
                if currentIndex < carouselIndex {
                    direction = UIPageViewController.NavigationDirection.forward
                } else if currentIndex > carouselIndex {
                    direction = UIPageViewController.NavigationDirection.reverse
                }
            }

            let vc = self.pages[carouselIndex]
            self.pageViewController.setViewControllers([vc], direction: direction, animated: true)
        }
    }
    
    func carouselActiveItemDoublePressed() {
        self.jumpToNewest()
    }
    
    func contextMenuForItem(withIndex index: Int) -> UIMenu? {
        return nil
    }
}

extension MentionsViewController: NewsFeedViewControllerDelegate {
    func willChangeFeed(_ type: NewsFeedTypes) {}
    
    func didChangeFeed(_ type: NewsFeedTypes) {}
    
    func userActivityStorageIdentifier() -> String {
        return "MentionsViewController"
    }
    
    func didScrollToTop() {
        if self.currentPageIndex() == 0 {
            // Hide the tab bar activity indicator (dot)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "hideIndActivity2"), object: nil)
        }
    }
    
    func isActiveFeed(_ type: NewsFeedTypes) -> Bool {
        return true
    }
}

// Jump to newest
extension MentionsViewController: JumpToNewest {
    @objc func jumpToNewest() {
        self.currentPage()?.jumpToNewest()
    }
}
