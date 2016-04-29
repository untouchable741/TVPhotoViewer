//
//  ViewController.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/15/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var collectionView : UICollectionView!
    let imageArray = ["https://farm6.staticflickr.com/5603/15317528089_b124ffd236_b.jpg",
                      "https://farm8.staticflickr.com/7390/13242901814_c24c8dc80a_b.jpg",
                      "https://farm4.staticflickr.com/3865/14537440701_f98354e9f5_b.jpg",
                      "https://farm3.staticflickr.com/2605/5701155952_090b93e693_b.jpg",
                      "https://farm4.staticflickr.com/3949/15312427830_1f090658d0_b.jpg",
                      "https://farm6.staticflickr.com/5235/5886244206_5b882247bf_b.jpg"]
    let imagesCount = 24
    var cellSize = CGSizeZero
    var column : CGFloat {
        let isIphone = UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone
        return isIphone ? 2.0 : 3.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let itemWidth = UIScreen.mainScreen().bounds.size.width / column
        cellSize = CGSizeMake(itemWidth, itemWidth * 9.0 / 16.0)
    }
}

extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath)
        let cellImageView = cell.viewWithTag(101) as! UIImageView
        if let url = NSURL(string: imageArray[indexPath.item % 6]) {
            cellImageView.kf_setImageWithURL(url)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return cellSize
    }
 
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)!
        let cellImageView = cell.viewWithTag(101) as! UIImageView
        cellImageView.presentInPhotoViewer(indexPath.item, delegate: self, dataSource: self)
    }
}

extension ViewController : TVPhotoViewerDataSource {
    func photoViewerNumberOfPhoto(photoViewer: TVPhotoViewerController) -> Int {
        return imagesCount
    }
    
    func photoViewerPhotoUrlAtIndex(photoViewer: TVPhotoViewerController, index: Int) -> NSURL? {
        return NSURL(string: imageArray[index % 6])
    }
    
    func photoViewerThumbnailUrlAtIndex(photoViewer: TVPhotoViewerController, index: Int) -> NSURL? {
        return NSURL(string: imageArray[index % 6])
    }
}

extension ViewController : TVPhotoViewerDelegate {
    
    func photoViewerDidPresentPhotoAtIndex(photoViewer: TVPhotoViewerController, presentingPhotoIndex: Int) {
         collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: presentingPhotoIndex, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
    }
    
    func photoViewerShouldPresentBuiltInActionSheetForPhotoAtIndex(photoViewer: TVPhotoViewerController, index: Int) -> Bool {
        return true
    }
    
    func photoViewerImageViewForPhotoIndex(photoViewer: TVPhotoViewerController, index: Int) -> UIImageView? {
        let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))
        return cell?.viewWithTag(101) as? UIImageView
    }
    
    func photoViewerActionsForPhotoAtIndex(photoViewer: TVPhotoViewerController, index: Int) -> [String]? {
        return index % 2 == 0 ? ["Share" , "Save", "Email"] : nil
    }
    
    func photoViewerShouldPresentCustomSheetForPhotoAtIndex(photoViewer: TVPhotoViewerController, index: Int) {
        
    }
    
    func photoViewerDidSelectActionForPhotoAtIndex(photoViewer: TVPhotoViewerController, action: String, index: Int) {
        debugPrint("selected action \(action)")
    }
}

