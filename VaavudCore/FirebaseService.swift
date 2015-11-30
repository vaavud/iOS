//
//  FirebaseSer.swift
//  samplePush
//
//  Created by Diego R on 11/12/15.
//  Copyright © 2015 Diego R Galindo. All rights reserved.
//

import Firebase

typealias FirebaseDictionary = [String : AnyObject]


func getDictionary(obj: Any) -> FirebaseDictionary{
    
    let ref = Mirror(reflecting: obj)
    var model = [String : AnyObject]()
    
    for (key, value) in ref.children {
        if let key = key {
            model[key] = value as? AnyObject
        }
        
    }
    
    return model
}



class FirebaseService: NSObject {

    let FIREBASE_URL = "https://vaavud-core-demo.firebaseio.com"
    let vaavudRootFirebase : Firebase
    
    class var sharedInstance: FirebaseService {
        struct Static {
            static let instance: FirebaseService = FirebaseService()
        }
        return Static.instance
    }
    
    override init(){
        vaavudRootFirebase = Firebase(url: FIREBASE_URL)
    }
    
    
    func login(user : String, password : String, callback: (Bool, String) -> Void) {
        
        vaavudRootFirebase.authUser(user, password: password) {
            error, authData in
            if error != nil {
                callback(false, "")
            }
            else {
                callback(true, authData.uid)
            }
        }
    }
    
    
    /*func setHistoryDelegate(historyDelegate : IHistoryDelegate){
        historyController = historyDelegate
        initHistory()
    }
    
    func setMapDelegate(mapDelegate : IMapDelegate){
        mapController = mapDelegate
        initMap()
    }
    
    func initHistory(){
        let ref = vaavudRootFirebase.childByAppendingPath("session").queryOrderedByChild("uid")
        
        print(User.sharedInstance.uid)
        
        ref.queryEqualToValue(User.sharedInstance.uid!).observeEventType(.ChildAdded, withBlock: { snapshot in
            self.historyController?.getMyHistory(snapshot)
        })
    }
    
    func initMap(){
        let ref = vaavudRootFirebase.childByAppendingPath("session")
        
        ref.queryOrderedByChild("timeStart").queryStartingAtValue(1447405235188).observeEventType(.ChildAdded, withBlock: { snapshot in
            print(snapshot)
            self.mapController?.onNewMapAdded(snapshot)
        })
    }*/
    
    
    func logout(){
        vaavudRootFirebase.unauth()
    }
    
    
    
    func createUser(name : String, password : String, callback: ((Bool, String) -> ())) {
        vaavudRootFirebase.createUser(name, password: password, withValueCompletionBlock: {error,authData in
            if (authData != nil) {
                let uid = authData["uid"] as! String
                callback(true,uid)
            }
            else{
                callback(false,"")
            }
            
        });
    }
    
    func push(smth: User) {
        
    }
    
    func pushItem(child : String, items : FirebaseDictionary) -> String {
        let ref = vaavudRootFirebase.childByAppendingPath(child)
        let post = ref.childByAutoId()
        post.setValue(items)
        return post.key
    }
    
    
    func pushItemByKey(child : String, key : String, items : AnyObject){
        vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key).setValue(items)
    }
    
    
    func deleteItem(child : String, key: String){
        let ref = vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key)
        ref.removeValue()
    }
    
    
    func updateChild(child : String, key : String, items : [NSObject : AnyObject]) {
        vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key).updateChildValues(items)
    }
    
    func getRowByValue(child : String, key : String, value : String ) {
        
        let ref = vaavudRootFirebase.childByAppendingPath(child).queryOrderedByChild(key).queryEqualToValue(value)
        
        print(ref)
        
        ref.observeSingleEventOfType(.Value, withBlock: {
            print($0)
        })
        
        //UIView.animateWithDuration(1, animations: {})
        //UIView.animateWithDuration(1) {}
    }
    
    func getRow(child : String, key : String, callback : (FDataSnapshot) -> Void) {
        let ref = vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key)
        
        ref.observeSingleEventOfType(.Value, withBlock: {data in
            callback(data)
        });
    }
    
    
    func authWithFacebook(accessToken : String, callback: (Bool, String) -> Void) {
        
        vaavudRootFirebase.authWithOAuthProvider("facebook", token: accessToken,
            withCompletionBlock: { error, authData in
                if error != nil {
                    print("Login failed. \(error)")
                    callback(false,"")
                } else {
                    callback(true,authData.uid)
                    print("Logged in! \(authData.uid)")
                }
        })
        
    }
    
    
    
}
