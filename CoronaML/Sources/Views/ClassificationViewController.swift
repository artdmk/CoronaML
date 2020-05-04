//
//  ClassificationViewController.swift
//  CoronaML
//
//  Created by Demchenko Artem on 03.05.2020.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit

class ClassificationViewController: UIViewController, ImagePickerDelegate {

    @IBOutlet weak private var checkVulnerabilityView: UIView?
    @IBOutlet weak private var chooseImageView: UIView?
    @IBOutlet weak private var imageContainerView: UIView?
    @IBOutlet weak private var imageView: UIImageView?
    @IBOutlet weak private var imageContainerHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak private var placeholderImageView: UIImageView?
    @IBOutlet weak private var confidenceView: UIView?
    @IBOutlet weak private var confidenceLabel: UILabel?
    @IBOutlet weak private var bottomView: UIView!
    
    private var imageClassificationProvider: MasksImageClassificationProvider?
    private var masksDetectionProvider: MasksObjectDetectionProvider?
    
    private lazy var imagePicker: ImagePickerHelper = {
        return ImagePickerHelper(presentationController: self, delegate: self)
    }()
    
    var selectedImage: UIImage?
    fileprivate var descriptions: [String]?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        imageClassificationProvider = MasksImageClassificationProvider()
        imageClassificationProvider?.delegate = self
        
        masksDetectionProvider = MasksObjectDetectionProvider()
        masksDetectionProvider?.delegate = self
        
        addGestureRecognizers()
        
        // inital UI setup
        configureUI()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkVulnerabilityView?.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.checkVulnerabilityView?.layoutIfNeeded()
        }
    }
    
    private func configureUI() {
        navigationItem.title = "Vulnerability check 🦠"
        
        // configure backgrounds
        checkVulnerabilityView?.backgroundColor = UIColor.generalBackgroundColor
        chooseImageView?.backgroundColor = UIColor.generalBackgroundColor
        bottomView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        view.backgroundColor = UIColor.generalBackgroundColor
        
        // configure view with prediction results
        confidenceView?.layer.cornerRadius = 28.0
        confidenceView?.clipsToBounds = true
        confidenceView?.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        confidenceLabel?.textColor = UIColor.white
        
        // add shadow to a bottom view
        bottomView.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        bottomView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.17).cgColor
        bottomView.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        bottomView.layer.shadowOpacity = 1.0
        bottomView.layer.shadowRadius = 5.0
    }
    
    private func addGestureRecognizers() {
        // gesture on overall inital screen
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickImage))
        placeholderImageView?.isUserInteractionEnabled = true
        placeholderImageView?.addGestureRecognizer(tapGestureRecognizer)

        // gesture outer the image
        let tapGestureRecognizerView = UITapGestureRecognizer(target: self, action: #selector(pickImage))
        checkVulnerabilityView?.isUserInteractionEnabled = true
        checkVulnerabilityView?.addGestureRecognizer(tapGestureRecognizerView)
    }
    
    fileprivate func updateUI() {
        // simple switch between views
        let isImageSelected = selectedImage != nil
        checkVulnerabilityView?.isHidden = isImageSelected
        chooseImageView?.isHidden = !isImageSelected
        
        // show prediction confidence results
        let isConfidenceLabelHidden = descriptions == nil
        confidenceLabel?.text = descriptions?.joined(separator: "\n")
        confidenceView?.isHidden = isConfidenceLabelHidden
        UIView.animate(withDuration: 0.3) {
            self.confidenceView?.layoutIfNeeded()
        }
        
        // update image view layout
        imageView?.image = selectedImage
        fitImageViewUpToImageSize()
    }
    
    private func fitImageViewUpToImageSize() {
        guard let imageContainer = imageContainerView,
            let image = selectedImage else {
                return
        }
        // calculate container height accordingly to image size
        let ratio = image.size.width / image.size.height
        let newHeight = imageContainer.frame.width / ratio
        self.imageContainerHeightConstraint?.constant = newHeight
    }

    // MARK: Actions
    
    @IBAction func didTapChooseFirstImage(_ sender: Any) {
        pickImage()
    }
    
    @IBAction func didTapChooseImage(_ sender: Any) {
        pickImage()
    }
    
    @IBAction func didTapClassify(_ sender: UIButton) {
        detectMasks()
    }
    
    @objc private func pickImage() {
        imagePicker.present(from: view)
    }
    
    private func classifyImage() {
        guard let image = self.selectedImage, let ciImage = CIImage(image: image) else {
            return
        }
        imageClassificationProvider?.updateClassificationsForImage(ciImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    }
    
    private func detectMasks() {
        guard let image = self.selectedImage, let ciImage = CIImage(image: image) else {
            return
        }
        masksDetectionProvider?.performMasksDetectionForImage(ciImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    }
    
    // MARK: ImagePickerDelegate
    
    func didSelect(image: UIImage?) {
        self.selectedImage = image
        self.descriptions = nil
        classifyImage()
        updateUI()
    }
}

extension ClassificationViewController: ImageClassificationDelegate {
    
    func finfishedClassificationProcessing(_ descriptions: [String]?) {
        self.descriptions = descriptions
        updateUI()
    }
}

extension ClassificationViewController: ImageDetectorDelegate {
    
    func didFinfishDetectionProcessing(_ image: UIImage?) {
        guard let image = image else { return }
        self.imageView?.image = image
    }
}
