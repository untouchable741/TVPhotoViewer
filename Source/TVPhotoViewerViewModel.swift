//
//  TVPhotoViewerViewModel.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/17/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

class TVPhotoViewerViewModel {
    var photoArray : [TVPhotoModel]?
    var cachedPhotoPages = NSCache()
    var preloadPhotoCount = 3
    
    func photoPageAtIndex(index : Int , thumbnailUrl: NSURL?, originalImageUrl : NSURL?) -> TVPhotoPage? {
        if let cachedPage = cachedPhotoPages.objectForKey(index) {
            return cachedPage as? TVPhotoPage
        }
        
        let photo = TVPhotoModel(index: index, thumbnailImageUrl: thumbnailUrl, originalImageUrl: originalImageUrl)
        let page = TVPhotoPage(photo: photo)
        cachedPhotoPages.setObject(page, forKey: index)
        cleanCacheAtIndex(index)
        
        return page
    }
    
    func cleanCacheAtIndex(index : Int) {
        let clearCachedIndex = [index - preloadPhotoCount , index + preloadPhotoCount]
        clearCachedIndex.forEach { index in
            cachedPhotoPages.removeObjectForKey(index)
        }
    }
    
    func cleanAllOtherCachedPage(exceptionalIndex : Int) {
        if let exceptionalPage = cachedPhotoPages.objectForKey(exceptionalIndex) {
            cachedPhotoPages.removeAllObjects()
            cachedPhotoPages.setObject(exceptionalPage, forKey: exceptionalIndex)
        }
    }
}