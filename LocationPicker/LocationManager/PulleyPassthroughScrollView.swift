//
//  LocationSharePassthroughScrollView.swift
//
//  Created by HB on 30/03/18.
//  Copyright © 2018 Hidden Brains. All rights reserved.
//

import UIKit

protocol LocationSharePassthroughScrollViewDelegate: class {
    
    func shouldTouchPassthroughScrollView(scrollView: LocationSharePassthroughScrollView, point: CGPoint) -> Bool
    func viewToReceiveTouch(scrollView: LocationSharePassthroughScrollView) -> UIView
}

class LocationSharePassthroughScrollView: UIScrollView {
    
    weak var touchDelegate: LocationSharePassthroughScrollViewDelegate?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let touchDel = touchDelegate
        {
            if touchDel.shouldTouchPassthroughScrollView(scrollView: self, point: point)
            {
                return touchDel.viewToReceiveTouch(scrollView: self).hitTest(touchDel.viewToReceiveTouch(scrollView: self).convert(point, from: self), with: event)
            }
        }
        
        return super.hitTest(point, with: event)
    }
}
