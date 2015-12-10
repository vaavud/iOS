//
//  HistoryController.swift
//  Vaavud
//
//  Created by Diego R on 12/3/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

protocol HistoryDelegate{
    func updateTable(sessions: [[Session]], sessionDates: [String])
}


class HistoryController: NSObject {

    var delegate: HistoryDelegate?
    let firebaseSession = Firebase(url: "https://vaavud-core-demo.firebaseio.com/")
    var sessions = [[Session]]()
    var sessionDate = [String]()

    init(delegate: HistoryDelegate){
        super.init()
        self.delegate = delegate
        getData()
    }
    
    func getData() {
        let uid = firebaseSession.authData.uid
        let ref = firebaseSession.childByAppendingPath("session")
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeEventType(.ChildAdded, withBlock: { snapshot in
            
            guard let _ = snapshot.value["timeEnd"] as? Double else{
                return
            }
            
            
            self.addSessionToStack(Session(snapshot: snapshot))
        })
        
        ref.queryOrderedByChild("uid").queryEqualToValue(uid).observeEventType(.ChildChanged, withBlock: { snapshot in
            guard snapshot.value["timeEnd"] is Double else{
                return
            }
        
            for session in self.sessions {
                for sess in session {
                    if snapshot.key == sess.key {
                        return
                    }
                }
            }
            
            self.addSessionToStack(Session(snapshot: snapshot))
        })
    }
    
    func removeItem(key: String, sessionDeleted: Session,section: Int, row: Int){
        
        sessions[section].removeAtIndex(row)
        
        let ref = firebaseSession.childByAppendingPath("session")
        let deletedRef = firebaseSession.childByAppendingPath("sessionDeleted")
        
        
        ref.childByAppendingPath(key).removeValue()
        deletedRef.childByAppendingPath(key).setValue(sessionDeleted.fireDict())
    }
    
    func addSessionToStack(session: Session) {
        if let sessioniate = VaavudFormatter.shared.localizedTitleDate(session.timeStart) {
            
            print(session.key)
            
            if sessions.isEmpty {
                sessionDate.append(sessioniate)
                sessions.append([session])
                delegate!.updateTable(sessions,sessionDates: sessionDate)
                return
            }
            
            for (index,date) in sessionDate.enumerate() {
                if date == sessioniate {
                    sessions[index].insert(session, atIndex: 0)
                    delegate!.updateTable(sessions,sessionDates: sessionDate)
                    return
                }
            }
            
            sessionDate.insert(sessioniate, atIndex: 0)
            sessions.insert([session], atIndex: 0)
            
            delegate!.updateTable(sessions,sessionDates: sessionDate)
            
        }
    }
}
