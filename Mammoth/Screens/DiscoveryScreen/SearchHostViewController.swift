//
//  SearchHostViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 8/28/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SearchHostViewController: UIViewController {
    
    private let viewModel: SearchHostViewModel
    
    private let headerView: SearchHostHeaderView = {
        let headerView = SearchHostHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    private let blurEffectView: BlurredBackground = {
        let blurredEffectView = BlurredBackground(dimmed: true)
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        return blurredEffectView
    }()
    
    private let pageViewController: UIPageViewController
    private let pages: [UIViewController] = [
        DiscoverSuggestionsViewController(viewModel: DiscoverSuggestionsViewModel()),
        DiscoveryViewController(viewModel: DiscoveryViewModel()),
        ChannelsViewController(viewModel: ChannelsViewModel()),
        HashtagsViewController(viewModel: HashtagsViewModel(allHashtags: [])),
        PostResultsViewController(viewModel: PostResultsViewModel()),
        InstancesViewController(viewModel: InstancesViewModel())
    ]
    
    required init() {
        self.viewModel = SearchHostViewModel()
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        super.init(nibName: nil, bundle: nil)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.pages.forEach({$0.additionalSafeAreaInsets.top = self.headerView.frame.size.height})
    }
    
    func setupUI() {
        self.viewModel.delegate = self
        self.headerView.carousel.delegate = self
        self.headerView.searchBar.delegate = self
        
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
            headerView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor)
        ])
        
        self.headerView.carousel.content = pages[1...].map({$0.title})
        self.viewModel.switchToViewAtIndex(0)
    }
}

extension SearchHostViewController: JumpToNewest {
    func jumpToNewest() {
        // Just forward the jumpToNewest() to our current page
        (self.pageViewController.viewControllers?.first as? JumpToNewest)?.jumpToNewest()
    }
}

// MARK: Carousel delegate and helpers
extension SearchHostViewController: CarouselDelegate {
    func carouselItemPressed(withIndex carouselIndex: Int) {
        DispatchQueue.main.async {
            let viewModelIndex = carouselIndex+1
            self.viewModel.switchToViewAtIndex(viewModelIndex)
        }
    }
    
    func carouselActiveItemDoublePressed() {
        self.jumpToNewest()
    }
    
    func contextMenuForItem(withIndex index: Int) -> UIMenu? {
        return nil
    }
}

extension SearchHostViewController: SearchHostDelegate {
    
    func didUpdateViewType(with viewType: SearchHostViewModel.ViewTypes) {
        // Switch to the view in question
        if let pageIndex = SearchHostViewModel.ViewTypes.allCases.firstIndex(of: viewType) {
            DispatchQueue.main.async {
                self.switchToViewControllerPage(self.pages[pageIndex])
            }
        }
    }
    
    func switchToViewControllerPage(_ viewPage: UIViewController) {
        let previousFeedController = self.pageViewController.viewControllers?.first
        
        guard viewPage != previousFeedController else { return }
        
        // Initial navigation or when going back to suggestions
        if previousFeedController == nil || (viewPage as? DiscoverSuggestionsViewController) != nil {
            pageViewController.setViewControllers([pages.first!], direction: .forward, animated: false)
            
            // disable horizontal scroll of pageViewController
            if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                scrollView.isScrollEnabled = false
            }
        } else {
            // Navigate to complete search results
            if let _ = previousFeedController as? DiscoverSuggestionsViewController {
                pageViewController.setViewControllers([pages[1]], direction: .forward, animated: false)
            } else {
                // Navigate between complete search result pages
                if let previousIndex = self.pageIndex(for: previousFeedController!),
                   let nextIndex = self.pageIndex(for: viewPage) {
                    if previousIndex < nextIndex {
                        pageViewController.setViewControllers([pages[nextIndex]], direction: .forward, animated: true)
                    } else {
                        pageViewController.setViewControllers([pages[nextIndex]], direction: .reverse, animated: true)
                    }
                }
            }
            
            // enable horizontal scroll of pageViewController
            if let scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                scrollView.isScrollEnabled = true
            }
        }

        let showCarousel = self.viewModel.shouldShowCarousel()
        self.headerView.hideCarousel(!showCarousel)
    }
}

// MARK: - UIPageViewController delegate methods and helper methods
extension SearchHostViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    
    func currentPageIndex() -> Int? {
        if let currentPageViewController = pageViewController.viewControllers?.first {
            return self.pageIndex(for: currentPageViewController)
        }
        
        return nil
    }
    
    func pageIndex(for viewController: UIViewController) -> Int? {
        return self.pages.firstIndex(of: viewController)
    }
    
    func currentPage() -> UIViewController? {
        if let currentIndex = self.currentPageIndex() {
            return self.pages[currentIndex]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let currentIndex = self.pages.firstIndex(of: viewController) {
            if currentIndex > 1 {
                return self.pages[currentIndex - 1]
            }
        }

        return nil
    }
      
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let currentIndex = self.pages.firstIndex(of: viewController) {
            if currentIndex == 0 {
                return nil
            }
            
            if currentIndex < self.pages.count - 1 {
                return self.pages[currentIndex + 1]
            }
        }

        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentIndex = self.currentPageIndex() {
            self.headerView.carousel.selectItem(atIndex: currentIndex-1)
            self.viewModel.switchToViewAtIndex(currentIndex)
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


// MARK: UISearchBarDelegate
//
// Just forward these to our current view controller
extension SearchHostViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Do the search/filter
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBar?(searchBar, textDidChange: searchText)
            }
        }
        (self.pages.first as? DiscoverSuggestionsViewController)?.searchBar(searchBar, textDidChange: searchText)
        
        // If the text is empty, show the base screen
        if searchText == "" {
            self.viewModel.userClearedTextField()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.text = ""
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBarCancelButtonClicked?(searchBar)
            }
        }
        (self.pages.first as? DiscoverSuggestionsViewController)?.searchBarCancelButtonClicked(searchBar)
        self.viewModel.userCancelledSearch()
        
        // Switch to the first tab in preparation for the next search
        self.headerView.carousel.selectItem(atIndex: 0)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        for viewPage in pages {
            if let viewPageAsSearchDelegate = viewPage as? UISearchBarDelegate {
                viewPageAsSearchDelegate.searchBarSearchButtonClicked?(searchBar)
            }
        }
        (self.pages.first as? DiscoverSuggestionsViewController)?.searchBarSearchButtonClicked(searchBar)
        self.viewModel.userInitiatedSearch()
        self.view.endEditing(true)

        // Re-enable the cancel button
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.isEnabled = true
        }

    }
    
}
