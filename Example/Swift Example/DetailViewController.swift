//
//  DetailViewController.swift
//  chat-demo
//
//  Created by Joey on 8/29/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet var detailTextView: UITextView!
    
    var detailText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailTextView.text = detailText
    }
}