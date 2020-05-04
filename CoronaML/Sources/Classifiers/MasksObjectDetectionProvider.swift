//
//  MasksObjectDetectionProvider.swift
//  CoronaML
//
//  Created by Demchenko Artem on 04.05.2020.
//  Copyright © 2020 Home. All rights reserved.
//

import UIKit
import CoreML
import Vision

class MasksObjectDetectionProvider {
    
    weak var delegate: ImageDetectorDelegate?
    
    private lazy var detectionRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MaskObjectDetector().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetectionForRequest(request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load mlmodel: \(error)")
        }
    }()
    
    func performMasksDetectionForImage(_ ciImage: CIImage, orientation: CGImagePropertyOrientation) {
           DispatchQueue.global(qos: .userInitiated).async {
               let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
               do {
                   try handler.perform([self.detectionRequest])
               } catch {
                   print("Failed to perform detection.\n\(error.localizedDescription)")
               }
           }
       }
    
    /// Updates selected image with the results of objects detection
    private func processDetectionForRequest(_ request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let observations = request.results as? [VNDetectedObjectObservation],
                let image = self.delegate?.selectedImage  else {
                self.delegate?.didFinfishDetectionProcessing(nil)
                return
            }
            
            // Quartz 2D coordinate -> UIKit coordinates and flip vertically
            let imageSize = image.size
            var transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
                .translatedBy(x: 0, y: -imageSize.height)
            // Scale the normalized bounding box based on the image dimensions
            transform = transform.scaledBy(x: imageSize.width, y: imageSize.height)
            
            // Rendering into bitmap
            UIGraphicsBeginImageContextWithOptions(imageSize, true, 0.0)
            let context = UIGraphicsGetCurrentContext()
            
            // Draw image in the current context within calculated bounds
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            context?.saveGState()
            
            // Join line, stroke color, fill color
            context?.setLineWidth(8.0)
            context?.setLineJoin(CGLineJoin.round)
            context?.setStrokeColor(UIColor.green.cgColor)
            context?.setFillColor(red: 0, green: 1, blue: 0, alpha: 0.3)
            
            observations.forEach({ observation in
                // observation rect transform into UIKit coordinates and add the rects
                let observationBounds = observation.boundingBox.applying(transform)
                context?.addRect(observationBounds)
            })
            // draw the rects
            context?.drawPath(using: CGPathDrawingMode.fillStroke)
            
            // restore current graphics state
            context?.restoreGState()
            // get the final image
            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
   
            UIGraphicsEndImageContext()
         
            self.delegate?.didFinfishDetectionProcessing(drawnImage)
        }
    }
}

protocol ImageDetectorDelegate: AnyObject {
    
    var selectedImage: UIImage? { get }
    
    func didFinfishDetectionProcessing(_ image: UIImage?)
}
