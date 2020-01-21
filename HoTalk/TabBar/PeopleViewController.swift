//
//  PeopleViewController.swift
//  HowlTalk
//
//  Created by 김호중 on 2019/05/19.
//  Copyright © 2019 hojung. All rights reserved.
//

import UIKit
import SnapKit
import Firebase

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var arrayUserInfo : [UserModel] = []
    var tableview: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview = UITableView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(PeopleViewTableCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableview)
        tableview.snp.makeConstraints { (m) in
            m.top.equalTo(view)
            m.bottom.left.right.equalTo(view)
            
        }
        
        let userID = Auth.auth().currentUser?.uid
        print(userID!)
        
        Database.database().reference().child("users").observe(DataEventType.value, with:  { (snapshot) in
            
            self.arrayUserInfo.removeAll()
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children {
                
                let fetChild = child as! DataSnapshot
                let userModel = UserModel()
                
                userModel.setValuesForKeys(fetChild.value as! [String : Any])
                
                if(userModel.uid == myUid) {
                    continue
                }
                
                self.arrayUserInfo.append(userModel)
            }
            DispatchQueue.main.async {
                self.tableview.reloadData();
            }
        })
        

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayUserInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableview.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PeopleViewTableCell
        
        let imageView = cell.imageview!
        cell.addSubview(imageView)
        imageView.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(cell).offset(10)
            m.height.width.equalTo(50)
        }
        
        guard let profileImageurl: String = arrayUserInfo[indexPath.row].profileImageurl else {
            print("fail")
            return cell
        }


        URLSession.shared.dataTask(with: URL(string: profileImageurl)!) { (data, response, error) in
            
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data!)
                imageView.layer.cornerRadius = imageView.frame.size.width / 2
                imageView.clipsToBounds = true
            }
        }.resume()
        
        let label = cell.label!
        cell.addSubview(label)
        label.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(imageView.snp.right).offset(30)
            
        }
        
        label.text = arrayUserInfo[indexPath.row].name
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let view =  self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        view?.destinationUid = self.arrayUserInfo[indexPath.row].uid
        
        self.navigationController?.pushViewController(view!, animated: true)
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

class PeopleViewTableCell: UITableViewCell {
    
    var imageview: UIImageView! = UIImageView()
    var label: UILabel! = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview)
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
