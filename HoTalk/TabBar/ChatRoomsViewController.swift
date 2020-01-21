//
//  ChatRoomsViewController.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/06/10.
//  Copyright © 2019 hojung. All rights reserved.
//

import UIKit
import Firebase

class ChatRoomsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var uid: String!
    var chatrooms: [ChatModel]! = []
    let databaseRef = Database.database().reference()
    var destinationUsers: [String] = []
    
    @IBOutlet weak var listTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uid = Auth.auth().currentUser?.uid
        
        self.getChatRoomsList()
        // Do any additional setup after loading the view.
    }
    
    func getChatRoomsList() {
        
        self.chatrooms.removeAll()
        
        databaseRef.child("chatrooms").queryOrdered(byChild: "users/" + uid).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatroomDic = item.value as? [String:AnyObject] {
                    let chatModel = ChatModel(JSON: chatroomDic)
                    self.chatrooms.append(chatModel!)
                    
                }
            }
            print("Comments's count info is \(self.chatrooms.count)")
            print("COmments's Info is \(String(describing: self.chatrooms.toJSONString()))")
            self.listTableView.reloadData()
        })
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("ChatRooms's count of rows is \(self.chatrooms.count - 1)")
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        var destinationUid: String?
        
        for item in chatrooms[indexPath.row].users {
            if (item.key != self.uid) {
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
            }
        }
        
        databaseRef.child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasanpshot) in
            
                let userModel = UserModel()
                userModel.setValuesForKeys(datasanpshot.value as! [String : AnyObject])
            
                cell.titleLabel.text = userModel.name
                let url = URL(string: userModel.profileImageurl!)
                URLSession.shared.dataTask(with: url!, completionHandler: { (data, resopond, error) in
                    
                    DispatchQueue.main.sync {
                        cell.imageview.image = UIImage(data: data!)
                        cell.imageview.layer.cornerRadius = cell.imageview.frame.height / 2
                        print("image's cornerRadius is \(cell.imageview.layer.cornerRadius)")
                        cell.imageview.layer.masksToBounds = true
                    }
                }).resume()
            
            let lastMessgeKey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.lastMessegeLabel.text = self.chatrooms[indexPath.row].comments[lastMessgeKey[0]]?.messege
            
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessgeKey[0]]?.timestamp
            
            cell.timestampLabel.text = unixTime?.toDayTime
            
            })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let destinationUid = self.destinationUsers[indexPath.row]
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        
        view.destinationUid = destinationUid
        
        self.navigationController?.pushViewController(view, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        viewDidLoad()
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

class CustomCell: UITableViewCell {
    
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessegeLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
}
