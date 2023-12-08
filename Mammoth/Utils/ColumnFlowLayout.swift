//
//  ColumnFlowLayout.swift
//  Mammoth
//
//  Created by Shihab Mehboob on 27/01/2022.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation
import UIKit

class ColumnFlowLayout: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 80), height: 220)
        } else {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth), height: 220)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 80), height: 220)
        } else {
            if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth), height: 220)
            } else {
                itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: 220)
            }
        }
#endif
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayoutBG: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 80 - 80), height: 220)
        } else {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth) - 80, height: 220)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 80 - 80), height: 220)
        } else {
            if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
                itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth) - 80, height: 220)
            } else {
                itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 80, height: 220)
            }
        }
#endif
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayoutS: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        itemSize = CGSize(width: 66, height: 66)
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayoutD: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    var preferredWidth: CGFloat?
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        let windowFrame = UIApplication.shared.connectedScenes
                        .compactMap({ scene -> UIWindow? in
                            (scene as? UIWindowScene)?.windows.first
                        }).first?.frame
        
        var fullWidth = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 220
        #if targetEnvironment(macCatalyst)
        fullWidth = windowFrame?.size.width ?? 0
        #endif
        
#if targetEnvironment(macCatalyst)
        if GlobalStruct.singleColumn {
            itemSize = CGSize(width: fullWidth, height: 400)
        } else {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth), height: 280)
        }
#elseif !targetEnvironment(macCatalyst)
        if UIDevice.current.userInterfaceIdiom == .pad && GlobalStruct.singleColumn && UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: preferredWidth ?? ((UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 220), height: 400)
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth), height: 280)
            } else {
                itemSize = CGSize(width: preferredWidth ?? CGFloat(UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width), height: 280)
            }
        }
#endif
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayout2: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
        } else {
            #if targetEnvironment(macCatalyst)
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 100), height: 190)
            #elseif !targetEnvironment(macCatalyst)
            itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 100, height: 190)
            #endif
        }
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayout3: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
        } else {
            #if targetEnvironment(macCatalyst)
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 40), height: 190)
            #elseif !targetEnvironment(macCatalyst)
            itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 190)
            #endif
        }
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayout4: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        var minusDiff: CGFloat = 32
        if (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) > 400 {
            minusDiff = 40
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            minusDiff = 32
        }
        var fullWidth = (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 87
        #if targetEnvironment(macCatalyst)
        fullWidth = UIApplication.shared.windows.first?.frame.size.width ?? 0
        #endif
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            if GlobalStruct.singleColumn {
                itemSize = CGSize(width: CGFloat(fullWidth) - minusDiff, height: 230)
            } else {
                itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth) - minusDiff, height: 230)
            }
        } else {
            #if targetEnvironment(macCatalyst)
            itemSize = CGSize(width: CGFloat(fullWidth) - minusDiff, height: 230)
            #elseif !targetEnvironment(macCatalyst)
            itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - minusDiff, height: 230)
            #endif
        }
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayout5: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
        } else {
            #if targetEnvironment(macCatalyst)
            itemSize = CGSize(width: CGFloat(GlobalStruct.padColWidth - 40), height: 240)
            #elseif !targetEnvironment(macCatalyst)
            itemSize = CGSize(width: (UIApplication.shared.windows.first?.bounds.width ?? UIScreen.main.bounds.width) - 40, height: 240)
            #endif
        }
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}

class ColumnFlowLayoutIAP: UICollectionViewFlowLayout {
    
    let cellsPerRow: Int
    
    init(cellsPerRow: Int, minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        self.cellsPerRow = cellsPerRow
        super.init()
        
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        if UIApplication.shared.preferredApplicationWindow?.traitCollection.horizontalSizeClass != .compact {
            itemSize = CGSize(width: CGFloat(150), height: 240)
        } else {
            #if targetEnvironment(macCatalyst)
            itemSize = CGSize(width: CGFloat(150), height: 240)
            #elseif !targetEnvironment(macCatalyst)
            itemSize = CGSize(width: 150, height: 240)
            #endif
        }
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
}
