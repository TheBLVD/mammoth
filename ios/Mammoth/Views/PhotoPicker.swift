//
//  PhotoPicker.swift
//  Mammoth
//
//  Created by Riley Howard on 1/17/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import UIKit
import MobileCoreServices

protocol PhotoPickerDelegate : AnyObject {
    func didUpdateImage(image: UIImage)
}

class PhotoPicker: NSObject {
    
    enum PhotoType {
        case Avatar
        case Header
    }
    
    weak var delegate: PhotoPickerDelegate? = nil
    var imagePickerController = UIImagePickerController()
    var cropViewController: CropViewController? = nil
    var photoType: PhotoType = .Avatar
    var hostViewController: UIViewController?
    
    override init() {
        super.init()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String]
    }
    
    func presentPicker(hostViewController: UIViewController, animated: Bool) {
        self.hostViewController = hostViewController
        imagePickerController.overrideUserInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
        hostViewController.present(imagePickerController, animated: animated)
    }
    
}


extension PhotoPicker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if mediaType == "public.movie" || mediaType == kUTTypeGIF as String {} else {
                if let photoToAttach = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    cropViewController = CropViewController(image: photoToAttach)
                    cropViewController?.overrideUserInterfaceStyle = picker.overrideUserInterfaceStyle
                    if let cropViewController {
                        cropViewController.delegate = self
                        if photoType == .Avatar {
                            cropViewController.aspectRatioPreset = CropViewControllerAspectRatioPreset.presetSquare
                        } else {
                            cropViewController.aspectRatioPreset = CropViewControllerAspectRatioPreset.preset3x1
                        }
                        cropViewController.aspectRatioLockEnabled = true
                        cropViewController.resetAspectRatioEnabled = false
                        cropViewController.aspectRatioPickerButtonHidden = true
                        cropViewController.title = "Resize"
                        getTopMostViewController()?.present(cropViewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
 
}


extension PhotoPicker : CropViewControllerDelegate {
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true, completion: nil)
        hostViewController!.dismiss(animated: false, completion: nil)
        if let delegate {
            delegate.didUpdateImage(image: image)
        }
    }

}




