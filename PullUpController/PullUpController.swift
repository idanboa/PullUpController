//
//  PullUpController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

open class PullUpController: UIViewController {
    
    private var leftConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    private var overlayView: UIView?
    /**
     Indicates whether an overlay view should be added to the parent when the drawer is fully open.
     */
    open var shouldAddOverlayWhenOpen: Bool {
        return true
    }
    
    /**
     the height of the view containing the PullUpController
    */
    private var parentHeight: CGFloat {
        return parent?.view.frame.height ?? 0
    }
    
    /**
     executes whenever the drawer changed vertical position.
     */
    public var topOffsetChanged: ((CGFloat?) -> Void)?
    
    /**
     executes whenever an animation block has completed.
     */
    public var didFinishAnimatingToPoint: ((CGFloat?) -> Void)?
    
    private let defaultAnimationDuration: TimeInterval = 0.3
    /// if nil animations will use 'defaultAnimationDuration' 0.3
    open var animationDuration: TimeInterval? {
        return nil
    }
    
    private let defaultAnimationDelay: TimeInterval = 0.0
    /// if nil animations will use 'defaultAnimationDelay' 0.0
    open var animationDelay: TimeInterval? {
        return nil
    }
    
    private let defaultSpringDamping: CGFloat = 0.8
    /// if nil animations will use 'defaultSpringDamping' 0.8
    open var springDamping: CGFloat? {
        return nil
    }
    
    private let defaultSpringVelocity: CGFloat = 0.0
    /// if nil animations will use 'defaultSpringVelocity' 0.0
    open var springVelocity: CGFloat? {
        return nil
    }
    
    private let defaultAnimationOptions: UIViewAnimationOptions = []
    /// if nil animations will use 'defaultAnimationOptions' []
    open var animationOptions: UIViewAnimationOptions? {
        return nil
    }
    
    /**
     The closure to execute before the view controller's view move to a sticky point.
     The target sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    open var willMoveToStickyPoint: ((_ point: CGFloat) -> Void)?
    
    /**
     The closure to execute after the view controller's view move to a sticky point.
     The sticky point, expressed in the pull up controller coordinate system, is provided in the closure parameter.
     */
    open var didMoveToStickyPoint: ((_ point: CGFloat) -> Void)?
    
    /**
     The desired height in screen units expressed in the pull up controller coordinate system that will be initially showed.
     The default value is 50.
     */
    open var pullUpControllerPreviewOffset: CGFloat {
        return 50
    }
    
    /**
     The desired size of the pull up controller’s view, in screen units.
     The default value is width: UIScreen.main.bounds.width, height: 400.
     */
    open var pullUpControllerPreferredSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 400)
    }
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gestures the pull up controller will scroll to the nearest point in the list.
     
     Please keep in mind that this array should contains only sticky points in the middle of the pull up controller's view;
     There is therefore no need to add the fist one (pullUpControllerPreviewOffset), and/or the last one (pullUpControllerPreferredSize.height).
     
     For a complete list of all the sticky points you can use `pullUpControllerAllStickyPoints`.
     */
    open var pullUpControllerMiddleStickyPoints: [CGFloat] {
        return []
    }
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gesture the pull up controller will scroll at the nearest point in the list.
     */
    public final var pullUpControllerAllStickyPoints: [CGFloat] {
        var sc_allStickyPoints = [pullUpControllerPreviewOffset, pullUpControllerPreferredSize.height]
        sc_allStickyPoints.append(contentsOf: pullUpControllerMiddleStickyPoints)
        return sc_allStickyPoints.sorted()
    }
    
    /**
     A Boolean value that determines whether bouncing occurs when scrolling reaches the end of the pull up controller's view size.
     The default value is false.
     */
    open var pullUpControllerIsBouncingEnabled: Bool {
        return false
    }
    
    /**
     A Boolean value that determines whether the user can pan the controller above the preview offset (defaults to true).
     */
    open var pullingAbovePreviewOffsetEnabled: Bool {
        return true
    }
    
    /**
     The desired size of the pull up controller’s view, in screen units when the device is in landscape mode.
     The default value is (x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20).
     */
    open var pullUpControllerPreferredLandscapeFrame: CGRect {
        return CGRect(x: 10, y: 10, width: 300, height: UIScreen.main.bounds.height - 20)
    }
    
    private var isPortrait: Bool {
        return UIScreen.main.bounds.height > UIScreen.main.bounds.width
    }
    
    private var portraitPreviousStickyPointIndex: Int?
    
    private var currentStickyPointIndex: Int {
        let stickyPointTreshold = (parentHeight) - (topConstraint?.constant ?? 0)
        let stickyPointsLessCurrentPosition = pullUpControllerAllStickyPoints.map { abs($0 - stickyPointTreshold) }
        guard let minStickyPointDifference = stickyPointsLessCurrentPosition.min() else { return 0 }
        return stickyPointsLessCurrentPosition.index(of: minStickyPointDifference) ?? 0
    }
    
    /**
     Current top offset
     */
    private var currentTopOffset: CGFloat? {
        return parentHeight - (topConstraint?.constant ?? 0)
    }
    
    private var fullyOpen: Bool {
        guard currentTopOffset != 0 else { return false }
        return pullUpControllerAllStickyPoints[currentStickyPointIndex] == pullUpControllerAllStickyPoints.last ?? 0
    }
    
    private var fullyHidden: Bool {
        return currentTopOffset == 0
    }
    
    /**
     This method will move the pull up controller's view in order to show the provided visible point.
     
     You may use on of `pullUpControllerAllStickyPoints` item to provide a valid visible point.
     - parameter visiblePoint: the y value to make visible, in screen units expressed in the pull up controller coordinate system.
     - parameter completion: The closure to execute after the animation is completed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    open func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, completion: ((Bool) -> Void)?) {
        guard isPortrait else { return }
        topConstraint?.constant = parentHeight - visiblePoint
        
        pullUpControllerOffsetIsChanging()
        
        animate(animations: { [weak self] in
            self?.parent?.view?.layoutIfNeeded()
            }, completion: completion)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isPortrait = size.height > size.width
        var targetStickyPoint: CGFloat?
        
        if !isPortrait {
            portraitPreviousStickyPointIndex = currentStickyPointIndex
        } else if
            let portraitPreviousStickyPointIndex = portraitPreviousStickyPointIndex,
            portraitPreviousStickyPointIndex < pullUpControllerAllStickyPoints.count
        {
            targetStickyPoint = pullUpControllerAllStickyPoints[portraitPreviousStickyPointIndex]
            self.portraitPreviousStickyPointIndex = nil
        }
        
        coordinator.animate(alongsideTransition: { [weak self] coordinator in
            self?.refreshConstraints(size: size)
            if let targetStickyPoint = targetStickyPoint {
                self?.pullUpControllerMoveToVisiblePoint(targetStickyPoint, completion: nil)
            }
        })
    }
    
    open func bounce() {
        guard !fullyOpen && !fullyHidden else {
            // does not bounce if hidden or fully open.
            return
        }
        
        let midY = view.center.y
        let movement = CGFloat(5)
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position.y"
        animation.values = [midY - movement, midY + movement, midY]
        animation.keyTimes = [0, 0.5, 1]
        animation.duration = 0.3
        animation.repeatCount = 2
        
        view.layer.add(animation, forKey: "bounce")
    }
    
    open func hideIfNeeded(_ completion: ((Bool) -> Void)? = nil) {
        guard topConstraint?.constant != parentHeight else {
            completion?(true)
            return
        }
        
        pullUpControllerMoveToVisiblePoint(0, completion: completion)
    }
    
    open func reveal(customHeight: CGFloat? = nil, completion: ((Bool) -> Void)? = nil) {
        pullUpControllerMoveToVisiblePoint(self.pullUpControllerPreviewOffset, completion: completion)
    }
}

// MARK: - private
private extension PullUpController {
    
    func animate(animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: animationDuration ?? defaultAnimationDuration,
                       delay: animationDelay ?? defaultAnimationDelay,
                       usingSpringWithDamping: springDamping ?? defaultSpringDamping,
                       initialSpringVelocity: springVelocity ?? defaultSpringVelocity,
                       options: animationOptions ?? defaultAnimationOptions,
                       animations: animations,
                       completion: { [weak self] finished in
                        if finished {
                            self?.didFinishAnimatingToPoint?(self?.currentTopOffset)
                        }
                        
                        completion?(finished)
        })
    }
    
    func nearestStickyPointY(yVelocity: CGFloat) -> CGFloat {
        var currentStickyPointIndex = self.currentStickyPointIndex
        if abs(yVelocity) > 700 { // 1000 points/sec = "fast" scroll
            if yVelocity > 0 {
                currentStickyPointIndex = max(currentStickyPointIndex - 1, 0)
            } else {
                currentStickyPointIndex = min(currentStickyPointIndex + 1, pullUpControllerAllStickyPoints.count - 1)
            }
        }
        
        willMoveToStickyPoint?(pullUpControllerAllStickyPoints[currentStickyPointIndex])
        return parentHeight - pullUpControllerAllStickyPoints[currentStickyPointIndex]
    }
    
    @objc func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            pullingAbovePreviewOffsetEnabled,
            isPortrait,
            let topConstraint = topConstraint,
            let parentViewHeight = parent?.view.frame.height
            else { return }
        
        let yTranslation = gestureRecognizer.translation(in: view).y
        gestureRecognizer.setTranslation(.zero, in: view)
        
        topConstraint.constant += yTranslation
        
        if !pullUpControllerIsBouncingEnabled {
            topConstraint.constant = max(topConstraint.constant, parentViewHeight - pullUpControllerPreferredSize.height)
            topConstraint.constant = min(topConstraint.constant, parentViewHeight - pullUpControllerPreviewOffset)
        }
        
        if gestureRecognizer.state == .ended {
            topConstraint.constant = nearestStickyPointY(yVelocity: gestureRecognizer.velocity(in: view).y)
            animateLayout()
        }
        
        pullUpControllerOffsetIsChanging()
    }
    
    func animateLayout() {
        self.animate(animations: { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.fullyOpen ? weakSelf.addOverlayIfNeeded() : weakSelf.removeOverlayIfNeeded()
            
            weakSelf.parent?.view.layoutIfNeeded()
//            let point = (self?.parent?.view.frame.height ?? 0.0) - (self?.topConstraint?.constant ?? 0.0)
        }, completion: nil)
    }
    
    func setPortraitConstraints(parentViewSize: CGSize, hidden: Bool) {
        topConstraint?.constant = hidden ? parentViewSize.height : parentViewSize.height - pullUpControllerPreviewOffset
        leftConstraint?.constant = (parentViewSize.width - min(pullUpControllerPreferredSize.width, parentViewSize.width))/2
        widthConstraint?.constant = pullUpControllerPreferredSize.width
        heightConstraint?.constant = pullUpControllerPreferredSize.height
    }
    
    func setLandscapeConstraints() {
        topConstraint?.constant = pullUpControllerPreferredLandscapeFrame.origin.y
        leftConstraint?.constant = pullUpControllerPreferredLandscapeFrame.origin.x
        widthConstraint?.constant = pullUpControllerPreferredLandscapeFrame.width
        heightConstraint?.constant = pullUpControllerPreferredLandscapeFrame.height
    }
    
    func pullUpControllerOffsetIsChanging() {
        topOffsetChanged?(self.currentTopOffset)
    }
}

// MARK: - fileprivate
fileprivate extension PullUpController {
    func setupPanGestureRecognizer() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        if let panGestureRecognizer = panGestureRecognizer {
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    func setupConstrains() {
        guard let parentView = parent?.view else { return }
        
        topConstraint = view.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 0)
        leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 0)
        widthConstraint = view.widthAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.width)
        heightConstraint = view.heightAnchor.constraint(equalToConstant: pullUpControllerPreferredSize.height)
        
        NSLayoutConstraint.activate([topConstraint,
                                     leftConstraint,
                                     widthConstraint,
                                     heightConstraint].compactMap { $0 })
    }
    
    @objc func handleInternalScrollViewPanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            isPortrait,
            let scrollView = gestureRecognizer.view as? UIScrollView,
            let lastStickyPoint = pullUpControllerAllStickyPoints.last,
            let parentViewHeight = parent?.view.frame.height,
            let topConstraintValue = topConstraint?.constant
            else { return }
        
        let isScrollingDown = gestureRecognizer.translation(in: view).y > 0
        let shouldScrollingDownTriggerGestureRecognizer = isScrollingDown && scrollView.contentOffset.y <= 0
        let shouldScrollingUpTriggerGestureRecognizer = !isScrollingDown && topConstraintValue != parentViewHeight - lastStickyPoint
        
        if shouldScrollingDownTriggerGestureRecognizer || shouldScrollingUpTriggerGestureRecognizer {
            handlePanGestureRecognizer(gestureRecognizer)
        }
        
        if gestureRecognizer.state.rawValue == 3 { // for some reason gestureRecognizer.state == .ended doesn't work
            topConstraint?.constant = nearestStickyPointY(yVelocity: 0)
            animateLayout()
        }
        
        pullUpControllerOffsetIsChanging()
    }
    
    func refreshConstraints(size: CGSize, hidden: Bool = false) {
        if size.width > size.height {
            setLandscapeConstraints()
        } else {
            setPortraitConstraints(parentViewSize: size, hidden: hidden)
        }
        
        pullUpControllerOffsetIsChanging()
    }
    
    func addOverlayIfNeeded() {
        guard
            shouldAddOverlayWhenOpen,
            overlayView == nil,
            let parent = parent else { return }
        
        let overlay = UIView.init(frame: parent.view.frame)
        overlay.backgroundColor = UIColor.black
        parent.view.insertSubview(overlay, belowSubview: self.view)
        overlay.alpha = 0
        
        self.overlayView = overlay
        UIView.animate(withDuration: defaultAnimationDuration,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: { overlay.alpha = 0.67 },
                       completion: nil)
    }
    
    func removeOverlayIfNeeded() {
        guard overlayView != nil else { return }
        
        UIView.animate(withDuration: defaultAnimationDuration,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { [weak self] in self?.overlayView?.alpha = 0 },
                       completion: { [weak self] finished in
                        if finished {
                            self?.overlayView?.removeFromSuperview()
                            self?.overlayView = nil
                        }
        })
    }
}

extension UIViewController {
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to add as a child of the current view controller.
     */
    open func addPullUpController(_ pullUpController: PullUpController, intiallyHidden: Bool = false) {
        addChildViewController(pullUpController)
        
        pullUpController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pullUpController.view)
        
        pullUpController.setupPanGestureRecognizer()
        pullUpController.setupConstrains()
        pullUpController.refreshConstraints(size: view.frame.size, hidden: intiallyHidden)
    }
    
}

extension UIScrollView {
    
    /**
     Attach the scroll view to the provided pull up controller in order to move it with the scroll view content.
     - parameter pullUpController: the pull up controller to move with the current scroll view content.
     */
    open func attach(to pullUpController: PullUpController) {
        panGestureRecognizer.addTarget(pullUpController, action: #selector(pullUpController.handleInternalScrollViewPanGestureRecognizer(_:)))
    }
}
