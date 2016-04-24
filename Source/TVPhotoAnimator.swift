//
//  TVPhotoAnimator.swift
//  TVPhotoViewer
//
//  Created by HuuTaiVuong on 4/15/16.
//  Copyright © 2016 Tai Vuong. All rights reserved.
//

import Foundation
import UIKit

class TVPhotoAnimator : NSObject {
    var isDismissed = false
    var transitionDuration = 0.2
}

extension TVPhotoAnimator : UIViewControllerTransitioningDelegate {
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isDismissed = true
        return self
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isDismissed = false
        return self
    }
}


extension TVPhotoAnimator : UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return transitionDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let container = transitionContext.containerView()
        let fromView = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!.view
        let toView = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!.view
        
        fromView.removeFromSuperview()
        container?.addSubview(toView)

        //Work-around fixing iOS 8 transition bug
        container?.superview?.addSubview(toView)
        
        transitionContext.completeTransition(true)
    }
}
