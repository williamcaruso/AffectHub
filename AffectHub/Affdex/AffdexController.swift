//
//  AffdexController.swift
//  AffectHub
//
//  Created by William Caruso on 6/12/18.
//  Copyright © 2018 wcaruso. All rights reserved.
//

import UIKit
import Affdex
import Foundation

class AffdexController: NSObject, AFDXDetectorDelegate {

    static let sharedInstance = AffdexController()
    let directoryModel = DirectoryModel.sharedInstance
    var detector:AFDXDetector? = nil
    var delegate:AffdexControllerDelegate?
    
    override init() {
        super.init()
        // create the detector
        detector = AFDXDetector(delegate:self, using:AFDX_CAMERA_FRONT, maximumFaces:1)
        detector?.setDetectEmojis(true)
        detector?.setDetectAllEmotions(true)
        detector?.setDetectAllExpressions(true)
    }
    
    func start() {
        detector!.start()
        print("started")
    }
    
    func stop() {
        detector!.stop()
    }
    
    
    func detector(_ detector : AFDXDetector, hasResults : NSMutableDictionary?, for forImage : UIImage, atTime : TimeInterval) {
//        self.cameraView.image = flipImageLeftRight(forImage)
        
        // handle processed and unprocessed images here
        if hasResults != nil {
            // handle processed image in this block of code
            
            // enumrate the dictionary of faces
            if (hasResults?.count)! > 0 {
                delegate?.startDetectedFace()
            } else {
                delegate?.stopDetectedFace()
            }
            
            for (_, face) in hasResults! {

//                let theEmoji = mapEmoji(emoji.dominantEmoji)
                
//                let orientation:AFDXOrientation = (face as AnyObject).orientation
//                let emotions:AFDXEmotions = (face as AnyObject).emotions
//                let expressions:AFDXExpressions = (face as AnyObject).expressions
//                let emojis:AFDXEmoji = (face as AnyObject).emojis
//                let faceBounds:CGRect = (face as AnyObject).faceBounds
//                let facePoints = (face as AnyObject).facePoints

//                print((face as AnyObject).jsonDescription())

                if let des = (face as AnyObject).jsonDescription() {
                    directoryModel.AffdexJSON += "\"\(Date().timeIntervalSince1970)\": {\(des)},\n"
                }
                
                var newLine = "\(Date().timeIntervalSince1970),"
                if let faceBounds:CGRect = (face as AnyObject).faceBounds {
                    newLine += "\(faceBounds.minX),\(faceBounds.minY),\(faceBounds.height),\(faceBounds.width),"

                } else {
                    newLine += "0,0,0,0,"

                }
                if let facePoints = (face as AnyObject).facePoints {
                    var xs = ""
                    var ys = ""
                    for point in facePoints! {
                        let pt:CGPoint = point as! CGPoint
                        xs += "\(pt.x),"
                        ys += "\(pt.y),"
                    }
                    newLine += xs
                    newLine += ys
                    newLine += "\n"
                } else {
                    newLine += "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\n"
                }
                
                directoryModel.AffdexCsvText += newLine
                print(newLine)
            }
        } else {
            // handle unprocessed image in this block of code
        }
    }
    
    // MARK: Private Helper Functions
    
    func flipImageLeftRight(_ image: UIImage) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.translateBy(x: image.size.width, y: image.size.height)
        context.scaleBy(x: -image.scale, y: -image.scale)
        
        context.draw(image.cgImage!, in: CGRect(origin:CGPoint.zero, size: image.size))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    // this method maps an emoji code to an emoji character
    func mapEmoji(_ emojiCode : Emoji) -> String {
        switch emojiCode {
        case AFDX_EMOJI_RAGE:
            return "😡"
        case AFDX_EMOJI_WINK:
            return "😉"
        case AFDX_EMOJI_SMIRK:
            return "😏"
        case AFDX_EMOJI_SCREAM:
            return "😱"
        case AFDX_EMOJI_SMILEY:
            return "😀"
        case AFDX_EMOJI_FLUSHED:
            return "😳"
        case AFDX_EMOJI_KISSING:
            return "😗"
        case AFDX_EMOJI_STUCK_OUT_TONGUE:
            return "😛"
        case AFDX_EMOJI_STUCK_OUT_TONGUE_WINKING_EYE:
            return "😜"
        case AFDX_EMOJI_RELAXED:
            return "☺️"
        case AFDX_EMOJI_LAUGHING:
            return "😆"
        case AFDX_EMOJI_DISAPPOINTED:
            return "😞"
        default:
            return "😶"
        }
    }
    
}


protocol AffdexControllerDelegate {
    func startDetectedFace()
    func stopDetectedFace()
}
