//
//  WebViewController.swift
//  Mammoth
//
//  Created by Benoit Nolens on 30/11/2023.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    let urlString: String
    
    init(url: String) {
        urlString = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
            webView = WKWebView()
            webView.navigationDelegate = self
            view = webView
       }

    override func viewDidLoad() {
        super.viewDidLoad()

        let closeButton = UIBarButtonItem(title: NSLocalizedString("generic.close", comment: ""), style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = closeButton

        if let url = URL(string: self.urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update the appearance of the navbar
        configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
    }
    
    @objc func close() {
        self.dismiss(animated: true)
    }

    @objc func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() {
            if scheme != "https" && scheme != "http" {
                if UIApplication.shared.canOpenURL(url){
                    UIApplication.shared.open(url)
                }
            }
        }
        
        decisionHandler(.allow)
    }
}

// MARK: - Appearance changes
internal extension WebViewController {
     override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
         if #available(iOS 13.0, *) {
             if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                 configureNavigationBarLayout(navigationController: self.navigationController, userInterfaceStyle: self.traitCollection.userInterfaceStyle)
             }
         }
    }
}
