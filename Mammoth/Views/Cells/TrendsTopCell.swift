//
//  TrendsTopCell.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 01/03/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit
import Vision
import NaturalLanguage
import LinkPresentation

class TrendsTopCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, SKPhotoBrowserDelegate {

    var bgView = UIView()
    var collectionView1: UICollectionView!
    var imageHeight: CGFloat = 230
    var allPosts: [Card] = []
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView = UIVisualEffectView()
    var tmpIndex: Int = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bgView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bgView)
        
        var fullWidth = UIScreen.main.bounds.size.width - 87
        #if targetEnvironment(macCatalyst)
        fullWidth = UIApplication.shared.windows.first?.frame.size.width ?? 0
        #endif

        let layout = ColumnFlowLayout4(
            cellsPerRow: 4,
            minimumInteritemSpacing: 0,
            minimumLineSpacing: 0,
            sectionInset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        )
        layout.itemSize = CGSize(width: contentView.bounds.width, height: contentView.bounds.width)
        layout.scrollDirection = .horizontal
        if !GlobalStruct.isCompact {
            if GlobalStruct.singleColumn {
                collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(fullWidth), height: CGFloat(400)), collectionViewLayout: layout)
            } else {
                collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(GlobalStruct.padColWidth), height: CGFloat(imageHeight)), collectionViewLayout: layout)
            }
        } else {
            collectionView1 = UICollectionView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: CGFloat(imageHeight)), collectionViewLayout: layout)
        }
        collectionView1.translatesAutoresizingMaskIntoConstraints = false
        collectionView1.backgroundColor = .custom.quoteTint
        collectionView1.delegate = self
        collectionView1.dataSource = self
        collectionView1.showsHorizontalScrollIndicator = false
        collectionView1.isPagingEnabled = true
        collectionView1.register(CollectionImageCell4.self, forCellWithReuseIdentifier: "CollectionImageCell")
        bgView.addSubview(collectionView1)

        let viewsDict = [
            "bgView" : bgView,
            "collectionView1" : collectionView1!,
        ] as [String : Any]

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[bgView]-0-|", options: [], metrics: nil, views: viewsDict))

        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[collectionView1]-0-|", options: [], metrics: nil, views: viewsDict))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[collectionView1(230)]-0-|", options: [], metrics: nil, views: viewsDict))
    }
    
    func setupDots() {
        for x in self.contentView.subviews {
            if x.tag >= 20 {
                x.removeFromSuperview()
            }
        }
        
        var minusDiff: CGFloat = 32
        if (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) > 370 {
            // this is for iPhone 8-sized devices
            minusDiff = 40
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            minusDiff = 32
        }
        var width: CGFloat = 0
        if !GlobalStruct.isCompact {
            var fullWidth = UIScreen.main.bounds.size.width - 87 - minusDiff
            #if targetEnvironment(macCatalyst)
            fullWidth = (UIApplication.shared.windows.first?.frame.size.width ?? 0) - minusDiff
            #endif
            if GlobalStruct.singleColumn {
                width = CGFloat(fullWidth)
            } else {
                width = CGFloat(GlobalStruct.padColWidth)
            }
        } else {
#if targetEnvironment(macCatalyst)
            width = CGFloat(GlobalStruct.padColWidth)
#elseif !targetEnvironment(macCatalyst)
            width = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff
#endif
        }
        
        let aa: CGFloat = CGFloat((6 * (self.allPosts.count - 1)))
        let widthofAllTogether: CGFloat = CGFloat((6 * self.allPosts.count)) + aa
        for (c,_) in self.allPosts.enumerated() {
            let startPos: CGFloat = CGFloat(width/2) - CGFloat(widthofAllTogether/2)
            let dot = UIView()
            dot.tag = c + 20
            dot.frame = CGRect(x: Int(Int(startPos) + (c * 12)), y: 212, width: 6, height: 6)
            if c == 0 {
                dot.backgroundColor = .white
            } else {
                dot.backgroundColor = .white.withAlphaComponent(0.4)
            }
            dot.layer.cornerRadius = 3
            self.contentView.addSubview(dot)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupPost(_ postText: [Card]) {
        self.allPosts = postText
        self.setupDots()
        self.collectionView1.reloadData()
    }
    
    func setupPostWithoutDots(_ postText: [Card]) {
        self.allPosts = postText
        self.collectionView1.reloadData()
    }

    // images

    var images: [String] = []
    var images2: [UIImageView] = []
    var images3: [String] = []
    let countButtonBG = UIButton()
    let countButton = UIButton()
    var allCounts: Int = 0
    var currentIndex: Int = 0
    var dataImages: [Data?] = []
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.allPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionImageCell", for: indexPath) as! CollectionImageCell4
        cell.configure()
        cell.image.contentMode = .scaleAspectFill
        if let ur = self.allPosts[indexPath.item].image ?? URL(string: "www.google.com") {
            cell.image.sd_setImage(with: ur)
        }
        cell.image.layer.masksToBounds = true
        
        if currentIndex < allPosts.count {
            let source = "\((allPosts[indexPath.row].providerName ?? allPosts[indexPath.row].authorName ?? "").replacingOccurrences(of: "\n\n", with: "\n"))"
            let titl = "\(allPosts[indexPath.row].description.stripHTML().replacingOccurrences(of: "\n\n", with: "\n"))"
            
            let attStringNewLine000 = NSMutableAttributedString()
            let attStringNewLine00 = NSMutableAttributedString(string: "\(source)\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .black), NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(1)])
            let attStringNewLine01 = NSMutableAttributedString(string: titl, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .semibold), NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.8)])
            attStringNewLine000.append(attStringNewLine00)
            attStringNewLine000.append(attStringNewLine01)
            cell.postButton.setAttributedTitle(attStringNewLine000, for: .normal)
            
            cell.postButton.layer.shadowColor = UIColor.black.cgColor
            cell.postButton.layer.shadowOffset = CGSize(width: 0, height: 1)
            cell.postButton.layer.shadowRadius = 1
            cell.postButton.layer.shadowOpacity = 0.7
            
            cell.postButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 23, right: 10)
            cell.postButton.isUserInteractionEnabled = false
            
            if cell.postButton.tag == 2 {} else {
                cell.postButton.tag = 2
                let colorTop =  UIColor.black.withAlphaComponent(0).cgColor
                let colorBottom = UIColor.black.withAlphaComponent(0.6).cgColor
                let gradientLayer = CAGradientLayer()
                gradientLayer.colors = [colorTop, colorBottom]
                gradientLayer.locations = [0.0, 1.0]
                gradientLayer.frame = cell.postButton.bounds
                gradientLayer.removeFromSuperlayer()
                cell.postButton.layer.insertSublayer(gradientLayer, at: 0)
            }
        }
        cell.backgroundColor = UIColor.clear
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        if let ip = self.collectionView1.indexPathForItem(at: center) {
            currentIndex = ip.row
            for sub in self.contentView.subviews {
                if sub.tag == currentIndex + 20 {
                    sub.backgroundColor = .white
                } else {
                    sub.backgroundColor = .white.withAlphaComponent(0.4)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        triggerHapticImpact(style: .light)
        if let x = self.allPosts[indexPath.item].url {
            if let ur = URL(string: x) {
                PostActions.openLink(ur)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(indexPath.row)
        })
    }

    func makeContextMenu(_ index: Int) -> UIMenu {
        let openLink = UIAction(title: "Open Link", image: UIImage(systemName: "safari"), identifier: nil) { action in
            if let x = self.allPosts[index].url {
                if let ur = URL(string: x) {
                    PostActions.openLink(ur)
                }
            }
        }
        let copy = UIAction(title: NSLocalizedString("generic.copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), identifier: nil) { action in
            if let x = self.allPosts[index].url {
                UIPasteboard.general.string = x
            }
        }
        let share = UIAction(title: NSLocalizedString("generic.share", comment: ""), image: FontAwesome.image(fromChar: "\u{e09a}"), identifier: nil) { action in
            if let x = self.allPosts[index].url {
                let linkToShare = [x]
                let activityViewController = UIActivityViewController(activityItems: linkToShare,  applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.contentView
                activityViewController.popoverPresentationController?.sourceRect = self.contentView.bounds
                self.getTopMostViewController()?.present(activityViewController, animated: true, completion: nil)
            }
        }
        return UIMenu(title: "", image: nil, identifier: nil, children: [openLink, copy, share])
    }

}

