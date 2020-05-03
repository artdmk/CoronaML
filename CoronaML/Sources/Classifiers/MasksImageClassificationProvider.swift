//
//  MasksImageClassificationProvider.swift
//  CoronaML
//
//  Created by Demchenko Artem on 03.05.2020.
//  Copyright © 2020 Home. All rights reserved.
//

import Foundation
import CoreImage
import CoreML
import Vision

class MasksImageClassificationProvider {
    
    private enum MaskClassificationIdentifier: String {
        case mask = "Masks"
        case noMasks = "NoMasks"
        
        func uiDescription(_ confidence: Float) -> String {
            switch self {
            case .mask:
                return String(format: "%.2f%% masks covered 😷", confidence * 100.0)
            case .noMasks:
                return String(format: "%.2f%% need a mask 🤒", confidence * 100.0)
            }
        }
    }
    
    weak var delegate: ImageClassificationDelegate?
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MasksImageClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassificationsForRequest(request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load mlmodel: \(error)")
        }
    }()
    
    func updateClassificationsForImage(_ ciImage: CIImage, orientation: CGImagePropertyOrientation) {
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the UI with the results of the classification
    private func processClassificationsForRequest(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let classifications = request.results as? [VNClassificationObservation] else {
                self.delegate?.finfishedClassificationProcessing(nil)
                return
            }
            
            // Masked and NoMasks Classifications sorted by confidence
            let descriptions = classifications.prefix(2).compactMap { MaskClassificationIdentifier(rawValue: $0.identifier)?.uiDescription($0.confidence) }
            
            self.delegate?.finfishedClassificationProcessing(descriptions)
        }
    }
}

protocol ImageClassificationDelegate: AnyObject {
    func finfishedClassificationProcessing(_ descriptions: [String]?)
}
