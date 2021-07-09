//
//  HyperlinkLabel.swift
//  HyperlinkLabel
//
//  Created by 家瑋 on 2021/7/7.
//

import UIKit

@objc protocol HyperlinkDelegate: AnyObject {
    func tapLink(label: HyperlinkLabel, link: String)
}

@IBDesignable
class HyperlinkLabel: UILabel {
    
    @IBOutlet
    weak var delegate: HyperlinkDelegate?
    
    override var text: String? {
        didSet {
            if let text = text {
                detectText(text)
            }
            setNeedUpdateArrtibuteText()
        }
    }
    
    override var font: UIFont! {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    override var textColor: UIColor! {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    @IBInspectable
    var linkColor: UIColor = .blue {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    @IBInspectable
    var underLineColor: UIColor = .blue {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    var linkFont: UIFont = .systemFont(ofSize: 17.0) {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    @IBInspectable
    var underLine: Int = 0 {
        didSet {
            setNeedUpdateArrtibuteText()
        }
    }
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapHandler(_:)))
        return tapGesture
    }()
    
    private var linkTable: [NSRange: String] = [:]
    
    // MARK: -
    deinit {
        removeTapGesture()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTapGesture()
    }
    
    public func addLink(_ link: String, range: NSRange) {
        linkTable[range] = link
        setNeedUpdateArrtibuteText()
    }
    
    // MARK: - Regular expression
    private func detectText(_ text: String) {
        if let urls = detectUrl(text: text) {
            urls.forEach { r in
                if let url = string(with: r) {
                    linkTable[r] = url
                }
            }
            debugPrint(linkTable)
        }
    }
    
    private func detectUrl(text: String) -> [NSRange]? {
        let pattern = "(https?://(?:www.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9].[^\\s]{2,}|www.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9].[^\\s]{2,}|https?://(?:www.|(?!www))[a-zA-Z0-9]+.[^\\s]{2,}|www.[a-zA-Z0-9]+.[^\\s]{2,})"
        return regularExpression(pattern, text: text)
    }
    
    private func regularExpression(_ pattern: String, text: String) -> [NSRange]? {
        guard let regularExpression = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.count)
        let matchResults = regularExpression.matches(in: text, options: [], range: range)
        return matchResults.map({ $0.range })
    }
    
    // MARK: - Attribute text
    private func setNeedUpdateArrtibuteText() {
        guard let text = text else {
            self.attributedText = nil
            return
        }
        
        let normalAttrs: [NSAttributedString.Key: Any] = [.font : self.font!,
                                                          .foregroundColor: self.textColor!]
        let attributedString = NSMutableAttributedString(string: text, attributes: normalAttrs)
        
        for range in linkTable.keys {
            let attrs: [NSAttributedString.Key: Any] = [.font : linkFont,
                                                        .foregroundColor: linkColor,
                                                        .underlineStyle: underLine,
                                                        .underlineColor: underLineColor]
            attributedString.addAttributes(attrs, range: range)
        }
        
        self.attributedText = attributedString
    }

    // MARK: - Gesture
    private func addTapGesture() {
        guard tapGesture.view == nil else { return }
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func removeTapGesture() {
        removeGestureRecognizer(tapGesture)
        isUserInteractionEnabled = false
    }
    
    @objc private func tapHandler(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: self)
        guard let charIndex = characterIndex(at: touchPoint) else { return }
        debugPrint(charIndex)
        
        guard let link = linkTable.filter({ $0.key.contains(charIndex) }).first?.value else { return }
        debugPrint(link)
        
        delegate?.tapLink(label: self, link: link)
    }
}

// MARK: - UILabel extension
private extension UILabel {
    func characterIndex(at point: CGPoint) -> Int? {
        guard let attributedText = attributedText else { return nil }
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.size = bounds.size
        
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        guard textBoundingBox.contains(point) else { return nil }
        
        let location = layoutManager.characterIndex(for: point,
                                                 in: textContainer,
                                                 fractionOfDistanceBetweenInsertionPoints: nil)
        let box = layoutManager.boundingRect(forGlyphRange: NSRange(location: location, length: 1),
                                             in: textContainer)
        /*
         點擊因為換行而留下的空白處，
         layoutManager.characterIndex還是會return 該行的最後一個字的index，
         導致判定有點擊不是很精準
         */
        guard box.contains(point) else { return nil }
        return location
    }
    
    func string(with range: NSRange) -> String? {
        return (text as NSString?)?.substring(with: range)
    }
}

// MARK: - UITapGestureRecognizer
//extension UITapGestureRecognizer {
//    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
//        guard let attributedText = label.attributedText else { return false }
//
//        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
//        let layoutManager = NSLayoutManager()
//        let textContainer = NSTextContainer(size: CGSize.zero)
//        let textStorage = NSTextStorage(attributedString: attributedText)
//
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//
//        // Configure textContainer
//        textContainer.lineFragmentPadding = 0.0
//        textContainer.lineBreakMode = label.lineBreakMode
//        textContainer.maximumNumberOfLines = label.numberOfLines
//        let labelSize = label.bounds.size
//        textContainer.size = labelSize
//
//        // Find the tapped character location and compare it to the specified range
//        let locationOfTouchInLabel = self.location(in: label)
//        let textBoundingBox = layoutManager.usedRect(for: textContainer)
//        //let textContainerOffset = CGPointMake((labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
//        //(labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
//        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
//
//        //let locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x,
//        // locationOfTouchInLabel.y - textContainerOffset.y);
//        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
//        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
//        return NSLocationInRange(indexOfCharacter, targetRange)
//    }
//}
