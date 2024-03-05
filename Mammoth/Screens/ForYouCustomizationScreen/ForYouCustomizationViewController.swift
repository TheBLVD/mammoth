//
//  ForYouCustomizationViewController.swift
//  Mammoth
//
//  Created by Riley Howard on 8/3/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ForYouCustomizationViewController: UIViewController {
    
    private lazy var topHeader: UIView = {
        let topHeader = UIView()
        topHeader.translatesAutoresizingMaskIntoConstraints = false
        return topHeader
    }()
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle(NSLocalizedString("generic.close", comment: ""), for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17)
        closeButton.setTitleColor(.custom.highContrast, for: .normal)
        return closeButton
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("title.forYou", comment: "")
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .custom.highContrast
        return titleLabel
    }()
    
    private lazy var titleDividerLine: UIView = {
        let titleDividerLine = UIView()
        titleDividerLine.translatesAutoresizingMaskIntoConstraints = false
        titleDividerLine.backgroundColor = .custom.outlines
        return titleDividerLine
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.register(UINib(nibName: "ForYouCustomizationCell", bundle: nil), forCellReuseIdentifier: ForYouCustomizationCell.reuseIdentifier)
        tableView.register(UINib(nibName: "ForYouChannelCell", bundle: nil), forCellReuseIdentifier: ForYouChannelCell.reuseIdentifier)
        tableView.register(NoResultsCell.self, forCellReuseIdentifier: NoResultsCell.reuseIdentifier)
        tableView.backgroundColor = .custom.background

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.sectionFooterHeight = 0
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        return tableView
    }()
    
    private lazy var accountNotReadyLabel: UILabel = {
        let accountNotReadyLabel = UILabel()
        accountNotReadyLabel.translatesAutoresizingMaskIntoConstraints = false
        accountNotReadyLabel.text = nil
        accountNotReadyLabel.font = .systemFont(ofSize: 15)
        accountNotReadyLabel.textColor = .custom.highContrast
        accountNotReadyLabel.numberOfLines = 0
        return accountNotReadyLabel
    }()

    private lazy var loader: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView()
        loader.startAnimating()
        loader.hidesWhenStopped = true
        loader.translatesAutoresizingMaskIntoConstraints = false
        return loader;
    }()
    
    private var viewModel: ForYouCustomizationViewModel
    
    required init() {
        self.viewModel = ForYouCustomizationViewModel()
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.title = "Instances"
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
}

    
    
    
// MARK: UI Setup
private extension ForYouCustomizationViewController {
    func setupUI() {
        self.view.backgroundColor = .custom.background
        closeButton.addTarget(self, action: #selector(self.done(_:)), for: .touchUpInside)
        topHeader.addSubview(closeButton)
        topHeader.addSubview(titleLabel)
        topHeader.addSubview(titleDividerLine)
        NSLayoutConstraint.activate([
            self.closeButton.topAnchor.constraint(equalTo: topHeader.topAnchor, constant: 10),
            self.closeButton.leadingAnchor.constraint(equalTo: topHeader.leadingAnchor, constant:13),
            self.titleLabel.topAnchor.constraint(equalTo: topHeader.topAnchor, constant: 16),
            self.titleLabel.centerXAnchor.constraint(equalTo: topHeader.centerXAnchor),

            self.titleDividerLine.heightAnchor.constraint(equalToConstant: 0.5),
            self.titleDividerLine.leadingAnchor.constraint(equalTo: topHeader.leadingAnchor),
            self.titleDividerLine.trailingAnchor.constraint(equalTo: topHeader.trailingAnchor),
            self.titleDividerLine.bottomAnchor.constraint(equalTo: topHeader.bottomAnchor, constant: 0),

        ])
        
        view.addSubview(topHeader)
        NSLayoutConstraint.activate([
            self.topHeader.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.topHeader.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.topHeader.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.topHeader.heightAnchor.constraint(equalToConstant: 48),
            ])
        
        view.addSubview(tableView)
        view.addSubview(loader)
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: topHeader.bottomAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.loader.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loader.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
        view.addSubview(accountNotReadyLabel)
        NSLayoutConstraint.activate([
            self.accountNotReadyLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 17),
            self.accountNotReadyLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -17),
            self.accountNotReadyLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
        ])
    }
}


// MARK: UITableViewDataSource & UITableViewDelegate
extension ForYouCustomizationViewController: UITableViewDataSource & UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  viewModel.numberOfItems(forSection: section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let forYouRowInfo = viewModel.getInfo(forIndexPath: indexPath) {
            switch ForYouCustomizationViewModel.Section(rawValue: indexPath.section) {
            case .mammothPicks:
                let cell = self.tableView.dequeueReusableCell(withIdentifier: ForYouCustomizationCell.reuseIdentifier, for: indexPath) as! ForYouCustomizationCell
                cell.delegate = self
                cell.enabledSwitch.isEnabled = true
                cell.configure(forYouRowInfo: forYouRowInfo, section: .mammothPicks, hasChildCells: false)
                return cell
            case .smartLists:
                if indexPath.row == 0 {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: ForYouCustomizationCell.reuseIdentifier, for: indexPath) as! ForYouCustomizationCell
                    cell.delegate = self
                    let hasChildCells = self.tableView.numberOfRows(inSection: indexPath.section) > 1
                    cell.enabledSwitch.isEnabled = true
                    cell.configure(forYouRowInfo: forYouRowInfo, section: .smartLists, hasChildCells: hasChildCells)
                    return cell
                } else {
                    let cell = self.tableView.dequeueReusableCell(withIdentifier: ForYouChannelCell.reuseIdentifier, for: indexPath) as! ForYouChannelCell
                    let isBottomCell = self.tableView.numberOfRows(inSection: indexPath.section) == indexPath.row + 1
                    cell.configure(forYouRowInfo: forYouRowInfo, index: indexPath.row, isBottomCell: isBottomCell)
                    return cell
                }
            case .beta:
                let cell = self.tableView.dequeueReusableCell(withIdentifier: ForYouCustomizationCell.reuseIdentifier, for: indexPath) as! ForYouCustomizationCell
                cell.delegate = self
                let hasChildCells = false
                cell.enabledSwitch.isEnabled = forYouRowInfo.isEnabled
                cell.configure(forYouRowInfo: forYouRowInfo, section: .beta, betaItem: ForYouCustomizationViewModel.BetaItem(rawValue: indexPath.item), hasChildCells: hasChildCells)
                return cell
            case .none:
                return UITableViewCell()
            }
        }
        log.error("Didn't expect to get here")
        return UITableViewCell()
    }
        
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.hasHeader(forSection: section) {
            return 34
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.hasHeader(forSection: section) {
            let header = ForYouCustomizationHeader()
            header.configure(labelText: viewModel.getSectionTitle(for: section))
            return header
        } else {
            return nil
        }
    }

    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if ForYouCustomizationViewModel.Section(rawValue: indexPath.section) == .smartLists && indexPath.row != 0 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if ForYouCustomizationViewModel.Section(rawValue: indexPath.section) == .smartLists && indexPath.row != 0 {
            return indexPath
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard ForYouCustomizationViewModel.Section(rawValue: indexPath.section) == .smartLists && indexPath.row != 0 else {
            log.error("unexpected section")
            return
        }
        // Toggle the checkbox
        if let forYouRowInfo = viewModel.getInfo(forIndexPath: indexPath) {
            self.viewModel.setForYouRowInfoOn(indexPath: indexPath, value: !forYouRowInfo.isOn)
        }
    }
    
}

// MARK: - ForYouCustomizationCellDelegate
extension ForYouCustomizationViewController: ForYouCustomizationCellDelegate {
    // User toggled one of the switches
    func setForYouRowInfoOn(section: ForYouCustomizationViewModel.Section, betaItem: ForYouCustomizationViewModel.BetaItem?, value: Bool) {
        let indexPath = IndexPath(item: betaItem?.rawValue ?? 0, section: section.rawValue)
        self.viewModel.setForYouRowInfoOn(indexPath: indexPath, value: value)
    }
}


// For when the top section changes
extension ForYouCustomizationViewController: ForYouCustomizationDelegate {
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
                log.error("Error on InstancesViewController didUpdate: \(state) - \(error)")
                break
            }
        }
    }
    
    func didUpdateForYouAccountType(_ forYouAccountType: ForYouAccountType?) {
        log.warning("updated waitlist forYouAccountType: \(forYouAccountType)")
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    
    func shouldJoinWaitlist(completion: @escaping (_ join: Bool) -> Void) {
        // Ask the user if they want to join the waitlist
        let dialogMessage = UIAlertController(title: "Join the waitlist?", message: "This option is currently in beta. Would you like to join the waitlist?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { UIAlertAction in
            completion(true)
            self.tableView.reloadSections([ForYouCustomizationViewModel.Section.beta.rawValue], with: .none)
        })
        dialogMessage.addAction(yesAction)
        let noAction = UIAlertAction(title: "No Thanks", style: .cancel, handler: { UIAlertAction in
            completion(false)
            self.tableView.reloadRows(at: [IndexPath(item: ForYouCustomizationViewModel.BetaItem.signUpForBeta.rawValue, section: ForYouCustomizationViewModel.Section.beta.rawValue)], with: .none)
        })
        dialogMessage.addAction(noAction)
        self.present(dialogMessage, animated: true, completion: nil)
    }

}

// MARK: - User actions
extension ForYouCustomizationViewController {
    @IBAction func done(_ sender: Any) {
        triggerHapticImpact(style: .light)
        guard viewModel.canSendSettingsToServer() else {
            let dialogMessage = UIAlertController(title: "No feeds selected", message: "You must select at least one active feed.", preferredStyle: .alert)
            dialogMessage.addAction(UIAlertAction(title: NSLocalizedString("generic.ok", comment: ""), style: .default))
            self.present(dialogMessage, animated: true, completion: nil)
            return
        }
        viewModel.sendSettingsToServer()
        self.dismiss(animated: true, completion: nil)
    }
}



