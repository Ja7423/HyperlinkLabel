//
//  ViewController.swift
//  HyperlinkLabel
//
//  Created by 家瑋 on 2021/7/7.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label1: HyperlinkLabel!
    @IBOutlet weak var label2: HyperlinkLabel!
    @IBOutlet weak var label3: HyperlinkLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        label1.numberOfLines = 0
        label1.backgroundColor = .lightGray
        label1.linkColor = .red
        label1.textColor = .black
        label1.underLine = 1
        label1.text = "123456789 https://github.com/Ja7423/HyperlinkLabel"
        label1.delegate = self
        
        let text = "swift roadmap"
        label2.text = text
        label2.addLink("https://medium.com/geekculture/guidelines-roadmap-and-resources-for-beginner-to-advanced-ios-app-development-using-swift-7370996b0dc5",
                       range: NSRange(location: 0, length: text.count))
        
        label3.delegate = self
        label3.text = "https://www.youtube.com/channel/UC8UlXXAlPiBsV-rKvMh_T0g 和 https://www.youtube.com/watch?v=MRKLggeJqLA"
    }
}

extension ViewController: HyperlinkDelegate {
    func tapLink(label: HyperlinkLabel, link: String) {
        guard let url = URL(string: link) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: {
                print("open \($0)")
            })
        }
    }
}

