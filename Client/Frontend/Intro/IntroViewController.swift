/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct IntroViewControllerUX {
    static let Width = 375
    static let Height = 667

    static let NumberOfCards = 3

    static let PagerCenterOffsetFromScrollViewBottom = 15

    static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "Do not translate yet")
    static let StartBrowsingButtonColor = UIColor(rgb: 0x363B40)
    static let StartBrowsingButtonHeight = 56
    static let StartBrowsingButtonFont = UIFont.systemFontOfSize(18)

    static let SignInButtonTitle = NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "Do not translate yet")
    static let SignInButtonColor = UIColor(red: 0.259, green: 0.49, blue: 0.831, alpha: 1.0)
    static let SignInButtonHeight = 46
    static let SignInButtonFont = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
    static let SignInButtonCornerRadius = CGFloat(4)

    static let CardTextFont = UIFont.systemFontOfSize(16)
    static let CardTitleFont = UIFont.systemFontOfSize(18, weight: UIFontWeightBold)
    static let CardTextLineHeight = CGFloat(6)

    static let Card1Title = NSLocalizedString("Organize", tableName: "Intro", comment: "Do not translate yet.")
    static let Card2Title = NSLocalizedString("Customize", tableName: "Intro", comment: "Do not translate yet.")

    static let Card1Text = NSLocalizedString("Browse multiple Web pages at the same time with tabs.", tableName: "Intro", comment: "Do not translate yet.")
    static let Card2Text = NSLocalizedString("Personalize your Firefox just the way you like in Settings.", tableName: "Intro", comment: "Do not translate yet.")
    static let Card3Text = NSLocalizedString("Connect Firefox everywhere you use it.", tableName: "Intro", comment: "Do not translate yet.")

    static let Card3TextOffsetFromCenter = 10
    static let Card3ButtonOffsetFromCenter = 10

    static let FadeDuration = 0.25

    static let BackForwardButtonEdgeInset = 20

    static let Card1Color = UIColor(rgb: 0xFFC81E)
    static let Card2Color = UIColor(rgb: 0x41B450)
    static let Card3Color = UIColor(rgb: 0x0096DD)
}

let IntroViewControllerSeenProfileKey = "IntroViewControllerSeen"

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish(introViewController: IntroViewController)
    func introViewControllerDidRequestToLogin(introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate {
    weak var delegate: IntroViewControllerDelegate?

    var slides = [UIImage]()
    var cards = [UIImageView]()
    var introViews = [UIView]()

    var startBrowsingButton: UIButton!
    var introView: UIView?
    var slideContainer: UIView!
    var pageControl: UIPageControl!
    var backButton: UIButton!
    var forwardButton: UIButton!
    var signInButton: UIButton!

    private var scrollView: IntroOverlayScrollView!

    var slideVerticalScaleFactor: CGFloat = 1.0

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        // scale the slides down for iPhone 4S
        if view.frame.height <=  480 {
            slideVerticalScaleFactor = 1.33
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            slides.append(UIImage(named: "slide\(i+1)")!)
        }

        startBrowsingButton = UIButton()
        startBrowsingButton.backgroundColor = IntroViewControllerUX.StartBrowsingButtonColor
        startBrowsingButton.setTitle(IntroViewControllerUX.StartBrowsingButtonTitle, forState: UIControlState.Normal)
        startBrowsingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startBrowsingButton.titleLabel?.font = IntroViewControllerUX.StartBrowsingButtonFont
        startBrowsingButton.addTarget(self, action: "SELstartBrowsing", forControlEvents: UIControlEvents.TouchUpInside)

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp_makeConstraints { (make) -> Void in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(IntroViewControllerUX.StartBrowsingButtonHeight)
        }

        scrollView = IntroOverlayScrollView()
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        view.addSubview(scrollView)

        slideContainer = UIView()
        slideContainer.backgroundColor = IntroViewControllerUX.Card1Color
        for i in 0..<IntroViewControllerUX.NumberOfCards {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = slides[i]
            slideContainer.addSubview(imageView)
        }

        scrollView.addSubview(slideContainer)
        scrollView.snp_makeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(startBrowsingButton.snp_top)
        }

        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.numberOfPages = IntroViewControllerUX.NumberOfCards

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.startBrowsingButton.snp_top).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
        }

        // Card1

        let introView1 = UIView()
        introViews.append(introView1)
        addLabelsToIntroView(introView1, text: IntroViewControllerUX.Card1Text, title: IntroViewControllerUX.Card1Title)
        addForwardButtonToIntroView(introView1)

        // Card 2

        let introView2 = UIView()
        introViews.append(introView2)
        addLabelsToIntroView(introView2, text: IntroViewControllerUX.Card2Text, title: IntroViewControllerUX.Card2Title)

        // Card 3

        let introView3 = UIView()
        let label3 = UILabel()
        label3.numberOfLines = 0
        label3.attributedText = attributedStringForLabel(IntroViewControllerUX.Card3Text)
        label3.font = IntroViewControllerUX.CardTextFont
        introView3.addSubview(label3)
        label3.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.bottom.equalTo(introView3.snp_centerY).offset(-IntroViewControllerUX.Card3TextOffsetFromCenter)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Talk to UX about small screen sizes
        }

        signInButton = UIButton()
        signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
        signInButton.setTitle(IntroViewControllerUX.SignInButtonTitle, forState: .Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.titleLabel?.font = IntroViewControllerUX.SignInButtonFont
        signInButton.layer.cornerRadius = IntroViewControllerUX.SignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: "SELlogin", forControlEvents: UIControlEvents.TouchUpInside)
        introView3.addSubview(signInButton)

        signInButton.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.top.equalTo(introView3.snp_centerY).offset(IntroViewControllerUX.Card3ButtonOffsetFromCenter)
            make.height.equalTo(IntroViewControllerUX.SignInButtonHeight)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Talk to UX about small screen sizes
        }

        introViews.append(introView3)

        // Add all the cards to the view, make them invisible with zero alpha

        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.slideContainer.snp_bottom)
                make.bottom.equalTo(self.startBrowsingButton.snp_top)
                make.left.right.equalTo(self.view)
            }
        }

        // Make whole screen scrollable by bringing the scrollview to the top
        view.bringSubviewToFront(scrollView)

        // Activate the first card
        setActiveIntroView(introViews[0], forPage: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.snp_remakeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(self.startBrowsingButton.snp_top)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            if let imageView = slideContainer.subviews[i] as? UIImageView {
                imageView.frame = CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide)
                imageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
        slideContainer.frame = CGRect(x: 0, y: 0, width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        scrollView.contentSize = CGSize(width: slideContainer.frame.width, height: slideContainer.frame.height)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> Int {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    func SELstartBrowsing() {
        delegate?.introViewControllerDidFinish(self)
    }

    func SELback() {
        if introView == introViews[1] {
            setActiveIntroView(introViews[0], forPage: 0)
            scrollView.scrollRectToVisible(scrollView.subviews[0].frame, animated: true)
            pageControl.currentPage = 0
        } else if introView == introViews[2] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        }
    }

    func SELforward() {
        if introView == introViews[0] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        } else if introView == introViews[1] {
            setActiveIntroView(introViews[2], forPage: 2)
            scrollView.scrollRectToVisible(scrollView.subviews[2].frame, animated: true)
            pageControl.currentPage = 2
        }
    }

    func SELlogin() {
		delegate?.introViewControllerDidRequestToLogin(self)
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        setActiveIntroView(introViews[page], forPage: page)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let maximumHorizontalOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame)
        let currentHorizontalOffset = scrollView.contentOffset.x

        var percentage = currentHorizontalOffset / maximumHorizontalOffset
        var startColor: UIColor, endColor: UIColor

        if(percentage < 0.5) {
            startColor = IntroViewControllerUX.Card1Color
            endColor = IntroViewControllerUX.Card2Color
            percentage = percentage * 2
        } else {
            startColor = IntroViewControllerUX.Card2Color
            endColor = IntroViewControllerUX.Card3Color
            percentage = (percentage - 0.5) * 2
        }

        slideContainer.backgroundColor = colorForPercentage(percentage, start: startColor, end: endColor)
    }

    private func colorForPercentage(percentage: CGFloat, start: UIColor, end: UIColor) -> UIColor {
        let s = start.components
        let e = end.components
        let newRed   = (1.0 - percentage) * s.red   + percentage * e.red
        let newGreen = (1.0 - percentage) * s.green + percentage * e.green
        let newBlue  = (1.0 - percentage) * s.blue  + percentage * e.blue
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

    private func setActiveIntroView(newIntroView: UIView, forPage page: Int) {
        if introView != newIntroView {
            UIView.animateWithDuration(IntroViewControllerUX.FadeDuration, animations: { () -> Void in
                self.introView?.alpha = 0
                self.introView = newIntroView
                newIntroView.alpha = 1.0
            }, completion: { _ in
                if page == 2 {
                    self.scrollView.signinButton = self.signInButton
                } else {
                    self.scrollView.signinButton = nil
                }
            })
        }
    }

    private var scaledWidthOfSlide: CGFloat {
        return view.frame.width
    }

    private var scaledHeightOfSlide: CGFloat {
        return (view.frame.width / slides[0].size.width) * slides[0].size.height / slideVerticalScaleFactor
    }

    private func addForwardButtonToIntroView(introView: UIView) {
        let button = UIImageView(image: UIImage(named: "intro-arrow"))
        introView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(introView)
            make.right.equalTo(introView.snp_right).offset(-IntroViewControllerUX.BackForwardButtonEdgeInset)
        }
    }

    private func attributedStringForLabel(text: String) -> NSMutableAttributedString {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = IntroViewControllerUX.CardTextLineHeight
        paragraphStyle.alignment = .Center

        var string = NSMutableAttributedString(string: text)
        string.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, string.length))
        return string
    }

    private func addLabelsToIntroView(introView: UIView, text: String, title: String = "") {
        let label = UILabel()

        label.numberOfLines = 0
        label.attributedText = attributedStringForLabel(text)
        label.font = IntroViewControllerUX.CardTextFont
        introView.addSubview(label)
        label.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView)
            make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
        }

        if !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = NSTextAlignment.Center
            titleLabel.text = title
            titleLabel.font = IntroViewControllerUX.CardTitleFont
            introView.addSubview(titleLabel)
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(introView)
                make.bottom.equalTo(label.snp_top)
                make.centerX.equalTo(introView)
                make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
            }
        }

    }
}

private class IntroOverlayScrollView: UIScrollView {
    weak var signinButton: UIButton?

    private override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if let signinFrame = signinButton?.frame {
            let convertedFrame = convertRect(signinFrame, fromView: signinButton?.superview)
            if CGRectContainsPoint(convertedFrame, point) {
                return false
            }
        }

        return CGRectContainsPoint(CGRect(origin: self.frame.origin, size: CGSize(width: self.contentSize.width, height: self.frame.size.height)), point)
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
}
