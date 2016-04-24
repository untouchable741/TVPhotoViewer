//
//  TVPhotoViewerExtension.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/17/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

//MARK: UIView
public extension UIView {
    func takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContext(frame.size)
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let sourceImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return sourceImage
    }
    
    public func frameInWindow() -> CGRect {
        let window = UIApplication.sharedApplication().keyWindow
        return superview?.convertRect(frame, toView: window) ?? CGRectZero
    }
}

//MARK: UIImageView
public extension UIImageView {
    public func presentInPhotoViewer(initialIndex : Int ,
                                  delegate : TVPhotoViewerDelegate,
                                dataSource : TVPhotoViewerDataSource){
        TVPhotoViewerPresenter.sharedInstance.presentFromImageView(self, initialIndex: initialIndex ,delegate: delegate, dataSource: dataSource)
    }
}

//MARK: UIPageViewController
extension UIPageViewController {
    var pageScrollView : UIScrollView? {
        for subview in view.subviews {
            if subview is UIScrollView {
                return subview as? UIScrollView
            }
        }
        return nil
    }
}

//MARK: CGRect
extension CGRect {
    static func rectForCenterOfBound(bound : CGRect, size : CGSize) -> CGRect {
        return CGRectMake(CGRectGetMidX(bound) - size.width/2,
                          CGRectGetMidY(bound) - size.height/2,
                          size.width,
                          size.height)
    }
}