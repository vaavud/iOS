//
//  HistoryController.swift
//  Vaavud
//
//  Created by Diego R on 12/3/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

protocol HistoryDelegate: class {
    func fetchedMeasurements()
    func gotMeasurements()
    func noMeasurements()
}

class HistoryController: NSObject {
    unowned var delegate: HistoryDelegate
    let firebase = Firebase(url: firebaseUrl)
    var sessionss = [[Session]]()
    var sessionDates = [String]()
    var addedSessionHandle: UInt!
    var changedSessionHandle: UInt!
    var sessionsLoaded = false
    
    
    
    init(delegate: HistoryDelegate) {
        self.delegate = delegate
        super.init()
        
        
        setupFirebase()
    }
    
    deinit {
        guard AuthorizationController.shared.isAuth else {
            return
        }
        
        firebase.childByAppendingPath("session").removeObserverWithHandle(addedSessionHandle)
        firebase.childByAppendingPath("session").removeObserverWithHandle(changedSessionHandle)
    }
    
    func setupFirebase() {
        
        guard  AuthorizationController.shared.isAuth else {
            return
        }
        
        
        let uid = firebase.authData.uid
        let ref = firebase.childByAppendingPath("session")
            .queryOrderedByChild("uid")
            .queryEqualToValue(uid)
        
        
        addedSessionHandle = ref.observeEventType(.ChildAdded, withBlock: { [unowned self] snapshot in
            
            if !self.sessionsLoaded {
                return
            }
            
            guard snapshot.value["timeEnd"] is Double else {
                return
            }
            
            self.addToStack(Session(snapshot: snapshot))
            })
        
        changedSessionHandle = ref.observeEventType(.ChildChanged, withBlock: { [unowned self] snapshot in
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
            self.delegate.fetchedMeasurements()
            })
        
        
        ref.observeSingleEventOfType(.Value, withBlock: { [weak self] snapshot in
            if snapshot.childrenCount > 0 {
                
                if let values = snapshot.value as? FirebaseDictionary {
                    var stackOfSessions : [Session] = []
                    for (key, val) in values {
                        guard let fbDictionary  = val as? FirebaseDictionary else {
                            fatalError("Wrong Firebase dictionary")
                        }
                        
                        stackOfSessions.append(Session(dict: fbDictionary, key: key))
                    }
                    
                    stackOfSessions.sortInPlace({$0.timeStart.timeIntervalSinceNow < $1.timeStart.timeIntervalSinceNow})
                    
                    for session in stackOfSessions {
                        self?.addToStack(session)
                    }
                    
                    self?.delegate.gotMeasurements()
                    self?.delegate.fetchedMeasurements()
                    self?.sessionsLoaded = true
                }
            }
            else {
                self?.delegate.noMeasurements()
            }
        })
    }
    
    func removeItem(session: Session, section: Int, row: Int) {
        sessionss[section].removeAtIndex(row)
        firebase.childByAppendingPaths("session", session.key).removeValue()
        firebase.childByAppendingPaths("sessionDeleted", session.key).setValue(session.fireDict)
    }
    
    func removeSection(section: Int) {
        sessionss.removeAtIndex(section)
        sessionDates.removeAtIndex(section)
    }
    
    func addToStack(session: Session) {
        let sessionDate = VaavudFormatter.shared.localizedTitleDate(session.timeStart)
        
        

        
        if sessionss.isEmpty {
            sessionDates.append(sessionDate)
            sessionss.append([session])
            return
        }
        
        for (index, date) in sessionDates.enumerate() {
            if date == sessionDate {
                sessionss[index].insert(session, atIndex: 0)
                return
            }
        }
        
        sessionDates.insert(sessionDate, atIndex: 0)
        sessionss.insert([session], atIndex: 0)
    }
}
