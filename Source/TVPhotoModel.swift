//
//  TVPhotoModel.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/17/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

public class TVPhotoModel {
    public var thumbnailImage : UIImage? {
        didSet {
            if let validImage = thumbnailImage {
               ratio = validImage.size.width / validImage.size.height
            }
        }
    }
    
    public var thumbnailImageUrl : NSURL?
    public var originalImageUrl : NSURL?
    public var ratio : CGFloat = 1
    public var index : Int = 0
    
    public init(index : Int , thumbnailImageUrl : NSURL? , originalImageUrl : NSURL?) {
        self.index = index
        self.thumbnailImageUrl = thumbnailImageUrl
        self.originalImageUrl = originalImageUrl
    }
}