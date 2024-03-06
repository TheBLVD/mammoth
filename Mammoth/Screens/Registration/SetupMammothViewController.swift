//
//  SetupMammothViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 10/13/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SetupMammothViewController: UIViewController {

    private lazy var navHeader: UIView = {
        let navHeader = UIView()
        navHeader.translatesAutoresizingMaskIntoConstraints = false
        navHeader.backgroundColor = .custom.background
        return navHeader
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UserCardCell.self, forCellReuseIdentifier: UserCardCell.reuseIdentifier)
        tableView.register(UINib(nibName: "SetupInstructionsCell", bundle: nil), forCellReuseIdentifier: SetupInstructionsCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .custom.background
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        }
        
        return tableView
    }()

    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader;
    }()

    private lazy var noThanksButton: UIButton = {
        let noThanksButton = UIButton()
        noThanksButton.translatesAutoresizingMaskIntoConstraints = false
        noThanksButton.setTitle(NSLocalizedString("onboarding.mammoth.noThanks", comment: ""), for: .normal)
        noThanksButton.backgroundColor = .clear
        noThanksButton.setTitleColor(.custom.mediumContrast, for: .normal)
        return noThanksButton
    }()

    private lazy var doneButton: UIButton = {
        let doneButton = UIButton()
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle(NSLocalizedString("onboarding.mammoth.followMammoth", comment: ""), for: .normal)
        doneButton.backgroundColor = .custom.OVRLYMedContrast
        doneButton.setTitleColor(.custom.highContrast, for: .normal)
        doneButton.layer.cornerRadius = 8
        return doneButton
    }()
    
    private lazy var doneButtonBackground: UIView = {
        let doneButtonBackground = UIView()
        doneButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        doneButtonBackground.backgroundColor = .custom.background
        return doneButtonBackground
    }()

    private var viewModel = SetupMammothViewModel.shared
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        self.isModalInPresentation = true
        self.viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onThemeChange),
                                               name: NSNotification.Name(rawValue: "reloadAll"),
                                               object: nil)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if let windowSafeAreaInsets = UIApplication.shared.keyWindow?.safeAreaInsets {
            let windowSafeAreaOrigin = CGPoint(x: 0, y: windowSafeAreaInsets.top)
            let safeAreaOrigin = self.view.convert(windowSafeAreaOrigin, from: UIApplication.shared.keyWindow)
            navHeader.heightAnchor.constraint(equalToConstant: safeAreaOrigin.y).isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc private func onThemeChange() {
        self.tableView.reloadData()
    }
}

// MARK: UI Setup
private extension SetupMammothViewController {
    func setupUI() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.view.layoutMargins = .init(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            self.view.layoutMargins = .init(top: 0, left: 0, bottom: 14, right: 0)
        }
        
        view.addSubview(navHeader)
        NSLayoutConstraint.activate([
            navHeader.topAnchor.constraint(equalTo: self.view.topAnchor),
            navHeader.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            navHeader.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])

        doneButton.addTarget(self, action: #selector(self.followMammothTapped), for: .touchUpInside)
        doneButtonBackground.addSubview(doneButton)
        
        noThanksButton.addTarget(self, action: #selector(self.noThanksTapped), for: .touchUpInside)
        doneButtonBackground.addSubview(noThanksButton)

        view.addSubview(doneButtonBackground)
        NSLayoutConstraint.activate([
            doneButtonBackground.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            doneButtonBackground.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            doneButtonBackground.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            doneButton.leadingAnchor.constraint(equalTo: doneButtonBackground.leadingAnchor, constant: 13),
            doneButton.trailingAnchor.constraint(equalTo: doneButtonBackground.trailingAnchor, constant: -13),
            doneButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 50),

            noThanksButton.leadingAnchor.constraint(equalTo: doneButtonBackground.leadingAnchor, constant: 13),
            noThanksButton.trailingAnchor.constraint(equalTo: doneButtonBackground.trailingAnchor, constant: -13),
            noThanksButton.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -1),
            noThanksButton.heightAnchor.constraint(equalToConstant: 50),

            noThanksButton.topAnchor.constraint(equalTo: doneButtonBackground.topAnchor, constant: 13),
        ])
                
        view.addSubview(tableView)
        view.addSubview(loader)
        
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.doneButtonBackground.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        self.view.bringSubviewToFront(navHeader)
        self.view.bringSubviewToFront(doneButtonBackground)
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate
extension SetupMammothViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.hasHeader(forSection: section) {
            return 29
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: SetupInstructionsCell.reuseIdentifier) as! SetupInstructionsCell
            cell.configure(title: NSLocalizedString("onboarding.mammoth.title", comment: ""), instructions: NSLocalizedString("onboarding.mammoth.description", comment: ""))
            return cell
        } else {
            if let userCard = viewModel.getInfo(forIndexPath: indexPath) {
                userCard.forceFollowButtonDisplay = true
                let cell = self.tableView.dequeueReusableCell(withIdentifier: UserCardCell.reuseIdentifier, for: indexPath) as! UserCardCell
                cell.configure(info: userCard, actionButtonType: .none) { [weak self] (type, isActive, data) in
                    guard let self else { return }
                    if type == .profile {
                        displayUserProfile(user: userCard)
                    } else {
                        PostActions.onActionPress(target: self, type: type, isActive: isActive, userCard: userCard, data: data)
                    }
                }
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let header = SectionHeader(buttonTitle: nil)
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 {
            if let userCard = viewModel.getInfo(forIndexPath: indexPath) {
                displayUserProfile(user: userCard)
            }
        }
    }
    
    func displayUserProfile(user: UserCardModel) {
        let vc = ProfileViewController(user: user, screenType: user.isSelf ? .own : .others)
        if vc.isBeingPresented {} else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
        
}

// MARK: RequestDelegate
extension SetupMammothViewController: RequestDelegate {
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                if self.viewModel.numberOfItems(forSection: 0) == 0 {
                    self.loader.isHidden = false
                    self.loader.startAnimating()
                }
                break
            case .success:
                self.loader.stopAnimating()
                self.loader.isHidden = true
                self.tableView.reloadData()
                break
            case .error(let error):
                self.loader.stopAnimating()
                self.loader.isHidden = true
                log.error("Error on SetupMammothViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }
    
    func didUpdateCard(at indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func didDeleteCard(at indexPath: IndexPath) {
        self.tableView.deleteRows(at: [indexPath], with: .bottom)
    }
}

extension SetupMammothViewController {
    
    @objc func noThanksTapped() {
        goToNextPane()
    }
    
    @objc func followMammothTapped() {
        self.viewModel.followMammothAccount()
        goToNextPane()
    }
    
    private func goToNextPane() {
        // Clear out the onboarding flag
        AccountsManager.shared.didShowOnboardingForCurrentAccount()
        // Exit the signup flow
        NotificationCenter.default.post(name: shouldChangeRootViewController, object: nil)
    }
}
