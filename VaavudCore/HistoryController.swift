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
    let firebaseSession = Firebase(url: firebaseUrl)
    var sessionss = [[Session]]()
    var sessionDates = [String]()
    var count: UInt = 0

    init(delegate: HistoryDelegate) {
        self.delegate = delegate
        super.init()
        setupFirebase()
    }
    
    func setupFirebase() {
        let uid = firebaseSession.authData.uid
        let ref = firebaseSession.childByAppendingPath("session")
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeEventType(.ChildAdded, withBlock: { snapshot in
            self.count++
            
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
    
    func removeItem(key: String, sessionDeleted: Session,section: Int, row: Int) {
        sessionss[section].removeAtIndex(row)
        
//        let ref = firebaseSession.childByAppendingPath("session")
//        let deletedRef = firebaseSession.childByAppendingPath("sessionDeleted")
//        
//        ref.childByAppendingPath(key).removeValue()
//        deletedRef.childByAppendingPath(key).setValue(sessionDeleted.fireDict)
        
        firebaseSession.childByAppendingPaths("session", key).removeValue()
        firebaseSession.childByAppendingPaths("sessionDeleted", key).setValue(sessionDeleted.fireDict)
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
