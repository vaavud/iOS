//
//  CoreLoadingHistoryViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 23/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class CoreLoadingHistoryViewController: UIViewController {
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        println("viewWillAppear")
        update()
    }
    
    func update() {
        if AccountManager.sharedInstance().isLoggedIn() {
            if ServerUploadManager.sharedInstance().isHistorySyncBusy {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "historySynced:", name: "HistorySynced", object: nil)
            }
            else {
                showHistory()
                // ServerUploadManager.sharedInstance().syncHistory(2, ignoreGracePeriod: false, success: showHistory, failure: nil)
            }
        }
        else {
            let storyboard = UIStoryboard(name: "Register", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("RegisterViewController") as RegisterViewController
            vc.teaserLabelText = NSLocalizedString("HISTORY_REGISTER_TEASER", comment: "") // LOKALISERA
            vc.completion = { let _ = self.navigationController?.popToViewController(self, animated: false) }
            navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    func historySynced(note: NSNotification) {
        showHistory()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func showHistory() {
        let id = MeasurementSession.MR_findFirst() == nil ? "EmptyHistoryViewController" : "HistoryViewController"
        let vc = storyboard?.instantiateViewControllerWithIdentifier(id) as UIViewController
        vc.navigationItem.hidesBackButton = true;
        navigationController?.pushViewController(vc, animated: false)
    }
}
