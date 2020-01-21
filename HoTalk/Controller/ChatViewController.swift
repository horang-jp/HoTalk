//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/05/26.
//  Copyright © 2019 hojung. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var textfieldMessege: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var uid: String?
    var chatRoomUid: String?
    var comments: [ChatModel.Comment] = []
    var userModel = UserModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createChatRoom), for: .touchUpInside)
        
        checkChatRoom()
        
        self.tabBarController?.tabBar.isHidden = true
        
        NotificationCenter.default.addObserver(self , selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self , selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tap: UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    // Close
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        
        let notiInfo = notification.userInfo!
        let keyboardFrame = notiInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let height = keyboardFrame.size.height + 20
        
        let animationDuration = notiInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
    
        UIView.animate(withDuration: animationDuration, animations: {
            self.bottomConstraint.constant = height - self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }, completion: {
            (complete) in
        
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        })
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let notiInfo = notification.userInfo!
        let animationDuration = notiInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        
        UIView.animate(withDuration: animationDuration) {
            self.bottomConstraint.constant = 20
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(comments.count)
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        print(self.comments[indexPath.row].messege!)
        
        let defaultCell: UITableViewCell
        
        if(self.comments[indexPath.row].uid == uid) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "myMessegeCell", for: indexPath) as! MyMessegeCell
            guard let messege = self.comments[indexPath.row].messege else {
                return cell
            }
            cell.myMessegeLabel.text = messege
            cell.myMessegeLabel.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp {
                 cell.timestampLabel.text = time.toDayTime
            }
            
            defaultCell = cell
            
            return defaultCell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "destinationMessegeCell", for: indexPath) as! DestinationMessegeCell
            guard let messege = self.comments[indexPath.row].messege else {
                return cell
            }
            guard let name = userModel.name else {
                return cell
            }
            print("messege is \(messege)")
            print("name is \(name)")
            cell.destinationNameLabel?.text = name
            cell.destinationMessegeLabel.text = messege
            cell.destinationMessegeLabel.numberOfLines = 0
            
            let url = URL(string: self.userModel.profileImageurl!)
            print("url is \(String(describing: url))")
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                
                DispatchQueue.main.sync {
                    
                    cell.destinationImageViewProfile.image = UIImage(data: data!)
                    cell.destinationImageViewProfile.layer.cornerRadius = cell.destinationImageViewProfile.frame.width/2
                    cell.destinationImageViewProfile.clipsToBounds = true
                }
            }).resume()
            
            if let time = self.comments[indexPath.row].timestamp {
                cell.timestampLabel.text = time.toDayTime
            }
            
            defaultCell = cell
            
            return defaultCell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    public var destinationUid: String? // 나중에 내가 사용할 대상의 uid
    
    @objc func createChatRoom() {
        
        let createChatRoomInfo: Dictionary<String, Any> =  [ "users" : [
            uid! : true,
            destinationUid! : true
            ]
        ]
        
        if(chatRoomUid == nil) {
            
            self.sendButton.isEnabled = false
            // 방 생성 코드
            // callBack하는 메소드
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createChatRoomInfo, withCompletionBlock: { (error, reference) in
                if(error == nil) {
                    
                    self.checkChatRoom()
                    
                }
            })
        } else {
            let value: Dictionary<String, Any> = [
                "uid" : uid!,
                "messege" : self.textfieldMessege.text!,
                "timestamp" : ServerValue.timestamp()
            ] 
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: { (error, reference) in
                self.textfieldMessege.text = ""
            })
        }
        
    }

    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomDic = item.value as? [String : AnyObject] {
                    
                    let chatModel = ChatModel(JSON: chatRoomDic)
                    
                    if(chatModel?.users[self.destinationUid!] == true) {
                        
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        self.getDestinationInfo()
                    }
                }
                
                
            }
        })
    }
    
    func getDestinationInfo() {
        
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.userModel = UserModel()
            self.userModel.setValuesForKeys(datasnapshot.value as! [String : Any])
            print("destinationUid is \(String(describing: self.userModel.uid))")
            self.getMessegeList()
        })
    }
    
    func getMessegeList() {
        Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments").observe(DataEventType.value, with: { (datasnapshot) in
            
            self.comments.removeAll()
            for  item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                let comment = ChatModel.Comment(JSON: item.value as! [String : AnyObject])
                self.comments.append(comment!)
                
                
            }
            
            self.tableview.reloadData()
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item: self.comments.count - 1, section: 0), at: UITableView.ScrollPosition.bottom, animated: true)
            }
        })
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension Int {
    
    var toDayTime: String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateFormat = "HH:mm"
        let date = Date(timeIntervalSince1970: Double(self) / 1000)
        let currentTime: String = dateFormatter.string(from: date)
        print("currentTiem is \(currentTime)")
        
        return currentTime
    }
}

class MyMessegeCell: UITableViewCell {
    
    @IBOutlet weak var myMessegeLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    
}

class DestinationMessegeCell: UITableViewCell {
    
    @IBOutlet weak var destinationImageViewProfile: UIImageView!
    @IBOutlet weak var destinationMessegeLabel: UILabel!
    @IBOutlet weak var destinationNameLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
}
