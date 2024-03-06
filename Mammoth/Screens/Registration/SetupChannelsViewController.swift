//
//  SetupChannelsViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 10/9/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit

class SetupChannelsViewController: UIViewController {
    
    private lazy var navHeader: UIView = {
        let navHeader = UIView()
        navHeader.translatesAutoresizingMaskIntoConstraints = false
        navHeader.backgroundColor = .custom.background
        return navHeader
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(UINib(nibName: "SetupInstructionsCell", bundle: nil), forCellReuseIdentifier: SetupInstructionsCell.reuseIdentifier)
        tableView.register(ChannelCell.self, forCellReuseIdentifier: ChannelCell.reuseIdentifier)
        tableView.register(NoResultsCell.self, forCellReuseIdentifier: NoResultsCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
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
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.startAnimating()
        loader.hidesWhenStopped = true
        return loader;
    }()
    
    private lazy var doneButton: UIButton = {
        let doneButton = UIButton()
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle(NSLocalizedString("generic.next", comment: ""), for: .normal)
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

    private var viewModel: SetupChannelsViewModel

    required init() {
        self.viewModel = SetupChannelsViewModel.shared
        super.init(nibName: nil, bundle: nil)
        self.isModalInPresentation = true
        self.viewModel.delegate = self
        
        // Give the next screen time to preload
        SetupAccountsViewModel.preload()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onThemeChange() {
        self.tableView.reloadData()
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
        
        doneButton.addTarget(self, action: #selector(self.doneTapped), for: .touchUpInside)
        doneButtonBackground.addSubview(doneButton)
        view.addSubview(doneButtonBackground)
        NSLayoutConstraint.activate([
            doneButtonBackground.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            doneButtonBackground.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            doneButtonBackground.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),

            doneButton.leadingAnchor.constraint(equalTo: doneButtonBackground.leadingAnchor, constant: 13),
            doneButton.trailingAnchor.constraint(equalTo: doneButtonBackground.trailingAnchor, constant: -13),
            doneButton.topAnchor.constraint(equalTo: doneButtonBackground.topAnchor, constant: 13),
            doneButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
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
extension SetupChannelsViewController: UITableViewDataSource & UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If no items present, return 1 to show the No Results cell
        let numItems = viewModel.numberOfItems(forSection: section)
        return numItems == 0 ? 1 : numItems
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
            cell.configure(title: NSLocalizedString("onboarding.smartlists.title", comment: ""), instructions: NSLocalizedString("onboarding.smartlists.description", comment: ""))
            return cell
        } else {
            if let (channel, isSubscribed) = viewModel.getInfo(forIndexPath: indexPath), let channel {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: ChannelCell.reuseIdentifier, for: indexPath) as! ChannelCell
                cell.configure(channel: channel, isSubscribed: isSubscribed)
                cell.delegate = self
                return cell
            } else {
                let cell = self.tableView.dequeueReusableCell(withIdentifier: NoResultsCell.reuseIdentifier) as! NoResultsCell
                return cell
            }
        }
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
        if let (channel, _) = viewModel.getInfo(forIndexPath: indexPath), let channel {
            let vc = NewsFeedViewController(type: .channel(channel))
            if vc.isBeingPresented {} else {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
}

extension SetupChannelsViewController: SetupChannelsViewModelDelegate {
    
    func didUpdate(with state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .idle:
                break
            case .loading:
                if self.viewModel.numberOfItems(forSection: 1) == 0 {
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
                log.error("Error on SetupChannelsViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }

}

extension SetupChannelsViewController {
    @objc func doneTapped() {
        // Sign up for the News channel
        if let newsChannel = viewModel.newsChannel {
            ChannelManager.shared.subscribeToChannel(newsChannel, silent: true)
        }
        // Go to the next screen
        let vc = SetupAccountsViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
