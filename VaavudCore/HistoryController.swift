//
//  HistoryController.swift
//  Vaavud
//
//  Created by Diego R on 12/3/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

protocol HistoryDelegate {
    func fetchedMeasurements(sessions: [[Session]], sessionDates: [String])
    func gotMeasurements()
    func noMeasurements()
}

class HistoryController: NSObject {
    let delegate: HistoryDelegate
    let firebase = Firebase(url: firebaseUrl)
    var sessionss = [[Session]]()
    var sessionDates = [String]()

    init(delegate: HistoryDelegate) {
        self.delegate = delegate
        super.init()
        setupFirebase()
    }
    
    func setupFirebase() {
        let uid = firebase.authData.uid
        let ref = firebase.childByAppendingPath("session")
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeEventType(.ChildAdded, withBlock: { snapshot in
            guard snapshot.value["timeEnd"] is Double else {
                return
            }
            
            self.addToStack(Session(snapshot: snapshot))
        })
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeEventType(.ChildChanged, withBlock: { snapshot in
            guard snapshot.value["timeEnd"] is Double else {
                return
            }
            
            for sessions in self.sessionss {
                for session in sessions {
                    if snapshot.key == session.key {
                        return
                    }
                }
            }
            
            self.addToStack(Session(snapshot: snapshot))
        })
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount > 0 {
                self.delegate.gotMeasurements()
            }
            else {
                self.delegate.noMeasurements()
            }
        })
    }
    
    func removeItem(session: Session, section: Int, row: Int) {
        sessionss[section].removeAtIndex(row)
        firebase.childByAppendingPaths("session", session.key).removeValue()
        firebase.childByAppendingPaths("sessionDeleted", session.key).setValue(session.fireDict)
    }
    
    func addToStack(session: Session) {
        let sessionDate = VaavudFormatter.shared.localizedTitleDate(session.timeStart)
        
        if sessionss.isEmpty {
            sessionDates.append(sessionDate)
            sessionss.append([session])
            delegate.fetchedMeasurements(sessionss, sessionDates: sessionDates)
            return
        }
        
        for (index, date) in sessionDates.enumerate() {
            if date == sessionDate {
                sessionss[index].insert(session, atIndex: 0)
                delegate.fetchedMeasurements(sessionss, sessionDates: sessionDates)
                return
            }
        }
        
        sessionDates.insert(sessionDate, atIndex: 0)
        sessionss.insert([session], atIndex: 0)
        
        delegate.fetchedMeasurements(sessionss, sessionDates: sessionDates)
    }
}
