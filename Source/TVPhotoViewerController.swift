//
//  TVPhotoViewerController.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/15/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

public protocol TVPhotoViewerDataSource : class {
    func photoViewerNumberOfPhoto(photoViewer : TVPhotoViewerController) -> Int
    func photoViewerThumbnailUrlAtIndex(photoViewer : TVPhotoViewerController , index : Int) -> NSURL?
    func photoViewerPhotoUrlAtIndex(photoViewer : TVPhotoViewerController , index : Int) -> NSURL?
}

public protocol TVPhotoViewerDelegate : class {
    func photoViewerDidPresentPhotoAtIndex(photoViewer : TVPhotoViewerController , presentingPhotoIndex : Int)
    func photoViewerImageViewForPhotoIndex(photoViewer : TVPhotoViewerController , index : Int) -> UIImageView?
}

public class TVPhotoViewerController : UIViewController {
    weak var delegate : TVPhotoViewerDelegate?
    weak var dataSource : TVPhotoViewerDataSource?
    
    let animationDuration = 0.4
    
    var overlayView : UIView!
    var pageScrollView : UIScrollView!
    var pagesContainer : UIPageViewController!
    var photoPagesArray : [TVPhotoPage]!
    var viewModel : TVPhotoViewerViewModel!
    
    var currentIndex = 0
    var totalImageCount = 0
    
    var originFrame : CGRect?
    var initialImage : UIImage?
    var currentImageView : UIImageView? {
        
        willSet {
            if currentImageView != nil {
                currentImageView?.hidden = false
            }
        }
        
        didSet {
            initialImage = currentImageView?.image
            originFrame = currentImageView?.frameInWindow()
        }
    }
    
    public override func loadView() {
        setupView()
        setupOverlayView()
        setupTestGesture()
        setupPhotoPageViewController()
    }
    
    public override func viewDidAppear(animated: Bool) {
        initialAnimation()
    }
    
    deinit {
        debugPrint("Deinit TVPhotoViewController")
    }
}

//MARK: Setup
extension TVPhotoViewerController {
    func setupView() {
        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.clearColor()
        view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    }

    func setupOverlayView() {
        overlayView = UIView(frame: UIScreen.mainScreen().bounds)
        overlayView.backgroundColor = UIColor.blackColor()
        overlayView.alpha = 0
        overlayView.autoresizingMask = [.FlexibleWidth , .FlexibleHeight]
        view.addSubview(overlayView)
    }
    
    func setupPhotoPageViewController() {
        
        totalImageCount = (dataSource?.photoViewerNumberOfPhoto(self))!
        
        pagesContainer = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pagesContainer.view.frame = view.bounds
        pagesContainer.dataSource = self
        pagesContainer.delegate = self
        pageScrollView = pagesContainer.pageScrollView
        
        view.addSubview(pagesContainer.view)
        addChildViewController(pagesContainer)
        
        loadInitPhotoPage()
    }
    
    func loadInitPhotoPage() {
        if let firstPhotoPage = photoPageAtIndex(currentIndex) {
            firstPhotoPage.isInitialPhoto = true
            firstPhotoPage.initialImage = initialImage
            pagesContainer.setViewControllers([firstPhotoPage], direction: .Forward, animated: false, completion: nil)
        }
    }
}

//MARK: Gesture
extension TVPhotoViewerController {
    
    func setupTestGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
    }
    
    func doubleTap(gesture : UITapGestureRecognizer) {
        dismissAnimated(true)
    }
}

//MARK: Animation
extension TVPhotoViewerController {
    func initialAnimation() {
        guard let currentPhotoPage = pagesContainer.viewControllers?.first as? TVPhotoPage else {
            return
        }
        
        UIView.animateWithDuration(animationDuration, animations: { [unowned self] _ in
            self.overlayView.alpha = 1
            self.currentImageView?.alpha = 0
            currentPhotoPage.moveImageToCenter()
            }, completion: { _ in
                self.currentImageView?.alpha = 1
                self.currentImageView?.hidden = true
        })
    }
    
    func dismissAnimated(animated : Bool) {

        let currentPhotoPage = pagesContainer.viewControllers?.first as! TVPhotoPage
        let dismissRect = currentImageView?.frameInWindow()
        
        UIView.animateWithDuration(animated ? animationDuration : 0, animations: { [unowned self] _ in
            self.overlayView.alpha = 0
            currentPhotoPage.restoreOriginFrame(dismissRect)
            }, completion: { _ in
                self.dismissViewControllerAnimated(true, completion: { _ in
                    self.currentImageView?.hidden = false
                })
        })
    }
}


//MARK: PageViewController
extension TVPhotoViewerController : UIPageViewControllerDataSource , UIPageViewControllerDelegate {
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        guard totalImageCount > 1 else {
            return nil
        }
        
        guard currentIndex + 1 < totalImageCount else {
            return nil
        }
        
        return photoPageAtIndex(currentIndex + 1)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        guard totalImageCount > 1 else {
            return nil
        }
        
        guard currentIndex > 0 else {
            return nil
        }
        
        return photoPageAtIndex(currentIndex - 1)
    }
    
    func photoPageAtIndex(index : Int) -> TVPhotoPage? {
        let thumbnailUrl = dataSource?.photoViewerThumbnailUrlAtIndex(self, index: index)
        let originalUrl = dataSource?.photoViewerPhotoUrlAtIndex(self, index: index)
        
        guard let photo = viewModel.photoPageAtIndex(index , thumbnailUrl: thumbnailUrl, originalImageUrl: originalUrl) else {
            return nil
        }
        
        photo.originFrame = originFrame ?? CGRectZero
        photo.pageScrollView = pageScrollView
        photo.delegate = self
        
        return photo
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard let viewControllers = pageViewController.viewControllers else {
            return
        }
        
        if let photoPage = viewControllers.first as? TVPhotoPage {
            currentIndex = photoPage.imageIndex
            delegate?.photoViewerDidPresentPhotoAtIndex(self, presentingPhotoIndex: photoPage.photo.index)
            currentImageView = delegate?.photoViewerImageViewForPhotoIndex(self, index: photoPage.imageIndex)
            currentImageView?.hidden = true
        }
    }
}

//MARK: PhotoPage delegate
extension TVPhotoViewerController : TVPhotoPageDelegate {
    func shouldDismissPhotoViewer(photoPage: TVPhotoPage, index: Int) {
        dismissAnimated(true)
    }
    
    func updateOverlayViewAlpha(alpha: CGFloat) {
        overlayView.alpha = alpha
    }
}