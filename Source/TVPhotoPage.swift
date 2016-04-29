//
//  TVPhotoPage.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/15/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

protocol TVPhotoPageDelegate : class {
    func updateOverlayViewAlpha(alpha : CGFloat)
    func shouldDismissPhotoViewer(photoPage: TVPhotoPage, index : Int)
}

class TVPhotoPage : UIViewController {
    
    weak var delegate : TVPhotoPageDelegate?
    
    var photo : TVPhotoModel!
    var image : UIImage?
    var imageView : UIImageView!
    
    var centerFrame = CGRectZero
    var originFrame = CGRectZero

    var imageIndex = 0
    var isInitialPhoto = false
    
    var initialImage : UIImage? {
        didSet {
            photo.thumbnailImage = initialImage
        }
    }
    
    var maskView = UIView()
    var imageScrollView = UIScrollView()
    var pageScrollView : UIScrollView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(photo : TVPhotoModel) {
        self.image = photo.thumbnailImage
        self.imageIndex = photo.index
        self.photo = photo
        super.init(nibName: nil , bundle : nil)
    }
    
    override func loadView() {
        setupView()
        setupViewHierachy()
    }
    
    deinit {
        debugPrint("Deinit photo page")
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        updateCenterFrameForOrientation(toInterfaceOrientation)
        moveImageToCenter()
    }
}

//MARK: Setup
extension TVPhotoPage {
    
    func setupView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    }
    
    func setupViewHierachy() {
        setupImageScrollView()
        setupImageView()
        setupImageMaskView()
        setupGesture()
        loadThumbnailImage()
    }
    
    func setupImageView() {
        let frame = initialFrame(isInitialPhoto)
        imageView = UIImageView(frame: frame)
        imageView.contentMode = .ScaleAspectFill
        imageScrollView.addSubview(imageView)
    }
    
    func setupImageMaskView() {
        let frame = initialFrame(isInitialPhoto)
        let maskViewFrame = maskViewTargetFrame(frame)
        maskView.frame = maskViewFrame
        maskView.backgroundColor = UIColor.blackColor()
        imageView.maskView = maskView
    }
    
    func setupImageScrollView() {
        imageScrollView = UIScrollView(frame: view.bounds)
        imageScrollView.maximumZoomScale = 4
        imageScrollView.minimumZoomScale = 1
        imageScrollView.delegate = self
        imageScrollView.backgroundColor = UIColor.clearColor()
        imageScrollView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        view.addSubview(imageScrollView)
    }
    
    func loadThumbnailImage() {
        
        guard isInitialPhoto == false else {
            updateCenterFrameForOrientation(UIApplication.sharedApplication().statusBarOrientation)
            startLoadOriginalImage()
            return
        }
        
        if let thumbnailUrl = photo.thumbnailImageUrl {
            imageView.kf_setImageWithURL(thumbnailUrl, placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                if let validImage = image {
                    self.updateThumbnailImage(validImage)
                }
                self.startLoadOriginalImage()
            })
        }
    }
    
    func startLoadOriginalImage() {
        if let validOriginalUrl = photo.originalImageUrl {
            imageView.kf_setImageWithURL(validOriginalUrl)
        }
    }
    
    func updateThumbnailImage(thumbnailImage : Image) {
        photo.thumbnailImage = thumbnailImage
        self.imageView.image = thumbnailImage
        updateCenterFrameForOrientation(UIApplication.sharedApplication().statusBarOrientation)
        moveImageToCenter()
    }
    
    func updateCenterFrameForOrientation(orientation : UIInterfaceOrientation) {
        let photoSize = getSuitableSizeForPhoto(photo, orientation: orientation)
        let viewSize = sizeInOrientation(orientation)
        centerFrame = CGRect.rectForCenterOfBound(CGRectMake(0, 0, viewSize.width, viewSize.height), size: photoSize)
    }
}

//MARK: Animation
extension TVPhotoPage {
    func moveImageToCenter() {
        imageView.frame = centerFrame
        maskView.frame = CGRectMake(0, 0 , centerFrame.size.width, centerFrame.size.height)
    }
    
    func restoreOriginFrame(frame : CGRect?) {
        let frameToRestore = frame ?? originFrame
        imageView.frame = frameToRestore
        maskView.frame = maskViewTargetFrame(frameToRestore)
    }
    
    func animateImageToCenter() {
        UIView.animateWithDuration(0.5, animations: { _ in
            self.moveImageToCenter()
            self.delegate?.updateOverlayViewAlpha(1)
        })
    }
}

//MARK: Gesture
extension TVPhotoPage : UIGestureRecognizerDelegate {
    func setupGesture() {
        
        //Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        imageScrollView.addGestureRecognizer(panGesture)
        pageScrollView?.panGestureRecognizer.requireGestureRecognizerToFail(panGesture)
        
        //Double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        imageScrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    func handlePanGesture(panGesture : UIPanGestureRecognizer) {
        
        let touchPoint = panGesture.locationInView(imageScrollView)
        let translation = panGesture.translationInView(imageScrollView)
        
        let alpha = 1 - (abs(touchPoint.y - CGRectGetMidY(imageScrollView.frame)) / CGRectGetHeight(imageScrollView.frame))
        
        switch panGesture.state {
        case .Changed:
            imageView.center = CGPointMake(imageScrollView.center.x + translation.x, imageScrollView.center.y + translation.y)
            delegate?.updateOverlayViewAlpha(alpha)
        case .Ended:
            if alpha < 0.75 {
                delegate?.shouldDismissPhotoViewer(self, index: self.imageIndex)
            }
            else {
                animateImageToCenter()
            }
            
        default:
            break
        }
        
    }
    
    func handleDoubleTapGesture(doubleTapGesture : UITapGestureRecognizer) {
        if imageScrollView.zoomScale > imageScrollView.minimumZoomScale {
            imageScrollView.setZoomScale(imageScrollView.minimumZoomScale, animated: true)
        }
        else {
            var center = doubleTapGesture.locationInView(doubleTapGesture.view)
            let zoomRect = self.zoomRectForScale(imageScrollView.maximumZoomScale, center: &center)
            imageScrollView.zoomToRect(zoomRect, animated: true)
        }
    }
    
    func zoomRectForScale(scale : CGFloat , inout     center : CGPoint) -> CGRect {
        
        var zoomRect = CGRectZero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        
        center = imageView.convertPoint(center, fromView: view)
        
        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0
        
        return zoomRect
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let panGesture = gestureRecognizer as! UIPanGestureRecognizer
            return panGesture.translationInView(imageScrollView).x == 0 && imageScrollView.zoomScale == imageScrollView.minimumZoomScale
        }
        return true
    }
}

//MARK: ScrollView delegate
extension TVPhotoPage : UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
        let offsetY = max((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
        
        imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                       scrollView.contentSize.height * 0.5 + offsetY);
        
        pageScrollView?.scrollEnabled = (imageScrollView.zoomScale == imageScrollView.minimumZoomScale)
    }
}

//MARK: Helper
extension TVPhotoPage {
    func getSuitableSizeForPhoto(photo : TVPhotoModel, orientation : UIInterfaceOrientation) -> CGSize {
        let isLandscapeImage = photo.ratio > 1
        let ratio = photo.ratio
        var suitableSize = CGSizeZero
        let size = sizeInOrientation(orientation)
        
        suitableSize = size
        
        if isLandscapeImage {
            
            suitableSize.height = suitableSize.width / ratio
            
            if suitableSize.height > size.height {
                suitableSize.height = size.height
                suitableSize.width = suitableSize.height * ratio
            }
        }
        else {
            
            suitableSize.width = suitableSize.height * ratio
            
            if suitableSize.width > size.width {
                suitableSize.width = size.width
                suitableSize.height = suitableSize.width / ratio
            }
        }
        
        return suitableSize
    }
    
    func maskViewTargetFrame(targetFrame : CGRect) -> CGRect {
        var navBarOffset : CGFloat = 0
        if let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController where rootViewController.navigationBarHidden == false {
            navBarOffset = max(CGRectGetMaxY(rootViewController.navigationBar.frame) - targetFrame.origin.y, 0)
        }
        
        return CGRectMake(0, navBarOffset, targetFrame.size.width, targetFrame.size.height - navBarOffset)
    }
    
    func initialFrame(isInitialPhoto : Bool) -> CGRect {
        if isInitialPhoto {
            let window = UIApplication.sharedApplication().keyWindow
            return imageScrollView.convertRect(originFrame, fromView: window)
        }
        else {
            return CGRect.rectForCenterOfBound(view.bounds, size: CGSizeMake(100, 100))
        }
    }
}