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
    func photoViewerShouldPresentBuiltInActionSheetForPhotoAtIndex(photoViewer :TVPhotoViewerController , index : Int) -> Bool
    func photoViewerShouldPresentCustomSheetForPhotoAtIndex(photoViewer : TVPhotoViewerController , index : Int)
    func photoViewerActionsForPhotoAtIndex(photoViewer : TVPhotoViewerController , index : Int) -> [String]?
    func photoViewerDidSelectActionForPhotoAtIndex(photoViewer : TVPhotoViewerController , action : String , index : Int)
}

public class TVPhotoViewerController : UIViewController {
    weak var delegate : TVPhotoViewerDelegate?
    weak var dataSource : TVPhotoViewerDataSource?
    
    let animationDuration = 0.4
    
    var overlayView : UIView!
    var pageScrollView : UIScrollView!
    var pagesContainer : UIPageViewController!
    var photoPagesArray : [TVPhotoPage]!
    var closeButton : UIButton!
    var actionButton : UIButton!
    
    var viewModel : TVPhotoViewerViewModel!
    var actions : [String]?
    
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
        setupButtons()
        setupPhotoPageViewController()
    }
    
    public override func viewDidAppear(animated: Bool) {
        initialAnimation()
    }
    
    deinit {
        debugPrint("Deinit TVPhotoViewController")
    }
    
    public override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        //Workaround for fixing a weird bug when wrong view size returned after rotate
        //We removed all cached page except current page to force re-calculate all pages
        viewModel.cleanAllOtherCachedPage(currentIndex)
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
        
        view.insertSubview(pagesContainer.view, aboveSubview: overlayView)
        addChildViewController(pagesContainer)
        
        loadInitPhotoPage()
    }
    
    func loadInitPhotoPage() {
        if let firstPhotoPage = photoPageAtIndex(currentIndex) {
            firstPhotoPage.isInitialPhoto = true
            firstPhotoPage.initialImage = initialImage
            updateCurrentImageIndex(currentIndex)
            pagesContainer.setViewControllers([firstPhotoPage], direction: .Forward, animated: false, completion: nil)
        }
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
            self.hidingButtons()
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
            updateCurrentImageIndex(photoPage.imageIndex)
            currentImageView?.hidden = true
        }
    }
    
    func updateCurrentImageIndex(newIndex : Int) {
        currentIndex = newIndex
        delegate?.photoViewerDidPresentPhotoAtIndex(self, presentingPhotoIndex: newIndex)
        currentImageView = delegate?.photoViewerImageViewForPhotoIndex(self, index: newIndex)
        actions = delegate?.photoViewerActionsForPhotoAtIndex(self, index: newIndex)
        actionButton?.hidden = (actions == nil)
    }
}

//MARK: Action
extension TVPhotoViewerController {
    func setupButtons() {
        setupActionButton()
        setupCloseButton()
        
    }
    
    func hidingButtons() {
        closeButton.alpha = 0
        actionButton.alpha = 0
    }
    
    func setupCloseButton() {
        closeButton = UIButton(type: .Custom)
        closeButton.frame = CGRectMake(0, 0, 50, 50)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(named: "ic_close"), forState: UIControlState.Normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), forControlEvents: .TouchUpInside)
        
        //Set up autolayout
        let topConstraint = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: closeButton, attribute: .TopMargin, multiplier: 1, constant: -5)
        let leadingConstraint = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: closeButton, attribute: .LeadingMargin, multiplier: 1, constant: -5)
        let widthConstraint = NSLayoutConstraint(item: closeButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        let heightConstraint = NSLayoutConstraint(item: closeButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        
        view.addSubview(closeButton)
        
        view.addConstraint(topConstraint)
        view.addConstraint(leadingConstraint)
        view.addConstraint(widthConstraint)
        view.addConstraint(heightConstraint)
    }
    
    func setupActionButton() {
        actionButton = UIButton(type: .Custom)
        actionButton.frame = CGRectMake(0, 0, 50, 50)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.setImage(UIImage(named: "ic_share"), forState: UIControlState.Normal)
        actionButton.addTarget(self, action: #selector(actionButtonTapped), forControlEvents: .TouchUpInside)
        
        //Set up autolayout
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: actionButton, attribute: .Bottom, multiplier: 1, constant: 5)
        let leadingConstraint = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: actionButton, attribute: .Leading, multiplier: 1, constant: -5)
        let widthConstraint = NSLayoutConstraint(item: actionButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        let heightConstraint = NSLayoutConstraint(item: actionButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        
        view.addSubview(actionButton)
        
        view.addConstraint(bottomConstraint)
        view.addConstraint(leadingConstraint)
        view.addConstraint(widthConstraint)
        view.addConstraint(heightConstraint)
    }
    
    func closeButtonTapped() {
        dismissAnimated(true)
    }
    
    func actionButtonTapped() {
        let shouldPresentNativeSheet = delegate?.photoViewerShouldPresentBuiltInActionSheetForPhotoAtIndex(self, index: currentIndex)
        if shouldPresentNativeSheet == true {
            let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            actions?.forEach { actionTitle in
                let action = UIAlertAction(title: actionTitle, style: UIAlertActionStyle.Default, handler: {
                    _ in
                    self.delegate?.photoViewerDidSelectActionForPhotoAtIndex(self, action: actionTitle, index: self.currentIndex)
                })
                actionSheetController.addAction(action)
            }
            
            actionSheetController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {     _ in
                actionSheetController.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            presentViewController(actionSheetController, animated: true, completion: nil)
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