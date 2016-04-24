//
//  TVPhotoViewerPresenter.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/15/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

public class TVPhotoViewerPresenter {
    
    public static let sharedInstance = TVPhotoViewerPresenter()
    
    var animator = TVPhotoAnimator()
    
    public func presentFromImageView(originalImageView : UIImageView,
                                     initialIndex : Int = 0,
                                     delegate : TVPhotoViewerDelegate?,
                                     dataSource : TVPhotoViewerDataSource?) {
        
        let appDelegate = UIApplication.sharedApplication().delegate
        if let rootViewController = appDelegate?.window??.rootViewController {
            
            let imageViewerController = TVPhotoViewerController()
            let viewModel = TVPhotoViewerViewModel()
            imageViewerController.currentIndex = initialIndex
            imageViewerController.viewModel = viewModel
            imageViewerController.modalPresentationStyle = .OverCurrentContext
            imageViewerController.transitioningDelegate = animator
            imageViewerController.currentImageView = originalImageView
            imageViewerController.delegate = delegate
            imageViewerController.dataSource = dataSource
            
            rootViewController.presentViewController(imageViewerController, animated: true, completion: nil)
        }
    }
}