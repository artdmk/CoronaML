//
//  ImagePickerHelper.swift
//  CoronaML
//
//  Created by Demchenko Artem on 03.05.2020.
//  Copyright © 2020 Home. All rights reserved.
//

import Foundation

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

open class ImagePickerHelper: NSObject {
    
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    
    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()
        
        super.init()
        
        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
    }
    
    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }
        
        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    private func titleForSource(_ source: UIImagePickerController.SourceType) -> String {
        switch source {
        case .photoLibrary:
            return "Photo library"
        case .camera:
            return "Take photo"
        case .savedPhotosAlbum:
            return "Camera roll"
        @unknown default:
            return ""
        }
    }
    
    public func present(from sourceView: UIView) {
        present(from: sourceView, sources: [.camera, .savedPhotosAlbum, .photoLibrary])
    }
    
    public func present(from sourceView: UIView, sources: [UIImagePickerController.SourceType]) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for source in sources {
            if let action = self.action(for: source, title: titleForSource(source)) {
                alertController.addAction(action)
            }
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }
        
        self.presentationController?.present(alertController, animated: true)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)
        
        self.delegate?.didSelect(image: image)
    }
}

extension ImagePickerHelper: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            picker.dismiss(animated: true, completion: nil)
            delegate?.didSelect(image: image)
            
        } else {
            self.pickerController(picker, didSelect: nil)
        }
    }
}
