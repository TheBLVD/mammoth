//
//  UpgradeCell.swift
//  Mammoth
//
//  Created by Benoit Nolens on 27/11/2023.
//

import UIKit
import StoreKit
import ArkanaKeys

// MARK: - UITableViewCell

final class UpgradeCell: UITableViewCell {
    static let reuseIdentifier = "UpgradeCell"
    public var delegate: UpgradeViewDelegate? {
        set {
            self.rootView.delegate = newValue
        }
        
        get {
            return self.rootView.delegate
        }
    }
    
    public let rootView = UpgradeRootView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        
        self.contentView.addSubview(rootView)
        rootView.translatesAutoresizingMaskIntoConstraints = false
        self.rootView.pinEdges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.delegate = nil
        self.rootView.prepareForReuse()
    }
    
    func configure(expanded: Bool, title: String, featureName: String? = nil) {
        self.rootView.configure(expanded: expanded, title: title, featureName: featureName)
    }
}

// MARK: - UICollectionViewCell

final class UpgradeItem: UICollectionViewCell {
    static let reuseIdentifier = "UpgradeItem"
    public weak var delegate: UpgradeViewDelegate? {
        set {
            self.rootView.delegate = newValue
        }
        
        get {
            return self.rootView.delegate
        }
    }
    
    private let rootView = UpgradeRootView()
    public var parentWidth: CGFloat?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
       self.contentView.backgroundColor = .clear
       self.backgroundColor = .clear

       self.contentView.addSubview(rootView)
       rootView.translatesAutoresizingMaskIntoConstraints = false
       self.rootView.pinEdges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.size = CGSize(width: (self.parentWidth ?? self.bounds.width) - 40, height: attributes.size.height)
        return attributes
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.delegate = nil
        self.rootView.prepareForReuse()
    }
    
    func configure(expanded: Bool, title: String, featureName: String? = nil) {
        self.rootView.configure(expanded: expanded, title: title, featureName: featureName)
    }
}

// MARK: - Root View

protocol UpgradeViewDelegate: AnyObject {
    func onStateChange(state: UpgradeRootView.UpgradeViewState)
}

final class UpgradeRootView: UIView, UpgradeOptionDelegate {
    
    enum UpgradeViewState {
        case loading
        case unsubscribed
        case subscribed
        case thanks
    }
    
    private let mainStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 14, left: 18, bottom: 14, right: 18)
        return stackView
    }()
    
    private let headerStack = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    private let expandedStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 14
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins.bottom = 2
        return stackView
    }()

    private let optionsListStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.preservesSuperviewLayoutMargins = false
        return stackView
    }()
    
    private let productOptionsStack = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 14
        stackView.isOpaque = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .zero
        stackView.layoutMargins.top = 8
        return stackView
    }()
    
    private let customBackground = {
        let view = GradientBorderView(colors: UIColor.gradients.goldBorder, startPoint: .init(x: 0, y: 0), endPoint: .init(x: 1, y: 1))
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.numberOfLines = 1
        return label
    }()
    
    private let createOptionLabel: (_ text: String) -> UIStackView = { text in
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 2

        let slash = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        slash.numberOfLines = 1
        slash.text = "/"
        slash.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .heavy)
        stackView.addArrangedSubview(slash)
        
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.text = text
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 1
        
        stackView.addArrangedSubview(label)
        return stackView
    }
    
    private let descriptionLabel: UILabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.text = NSLocalizedString("settings.gold.community", comment: "")
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let actionButton: GradientButton = {
        let button = GradientButton(colors: UIColor.gradients.goldButtonBackground, startPoint: .init(x: 1, y: 0.5), endPoint: .init(x: 0, y: 1))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("settings.gold.upgrade", comment: ""), for: .normal)
        button.setTitleColor(.custom.background, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.frame.size.height = 38
        button.contentEdgeInsets = .init(top: 10, left: 17, bottom: 10, right: 17)
        return button
    }()
    
    private let restoreButton: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.textAlignment = .center
        label.text = NSLocalizedString("settings.gold.restore", comment: "")
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let expandIcon: UILabel = {
        let icon = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        icon.numberOfLines = 1
        icon.text = "+"
        icon.textAlignment = .right
        icon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
        return icon
    }()
    
    public weak var delegate: UpgradeViewDelegate?
    
    private let gradientBorder = CAGradientLayer()
    private let gradientBorderShape = CAShapeLayer()
    private let loader = UIActivityIndicatorView(style: .medium)
    private var options: [UpgradeOption] = []
    private var optionsContraints: [NSLayoutConstraint] = []
    private var iapProducts: [SKProduct] = [] {
        didSet {
            if oldValue != iapProducts {
                self.clearProductOptions()
                self.setupProductOptions(products: iapProducts)
            }
        }
    }
    public var state: UpgradeViewState = IAPManager.isGoldMember ? .subscribed : .loading {
        didSet {
            if oldValue != state {
                configureUIForState(state)
                self.delegate?.onStateChange(state: state)
                
                if self.delegate == nil {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadAll"), object: nil)
                }
            }
        }
    }
    
    private(set) var expanded: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
        
        let restoreGesture = UITapGestureRecognizer(target: self, action: #selector(self.onRestorePress))
        self.restoreButton.addGestureRecognizer(restoreGesture)
        
        IAPManager.shared.fetchAvailableProductsBlock = { (products) in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.iapProducts = products
                self.state = IAPManager.isGoldMember ? .subscribed : .unsubscribed
            }
        }
        
        IAPManager.shared.purchaseStatusBlock = { (type) in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                
                switch type {
                case .disabled:
                    AnalyticsManager.track(event: .failedToUpgrade)
                    let alert = UIAlertController(title: NSLocalizedString("error.purchaseError", comment: ""), message: type.message(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: UIAlertAction.Style.default, handler: nil))
            
                    if let presentingVC = getTopMostViewController() {
                        presentingVC.present(alert, animated: true, completion: nil)
                    }
                case .failed(let error):
                    self.state = .unsubscribed
                    AnalyticsManager.track(event: .failedToUpgrade)
                    
                    guard (error as? NSError)?.description.range(of: NSLocalizedString("error.paymentSheet", comment: "")) == nil else { return }
                    
                    let alert = UIAlertController(title: NSLocalizedString("error.purchaseError", comment: ""), message: type.message(), preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: UIAlertAction.Style.default, handler: nil))
            
                    if let presentingVC = getTopMostViewController() {
                        presentingVC.present(alert, animated: true, completion: nil)
                    }
                case .restored:
                    self.state = .subscribed
                    AnalyticsManager.track(event: .restoredToGold)
                case .purchased:
                    self.state = .thanks
                    AnalyticsManager.track(event: .upgradedToGold)
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        self.delegate = nil
        setupUIFromSettings()
    }
    
    func onOptionSelect(planId: String) {
        self.options.forEach({
            if $0.planId == planId {
                $0.selected = true
            } else {
                $0.selected = false
            }
        })
    }
    
    @objc func onActionButtonPressed() {
        switch self.state {
        case .unsubscribed:
            self.state = .loading
            if let selected = self.options.first(where: { $0.selected })?.planId {
                IAPManager.shared.purchaseProduct(productIdentifier: selected)
            }
        case .thanks, .subscribed:
            openCommunityWebView()
        default:
            break
        }
    }
    
    private func openCommunityWebView() {
        let userId = (AccountsManager.shared.currentAccount as? MastodonAcctData)?.remoteFullOriginalAcct
        let queryItems = [URLQueryItem(name: "id", value: userId)]
        var communityURLComponents = URLComponents(string: ArkanaKeys.Global().joinCommunityPageURL)!
        communityURLComponents.queryItems = queryItems
        if let communityURL = communityURLComponents.url {
            let vc = WebViewController(url: communityURL.absoluteString)
            if let presentingVC = getTopMostViewController() {
                presentingVC.present(UINavigationController(rootViewController: vc), animated: true)
            }
        } else {
            log.error("unable to generate correct community URL")
        }
    }
    
    @objc func onRestorePress() {
        self.state = .loading
        IAPManager.shared.restorePurchase()
    }
}

private extension UpgradeRootView {
    func setupUI() {
        self.contentMode = .top
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.backgroundColor = .clear
        self.layoutMargins = .zero
        
        self.addSubview(customBackground)
        self.addSubview(mainStack)
        
        mainStack.addArrangedSubview(headerStack)
        
        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(expandIcon)
        headerStack.addArrangedSubview(loader)
        
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        expandIcon.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        NSLayoutConstraint.activate([
            customBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            customBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            customBackground.topAnchor.constraint(equalTo: self.topAnchor),
            customBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            mainStack.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            
            headerStack.leadingAnchor.constraint(equalTo: self.mainStack.layoutMarginsGuide.leadingAnchor),
            headerStack.trailingAnchor.constraint(equalTo: self.mainStack.layoutMarginsGuide.trailingAnchor),
        ])
        
        expandedStack.addArrangedSubview(descriptionLabel)
        expandedStack.addArrangedSubview(optionsListStack)
        expandedStack.addArrangedSubview(productOptionsStack)
        
        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.earlyAccess", comment: "")))
        var appIconBenefit = NSLocalizedString("settings.gold.icons", comment: "")
        if !UIApplication.shared.supportsAlternateIcons {
            appIconBenefit += " (iOS)"
        }
        optionsListStack.addArrangedSubview(createOptionLabel(appIconBenefit))
        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.support", comment: "")))
        optionsListStack.addArrangedSubview(createOptionLabel(NSLocalizedString("settings.gold.vote", comment: "")))
        
        mainStack.addArrangedSubview(expandedStack)
        expandedStack.isHidden = true
        
        expandedStack.addArrangedSubview(actionButton)
        expandedStack.addArrangedSubview(restoreButton)
                
        NSLayoutConstraint.activate([
            expandedStack.trailingAnchor.constraint(equalTo: self.mainStack.layoutMarginsGuide.trailingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor),
            restoreButton.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor)
        ])
        
        actionButton.addTarget(self, action: #selector(self.onActionButtonPressed), for: .touchUpInside)
        
        setupUIFromSettings()
        configureUIForState(self.state)
    }
    
    func setupUIFromSettings() {
        titleLabel.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
    }
    
    func setupProductOptions(products: [SKProduct]) {
        self.options = []
        products.forEach({ [weak self] product in
            guard let self else { return }
            let isYearly = product.productIdentifier == IAPManager.GOLD_YEAR_PRODUCT_ID
            
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.locale = product.priceLocale
            
            let priceString = currencyFormatter.string(from: product.price)
            
            let option = UpgradeOption(title: product.localizedTitle,
                                       description: product.localizedDescription,
                                       price: priceString ?? "",
                                       selected: isYearly,
                                       planId: product.productIdentifier,
                                       badge: isYearly ? NSLocalizedString("settings.gold.bestDeal", comment: "") : nil)
            
            option.delegate = self
            
            self.options.append(option)
            productOptionsStack.addArrangedSubview(option)
            
            let c = option.trailingAnchor.constraint(equalTo: expandedStack.layoutMarginsGuide.trailingAnchor)
            c.isActive = true
            self.optionsContraints.append(c)
        })
    }
    
    func clearProductOptions() {
        self.options.forEach({
            productOptionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        })
        
        self.options = []
        
        NSLayoutConstraint.deactivate(self.optionsContraints)
        self.optionsContraints = []
    }
}

extension UpgradeRootView {
    func configure(expanded: Bool, title: String, featureName: String?) {
        
        self.titleLabel.text = title
        
        if expanded && IAPManager.shared.iapProducts.isEmpty {
            IAPManager.shared.prepareForUse()
            IAPManager.shared.fetchAvailableProductsBlock = { products in
                DispatchQueue.main.async {
                    self.iapProducts = products
                    self.configure(expanded: expanded, title: title, featureName: featureName)
                }
            }
            return
        }
        
        self.expand(expanded)
        
        if expanded {
            expandIcon.text = "–"
            expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
        } else {
            expandIcon.text = featureName ?? "+"
            
            if featureName != nil {
                expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .regular)
            } else {
                expandIcon.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .black)
            }
        }
        
        self.configureUIForState(self.state)
    }
    
    private func expand(_ expanded: Bool) {
        self.expanded = expanded
        
        if expanded {
            expandedStack.alpha = 0
            expandedStack.isHidden = false
                        
            UIView.animate(withDuration: 0.12, delay: 0.21) {
                self.expandedStack.alpha = 1
            }
        } else {
            // This needs to be wrapped in DispatchQueue.main.async
            // to prevent an animation glitch
            DispatchQueue.main.async {
                self.expandedStack.alpha = 0

            }
            self.expandedStack.isHidden = true
        }
    }
    
    func configureUIForState(_ state: UpgradeViewState) {
        switch state {
        case .loading:
            self.loader.isHidden = false
            self.expandIcon.isHidden = true
            self.loader.hidesWhenStopped = true
            self.expandedStack.isHidden = true
            self.loader.startAnimating()
        case .subscribed:
            self.loader.stopAnimating()
            self.expandIcon.isHidden = false
            self.productOptionsStack.isHidden = true
            self.expandedStack.isHidden = !self.expanded
            self.titleLabel.text = NSLocalizedString("settings.gold.active", comment: "")
            self.descriptionLabel.isHidden = false
            self.optionsListStack.isHidden = true
            self.actionButton.setTitle(NSLocalizedString("settings.gold.join", comment: ""), for: .normal)
            self.restoreButton.isHidden = true
        case .unsubscribed:
            self.loader.stopAnimating()
            self.loader.isHidden = true
            self.expandIcon.isHidden = false
            self.expandedStack.isHidden = !self.expanded
            self.productOptionsStack.isHidden = false
            self.descriptionLabel.isHidden = true
            self.optionsListStack.isHidden = false
            self.actionButton.setTitle(NSLocalizedString("settings.gold.upgrade", comment: ""), for: .normal)
            self.restoreButton.isHidden = false
        case .thanks:
            self.loader.stopAnimating()
            self.expandIcon.isHidden = false
            self.titleLabel.text = NSLocalizedString("settings.gold.active", comment: "")
            self.productOptionsStack.isHidden = true
            self.expandedStack.isHidden = !self.expanded
            self.descriptionLabel.isHidden = false
            self.optionsListStack.isHidden = true
            self.actionButton.setTitle(NSLocalizedString("settings.gold.join", comment: ""), for: .normal)
            self.restoreButton.isHidden = true
        }
    }
}


// MARK: - Upgrade Option View

protocol UpgradeOptionDelegate: AnyObject {
    func onOptionSelect(planId: String)
}

final class UpgradeOption: UIView {
    private let customBackground = {
        let view = GradientBorderView(colors: UIColor.gradients.goldBorder, startPoint: .init(x: 1, y: 0), endPoint: .init(x: 0, y: 1))
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let mainStack: UIStackView = {
        let mainStack = UIStackView()
        mainStack.axis = .horizontal
        mainStack.distribution = .fill
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        return mainStack
    }()
    
    private let leftColumn: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()
    
    private let titleLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let descriptionLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 3, weight: .regular)
        label.numberOfLines = 1
        return label
    }()
    
    private let priceLabel: GradientLabel = {
        let label = GradientLabel(colors: UIColor.gradients.goldText, startPoint: .init(x: 1, y: 1), endPoint: .init(x: 0, y: 0))
        label.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 1, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let badgeLabel: UIButton = {
        let label = UIButton()
        label.titleLabel?.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize + GlobalStruct.customTextSize - 4, weight: .heavy)
        label.backgroundColor = .custom.gold
        label.setTitleColor(.custom.background, for: .normal)
        label.layer.cornerRadius = 4
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        label.contentEdgeInsets = .init(top: 1, left: 6, bottom: 0, right: 6)
        label.isUserInteractionEnabled = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let planId: String
    public var selected: Bool = false {
        didSet {
            self.layoutSubviews()
        }
    }
    weak var delegate: UpgradeOptionDelegate?
    
    private var backgroundColors: [CGColor] {
        if self.traitCollection.userInterfaceStyle == .dark {
            return [
                UIColor(red: 82.0/255.0, green: 61.0/255.0, blue: 30.0/255.0, alpha: 1.0).cgColor,
                UIColor(red: 109.0/255.0, green: 81.0/255.0, blue: 38.0/255.0, alpha: 1.0).cgColor,
            ]
        } else {
            return [
                UIColor(red: 221.0/255.0, green: 175.0/255.0, blue: 107.0/255.0, alpha: 0.8).cgColor,
                UIColor(red: 238.0/255.0, green: 180.0/255.0, blue: 92.0/255.0, alpha: 0.8).cgColor,
            ]
        }
    }
    
    init(title: String, description: String, price: String, selected: Bool, planId: String, badge: String? = nil) {
        self.planId = planId
        super.init(frame: .zero)
        self.selected = selected
        self.translatesAutoresizingMaskIntoConstraints = false
        self.setupUI()
        
        self.titleLabel.text = title
        self.descriptionLabel.text = description
        self.priceLabel.text = price
        
        if let badge {
            self.badgeLabel.setTitle(badge, for: .normal)
        } else {
            self.badgeLabel.isHidden = true
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onPress))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds.size.height != 0 && self.selected {
            self.customBackground.backgroundColor = UIColor.gradient(colors: self.backgroundColors, startPoint: .init(x: 0, y: 1), endPoint: .init(x: 1, y: 0), bounds: self.customBackground.bounds)
        } else {
            self.customBackground.backgroundColor = .clear
        }
        
        if self.selected && self.traitCollection.userInterfaceStyle == .light {
            titleLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
            ]
            descriptionLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
            ]
            priceLabel.colors = [
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor,
                UIColor(red: 255, green: 255, blue: 255, alpha: 1.0).cgColor
            ]
        } else {
            titleLabel.colors = UIColor.gradients.goldText
            descriptionLabel.colors = UIColor.gradients.goldText
            priceLabel.colors = UIColor.gradients.goldText
        }
    }
    
    private func setupUI() {
        self.addSubview(customBackground)
        self.addSubview(mainStack)
        
        mainStack.addArrangedSubview(leftColumn)
        self.layoutMargins = .init(top: 18, left: 16, bottom: 18, right: 16)
        
        leftColumn.addArrangedSubview(titleLabel)
        leftColumn.addArrangedSubview(descriptionLabel)
        
        mainStack.addArrangedSubview(priceLabel)
        
        mainStack.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            customBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            customBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            customBackground.topAnchor.constraint(equalTo: self.topAnchor),
            customBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            mainStack.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor),
            
            badgeLabel.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor, constant: -5),
            badgeLabel.topAnchor.constraint(equalTo: mainStack.topAnchor, constant: -26)
        ])
    }
    
    @objc func onPress() {
        self.selected = !self.selected
        self.layoutSubviews()
        self.delegate?.onOptionSelect(planId: self.planId)
    }
}
